#!/bin/bash
###############################################################################
# Debug Admin Dashboard Issues
###############################################################################

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║     🔍 DEBUGGING ADMIN DASHBOARD                         ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Check if admin directory exists
echo "[1] Checking admin directory..."
if [ -d "/var/www/whatsapp-bot/admin" ]; then
    echo "✅ Directory exists: /var/www/whatsapp-bot/admin"
    echo ""
    echo "📁 Contents:"
    ls -lah /var/www/whatsapp-bot/admin/
else
    echo "❌ Directory MISSING: /var/www/whatsapp-bot/admin"
fi

echo ""
echo "[2] Checking admin PHP files..."
for file in index.php customers.php messages.php orders.php products.php sync.php test-apis.php; do
    if [ -f "/var/www/whatsapp-bot/admin/$file" ]; then
        echo "✅ $file exists"
    else
        echo "❌ $file MISSING"
    fi
done

echo ""
echo "[3] Checking file permissions..."
ls -la /var/www/whatsapp-bot/admin/ 2>/dev/null || echo "Cannot check permissions"

echo ""
echo "[4] Checking Nginx config..."
grep -A 20 "location.*admin" /etc/nginx/sites-available/whatsapp-bot

echo ""
echo "[5] Checking PHP-FPM status..."
systemctl status php*-fpm --no-pager | grep -E "(Active|Main PID)"

echo ""
echo "[6] Checking Nginx error log (last 10 lines)..."
tail -10 /var/www/whatsapp-bot/logs/error.log 2>/dev/null || tail -10 /var/log/nginx/error.log

echo ""
echo "[7] Testing PHP processing..."
echo "<?php phpinfo(); ?>" > /tmp/test-php.php
PHP_VERSION=$(php -v | head -1 | cut -d' ' -f2 | cut -d'.' -f1,2)
echo "PHP Version: $PHP_VERSION"

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║     📋 DIAGNOSIS COMPLETE - Review output above          ║"
echo "╚═══════════════════════════════════════════════════════════╝"
