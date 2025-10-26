#!/bin/bash
###############################################################################
# WhatsApp Bot v4.0 - One-Click Installer for Ubuntu 22.04
# Complete installation with Brains ERP integration
###############################################################################

set -e

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║     📚 WHATSAPP BOT v4.0 - COMPLETE INSTALLER            ║"
echo "║        Brains ERP Integration | Claude AI                ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Check root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Please run as root (use: sudo bash install.sh)"
    exit 1
fi

# Check Ubuntu version
if ! grep -q "22.04" /etc/os-release 2>/dev/null; then
    echo "⚠️  Warning: This script is designed for Ubuntu 22.04"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check existing installation
if [ -f "/var/www/whatsapp-bot/.env" ]; then
    echo "✅ Installation detected at /var/www/whatsapp-bot"
    echo ""
    SERVER_IP=$(hostname -I | awk '{print $1}')
    echo "🌐 Admin Panel: http://$SERVER_IP/admin"
    echo "🔗 Webhook: http://$SERVER_IP/webhook-whatsapp"
    echo ""
    echo "📋 To view credentials: cat /root/.whatsapp-bot-creds"
    echo ""
    exit 0
fi

echo "📝 Configuration Required:"
echo ""

# Get configuration
read -p "🌐 Domain or IP [$(hostname -I | awk '{print $1}')]: " DOMAIN
DOMAIN=${DOMAIN:-$(hostname -I | awk '{print $1}')}

echo ""
read -p "👤 Admin username [admin]: " ADMIN_USER
ADMIN_USER=${ADMIN_USER:-admin}

read -sp "🔐 Admin password: " ADMIN_PASS
echo ""
while [ -z "$ADMIN_PASS" ]; do
    read -sp "🔐 Admin password (required): " ADMIN_PASS
    echo ""
done

echo ""
read -p "📱 ProxSMS Account ID: " WHATSAPP_ACCOUNT
read -sp "🔑 ProxSMS Secret Key: " WHATSAPP_SECRET
echo ""

echo ""
read -sp "🤖 Anthropic API Key: " ANTHROPIC_KEY
echo ""

# Generate secure passwords
DB_PASS=$(openssl rand -base64 24)
WEBHOOK_SECRET=$(openssl rand -hex 32)

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║  ⏳ Installing... (this may take 3-5 minutes)            ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

export DEBIAN_FRONTEND=noninteractive

# Update system
echo "[1/8] 🔄 Updating system packages..."
apt-get update -qq 2>&1 > /dev/null

# Install packages
echo "[2/8] 📦 Installing Nginx, PHP 8.2, MySQL, Redis..."
apt-get install -y -qq \
    nginx \
    php8.2-fpm \
    php8.2-mysql \
    php8.2-curl \
    php8.2-mbstring \
    php8.2-xml \
    mysql-server \
    redis-server \
    curl \
    git \
    2>&1 > /dev/null

# Setup MySQL
echo "[3/8] 🗄️  Setting up MySQL database..."
mysql -u root <<SQL 2>/dev/null
CREATE DATABASE IF NOT EXISTS whatsapp_bot CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'whatsapp_user'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON whatsapp_bot.* TO 'whatsapp_user'@'localhost';
FLUSH PRIVILEGES;
SQL

