#!/bin/bash

# Master setup script - runs all setup tasks for Sparkle and Homebrew
# Prerequisites: brew install gh && gh auth login

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║       Vercel Menu Bar - Complete Setup                     ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

if ! command -v gh &> /dev/null; then
    echo -e "${RED}GitHub CLI (gh) not found.${NC}"
    echo "Install it with: brew install gh"
    exit 1
fi

if ! gh auth status &> /dev/null 2>&1; then
    echo -e "${YELLOW}Please log in to GitHub CLI:${NC}"
    gh auth login
fi

echo -e "${GREEN}Prerequisites OK!${NC}"
echo ""

# Step 1: Sparkle setup
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Step 1: Setting up Sparkle auto-updates${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
"$SCRIPT_DIR/setup-sparkle.sh"

echo ""

# Step 2: Homebrew tap
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Step 2: Setting up Homebrew tap${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
"$SCRIPT_DIR/create-homebrew-tap.sh"

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                    Setup Complete!                         ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}What's configured:${NC}"
echo "  ✓ Sparkle EdDSA keys generated"
echo "  ✓ Info.plist updated with public key"
echo "  ✓ SPARKLE_PRIVATE_KEY added to GitHub Secrets"
echo "  ✓ GitHub Pages enabled for /docs"
echo "  ✓ homebrew-tap repository created"
echo "  ✓ HOMEBREW_TAP_TOKEN added to GitHub Secrets"
echo ""
echo -e "${CYAN}Next steps:${NC}"
echo "  1. Add Sparkle package in Xcode:"
echo "     File → Add Package Dependencies..."
echo "     URL: https://github.com/sparkle-project/Sparkle"
echo ""
echo "  2. Commit and push your changes:"
echo "     git add . && git commit -m 'Add Sparkle and Homebrew automation'"
echo "     git push origin main"
echo ""
echo "  3. Create your first release:"
echo "     git tag v1.0.0 && git push origin v1.0.0"
echo ""
echo -e "${GREEN}Done! Your app will auto-update and be installable via Homebrew.${NC}"
