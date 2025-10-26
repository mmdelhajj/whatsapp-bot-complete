#!/bin/bash
# (Copy the full installer from my previous message)
# I'll give you a shorter working version:

set -e

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║     📚 WHATSAPP BOT v4.0 - INSTALLER                     ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

[ "$EUID" -ne 0 ] && { echo "Run as root"; exit 1; }

# Check existing installation
if [ -f "/var/www/whatsapp-bot/.env" ]; then
    echo "✅ Already installed at /var/www/whatsapp-bot"
    echo "🌐 Admin: http://$(hostname -I | awk '{print $1}')/admin"
    exit 0
fi

# Configuration
read -p "Domain/IP [$(hostname -I | awk '{print $1}')]: " DOMAIN
DOMAIN=${DOMAIN:-$(hostname -I | awk '{print $1}')}

read -p "Admin email: " ADMIN_EMAIL
read -sp "Admin password: " ADMIN_PASS
echo ""

read -p "ProxSMS Account: " WHATSAPP_ACCOUNT
read -sp "ProxSMS Secret: " WHATSAPP_SECRET
echo ""

read -sp "Anthropic Key: " ANTHROPIC_KEY
echo ""

# Generate passwords
DB_PASS=$(openssl rand -base64 16)
WEBHOOK_SECRET=$(openssl rand -hex 16)

echo ""
echo "⏳ Installing (this takes 3-5 minutes)..."
export DEBIAN_FRONTEND=noninteractive

# Install packages
apt-get update -qq 2>&1 > /dev/null
apt-get install -y -qq nginx php8.2-fpm php8.2-mysql php8.2-curl mysql-server redis-server 2>&1 > /dev/null

# Setup MySQL
mysql -u root <<SQL 2>/dev/null
CREATE DATABASE IF NOT EXISTS whatsapp_bot;
CREATE USER IF NOT EXISTS 'whatsapp_user'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON whatsapp_bot.* TO 'whatsapp_user'@'localhost';
FLUSH PRIVILEGES;
SQL

# Create schema
mysql -u root whatsapp_bot <<'SCHEMA' 2>/dev/null
CREATE TABLE IF NOT EXISTS customers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    phone VARCHAR(20) UNIQUE,
    name VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS messages (
    id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT,
    direction ENUM('RECEIVED','SENT'),
    message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(id)
);
CREATE TABLE IF NOT EXISTS product_info (
    id INT AUTO_INCREMENT PRIMARY KEY,
    item_code VARCHAR(100) UNIQUE,
    item_name VARCHAR(500),
    price DECIMAL(15,2)
);
CREATE TABLE IF NOT EXISTS admin_users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE,
    password VARCHAR(255)
);
SCHEMA

# Create app
mkdir -p /var/www/whatsapp-bot/{public,admin,logs,config,src/Services,scripts}

cat > /var/www/whatsapp-bot/.env <<ENV
DB_HOST=localhost
DB_NAME=whatsapp_bot
DB_USER=whatsapp_user
DB_PASS=$DB_PASS
BRAINS_API_BASE=http://194.126.6.162:1980/Api
WHATSAPP_ACCOUNT_ID=$WHATSAPP_ACCOUNT
WHATSAPP_SEND_SECRET=$WHATSAPP_SECRET
ANTHROPIC_API_KEY=$ANTHROPIC_KEY
ENV

# Copy files from repo
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[ -d "$SCRIPT_DIR/src" ] && cp -r "$SCRIPT_DIR/src"/* /var/www/whatsapp-bot/src/ 2>/dev/null || true
[ -d "$SCRIPT_DIR/public" ] && cp -r "$SCRIPT_DIR/public"/* /var/www/whatsapp-bot/public/ 2>/dev/null || true
[ -d "$SCRIPT_DIR/admin" ] && cp -r "$SCRIPT_DIR/admin"/* /var/www/whatsapp-bot/admin/ 2>/dev/null || true
[ -d "$SCRIPT_DIR/config" ] && cp -r "$SCRIPT_DIR/config"/* /var/www/whatsapp-bot/config/ 2>/dev/null || true
[ -d "$SCRIPT_DIR/scripts" ] && cp -r "$SCRIPT_DIR/scripts"/* /var/www/whatsapp-bot/scripts/ 2>/dev/null || true

# Nginx config
cat > /etc/nginx/sites-available/whatsapp-bot <<NGINX
server {
    listen 80;
    server_name $DOMAIN;
    root /var/www/whatsapp-bot/public;
    index index.php;
    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.2-fpm.sock;
    }
}
NGINX

ln -sf /etc/nginx/sites-available/whatsapp-bot /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
systemctl reload nginx

# Create admin
HASH=$(php -r "echo password_hash('$ADMIN_PASS', PASSWORD_BCRYPT);")
mysql -u root whatsapp_bot <<ADMIN 2>/dev/null
INSERT INTO admin_users (username, password) VALUES ('admin', '$HASH');
ADMIN

# Permissions
chown -R www-data:www-data /var/www/whatsapp-bot
chmod 600 /var/www/whatsapp-bot/.env

# Save credentials
cat > /root/.whatsapp-bot-creds <<CREDS
╔═══════════════════════════════════════════════════════════╗
║            ✅ INSTALLATION COMPLETE                       ║
╚═══════════════════════════════════════════════════════════╝

Admin: http://$DOMAIN/admin
Login: admin / $ADMIN_PASS

Webhook: http://$DOMAIN/webhook-whatsapp
MySQL Password: $DB_PASS
CREDS

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║            ✅ INSTALLATION COMPLETE!                      ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "🌐 Admin: http://$DOMAIN/admin"
echo "🔗 Webhook: http://$DOMAIN/webhook-whatsapp"
echo ""
