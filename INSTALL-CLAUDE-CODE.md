# Installing Claude Code on Your Ubuntu Server

Complete guide to install Claude Code on your WhatsApp Bot server (Ubuntu 22.04).

---

## 🎯 Why Install Claude Code?

With Claude Code installed on your server, I can:
- ✅ **Debug issues in real-time** - No more copy/paste of commands
- ✅ **Fix problems directly** - Edit configs, check logs, test immediately
- ✅ **Run diagnostics automatically** - Find and fix issues faster
- ✅ **Complete setup tasks** - Configure ProxSMS, test APIs, sync data
- ✅ **Monitor and maintain** - Check logs, restart services, update code

---

## 📋 Prerequisites

Your server already has:
- ✅ Ubuntu 22.04 LTS
- ✅ Root/sudo access
- ✅ Internet connection
- ✅ WhatsApp Bot installed at `/var/www/whatsapp-bot`

---

## 🚀 Installation Methods

### **Method 1: Quick Install (Recommended)**

```bash
# Download and run the official installer
curl -fsSL https://cli.claude.ai/install.sh | sh

# The installer will:
# - Detect your system (Ubuntu)
# - Download the appropriate binary
# - Install to /usr/local/bin/claude
# - Make it executable
```

### **Method 2: Manual Download**

```bash
# Download the latest release
cd /tmp
wget https://github.com/anthropics/claude-code/releases/latest/download/claude-code-linux-x64.tar.gz

# Extract
tar -xzf claude-code-linux-x64.tar.gz

# Move to system path
sudo mv claude /usr/local/bin/

# Make executable
sudo chmod +x /usr/local/bin/claude

# Verify installation
claude --version
```

### **Method 3: Using npm (if Node.js installed)**

```bash
# Install Node.js 20.x (if not already installed)
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install Claude Code globally
sudo npm install -g @anthropic-ai/claude-code

# Verify
claude --version
```

---

## 🔐 Authentication

After installation, authenticate Claude Code:

### **Step 1: Start Authentication**

```bash
claude auth login
```

This will:
1. Display a URL
2. Show an authentication code
3. Open your browser (or you manually visit the URL)

### **Step 2: Complete Authentication**

Option A - **On the server** (if you have a browser):
- The browser will open automatically
- Enter the code shown in terminal
- Sign in with your Anthropic account

Option B - **From your local machine** (if server has no GUI):
```bash
# On your local computer, visit the URL shown
# Enter the authentication code
# After successful auth, the server terminal will confirm
```

### **Step 3: Verify Authentication**

```bash
claude auth whoami
```

Should show your Anthropic account email.

---

## ⚙️ Configuration for Your WhatsApp Bot

### **Step 1: Navigate to Project**

```bash
cd ~/whatsapp-bot-complete
```

### **Step 2: Create Claude Code Configuration**

```bash
# Create .claude directory
mkdir -p .claude

# Create configuration file
cat > .claude/config.json <<'EOF'
{
  "project_name": "WhatsApp Bot - Brains ERP Integration",
  "work_dir": "/root/whatsapp-bot-complete",
  "web_root": "/var/www/whatsapp-bot",
  "custom_instructions": [
    "This is a WhatsApp bot with Brains ERP integration",
    "Web root: /var/www/whatsapp-bot",
    "Admin dashboard: /var/www/whatsapp-bot/admin",
    "PHP version: Auto-detected",
    "Nginx config: /etc/nginx/sites-available/whatsapp-bot",
    "Logs: /var/www/whatsapp-bot/logs/",
    "Database: MySQL (whatsapp_bot)",
    "When making changes, always test and restart services as needed"
  ]
}
EOF
```

### **Step 3: Set Environment Variables (Optional)**

```bash
# Add to ~/.bashrc for persistence
cat >> ~/.bashrc <<'EOF'

# Claude Code settings
export CLAUDE_API_KEY="your-anthropic-api-key"  # Optional if using auth login
export CLAUDE_MODEL="claude-sonnet-4-20250514"
EOF

source ~/.bashrc
```

---

## 🎮 Usage

### **Start Claude Code Session**

```bash
# Navigate to your project
cd ~/whatsapp-bot-complete

# Start Claude Code
claude code

# Or start with a specific task
claude code "Debug why admin pages show 404"
```

### **Interactive Mode**

Once in Claude Code session, you can ask:

```
> Check if all admin PHP files exist
> Show me the Nginx configuration
> What's in the error log?
> Fix the admin dashboard 404 errors
> Test the ProxSMS webhook
> Run the Brains sync script
> Check database connection
> Restart PHP-FPM and Nginx
```

### **One-Off Commands**

