# 📚 WhatsApp Bot v4.0 - Complete Solution

**AI-powered WhatsApp chatbot** for bookstores with full **Brains ERP integration**.

Built for **Librarie Memoires**, Tripoli, Lebanon 🇱🇧

---

## ✨ Features

- 🤖 **AI Conversations** - Claude Sonnet 4.5
- 📦 **Brains ERP** - Items, Accounts, Sales APIs
- 💬 **Real-time Webhook** - Instant responses
- 👨‍💼 **Admin Dashboard** - Manage everything
- 🔄 **Auto-sync** - Products & customers
- 🌍 **Multi-language** - Arabic, English, French

---

## 🚀 Quick Install
```bash
git clone https://github.com/mmdelhajj/whatsapp-bot-complete.git
cd whatsapp-bot-complete
sudo bash install.sh
```

**Time:** 5-10 minutes

---

## 📋 Requirements

- Ubuntu 22.04 LTS
- 2GB RAM minimum
- Brains ERP access
- ProxSMS account
- Anthropic API key

---

## 🛠️ Tech Stack

- PHP 8.2, MySQL 8.0, Nginx
- Claude AI, ProxSMS
- Redis caching

---

## 📱 Post-Install

1. **Update ProxSMS webhook:**
```
   http://YOUR-DOMAIN/webhook-whatsapp
```

2. **Access admin:**
```
   http://YOUR-DOMAIN/admin
```

3. **Run sync:**
```bash
   php /var/www/whatsapp-bot/scripts/sync_from_brains.php
```

---

## 📊 Management
```bash
# View logs
tail -f /var/www/whatsapp-bot/logs/webhook.log

# Manual sync
php /var/www/whatsapp-bot/scripts/sync_from_brains.php

# Restart services
systemctl restart php8.2-fpm nginx
```

---

## 📄 License

MIT License

---

## 👨‍💻 Author

**M. EL HAJJ**
- 🏢 Middle East Services LLC (AS213962)
- 📚 Librarie Memoires
- 📍 Tripoli, Lebanon
- 📧 mmdelhajj@gmail.com

---

**Made with ❤️ in Lebanon 🇱🇧**
