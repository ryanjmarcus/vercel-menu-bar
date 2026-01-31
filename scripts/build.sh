#!/bin/bash

# Build script for Vercel Menu Bar
# This script builds the app and creates a distributable .dmg file

set -e

# Configuration
APP_NAME="vercel-menu-bar"
DISPLAY_NAME="Vercel Menu Bar"
SCHEME="vercel-menu-bar"
PROJECT="vercel-menu-bar.xcodeproj"
BUILD_DIR="build"
ARCHIVE_PATH="$BUILD_DIR/$APP_NAME.xcarchive"
EXPORT_PATH="$BUILD_DIR/export"
DMG_NAME="Vercel-Menu-Bar"

# Code signing identity (use ad-hoc if not available)
SIGNING_IDENTITY="${SIGNING_IDENTITY:-Developer ID Application: Ryan Marcus (JM7ZEPER79)}"

# Notarization profile (stored in Keychain via: xcrun notarytool store-credentials)
NOTARIZATION_PROFILE="${NOTARIZATION_PROFILE:-vercel-menu-notarization}"

# Skip notarization with SKIP_NOTARIZATION=1
SKIP_NOTARIZATION="${SKIP_NOTARIZATION:-0}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Building $APP_NAME...${NC}"

# Clean build directory
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Build and archive
echo -e "${YELLOW}Creating archive...${NC}"
echo -e "${YELLOW}Using signing identity: $SIGNING_IDENTITY${NC}"

xcodebuild archive \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH" \
    CODE_SIGN_IDENTITY="$SIGNING_IDENTITY" \
    CODE_SIGNING_REQUIRED=YES \
    CODE_SIGNING_ALLOWED=YES \
    | xcbeautify || xcodebuild archive \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH" \
    CODE_SIGN_IDENTITY="$SIGNING_IDENTITY" \
    CODE_SIGNING_REQUIRED=YES \
    CODE_SIGNING_ALLOWED=YES

# Export the app
echo -e "${YELLOW}Exporting app...${NC}"
mkdir -p "$EXPORT_PATH"

# Copy the .app from the archive
cp -R "$ARCHIVE_PATH/Products/Applications/$APP_NAME.app" "$EXPORT_PATH/$DISPLAY_NAME.app"

# Deep re-sign the app and all embedded frameworks/binaries for notarization
# Sparkle framework components need to be signed with our Developer ID
echo -e "${YELLOW}Deep signing app for notarization...${NC}"

APP_PATH="$EXPORT_PATH/$DISPLAY_NAME.app"
ENTITLEMENTS="vercel-menu-bar/vercel-menu-bar.entitlements"

# Sign Sparkle framework components (inside-out signing order)
if [ -d "$APP_PATH/Contents/Frameworks/Sparkle.framework" ]; then
    # Sign XPC services first
    find "$APP_PATH/Contents/Frameworks/Sparkle.framework" -name "*.xpc" -type d | while read xpc; do
        codesign --force --options runtime --timestamp --sign "$SIGNING_IDENTITY" "$xpc" 2>/dev/null || true
    done
    
    # Sign helper apps
    find "$APP_PATH/Contents/Frameworks/Sparkle.framework" -name "*.app" -type d | while read app; do
        codesign --force --options runtime --timestamp --sign "$SIGNING_IDENTITY" "$app" 2>/dev/null || true
    done
    
    # Sign standalone binaries (Autoupdate, etc.)
    find "$APP_PATH/Contents/Frameworks/Sparkle.framework" -type f -perm +111 ! -name "*.dylib" | while read binary; do
        if file "$binary" | grep -q "Mach-O"; then
            codesign --force --options runtime --timestamp --sign "$SIGNING_IDENTITY" "$binary" 2>/dev/null || true
        fi
    done
    
    # Sign the framework itself
    codesign --force --options runtime --timestamp --sign "$SIGNING_IDENTITY" \
        "$APP_PATH/Contents/Frameworks/Sparkle.framework" 2>/dev/null || true
fi

# Sign any other frameworks
find "$APP_PATH/Contents/Frameworks" -name "*.framework" -type d -maxdepth 1 2>/dev/null | while read framework; do
    codesign --force --options runtime --timestamp --sign "$SIGNING_IDENTITY" "$framework" 2>/dev/null || true
done

# Sign any dylibs
find "$APP_PATH/Contents/Frameworks" -name "*.dylib" -type f 2>/dev/null | while read dylib; do
    codesign --force --options runtime --timestamp --sign "$SIGNING_IDENTITY" "$dylib" 2>/dev/null || true
done

# Finally, sign the main app with entitlements
codesign --force --options runtime --timestamp --sign "$SIGNING_IDENTITY" \
    --entitlements "$ENTITLEMENTS" "$APP_PATH"

echo -e "${GREEN}Deep signing complete!${NC}"

# Verify the signature
echo -e "${YELLOW}Verifying signature...${NC}"
codesign --verify --deep --strict "$APP_PATH" && \
    echo -e "${GREEN}Signature verified!${NC}" || \
    echo -e "${RED}Signature verification failed${NC}"

echo -e "${GREEN}Build complete!${NC}"
echo -e "App location: $EXPORT_PATH/$DISPLAY_NAME.app"

