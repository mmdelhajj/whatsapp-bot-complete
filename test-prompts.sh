#!/bin/bash
# Quick test to verify installer prompts

echo "Testing installer prompts..."
echo ""

# Test the ProxSMS prompts
echo "📱 ProxSMS Configuration (from proxsms.com):"
echo "   Get API Secret from: Tools -> API Keys"
echo "   Get WhatsApp Unique ID from: Dashboard or /get/wa.accounts"
echo "   Get Webhook Secret from: Tools -> Webhooks"
echo ""

# Simulate the prompts
read -sp "🔑 ProxSMS API Secret: " WHATSAPP_SECRET
echo ""

read -p "📱 WhatsApp Account Unique ID: " WHATSAPP_ACCOUNT

read -sp "🔐 ProxSMS Webhook Secret: " WEBHOOK_SECRET
echo ""

echo ""
echo "You entered:"
echo "API Secret: ${WHATSAPP_SECRET}"
echo "Account ID: ${WHATSAPP_ACCOUNT}"
echo "Webhook Secret: ${WEBHOOK_SECRET}"
