#!/bin/bash
# CodexBar Hook Installer
# Copies the hook dispatch script to ~/.codex/hooks/

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CODEX_DIR="$HOME/.codex"
HOOKS_DIR="$CODEX_DIR/hooks"
DISPATCH_DST="$HOOKS_DIR/codexbar_dispatch.py"

echo "CodexBar Hook Installer"
echo "======================="

# Check if ~/.codex exists
if [ ! -d "$CODEX_DIR" ]; then
    echo "Error: ~/.codex directory not found"
    echo "Please install Codex first: https://github.com/openai/codex"
    exit 1
fi

# Create hooks directory
mkdir -p "$HOOKS_DIR"

# Check if dispatch script exists in app bundle
DISPATCH_SRC="$(dirname "$0")/../MacOS/codexbar_dispatch.py"
if [ ! -f "$DISPATCH_SRC" ]; then
    # Try alternate location
    DISPATCH_SRC="$(dirname "$0")/codexbar_dispatch.py"
fi

if [ ! -f "$DISPATCH_SRC" ]; then
    echo "Error: codexbar_dispatch.py not found"
    echo "Please ensure the app bundle is intact"
    exit 1
fi

# Copy dispatch script
cp "$DISPATCH_SRC" "$DISPATCH_DST"
chmod +x "$DISPATCH_DST"
echo "✓ Installed dispatch script to $DISPATCH_DST"

# Check for existing hooks.json
if [ -f "$CODEX_DIR/hooks.json" ]; then
    echo ""
    echo "⚠ hooks.json already exists at $CODEX_DIR/hooks.json"
    echo "  You may need to merge the CodexBar hooks manually."
    echo "  Or replace the file (WARNING: overwrites existing hooks)."
else
    # Create hooks.json
    cat > "$CODEX_DIR/hooks.json" << 'HOOKS'
{
  "hooks": {
    "SessionStart": [{"hooks": [{"type": "command", "command": "/usr/bin/python3 ~/.codex/hooks/codexbar_dispatch.py", "timeout": 5}]}],
    "UserPromptSubmit": [{"hooks": [{"type": "command", "command": "/usr/bin/python3 ~/.codex/hooks/codexbar_dispatch.py", "timeout": 5}]}],
    "SubagentStart": [{"hooks": [{"type": "command", "command": "/usr/bin/python3 ~/.codex/hooks/codexbar_dispatch.py", "timeout": 5}]}],
    "PreToolUse": [{"hooks": [{"type": "command", "command": "/usr/bin/python3 ~/.codex/hooks/codexbar_dispatch.py", "timeout": 5}]}],
    "PostToolUse": [{"hooks": [{"type": "command", "command": "/usr/bin/python3 ~/.codex/hooks/codexbar_dispatch.py", "timeout": 5}]}],
    "PermissionRequest": [{"hooks": [{"type": "command", "command": "/usr/bin/python3 ~/.codex/hooks/codexbar_dispatch.py", "timeout": 5}]}],
    "Stop": [{"hooks": [{"type": "command", "command": "/usr/bin/python3 ~/.codex/hooks/codexbar_dispatch.py", "timeout": 5}]}]
  }
}
HOOKS
    echo "✓ Installed hooks.json to $CODEX_DIR/hooks.json"
fi

echo ""
echo "Installation complete!"
echo ""
echo "Next steps:"
echo "  1. Restart Codex"
echo "  2. Codex will prompt you to trust the hooks - click 'Trust'"
echo "  3. Launch CodexBar from Applications"