# Create DMG if create-dmg is available
if command -v create-dmg &> /dev/null; then
    echo -e "${YELLOW}Creating DMG...${NC}"
    
    # Get version from Info.plist
    VERSION=$(defaults read "$(pwd)/$EXPORT_PATH/$DISPLAY_NAME.app/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo "1.0.0")
    
    # Generate DMG background if script exists and background doesn't
    if [ -f "scripts/generate-dmg-background.swift" ] && [ ! -f "vercel-menu-bar/Resources/dmg-background.png" ]; then
        echo -e "${YELLOW}Generating DMG background image...${NC}"
        swift scripts/generate-dmg-background.swift || echo -e "${YELLOW}Background generation failed, continuing without...${NC}"
    fi
    
    # Build create-dmg command with optional background
    DMG_ARGS=(
        --volname "$DISPLAY_NAME"
        --volicon "vercel-menu-bar/Resources/Assets.xcassets/AppIcon.appiconset/icon_512x512.png"
        --window-pos 200 120
        --window-size 600 400
        --icon-size 100
        --icon "$DISPLAY_NAME.app" 150 185
        --hide-extension "$DISPLAY_NAME.app"
        --app-drop-link 450 185
    )
    
    # Add background if available
    if [ -f "vercel-menu-bar/Resources/dmg-background.png" ]; then
        DMG_ARGS+=(--background "vercel-menu-bar/Resources/dmg-background.png")
        echo -e "${GREEN}Using custom DMG background${NC}"
    fi
    
    create-dmg "${DMG_ARGS[@]}" \
        "$BUILD_DIR/$DMG_NAME-$VERSION.dmg" \
        "$EXPORT_PATH/" \
        || echo -e "${YELLOW}Note: create-dmg failed, creating simple DMG instead...${NC}"
    
    # Fallback to simple DMG if create-dmg fails
    if [ ! -f "$BUILD_DIR/$DMG_NAME-$VERSION.dmg" ]; then
        hdiutil create -volname "$DISPLAY_NAME" -srcfolder "$EXPORT_PATH" -ov -format UDZO "$BUILD_DIR/$DMG_NAME-$VERSION.dmg"
    fi
    
    echo -e "${GREEN}DMG created: $BUILD_DIR/$DMG_NAME-$VERSION.dmg${NC}"
else
    echo -e "${YELLOW}create-dmg not found. Creating simple DMG...${NC}"
    echo -e "Install create-dmg for prettier DMGs: brew install create-dmg"
    
    VERSION=$(defaults read "$(pwd)/$EXPORT_PATH/$DISPLAY_NAME.app/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo "1.0.0")
    hdiutil create -volname "$DISPLAY_NAME" -srcfolder "$EXPORT_PATH" -ov -format UDZO "$BUILD_DIR/$DMG_NAME-$VERSION.dmg"
    
    echo -e "${GREEN}DMG created: $BUILD_DIR/$DMG_NAME-$VERSION.dmg${NC}"
fi

# Sign the DMG with Developer ID
if [ -f "$BUILD_DIR/$DMG_NAME-$VERSION.dmg" ]; then
    echo -e "${YELLOW}Signing DMG...${NC}"
    codesign --force --sign "$SIGNING_IDENTITY" "$BUILD_DIR/$DMG_NAME-$VERSION.dmg" 2>/dev/null && \
        echo -e "${GREEN}DMG signed successfully${NC}" || \
        echo -e "${YELLOW}DMG signing skipped (no valid identity)${NC}"
fi

# Notarize the DMG with Apple
if [ "$SKIP_NOTARIZATION" != "1" ] && [ -f "$BUILD_DIR/$DMG_NAME-$VERSION.dmg" ]; then
    echo -e "${YELLOW}Submitting for notarization (this may take a few minutes)...${NC}"
    
    if xcrun notarytool submit "$BUILD_DIR/$DMG_NAME-$VERSION.dmg" \
        --keychain-profile "$NOTARIZATION_PROFILE" \
        --wait; then
        
        echo -e "${GREEN}Notarization successful!${NC}"
        
        # Staple the notarization ticket to the DMG
        echo -e "${YELLOW}Stapling notarization ticket...${NC}"
        xcrun stapler staple "$BUILD_DIR/$DMG_NAME-$VERSION.dmg" && \
            echo -e "${GREEN}Stapling complete!${NC}" || \
            echo -e "${YELLOW}Stapling failed (app will still work, just needs internet on first launch)${NC}"
    else
        echo -e "${RED}Notarization failed. Check the logs above for details.${NC}"
        echo -e "${YELLOW}You can skip notarization with: SKIP_NOTARIZATION=1 ./scripts/build.sh${NC}"
    fi
else
    if [ "$SKIP_NOTARIZATION" == "1" ]; then
        echo -e "${YELLOW}Skipping notarization (SKIP_NOTARIZATION=1)${NC}"
    fi
fi

# Also create a zip for GitHub releases
echo -e "${YELLOW}Creating ZIP...${NC}"
cd "$EXPORT_PATH"
zip -r "../$DMG_NAME-$VERSION.zip" "$DISPLAY_NAME.app"
cd - > /dev/null

echo -e "${GREEN}ZIP created: $BUILD_DIR/$DMG_NAME-$VERSION.zip${NC}"
echo ""
echo -e "${GREEN}Build artifacts:${NC}"
ls -la "$BUILD_DIR"/*.dmg "$BUILD_DIR"/*.zip 2>/dev/null || true
