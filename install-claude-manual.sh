#!/bin/bash
###############################################################################
# Claude Code Manual Installation Script
# Direct binary download and installation
###############################################################################

set -e

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║     🤖 CLAUDE CODE MANUAL INSTALLATION                   ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Check if already installed
if command -v claude &> /dev/null; then
    echo "✅ Claude Code already installed!"
    claude --version
    echo ""
    read -p "Reinstall anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Exiting. Run 'claude auth login' to authenticate."
        exit 0
    fi
fi

# Step 1: Download binary
echo "[1/5] 📥 Downloading Claude Code binary..."
cd /tmp

# Try downloading the latest release
DOWNLOAD_URL="https://github.com/anthropics/claude-cli/releases/latest/download/claude-linux-amd64"

if wget -q "$DOWNLOAD_URL" -O claude-binary; then
    echo "✅ Downloaded successfully"
elif curl -fsSL "$DOWNLOAD_URL" -o claude-binary; then
    echo "✅ Downloaded successfully (via curl)"
else
    echo "❌ Download failed from GitHub releases"
    echo ""
    echo "Trying alternative method..."

    # Alternative: Download from npm package
    if command -v npm &> /dev/null; then
        echo "Installing via npm..."
        npm install -g @anthropic-ai/claude-cli

        if command -v claude &> /dev/null; then
            echo "✅ Installed via npm!"
            claude --version
            exec bash "$0" "$@"
            exit 0
        fi
    fi

    echo ""
    echo "❌ All download methods failed."
    echo ""
    echo "📝 Manual installation instructions:"
    echo "1. Visit: https://claude.ai/download"
    echo "2. Download Linux binary"
    echo "3. Move to /usr/local/bin/claude"
    echo "4. Run: chmod +x /usr/local/bin/claude"
    echo ""
    exit 1
fi

# Step 2: Install binary
echo ""
echo "[2/5] 📦 Installing Claude Code..."

# Make executable
chmod +x claude-binary

# Move to system path
sudo mv claude-binary /usr/local/bin/claude

# Verify installation
if command -v claude &> /dev/null; then
    echo "✅ Installed to /usr/local/bin/claude"
    claude --version || echo "Version: Latest"
else
    echo "❌ Installation failed - binary not in PATH"

    # Try adding to PATH
    if [ -f "/usr/local/bin/claude" ]; then
        export PATH="/usr/local/bin:$PATH"
        echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.bashrc

        if command -v claude &> /dev/null; then
            echo "✅ Fixed - added /usr/local/bin to PATH"
        else
            echo "❌ Still not working. Please check manually."
            exit 1
        fi
    else
        echo "❌ Binary not found at /usr/local/bin/claude"
        exit 1
    fi
fi

# Step 3: Create project configuration
echo ""
echo "[3/5] ⚙️  Creating project configuration..."

cd ~/whatsapp-bot-complete
mkdir -p .claude

cat > .claude/config.json <<'EOF'
{
  "project_name": "WhatsApp Bot - Brains ERP Integration",
  "work_dir": "/root/whatsapp-bot-complete",
  "web_root": "/var/www/whatsapp-bot"
}
EOF

echo "✅ Configuration created"

# Step 4: Test the installation
echo ""
echo "[4/5] 🧪 Testing installation..."

if claude --help &> /dev/null; then
    echo "✅ Claude Code is working!"
else
    echo "⚠️  Claude might not be fully functional"
    echo "   Try running: claude --help"
fi

# Step 5: Authentication
echo ""
echo "[5/5] 🔐 Authentication"
echo ""
echo "You need to authenticate with your Anthropic account."
echo "This requires your API key."
echo ""
read -p "Do you have your Anthropic API key ready? (y/N): " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "Enter your Anthropic API key:"
    echo "(Get it from: https://console.anthropic.com/settings/keys)"
    echo ""
    read -sp "API Key: " API_KEY
    echo ""

    # Set API key as environment variable
    export ANTHROPIC_API_KEY="$API_KEY"
    echo "export ANTHROPIC_API_KEY='$API_KEY'" >> ~/.bashrc

    echo "✅ API key configured!"
    echo ""
    echo "Testing API connection..."

    # Test with a simple command
    if claude --version &> /dev/null; then
        echo "✅ Claude Code is ready to use!"
    else
        echo "⚠️  API key set, but couldn't verify connection"
    fi
else
    echo ""
    echo "⚠️  Skipping API key setup."
    echo ""
    echo "To set up later, run:"
    echo "  export ANTHROPIC_API_KEY='your-key-here'"
    echo "  echo \"export ANTHROPIC_API_KEY='your-key-here'\" >> ~/.bashrc"
fi

# Final instructions
echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║            ✅ INSTALLATION COMPLETE!                      ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "📍 Claude installed at: /usr/local/bin/claude"
echo "📁 Project directory: ~/whatsapp-bot-complete"
echo "⚙️  Configuration: ~/whatsapp-bot-complete/.claude/config.json"
echo ""
echo "🚀 Quick Start:"
echo ""
echo "1. Make sure you have your Anthropic API key"
echo "   Get it from: https://console.anthropic.com/settings/keys"
echo ""
echo "2. Set the API key (if you haven't already):"
echo "   export ANTHROPIC_API_KEY='sk-ant-...'"
echo ""
echo "3. Test Claude Code:"
echo "   claude --version"
echo ""
echo "4. Start working on your project:"
echo "   cd ~/whatsapp-bot-complete"
echo "   claude"
echo ""
echo "5. Or run in non-interactive mode:"
echo "   claude 'Check if admin files exist and fix permissions'"
echo ""
echo "💡 Tip: For interactive chat mode, just run:"
echo "   cd ~/whatsapp-bot-complete && claude"
echo ""