```bash
# Run a single task without interactive mode
claude code --exec "Check file permissions on /var/www/whatsapp-bot"

# Get current status
claude code --exec "Show system status and recent errors"

# Fix specific issue
claude code --exec "Fix Nginx configuration for admin routes"
```

---

## 🔧 Common Tasks with Claude Code

### **1. Debug Admin Dashboard**

```bash
cd ~/whatsapp-bot-complete
claude code
```

Then ask:
```
> Why are admin pages showing 404?
> Check if admin files exist and have correct permissions
> Fix the admin dashboard routing
```

### **2. Configure ProxSMS**

```
> Help me configure ProxSMS webhook
> Test ProxSMS API connection
> Show me webhook logs
```

### **3. Sync with Brains ERP**

```
> Run the Brains sync script
> Show me sync logs
> Test Brains API connection
```

### **4. Monitor System**

```
> Show recent webhook activity
> Check for errors in last hour
> What's the system status?
```

---

## 📁 Recommended Project Structure

Claude Code works best when you organize files:

```
~/whatsapp-bot-complete/          ← Git repository (start here)
├── .claude/
│   └── config.json               ← Claude Code config
├── admin/                        ← Source admin files
├── config/                       ← Source config files
├── public/                       ← Source public files
├── src/                          ← Source code
└── scripts/                      ← Utility scripts

/var/www/whatsapp-bot/           ← Live installation
├── admin/                        ← Deployed admin
├── config/                       ← Deployed config
├── public/                       ← Deployed public
├── src/                          ← Deployed code
└── logs/                         ← Application logs
```

---

## 🛠️ Troubleshooting

### **Issue: "claude: command not found"**

```bash
# Add to PATH
echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Verify
which claude
```

### **Issue: "Authentication failed"**

```bash
# Re-authenticate
claude auth logout
claude auth login
```

### **Issue: "Permission denied"**

```bash
# Fix permissions
sudo chmod +x /usr/local/bin/claude

# Or run with sudo
sudo claude code
```

### **Issue: "Cannot find project"**

```bash
# Make sure you're in the project directory
cd ~/whatsapp-bot-complete
pwd  # Should show /root/whatsapp-bot-complete

# Then start Claude Code
claude code
```

---

## 🔒 Security Notes

1. **API Key**: Claude Code uses your Anthropic account
2. **Root Access**: Can execute commands with sudo
3. **File Access**: Can read/write files in the project
4. **Best Practice**: Run in the project directory only

### **Secure Configuration**

```bash
# Protect Claude Code config
chmod 600 .claude/config.json

# Don't commit API keys to git
echo ".claude/" >> .gitignore
```

---

## 📊 What Happens Next

After installing Claude Code on your server:

### **Immediate Benefits:**

1. **I can directly debug** your admin 404 issue
   - Check which files are missing
   - Verify Nginx configuration
   - Test PHP processing
   - Fix permissions

2. **I can configure ProxSMS**
   - Set webhook URL
   - Test API connection
   - Verify credentials

3. **I can setup Brains sync**
   - Test API endpoints
   - Run initial sync
   - Configure cron jobs

4. **I can monitor and maintain**
   - Check logs in real-time
   - Restart services when needed
   - Update configurations

### **Interactive Session Example:**

```
You: Install Claude Code on server
Me: [Checking installation...]
Me: ✅ Claude Code installed successfully!
Me: [Checking admin files...]
Me: ❌ Found issue: admin files missing!
Me: [Copying files from repo...]
Me: [Setting permissions...]
Me: [Testing...]
Me: ✅ Admin dashboard fixed!
You: Test the ProxSMS webhook
Me: [Checking ProxSMS config...]
Me: [Testing webhook endpoint...]
Me: ✅ Webhook working!
```

Much faster than copy/paste! 🚀

---

## 📖 Additional Resources

- **Claude Code Docs**: https://docs.claude.ai/claude-code
- **GitHub**: https://github.com/anthropics/claude-code
- **Support**: https://support.anthropic.com

---

## ✅ Quick Start Checklist

After installation, verify everything:

```bash
# 1. Check Claude Code is installed
claude --version

# 2. Check authentication
claude auth whoami

# 3. Navigate to project
cd ~/whatsapp-bot-complete

# 4. Start interactive session
claude code

# 5. First command to try
> Check the system status and show me what needs to be fixed
```

---

## 🎯 Next Steps

Once Claude Code is installed:

1. ✅ **Start a session**: `cd ~/whatsapp-bot-complete && claude code`
2. ✅ **Ask me to debug**: "Fix admin dashboard 404 errors"
3. ✅ **Configure ProxSMS**: "Help setup ProxSMS webhook"
4. ✅ **Test everything**: "Run all system tests"
5. ✅ **Go live**: "Make the bot operational"

**Ready to install?** Copy the commands from Method 1 above!

---

**Made with ❤️ for your WhatsApp Bot project**
