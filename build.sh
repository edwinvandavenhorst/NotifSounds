#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="NotifSounds"
BUILD_DIR="$SCRIPT_DIR/build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
BINARY="$CONTENTS/MacOS/$APP_NAME"

echo "Building $APP_NAME..."

mkdir -p "$CONTENTS/MacOS"
mkdir -p "$CONTENTS/Resources"

swiftc -framework Cocoa -O \
    "$SCRIPT_DIR/main.swift" \
    -o "$BINARY"

cp "$SCRIPT_DIR/Info.plist" "$CONTENTS/"
cp "$SCRIPT_DIR/icons/AppIcon.icns" "$CONTENTS/Resources/"

# Ad-hoc sign — required for Apple Silicon to execute the binary
codesign --force --sign - "$APP_BUNDLE"

echo "Built: $APP_BUNDLE"
echo ""
read -rp "Install to /Applications? [y/N] " reply
if [[ "${reply:-N}" =~ ^[Yy]$ ]]; then
    pkill -x NotifSounds 2>/dev/null || true
    rm -rf "/Applications/$APP_NAME.app"          # must remove first — cp -r nests if dest exists
    cp -r "$APP_BUNDLE" "/Applications/"
    echo "Installed: /Applications/$APP_NAME.app"
    open "/Applications/$APP_NAME.app"
fi
