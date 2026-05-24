#!/bin/bash
# CodexBar Build Script
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"

echo "Building CodexBar..."
cd "$SCRIPT_DIR/CodexBar"

swift build -c release 2>&1

mkdir -p "$BUILD_DIR"
cp .build/release/CodexBar "$BUILD_DIR/"

echo ""
echo "✓ Build complete!"
echo "  Binary: $BUILD_DIR/CodexBar"
echo ""
echo "To run:"
echo "  $BUILD_DIR/CodexBar &"
