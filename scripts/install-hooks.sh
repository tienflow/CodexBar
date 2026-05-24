#!/bin/bash
# CodexBar Hook Installer
# Copies dispatch script and hooks.json to ~/.codex/

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CODEX_DIR="$HOME/.codex"
HOOKS_DIR="$CODEX_DIR/hooks"
DISPATCH_SRC="$SCRIPT_DIR/hooks/codexbar_dispatch.py"
DISPATCH_DST="$HOOKS_DIR/codexbar_dispatch.py"
HOOKS_JSON_SRC="$SCRIPT_DIR/hooks/hooks.json"
HOOKS_JSON_DST="$CODEX_DIR/hooks.json"

echo "CodexBar Hook Installer"
echo "======================="

# Check source files exist
if [ ! -f "$DISPATCH_SRC" ]; then
    echo "Error: $DISPATCH_SRC not found"
    exit 1
fi

if [ ! -f "$HOOKS_JSON_SRC" ]; then
    echo "Error: $HOOKS_JSON_SRC not found"
    exit 1
fi

# Create hooks directory
mkdir -p "$HOOKS_DIR"

# Copy dispatch script
cp "$DISPATCH_SRC" "$DISPATCH_DST"
chmod +x "$DISPATCH_DST"
echo "✓ Installed dispatch script to $DISPATCH_DST"

# Check if hooks.json already exists
if [ -f "$HOOKS_JSON_DST" ]; then
    echo ""
    echo "⚠ hooks.json already exists at $HOOKS_JSON_DST"
    echo "  CodexBar hooks will be merged with existing hooks."
    echo "  Manual merge may be required."
    echo ""
    echo "  To install manually:"
    echo "  1. Add the hook entries from $HOOKS_JSON_SRC to $HOOKS_JSON_DST"
    echo "  2. Or replace $HOOKS_JSON_DST (WARNING: overwrites existing hooks)"
else
    cp "$HOOKS_JSON_SRC" "$HOOKS_JSON_DST"
    echo "✓ Installed hooks.json to $HOOKS_JSON_DST"
fi

echo ""
echo "Installation complete!"
echo ""
echo "Next steps:"
echo "  1. Review the hooks in $HOOKS_JSON_DST"
echo "  2. Start Codex - it will prompt you to trust the new hooks"
echo "  3. Click 'Trust' to enable CodexBar"
