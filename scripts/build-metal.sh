#!/usr/bin/env bash
# SwiftPM does not compile MLX's Metal kernels; use the pinned dependency's script.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG="${1:-release}"
# Shader compiler flags are identical for debug/release. Share the upstream
# source + SDK + compiler hash cache so each kernel is only compiled once.
SHADER_BUILD="$ROOT/.build/mlx-shaders"
mkdir -p "$SHADER_BUILD/debug"
ln -sfn ../checkouts "$SHADER_BUILD/checkouts"
BUILD_DIR="$SHADER_BUILD" bash "$ROOT/.build/checkouts/speech-swift/scripts/build_mlx_metallib.sh" debug

BIN_PATH="$(cd "$ROOT" && swift build -c "$CONFIG" --show-bin-path)"
cp "$SHADER_BUILD/debug/mlx.metallib" "$BIN_PATH/mlx.metallib"
TEST_BIN="$BIN_PATH/SpeechRecogPackageTests.xctest/Contents/MacOS"
if [[ -d "$TEST_BIN" ]]; then
    cp "$BIN_PATH/mlx.metallib" "$TEST_BIN/mlx.metallib"
fi
