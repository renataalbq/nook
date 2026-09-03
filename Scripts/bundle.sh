#!/bin/bash
# Builds Nook and assembles a runnable .app bundle at build/Nook.app
set -euo pipefail
cd "$(dirname "$0")/.."

CONFIG="${1:-debug}"
swift build -c "$CONFIG"
BIN="$(swift build -c "$CONFIG" --show-bin-path)/Nook"

APP="build/Nook.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources/Fonts"
cp "$BIN" "$APP/Contents/MacOS/Nook"
cp Resources/Info.plist "$APP/Contents/Info.plist"
cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
cp Resources/Fonts/*.ttf "$APP/Contents/Resources/Fonts/"
codesign --force --deep --sign - "$APP" 2>/dev/null || true

echo "built $APP"
