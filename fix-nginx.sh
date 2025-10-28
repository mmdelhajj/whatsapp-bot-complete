#!/bin/bash
###############################################################################
# Nginx Configuration Fix for WhatsApp Bot Admin Dashboard
# Fixes 404 errors on admin pages
###############################################################################

set -e

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║     🔧 NGINX CONFIGURATION FIX                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Check root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Please run as root (use: sudo bash fix-nginx.sh)"
    exit 1
fi

# Detect PHP version
echo "[1/4] 🔍 Detecting PHP version..."
PHP_VERSION=""
for version in 8.3 8.2 8.1 8.0 7.4; do
    if [ -S "/run/php/php${version}-fpm.sock" ]; then
        PHP_VERSION=$version
        break
    fi
done

if [ -z "$PHP_VERSION" ]; then
    echo "❌ No PHP-FPM socket found!"
    exit 1
fi

echo "    ✅ Found PHP $PHP_VERSION"

# Get domain from current config
echo "[2/4] 📋 Getting current configuration..."
DOMAIN=$(grep "server_name" /etc/nginx/sites-available/whatsapp-bot 2>/dev/null | awk '{print $2}' | tr -d ';' || hostname -I | awk '{print $1}')
echo "    Domain/IP: $DOMAIN"

# Backup current config
echo "[3/4] 💾 Backing up current configuration..."
cp /etc/nginx/sites-available/whatsapp-bot /etc/nginx/sites-available/whatsapp-bot.backup.$(date +%Y%m%d_%H%M%S)

# Create new Nginx configuration
echo "[4/4] ⚙️  Creating new Nginx configuration..."
cat > /etc/nginx/sites-available/whatsapp-bot <<NGINX
server {
    listen 80;
    server_name $DOMAIN;
    root /var/www/whatsapp-bot/public;
    index index.php;

    # Logging
    access_log /var/www/whatsapp-bot/logs/access.log;
    error_log /var/www/whatsapp-bot/logs/error.log;

    # Admin routes - IMPORTANT: This must come before the main location block
    location ^~ /admin/ {
        alias /var/www/whatsapp-bot/admin/;
        index index.php;

        # Handle PHP files in admin directory
        location ~ \.php\$ {
            if (!-f \$request_filename) { return 404; }
            include fastcgi_params;
            fastcgi_pass unix:/run/php/php${PHP_VERSION}-fpm.sock;
            fastcgi_index index.php;
            fastcgi_param SCRIPT_FILENAME \$request_filename;
        }

        # Serve static files
        try_files \$uri \$uri/ =404;
    }

    # Handle /admin without trailing slash
    location = /admin {
        return 301 /admin/;
    }

    # Public routes
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    # PHP files in public directory
    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php${PHP_VERSION}-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }

    # Deny access to hidden files
    location ~ /\. {
        deny all;
    }

    # Deny access to sensitive files
    location ~* \.(env|md)\$ {
        deny all;
    }
}
NGINX

# Test Nginx configuration
echo ""
echo "🧪 Testing Nginx configuration..."
if nginx -t 2>&1 | grep -q "successful"; then
    echo "✅ Nginx configuration is valid"

    # Reload Nginx
    echo ""
    echo "🔄 Reloading Nginx..."
    systemctl reload nginx

    echo ""
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║            ✅ FIX COMPLETED SUCCESSFULLY!                 ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo ""
    echo "🌐 Admin Dashboard: http://$DOMAIN/admin"
    echo ""
    echo "📋 Test these URLs:"
    echo "   http://$DOMAIN/admin/customers.php"
    echo "   http://$DOMAIN/admin/messages.php"
    echo "   http://$DOMAIN/admin/orders.php"
    echo "   http://$DOMAIN/admin/products.php"
    echo ""
    echo "💾 Backup saved to:"
    echo "   /etc/nginx/sites-available/whatsapp-bot.backup.*"
    echo ""
else
    echo "❌ Nginx configuration test failed!"
    echo ""
    echo "Restoring backup..."
    mv /etc/nginx/sites-available/whatsapp-bot.backup.* /etc/nginx/sites-available/whatsapp-bot
    echo ""
    echo "Please check the error messages above."
    exit 1
fi
