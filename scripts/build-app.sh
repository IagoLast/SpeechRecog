#!/usr/bin/env bash
# Builds SpeechRecog as a proper .app bundle from the SwiftPM target.
#
# Requirements:
#   - Apple Silicon, macOS 15+
#   - Xcode with Swift 6.3+ and the Metal Toolchain
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

if [[ "$(uname -m)" != "arm64" ]]; then
    echo "Error: SpeechRecog's local models require Apple Silicon." >&2
    exit 1
fi

SWIFT_FLAGS=(--configuration release)

echo "→ swift build ${SWIFT_FLAGS[*]}"
swift build "${SWIFT_FLAGS[@]}"
bash "$ROOT/scripts/build-metal.sh" release

BIN_PATH="$(swift build "${SWIFT_FLAGS[@]}" --show-bin-path)"

echo "→ Assembling $APP_BUNDLE"
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS" "$RESOURCES"

cp "$BIN_PATH/$APP_NAME" "$MACOS/$APP_NAME"
cp "$BIN_PATH/mlx.metallib" "$MACOS/mlx.metallib"
cp "$PLIST" "$CONTENTS/Info.plist"
cp "$ROOT/Sources/SpeechRecog/Resources/AppIcon.icns" "$RESOURCES/AppIcon.icns"

# Copy any SwiftPM-emitted resource bundles (e.g. SpeechRecog_SpeechRecog.bundle).
shopt -s nullglob
for bundle in "$BIN_PATH"/*.bundle; do
    cp -R "$bundle" "$RESOURCES/"
done
shopt -u nullglob

# A certificate gives TCC a stable identity across rebuilds. Ad-hoc signatures
# identify the executable by its hash, invalidating permissions when it changes.
SIGN_ID="${CODESIGN_IDENTITY:-}"
if [[ -z "$SIGN_ID" ]]; then
    IDENTITIES="$(security find-identity -v -p codesigning 2>/dev/null || true)"
    SIGN_ID="$(awk '/"Apple Development:|"Mac Developer:/ { print $2; exit }' <<< "$IDENTITIES")"
    if [[ -z "$SIGN_ID" ]]; then
        SIGN_ID="$(awk '/"Developer ID Application:/ { print $2; exit }' <<< "$IDENTITIES")"
    fi
    SIGN_ID="${SIGN_ID:--}"
fi

if [[ "$SIGN_ID" == "-" ]]; then
    echo "  No signing certificate selected; using an ad-hoc signature."
    echo "  macOS may ask for permissions again after rebuilding."
    echo "  Set CODESIGN_IDENTITY to a development certificate to preserve permissions."
fi

echo "→ codesign --sign $SIGN_ID --entitlements $ENTITLEMENTS"
codesign --force --deep --sign "$SIGN_ID" \
    --entitlements "$ENTITLEMENTS" \
    --options runtime \
    "$APP_BUNDLE"

echo "✓ Built $APP_BUNDLE"
echo
echo "Open it with:  open '$APP_BUNDLE'"