# Create application directory
echo "[4/8] 📁 Creating application structure..."
mkdir -p /var/www/whatsapp-bot/{public,admin,logs,config,src/{Models,Services,Controllers},scripts,admin/pages,admin/assets}

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Copy application files
echo "[5/8] 📋 Copying application files..."
if [ -d "$SCRIPT_DIR/src" ]; then
    cp -r "$SCRIPT_DIR/src"/* /var/www/whatsapp-bot/src/ 2>/dev/null || true
fi
if [ -d "$SCRIPT_DIR/public" ]; then
    cp -r "$SCRIPT_DIR/public"/* /var/www/whatsapp-bot/public/ 2>/dev/null || true
fi
if [ -d "$SCRIPT_DIR/admin" ]; then
    cp -r "$SCRIPT_DIR/admin"/* /var/www/whatsapp-bot/admin/ 2>/dev/null || true
fi
if [ -d "$SCRIPT_DIR/config" ]; then
    cp -r "$SCRIPT_DIR/config"/* /var/www/whatsapp-bot/config/ 2>/dev/null || true
fi
if [ -d "$SCRIPT_DIR/scripts" ]; then
    cp -r "$SCRIPT_DIR/scripts"/* /var/www/whatsapp-bot/scripts/ 2>/dev/null || true
fi

# Create .env file
cat > /var/www/whatsapp-bot/.env <<ENV
# Database Configuration
DB_HOST=localhost
DB_NAME=whatsapp_bot
DB_USER=whatsapp_user
DB_PASS=$DB_PASS

# Brains ERP API
BRAINS_API_BASE=http://194.126.6.162:1980/Api

# WhatsApp (ProxSMS)
WHATSAPP_ACCOUNT_ID=$WHATSAPP_ACCOUNT
WHATSAPP_SEND_SECRET=$WHATSAPP_SECRET
WEBHOOK_SECRET=$WEBHOOK_SECRET

# Anthropic Claude AI
ANTHROPIC_API_KEY=$ANTHROPIC_KEY

# Application Settings
TIMEZONE=Asia/Beirut
CURRENCY=LBP
STORE_NAME=Librarie Memoires
STORE_LOCATION=Tripoli, Lebanon
ENV

# Import database schema
echo "[6/8] 🏗️  Creating database tables..."
if [ -f "$SCRIPT_DIR/config/schema.sql" ]; then
    mysql -u root whatsapp_bot < "$SCRIPT_DIR/config/schema.sql" 2>/dev/null
fi

# Configure Nginx
echo "[7/8] ⚙️  Configuring Nginx web server..."
cat > /etc/nginx/sites-available/whatsapp-bot <<'NGINX'
server {
    listen 80;
    server_name DOMAIN_PLACEHOLDER;
    root /var/www/whatsapp-bot/public;
    index index.php;

    # Logging
    access_log /var/www/whatsapp-bot/logs/access.log;
    error_log /var/www/whatsapp-bot/logs/error.log;

    # Public routes
    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    # Admin routes
    location /admin {
        alias /var/www/whatsapp-bot/admin;
        index index.php;

        location ~ \.php$ {
            include snippets/fastcgi-php.conf;
            fastcgi_pass unix:/run/php/php8.2-fpm.sock;
            fastcgi_param SCRIPT_FILENAME $request_filename;
        }
    }

    # PHP processing
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.2-fpm.sock;
    }

    # Deny access to hidden files
    location ~ /\. {
        deny all;
    }
}
NGINX

# Replace domain placeholder
sed -i "s/DOMAIN_PLACEHOLDER/$DOMAIN/g" /etc/nginx/sites-available/whatsapp-bot

ln -sf /etc/nginx/sites-available/whatsapp-bot /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test and reload Nginx
nginx -t 2>/dev/null && systemctl reload nginx

# Create admin user
echo "[8/8] 👤 Creating admin user..."
HASH=$(php -r "echo password_hash('$ADMIN_PASS', PASSWORD_BCRYPT);")
mysql -u root whatsapp_bot <<ADMIN 2>/dev/null
INSERT INTO admin_users (username, password, role) VALUES ('$ADMIN_USER', '$HASH', 'admin')
ON DUPLICATE KEY UPDATE password = '$HASH';
ADMIN

# Set permissions
chown -R www-data:www-data /var/www/whatsapp-bot
chmod 600 /var/www/whatsapp-bot/.env
chmod 755 /var/www/whatsapp-bot/scripts/*.php

# Setup cron job for sync
echo "0 */4 * * * php /var/www/whatsapp-bot/scripts/sync_from_brains.php >> /var/www/whatsapp-bot/logs/sync.log 2>&1" | crontab -u www-data -

# Save credentials
cat > /root/.whatsapp-bot-creds <<CREDS
╔═══════════════════════════════════════════════════════════╗
║            ✅ INSTALLATION COMPLETE                       ║
╚═══════════════════════════════════════════════════════════╝

🌐 Admin Panel: http://$DOMAIN/admin
👤 Username: $ADMIN_USER
🔐 Password: $ADMIN_PASS

🔗 Webhook URL: http://$DOMAIN/webhook-whatsapp
   Configure this in ProxSMS settings

🗄️  MySQL Database:
   Host: localhost
   Database: whatsapp_bot
   User: whatsapp_user
   Password: $DB_PASS

📝 Configuration File: /var/www/whatsapp-bot/.env

🔄 Manual Sync Command:
   php /var/www/whatsapp-bot/scripts/sync_from_brains.php

📊 View Logs:
   tail -f /var/www/whatsapp-bot/logs/webhook.log

🛠️  Restart Services:
   systemctl restart php8.2-fpm nginx

═══════════════════════════════════════════════════════════

📱 Next Steps:
1. Configure ProxSMS webhook to: http://$DOMAIN/webhook-whatsapp
2. Access admin panel and test APIs
3. Run initial sync: php /var/www/whatsapp-bot/scripts/sync_from_brains.php

═══════════════════════════════════════════════════════════
CREDS

chmod 600 /root/.whatsapp-bot-creds

# Display success message
clear
echo ""
cat /root/.whatsapp-bot-creds
echo ""
echo "💾 Credentials saved to: /root/.whatsapp-bot-creds"
echo ""
