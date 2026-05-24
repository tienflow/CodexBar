#!/bin/bash
# CodexBar Hook Installer
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

# Copy dispatch script
cp "$SCRIPT_DIR/codexbar_dispatch.py" "$DISPATCH_DST"
chmod +x "$DISPATCH_DST"
echo "✓ Installed dispatch script to $DISPATCH_DST"

# Check for existing hooks.json
if [ -f "$CODEX_DIR/hooks.json" ]; then
    echo ""
    echo "⚠ hooks.json already exists at $CODEX_DIR/hooks.json"
    echo "  You may need to merge the CodexBar hooks manually."
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
