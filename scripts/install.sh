#!/usr/bin/env bash
# Remote installer for SpeechRecog — pipe from curl:
#   curl -fsSL https://raw.githubusercontent.com/IagoLast/SpeechRecog/master/scripts/install.sh | bash
set -euo pipefail

MIN_MACOS="14.2"
REPO="https://github.com/IagoLast/SpeechRecog.git"
TMP_DIR="$(mktemp -d)"

cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

echo ""
echo "  SpeechRecog Installer"
echo "  ====================="
echo ""

# --- Check macOS ---
if [[ "$(uname)" != "Darwin" ]]; then
    echo "Error: SpeechRecog only runs on macOS." >&2
    exit 1
fi

MACOS_VERSION="$(sw_vers -productVersion)"
if [[ "$(printf '%s\n' "$MIN_MACOS" "$MACOS_VERSION" | sort -V | head -n1)" != "$MIN_MACOS" ]]; then
    echo "Error: macOS $MIN_MACOS+ required (you have $MACOS_VERSION)." >&2
    exit 1
fi
echo "  macOS $MACOS_VERSION ✓"

# --- Check Xcode / CLI tools ---
if ! xcode-select -p &>/dev/null; then
    echo "Error: Xcode Command Line Tools not found. Install with:" >&2
    echo "  xcode-select --install" >&2
    exit 1
fi
echo "  Xcode CLI tools ✓"

# --- Check Swift ---
if ! command -v swift &>/dev/null; then
    echo "Error: Swift not found. Install Xcode or Command Line Tools." >&2
    exit 1
fi
SWIFT_VERSION="$(swift --version 2>&1 | head -1)"
echo "  $SWIFT_VERSION ✓"

# --- Clone & build ---
echo ""
echo "  Cloning SpeechRecog..."
git clone --depth 1 "$REPO" "$TMP_DIR/SpeechRecog" 2>&1 | sed 's/^/  /'

echo ""
echo "  Building & installing to /Applications..."
echo "  (this may take a minute on first build)"
echo ""
make -C "$TMP_DIR/SpeechRecog" install 2>&1 | sed 's/^/  /'

echo ""
echo "  ✓ SpeechRecog installed to /Applications/SpeechRecog.app"
echo ""
echo "  Open it with:"
echo "    open /Applications/SpeechRecog.app"
echo ""
echo "  On first launch, macOS will ask for Screen Recording"
echo "  and Microphone permissions."
echo ""
