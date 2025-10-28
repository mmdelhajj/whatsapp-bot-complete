#!/bin/bash
###############################################################################
# Claude Code Quick Setup Script
# Installs Claude Code on Ubuntu server and configures for WhatsApp Bot
###############################################################################

set -e

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║     🤖 CLAUDE CODE INSTALLATION                          ║"
echo "║        Interactive AI Assistant for Your Server          ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Check if running on Ubuntu
if ! grep -q "Ubuntu" /etc/os-release 2>/dev/null; then
    echo "⚠️  Warning: This script is designed for Ubuntu"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Step 1: Install Claude Code
echo "[1/4] 📦 Installing Claude Code..."
echo ""

if command -v claude &> /dev/null; then
    echo "✅ Claude Code already installed!"
    claude --version
else
    echo "Downloading and installing..."
    if curl -fsSL https://cli.claude.ai/install.sh | sh; then
        echo "✅ Claude Code installed successfully!"
    else
        echo "❌ Installation failed. Trying alternative method..."

        # Alternative: Direct download
        cd /tmp
        wget -q https://github.com/anthropics/claude-code/releases/latest/download/claude-code-linux-x64.tar.gz
        tar -xzf claude-code-linux-x64.tar.gz
        sudo mv claude /usr/local/bin/
        sudo chmod +x /usr/local/bin/claude

        if command -v claude &> /dev/null; then
            echo "✅ Claude Code installed via direct download!"
        else
            echo "❌ Installation failed. Please install manually."
            exit 1
        fi
    fi
fi

# Add to PATH if needed
if ! echo $PATH | grep -q "/usr/local/bin"; then
    echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.bashrc
    export PATH="/usr/local/bin:$PATH"
fi

# Step 2: Create project configuration
echo ""
echo "[2/4] ⚙️  Creating project configuration..."

mkdir -p ~/whatsapp-bot-complete/.claude

cat > ~/whatsapp-bot-complete/.claude/config.json <<'EOF'
{
  "project_name": "WhatsApp Bot - Brains ERP Integration",
  "work_dir": "/root/whatsapp-bot-complete",
  "web_root": "/var/www/whatsapp-bot",
  "custom_instructions": [
    "This is a WhatsApp bot with Brains ERP integration for Lebanese bookstore",
    "Web root: /var/www/whatsapp-bot",
    "Admin dashboard: /var/www/whatsapp-bot/admin",
    "Nginx config: /etc/nginx/sites-available/whatsapp-bot",
    "Logs: /var/www/whatsapp-bot/logs/",
    "Database: MySQL (whatsapp_bot)",
    "APIs: Brains ERP, ProxSMS WhatsApp, Anthropic Claude",
    "When making changes, test and restart services as needed",
    "Primary issue to fix: Admin dashboard pages returning 404"
  ]
}
EOF

echo "✅ Configuration created!"

# Step 3: Authentication
echo ""
echo "[3/4] 🔐 Authentication Setup"
echo ""
echo "You need to authenticate Claude Code with your Anthropic account."
echo "This will open a browser or show you a URL to visit."
echo ""
read -p "Ready to authenticate? (y/N): " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    claude auth login

    if claude auth whoami &> /dev/null; then
        echo ""
        echo "✅ Authentication successful!"
        claude auth whoami
    else
        echo ""
        echo "⚠️  Authentication incomplete. Run later:"
        echo "   claude auth login"
    fi
else
    echo ""
    echo "⚠️  Skipping authentication. Run this later:"
    echo "   claude auth login"
fi

# Step 4: Quick system check
echo ""
echo "[4/4] 🔍 System Check..."
echo ""

# Check project directory
if [ -d "/root/whatsapp-bot-complete" ]; then
    echo "✅ Project directory: /root/whatsapp-bot-complete"
else
    echo "⚠️  Project directory not found"
fi

# Check web installation
if [ -d "/var/www/whatsapp-bot" ]; then
    echo "✅ Web installation: /var/www/whatsapp-bot"
else
    echo "⚠️  Web installation not found"
fi

# Check admin directory
if [ -d "/var/www/whatsapp-bot/admin" ]; then
    ADMIN_FILE_COUNT=$(ls -1 /var/www/whatsapp-bot/admin/*.php 2>/dev/null | wc -l)
    echo "✅ Admin directory exists ($ADMIN_FILE_COUNT PHP files)"
else
    echo "❌ Admin directory missing or empty"
fi

# Final instructions
echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║            ✅ INSTALLATION COMPLETE!                      ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "🚀 Next Steps:"
echo ""
echo "1. Start Claude Code session:"
echo "   cd ~/whatsapp-bot-complete"
echo "   claude code"
echo ""
echo "2. First command to try:"
echo "   > Fix the admin dashboard 404 errors"
echo ""
echo "3. Or ask Claude to:"
echo "   > Check system status"
echo "   > Configure ProxSMS webhook"
echo "   > Test Brains ERP integration"
echo "   > Run initial data sync"
echo ""
echo "📚 Documentation:"
echo "   ~/whatsapp-bot-complete/INSTALL-CLAUDE-CODE.md"
echo ""
echo "💡 Pro tip: Claude can now directly:"
echo "   - Read logs and configs"
echo "   - Edit files and test changes"
echo "   - Run commands and see output"
echo "   - Debug and fix issues in real-time"
echo ""
echo "🎯 Ready to start? Run:"
echo "   cd ~/whatsapp-bot-complete && claude code"
echo ""
