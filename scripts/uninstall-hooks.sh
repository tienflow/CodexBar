#!/bin/bash
# CodexBar Hook Uninstaller
# Removes dispatch script and CodexBar entries from hooks.json

set -e

CODEX_DIR="$HOME/.codex"
HOOKS_DIR="$CODEX_DIR/hooks"
DISPATCH_DST="$HOOKS_DIR/codexbar_dispatch.py"
HOOKS_JSON_DST="$CODEX_DIR/hooks.json"

echo "CodexBar Hook Uninstaller"
echo "========================="

# Remove dispatch script
if [ -f "$DISPATCH_DST" ]; then
    rm "$DISPATCH_DST"
    echo "✓ Removed $DISPATCH_DST"
else
    echo "• $DISPATCH_DST not found (already removed)"
fi

# Remove hooks.json if it only contains CodexBar hooks
if [ -f "$HOOKS_JSON_DST" ]; then
    # Check if it's a CodexBar-only hooks.json
    if grep -q "codexbar_dispatch" "$HOOKS_JSON_DST" 2>/dev/null; then
        echo ""
        echo "⚠ hooks.json contains CodexBar entries."
        echo "  To fully remove, edit $HOOKS_JSON_DST and delete"
        echo "  the entries referencing codexbar_dispatch.py"
        echo ""
        echo "  Or delete the entire file: rm $HOOKS_JSON_DST"
    else
        echo "• hooks.json does not contain CodexBar entries"
    fi
else
    echo "• hooks.json not found"
fi

echo ""
echo "Uninstallation complete!"
