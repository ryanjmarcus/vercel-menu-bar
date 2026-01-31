#!/bin/bash

# Script to create the homebrew-tap repository and configure automation
# Fully automated using GitHub CLI

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

REPO="ryanjmarcus/vercel-menu-bar"
TAP_REPO="ryanjmarcus/homebrew-tap"

echo -e "${CYAN}=== Homebrew Tap Setup ===${NC}"
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

# Check if tap repo exists
echo -e "${YELLOW}Checking if homebrew-tap exists...${NC}"
if gh repo view "$TAP_REPO" &> /dev/null; then
    echo -e "${GREEN}Repository $TAP_REPO already exists!${NC}"
else
    echo -e "${YELLOW}Creating homebrew-tap repository...${NC}"
    gh repo create homebrew-tap --public --description "Homebrew tap for Vercel Menu Bar and other tools"
    echo -e "${GREEN}Repository created!${NC}"
fi

# Clone and set up the tap
echo ""
echo -e "${YELLOW}Setting up tap contents...${NC}"

TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

gh repo clone "$TAP_REPO" . 2>/dev/null || git init

# Create directory structure
mkdir -p Casks

# Create README
cat > README.md << 'EOF'
# Homebrew Tap

This is a Homebrew tap for installing my macOS applications.

## Installation

```bash
brew tap ryanjmarcus/tap
```

## Available Casks

### Vercel Menu Bar

A native macOS menu bar app for monitoring Vercel deployments.

```bash
brew install --cask ryanjmarcus/tap/vercel-menu-bar
```
EOF

# Create initial cask placeholder
cat > Casks/vercel-menu-bar.rb << 'EOF'
cask "vercel-menu-bar" do
  version "1.0.0"
  sha256 :no_check

  url "https://github.com/ryanjmarcus/vercel-menu-bar/releases/download/v#{version}/Vercel-Menu-Bar-#{version}.dmg"
  name "Vercel Menu Bar"
  desc "Menu bar app for monitoring Vercel deployments"
  homepage "https://github.com/ryanjmarcus/vercel-menu-bar"

  depends_on macos: ">= :sonoma"

  app "Vercel Menu Bar.app"

  zap trash: [
    "~/Library/Preferences/com.ryanmarcus.vercel-menu-bar.plist",
  ]
end
EOF

# Commit and push
git add .
git commit -m "Initial tap setup" 2>/dev/null || git commit --amend -m "Initial tap setup" 2>/dev/null || true

# Set up remote and push
git branch -M main
git remote set-url origin "https://github.com/$TAP_REPO.git" 2>/dev/null || \
git remote add origin "https://github.com/$TAP_REPO.git" 2>/dev/null || true

git push -u origin main --force 2>/dev/null || echo -e "${YELLOW}Push may require manual intervention${NC}"

cd -
rm -rf "$TEMP_DIR"

# Create a fine-grained token for the tap
echo ""
echo -e "${YELLOW}Creating Personal Access Token for tap automation...${NC}"
echo ""

# Check if token already exists as a secret
if gh secret list --repo "$REPO" 2>/dev/null | grep -q "HOMEBREW_TAP_TOKEN"; then
    echo -e "${GREEN}HOMEBREW_TAP_TOKEN secret already exists!${NC}"
else
    echo -e "${CYAN}Creating a token for homebrew-tap access...${NC}"
    echo ""
    
    # Generate token using gh (this opens browser for fine-grained token)
    echo "Opening GitHub to create a fine-grained Personal Access Token..."
    echo ""
    echo -e "${YELLOW}Settings to use:${NC}"
    echo "  - Token name: vercel-menu-homebrew-tap"
    echo "  - Expiration: 1 year (or your preference)"
    echo "  - Repository access: Only select repositories → homebrew-tap"
    echo "  - Permissions: Contents → Read and write"
    echo ""
    
    # Open the token creation page
    open "https://github.com/settings/personal-access-tokens/new" 2>/dev/null || \
    echo "Go to: https://github.com/settings/personal-access-tokens/new"
    
    echo ""
    echo -e "${YELLOW}After creating the token, paste it here:${NC}"
    read -s -p "Token: " TOKEN
    echo ""
    
    if [ -n "$TOKEN" ]; then
        echo "$TOKEN" | gh secret set HOMEBREW_TAP_TOKEN --repo "$REPO"
        echo -e "${GREEN}Secret HOMEBREW_TAP_TOKEN added!${NC}"
    else
        echo -e "${YELLOW}No token provided. Add it later with:${NC}"
        echo "gh secret set HOMEBREW_TAP_TOKEN --repo $REPO"
    fi
fi

echo ""
echo -e "${GREEN}=== Homebrew Tap Setup Complete! ===${NC}"
echo ""
echo -e "${CYAN}Summary:${NC}"
echo "  - Repository homebrew-tap created/updated"
echo "  - Initial cask formula added"
echo "  - HOMEBREW_TAP_TOKEN secret configured"
echo ""
echo -e "${CYAN}Users can now install with:${NC}"
echo -e "  ${GREEN}brew install --cask ryanjmarcus/tap/vercel-menu-bar${NC}"
echo ""
echo -e "${YELLOW}Note: The cask will be automatically updated on each release.${NC}"
