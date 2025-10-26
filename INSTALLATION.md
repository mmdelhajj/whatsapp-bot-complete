# Installation Guide - WhatsApp Bot v4.0

Complete guide for installing and configuring the WhatsApp Bot with Brains ERP integration.

---

## 📋 Prerequisites

### System Requirements
- **OS:** Ubuntu 22.04 LTS (recommended)
- **RAM:** Minimum 2GB
- **Disk Space:** 5GB free
- **Root Access:** Required for installation

### API Requirements
1. **Brains ERP Access**
   - Access to Brains API endpoints
   - API Base URL: `http://194.126.6.162:1980/Api`

2. **ProxSMS Account**
   - Account ID
   - API Secret Key
   - [Sign up at ProxSMS](https://proxsms.com)

3. **Anthropic Claude API**
   - API Key for Claude Sonnet 4
   - [Get API key from Anthropic](https://console.anthropic.com)

---

## 🚀 Quick Installation (5 Minutes)

### Step 1: Clone Repository
```bash
git clone https://github.com/mmdelhajj/whatsapp-bot-complete.git
cd whatsapp-bot-complete
```

### Step 2: Run Installer
```bash
sudo bash install.sh
```

### Step 3: Follow Prompts
The installer will ask for:
- Domain or IP address
- Admin username and password
- ProxSMS credentials
- Anthropic API key

### Step 4: Wait for Completion
Installation typically takes 3-5 minutes.

---

## 📝 Post-Installation

### 1. Configure ProxSMS Webhook
Set your ProxSMS webhook URL to:
```
http://YOUR-DOMAIN/webhook-whatsapp
```

### 2. Access Admin Dashboard
```
http://YOUR-DOMAIN/admin
```

Login with credentials provided during installation.

### 3. Test API Connections
Navigate to: **Admin Dashboard → API Tests**

Test each integration:
- ✅ Brains ERP API
- ✅ Claude AI API
- ✅ ProxSMS WhatsApp API

### 4. Run Initial Sync
Sync products and accounts from Brains:
```bash
php /var/www/whatsapp-bot/scripts/sync_from_brains.php
```

---

## 🔧 Configuration

### Environment Variables
Edit `/var/www/whatsapp-bot/.env`:

```bash
# Database
DB_HOST=localhost
DB_NAME=whatsapp_bot
DB_USER=whatsapp_user
DB_PASS=auto_generated_password

# Brains ERP
BRAINS_API_BASE=http://194.126.6.162:1980/Api

# WhatsApp (ProxSMS)
WHATSAPP_ACCOUNT_ID=your_account_id
WHATSAPP_SEND_SECRET=your_secret_key
WEBHOOK_SECRET=auto_generated_secret

# Claude AI
ANTHROPIC_API_KEY=your_api_key

# Application
TIMEZONE=Asia/Beirut
CURRENCY=LBP
STORE_NAME=Librarie Memoires
STORE_LOCATION=Tripoli, Lebanon
```

### Cron Jobs
Automatic sync runs every 4 hours. To modify:
```bash
crontab -e -u www-data
```

Current schedule:
```
0 */4 * * * php /var/www/whatsapp-bot/scripts/sync_from_brains.php
```

---

## 📊 Usage

### Admin Dashboard Features

1. **Dashboard**
   - Real-time statistics
   - Recent messages and orders
   - System health

2. **Customers**
   - View all customers
   - Link Brains accounts
   - Conversation history

3. **Messages**
   - All message logs
   - Search and filter
   - Direction (received/sent)

4. **Orders**
   - Order management
   - Status updates
   - Brains invoice linking

5. **Products**
   - Product catalog
   - Stock levels
   - Search functionality

6. **Sync**
   - Manual sync trigger
   - Sync history
   - Error logs

### Manual Operations

**Run Manual Sync:**
```bash
php /var/www/whatsapp-bot/scripts/sync_from_brains.php
```

**View Webhook Logs:**
```bash
tail -f /var/www/whatsapp-bot/logs/webhook.log
```

**Restart Services:**
```bash
systemctl restart php8.2-fpm nginx
```

---

## 🔒 Security

### File Permissions
```bash
chmod 600 /var/www/whatsapp-bot/.env
chown -R www-data:www-data /var/www/whatsapp-bot
```

### Firewall (Optional)
```bash
ufw allow 80/tcp
ufw allow 443/tcp
ufw enable
```

### SSL Certificate (Recommended)
```bash
apt install certbot python3-certbot-nginx
certbot --nginx -d your-domain.com
```

---

## 🐛 Troubleshooting

### Webhook Not Receiving Messages
1. Check ProxSMS webhook configuration
2. Verify webhook URL is accessible
3. Check logs: `tail -f /var/www/whatsapp-bot/logs/webhook.log`

### Database Connection Error
1. Check MySQL service: `systemctl status mysql`
2. Verify credentials in `.env`
3. Test connection: `mysql -u whatsapp_user -p whatsapp_bot`

### API Connection Failed
1. Test APIs via Admin Dashboard → API Tests
2. Check API credentials in `.env`
3. Verify network connectivity to API endpoints

### Sync Failing
1. Check Brains API accessibility
2. Review sync logs: `tail -f /var/www/whatsapp-bot/logs/sync.log`
3. Run manual sync with verbose output

---

## 📞 Support

### View Installation Credentials
```bash
cat /root/.whatsapp-bot-creds
```

### Check Service Status
```bash
systemctl status nginx
systemctl status php8.2-fpm
systemctl status mysql
```

### Logs Location
- Application: `/var/www/whatsapp-bot/logs/app.log`
- Webhook: `/var/www/whatsapp-bot/logs/webhook.log`
- Sync: `/var/www/whatsapp-bot/logs/sync.log`
- Nginx Access: `/var/www/whatsapp-bot/logs/access.log`
- Nginx Error: `/var/www/whatsapp-bot/logs/error.log`

---

## 🔄 Updating

### Update Application
```bash
cd whatsapp-bot-complete
git pull
sudo bash install.sh
```

The installer will detect existing installation and preserve data.

---

## 🗑️ Uninstallation

```bash
# Stop services
systemctl stop nginx php8.2-fpm

# Remove application
rm -rf /var/www/whatsapp-bot

# Remove database
mysql -u root -e "DROP DATABASE whatsapp_bot; DROP USER 'whatsapp_user'@'localhost';"

# Remove Nginx config
rm /etc/nginx/sites-enabled/whatsapp-bot
rm /etc/nginx/sites-available/whatsapp-bot

# Restart Nginx
systemctl start nginx
```

---

**Made with ❤️ in Lebanon 🇱🇧**
