#!/bin/bash
###############################################################################
# WhatsApp Bot v4.0 - Alternative Installer (Works with any PHP version)
# Supports PHP 7.4, 8.0, 8.1, 8.2, 8.3
###############################################################################

set -e

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║     📚 WHATSAPP BOT v4.0 - ALTERNATIVE INSTALLER         ║"
echo "║        Works with PHP 7.4+ (auto-detects version)        ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Check root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Please run as root (use: sudo bash install-alt.sh)"
    exit 1
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
echo "║  ⏳ Installing... (this may take 5-10 minutes)           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

export DEBIAN_FRONTEND=noninteractive

# Update system
echo "[1/10] 🔄 Updating system packages..."
apt-get update -qq

# Install basic packages first
echo "[2/10] 📦 Installing basic packages..."
apt-get install -y software-properties-common curl git openssl 2>&1 > /dev/null

# Try to add PHP 8.2 repository (but don't fail if it doesn't work)
echo "[3/10] 📦 Adding PHP repository..."
if LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php 2>/dev/null; then
    apt-get update -qq 2>&1 > /dev/null
    echo "    ✅ PHP 8.2 repository added"
else
    echo "    ⚠️  Using system PHP version"
fi

# Detect available PHP version
echo "[4/10] 🔍 Detecting PHP version..."
PHP_VERSION=""
for version in 8.3 8.2 8.1 8.0 7.4; do
    if apt-cache show php${version}-fpm 2>/dev/null | grep -q "Package: php${version}-fpm"; then
        PHP_VERSION=$version
        break
    fi
done

if [ -z "$PHP_VERSION" ]; then
    echo "❌ No suitable PHP version found!"
    echo "Available PHP packages:"
    apt-cache search php.*-fpm | head -5
    exit 1
fi

echo "    ✅ Using PHP $PHP_VERSION"

# Install packages with detected PHP version
echo "[5/10] 📦 Installing Nginx, PHP $PHP_VERSION, MySQL, Redis..."
apt-get install -y -qq \
    nginx \
    php${PHP_VERSION}-fpm \
    php${PHP_VERSION}-mysql \
    php${PHP_VERSION}-curl \
    php${PHP_VERSION}-mbstring \
    php${PHP_VERSION}-xml \
    mysql-server \
    redis-server \
    2>&1 > /dev/null

# Setup MySQL
echo "[6/10] 🗄️  Setting up MySQL database..."
mysql -u root <<SQL 2>/dev/null
CREATE DATABASE IF NOT EXISTS whatsapp_bot CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'whatsapp_user'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON whatsapp_bot.* TO 'whatsapp_user'@'localhost';
FLUSH PRIVILEGES;
SQL

# Create application directory
echo "[7/10] 📁 Creating application structure..."
mkdir -p /var/www/whatsapp-bot/{public,admin,logs,config,src/{Models,Services,Controllers},scripts,admin/pages,admin/assets}

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Copy application files
echo "[8/10] 📋 Copying application files..."
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
echo "[9/10] 🏗️  Creating database tables..."
if [ -f "$SCRIPT_DIR/config/schema.sql" ]; then
    mysql -u root whatsapp_bot < "$SCRIPT_DIR/config/schema.sql" 2>/dev/null
fi

# Configure Nginx with detected PHP version
echo "[10/10] ⚙️  Configuring Nginx web server..."
PHP_SOCK="/run/php/php${PHP_VERSION}-fpm.sock"

cat > /etc/nginx/sites-available/whatsapp-bot <<NGINX
server {
    listen 80;
    server_name $DOMAIN;
    root /var/www/whatsapp-bot/public;
    index index.php;

    # Logging
    access_log /var/www/whatsapp-bot/logs/access.log;
    error_log /var/www/whatsapp-bot/logs/error.log;

    # Public routes
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    # Admin routes
    location /admin {
        alias /var/www/whatsapp-bot/admin;
        index index.php;

        location ~ \.php\$ {
            include snippets/fastcgi-php.conf;
            fastcgi_pass unix:$PHP_SOCK;
            fastcgi_param SCRIPT_FILENAME \$request_filename;
        }
    }

    # PHP processing
    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:$PHP_SOCK;
    }

    # Deny access to hidden files
    location ~ /\. {
        deny all;
    }
}
NGINX

ln -sf /etc/nginx/sites-available/whatsapp-bot /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test and reload Nginx
nginx -t 2>/dev/null && systemctl reload nginx

# Create admin user
echo ""
echo "👤 Creating admin user..."
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

🐘 PHP Version: $PHP_VERSION

🔄 Manual Sync Command:
   php /var/www/whatsapp-bot/scripts/sync_from_brains.php

📊 View Logs:
   tail -f /var/www/whatsapp-bot/logs/webhook.log

🛠️  Restart Services:
   systemctl restart php${PHP_VERSION}-fpm nginx

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
