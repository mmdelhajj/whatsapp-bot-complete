# Quick Start Guide

## Installation Steps

### 1. Get Latest Code
```bash
cd ~/whatsapp-bot-complete
git pull origin claude/build-sales-api-system-011CUWdUnd9xhZJgvkhGndox
```

### 2. Run the ALTERNATIVE Installer (with auto PHP detection)
```bash
sudo bash install-alt.sh
```

**IMPORTANT:** Use `install-alt.sh` NOT `install.sh`!

### 3. You Will Be Asked For:

#### Basic Config:
- **Domain/IP**: Your server IP or domain name
- **Admin Username**: Default is "admin"
- **Admin Password**: Choose a strong password

#### ProxSMS Config (Get from https://proxsms.com):

1. **🔑 ProxSMS API Secret**
   - Login to proxsms.com
   - Go to: **Tools → API Keys**
   - Copy the API secret

2. **📱 WhatsApp Account Unique ID**
   - Go to: **Dashboard** or call API `/get/wa.accounts`
   - Copy the **"unique"** field of your linked WhatsApp account
   - Example: `abc123-def456-ghi789`

3. **🔐 ProxSMS Webhook Secret**
   - Go to: **Tools → Webhooks**
   - Copy the webhook secret
   - This is DIFFERENT from API secret!

#### Anthropic Config:
4. **🤖 Anthropic API Key**
   - Get from: https://console.anthropic.com
   - Copy your API key

### 4. Configure ProxSMS Webhook After Installation

After installation completes, you must configure ProxSMS to send webhooks:

1. Login to https://proxsms.com
2. Go to **Tools → Webhooks**
3. Set webhook URL to: `http://YOUR-SERVER-IP/webhook-whatsapp`
4. Click Save

### 5. Test the Installation

```bash
# View the credentials
cat /root/.whatsapp-bot-creds

# Access admin dashboard
http://YOUR-SERVER-IP/admin

# Test APIs
http://YOUR-SERVER-IP/admin/test-apis.php

# Run initial sync
php /var/www/whatsapp-bot/scripts/sync_from_brains.php
```

---

## Troubleshooting

### If installer doesn't ask for webhook secret:
1. Make sure you pulled latest code: `git pull`
2. Make sure you're running `install-alt.sh` not `install.sh`
3. Check you're in the repo directory: `cd ~/whatsapp-bot-complete`

### If PHP installation fails:
The `install-alt.sh` automatically detects PHP version, so this shouldn't happen.

### To view logs:
```bash
tail -f /var/www/whatsapp-bot/logs/webhook.log
tail -f /var/www/whatsapp-bot/logs/app.log
```

---

## Important Notes

- The installer asks for **3 ProxSMS credentials**, not just one!
- API Secret ≠ Webhook Secret (they are different!)
- Must configure webhook URL in ProxSMS after installation
- Must run initial sync after installation

---

**Need help?** Check the logs or create an issue on GitHub.
