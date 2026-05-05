#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

APP_NAME="LidMonitor"
BUILD_DIR=".build/release"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"

echo "==> Building release binary..."
swift build -c release

echo "==> Assembling .app bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"
cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
cp "Resources/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

if [[ -f "Resources/AppIcon.icns" ]]; then
    cp "Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
fi

echo "==> Ad-hoc signing..."
codesign --force --deep --sign - "$APP_BUNDLE"

if [[ "${1:-}" == "--install" ]]; then
    echo "==> Stopping any running instance..."
    pkill -x "$APP_NAME" 2>/dev/null || true
    sleep 0.3

    DEST="/Applications/$APP_NAME.app"
    echo "==> Installing to $DEST..."
    rm -rf "$DEST"
    cp -R "$APP_BUNDLE" "$DEST"

    echo "==> Launching..."
    open "$DEST"

    echo
    echo "Installed and launched. Look for the laptop icon in your menu bar."
else
    echo
    echo "Built at: $APP_BUNDLE"
    echo "Run with --install to copy to /Applications/ and launch."
fi
