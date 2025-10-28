#!/bin/bash
###############################################################################
# Fix Git Divergent Branches and Nginx Configuration
# One command to fix everything
###############################################################################

set -e

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║     🔧 GIT + NGINX FIX                                   ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

cd ~/whatsapp-bot-complete

# Step 1: Check git status
echo "[1/5] 📋 Checking current status..."
git status

# Step 2: Stash any local changes
echo ""
echo "[2/5] 💾 Saving local changes..."
git stash

# Step 3: Pull latest code
echo ""
echo "[3/5] 🔄 Pulling latest code..."
git pull origin claude/build-sales-api-system-011CUWdUnd9xhZJgvkhGndox --rebase

# Step 4: Re-apply local changes if any
echo ""
echo "[4/5] 📝 Re-applying local changes (if any)..."
git stash pop 2>/dev/null || echo "No stashed changes"

# Step 5: Run Nginx fix
echo ""
echo "[5/5] ⚙️  Fixing Nginx configuration..."
echo ""

# Check root for Nginx fix
if [ "$EUID" -ne 0 ]; then
    echo "❌ Need root access to fix Nginx"
    echo ""
    echo "✅ Git is fixed! Now run:"
    echo "   sudo bash fix-nginx.sh"
    exit 0
fi

# Continue with Nginx fix
bash fix-nginx.sh

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║            ✅ ALL FIXES COMPLETED!                        ║"
echo "╚═══════════════════════════════════════════════════════════╝"
