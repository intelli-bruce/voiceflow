#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/VoiceFlow/.build/debug"
APP_DIR="$PROJECT_DIR/VoiceFlow.app"

echo "Building..."
cd "$PROJECT_DIR/VoiceFlow"
swift build 2>&1

echo "Creating .app bundle..."
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

cp "$BUILD_DIR/VoiceFlow" "$APP_DIR/Contents/MacOS/VoiceFlow"

cat > "$APP_DIR/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.voiceflow.app</string>
    <key>CFBundleName</key>
    <string>VoiceFlow</string>
    <key>CFBundleExecutable</key>
    <string>VoiceFlow</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSMicrophoneUsageDescription</key>
    <string>VoiceFlow needs microphone access for speech recognition.</string>
    <key>NSAccessibilityUsageDescription</key>
    <string>VoiceFlow needs accessibility access to type text and detect hotkeys.</string>
</dict>
</plist>
PLIST

# Code sign with VoiceFlowDev certificate + Hardened Runtime
SIGN_NAME="VoiceFlowDev"
ENTITLEMENTS="$PROJECT_DIR/VoiceFlow/VoiceFlow.entitlements"

# Get the valid certificate hash to avoid ambiguity with duplicates
SIGN_HASH=$(security find-identity -v -p codesigning | grep "$SIGN_NAME" | head -1 | awk '{print $2}')

if [ -n "$SIGN_HASH" ]; then
    echo "Signing with $SIGN_NAME ($SIGN_HASH)..."
    codesign --force --sign "$SIGN_HASH" \
        --options runtime \
        --entitlements "$ENTITLEMENTS" \
        --identifier "com.voiceflow.app" \
        "$APP_DIR"
    echo "✅ Signed with Hardened Runtime"
else
    echo "⚠️  $SIGN_NAME certificate not found, falling back to ad-hoc signing"
    codesign --force --sign - \
        --options runtime \
        --entitlements "$ENTITLEMENTS" \
        --identifier "com.voiceflow.app" \
        "$APP_DIR"
fi

echo "Done! App bundle at: $APP_DIR"
echo "Run with: open $APP_DIR"
