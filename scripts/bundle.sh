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

echo "Done! App bundle at: $APP_DIR"
echo "Run with: open $APP_DIR"
