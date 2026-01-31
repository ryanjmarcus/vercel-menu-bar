#!/bin/bash

# Setup script for Sparkle auto-updates
# Generates EdDSA keys and configures GitHub secrets + Pages

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

REPO="ryanjmarcus/vercel-menu-bar"

echo -e "${CYAN}=== Sparkle Setup for Vercel Menu Bar ===${NC}"
echo ""

# Check for gh CLI
if ! command -v gh &> /dev/null; then
    echo -e "${RED}GitHub CLI (gh) not found.${NC}"
    echo "Install it with: brew install gh"
    exit 1
fi

# Check if logged in
if ! gh auth status &> /dev/null 2>&1; then
    echo -e "${YELLOW}Please log in to GitHub CLI:${NC}"
    gh auth login
fi

# Download Sparkle if not present
SPARKLE_VERSION="2.6.4"
SPARKLE_DIR="$HOME/.sparkle-tools"

if [ ! -f "$SPARKLE_DIR/bin/generate_keys" ]; then
    echo -e "${YELLOW}Downloading Sparkle tools...${NC}"
    mkdir -p "$SPARKLE_DIR"
    curl -L -o /tmp/sparkle.tar.xz "https://github.com/sparkle-project/Sparkle/releases/download/$SPARKLE_VERSION/Sparkle-$SPARKLE_VERSION.tar.xz"
    tar -xf /tmp/sparkle.tar.xz -C "$SPARKLE_DIR"
    rm /tmp/sparkle.tar.xz
    echo -e "${GREEN}Sparkle tools installed to $SPARKLE_DIR${NC}"
fi

echo ""
echo -e "${YELLOW}Generating EdDSA key pair...${NC}"
echo ""

# Generate keys and capture output
KEY_OUTPUT=$("$SPARKLE_DIR/bin/generate_keys" 2>&1) || true

# Check if keys already exist in keychain
if echo "$KEY_OUTPUT" | grep -q "already exists"; then
    echo -e "${YELLOW}Keys already exist in Keychain. Exporting...${NC}"
fi

# Export the private key
echo -e "${YELLOW}Exporting private key...${NC}"
PRIVATE_KEY=$("$SPARKLE_DIR/bin/generate_keys" -x 2>&1 | grep -A1 "private key" | tail -1 | tr -d ' ') || true

if [ -z "$PRIVATE_KEY" ]; then
    # Try alternative export
    PRIVATE_KEY=$("$SPARKLE_DIR/bin/generate_keys" -x 2>&1 | tail -1 | tr -d ' ')
fi

# Get the public key
echo -e "${YELLOW}Getting public key...${NC}"
PUBLIC_KEY=$("$SPARKLE_DIR/bin/generate_keys" -p 2>&1 | tail -1 | tr -d ' ')

if [ -z "$PUBLIC_KEY" ]; then
    echo -e "${RED}Failed to get public key. Please run manually:${NC}"
    echo "$SPARKLE_DIR/bin/generate_keys"
    exit 1
fi

echo ""
echo -e "${GREEN}Keys generated!${NC}"
echo -e "Public key: ${CYAN}$PUBLIC_KEY${NC}"
echo ""

# Update Info.plist with public key
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
INFO_PLIST="$PROJECT_DIR/vercel-menu-bar/Info.plist"

if [ -f "$INFO_PLIST" ]; then
    echo -e "${YELLOW}Updating Info.plist with public key...${NC}"
    sed -i '' "s/SPARKLE_PUBLIC_KEY_PLACEHOLDER/$PUBLIC_KEY/" "$INFO_PLIST"
    echo -e "${GREEN}Info.plist updated!${NC}"
else
    echo -e "${RED}Info.plist not found at $INFO_PLIST${NC}"
fi

# Add private key to GitHub Secrets
if [ -n "$PRIVATE_KEY" ]; then
    echo ""
    echo -e "${YELLOW}Adding private key to GitHub Secrets...${NC}"
    echo "$PRIVATE_KEY" | gh secret set SPARKLE_PRIVATE_KEY --repo "$REPO"
    echo -e "${GREEN}Secret SPARKLE_PRIVATE_KEY added!${NC}"
else
    echo -e "${YELLOW}Could not export private key automatically.${NC}"
    echo "Please run: $SPARKLE_DIR/bin/generate_keys -x"
    echo "Then add it manually: gh secret set SPARKLE_PRIVATE_KEY --repo $REPO"
fi

# Enable GitHub Pages
echo ""
echo -e "${YELLOW}Enabling GitHub Pages...${NC}"

# First, ensure the docs folder is committed and pushed
echo -e "${YELLOW}Note: Make sure to commit and push the docs/ folder first.${NC}"

# Enable Pages via API
gh api \
  --method POST \
  -H "Accept: application/vnd.github+json" \
  "/repos/$REPO/pages" \
  -f "source[branch]=main" \
  -f "source[path]=/docs" 2>/dev/null || \
gh api \
  --method PUT \
  -H "Accept: application/vnd.github+json" \
  "/repos/$REPO/pages" \
  -f "source[branch]=main" \
  -f "source[path]=/docs" 2>/dev/null || \
echo -e "${YELLOW}Pages may already be enabled or needs manual setup.${NC}"

echo ""
echo -e "${GREEN}=== Sparkle Setup Complete! ===${NC}"
echo ""
echo -e "${CYAN}Summary:${NC}"
echo "  - EdDSA keys generated and stored in Keychain"
echo "  - Public key added to Info.plist"
echo "  - Private key added to GitHub Secrets"
echo "  - GitHub Pages configured for /docs"
echo ""
echo -e "${YELLOW}Next: Run ./scripts/create-homebrew-tap.sh to set up Homebrew${NC}"
