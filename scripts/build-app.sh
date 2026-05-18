#!/usr/bin/env bash
# Builds SpeechRecog as a proper .app bundle from the SwiftPM target.
#
# Requirements:
#   - macOS 14.2+
#   - Xcode 15.2+ (or matching Command Line Tools providing Swift 5.9+)
#
# Usage:
#   ./scripts/build-app.sh
#
# Output:
#   ./build/SpeechRecog.app
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

APP_NAME="SpeechRecog"
BUILD_DIR="$ROOT/build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"
PLIST="$ROOT/Sources/SpeechRecog/Resources/Info.plist"
ENTITLEMENTS="$ROOT/Sources/SpeechRecog/Resources/SpeechRecog.entitlements"

SWIFT_FLAGS=(--configuration release --arch arm64 --arch x86_64)

echo "→ swift build ${SWIFT_FLAGS[*]}"
swift build "${SWIFT_FLAGS[@]}"

BIN_PATH="$(swift build "${SWIFT_FLAGS[@]}" --show-bin-path)"

echo "→ Assembling $APP_BUNDLE"
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS" "$RESOURCES"

cp "$BIN_PATH/$APP_NAME" "$MACOS/$APP_NAME"
cp "$PLIST" "$CONTENTS/Info.plist"
cp "$ROOT/Sources/SpeechRecog/Resources/AppIcon.icns" "$RESOURCES/AppIcon.icns"

# Copy any SwiftPM-emitted resource bundles (e.g. SpeechRecog_SpeechRecog.bundle).
shopt -s nullglob
for bundle in "$BIN_PATH"/*.bundle; do
    cp -R "$bundle" "$RESOURCES/"
done
shopt -u nullglob

# Sign for local development. For distribution, replace with your Developer ID.
SIGN_ID="${CODESIGN_IDENTITY:--}"
echo "→ codesign --sign $SIGN_ID --entitlements $ENTITLEMENTS"
codesign --force --deep --sign "$SIGN_ID" \
    --entitlements "$ENTITLEMENTS" \
    --options runtime \
    "$APP_BUNDLE"

echo "✓ Built $APP_BUNDLE"
echo
echo "Open it with:  open '$APP_BUNDLE'"
