#!/usr/bin/env python3
"""CodexBar hook dispatcher.

Reads Codex hook JSON from stdin, maps events to agent states,
and atomically writes ~/.codex/agent-status.json for the Swift menu bar app.
"""
import json
import os
import sys
import tempfile
import fcntl
from datetime import datetime, timezone, timedelta

STATUS_PATH = os.path.expanduser("~/.codex/agent-status.json")

# Event -> state mapping. None means "don't change state, only update metadata".
EVENT_STATE_MAP = {
    "SessionStart":       "idle",
    "UserPromptSubmit":   "thinking",
    "SubagentStart":      "thinking",
    "PreToolUse":         "developing",
    "PermissionRequest":  "confirming",
    "PostToolUse":        None,       # update last_tool only
    "Stop":               "completed",
}

# Events that carry tool information
TOOL_EVENTS = {"PreToolUse", "PostToolUse"}


def extract_tool_detail(event_name: str, data: dict) -> tuple[str | None, str | None]:
    """Extract tool name and human-readable detail from hook data."""
    tool_name = data.get("tool_name")
    tool_input = data.get("tool_input") or {}

    if not tool_name:
        return None, None

    if tool_name == "apply_patch":
        # tool_input.command contains the patch; extract first file path
        cmd = tool_input.get("command", "")
        detail = cmd.split("\n")[0][:80] if cmd else "apply_patch"
        return tool_name, detail

    if tool_name == "Bash":
        cmd = tool_input.get("command", "")
        # Truncate to 60 chars for display
        detail = cmd[:60] + ("..." if len(cmd) > 60 else "")
        return tool_name, detail

    # MCP tools or others
    return tool_name, tool_name


def read_existing_status() -> dict:
    """Read existing status file, returning empty dict on failure."""
    try:
        with open(STATUS_PATH, "r") as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return {}


def write_status_atomic(status: dict) -> None:
    """Write status file atomically using temp file + rename + flock."""
    dir_name = os.path.dirname(STATUS_PATH) or "."
    fd, tmp_path = tempfile.mkstemp(dir=dir_name, suffix=".tmp")
    try:
        with os.fdopen(fd, "w") as f:
            # Advisory lock to prevent partial reads
            fcntl.flock(f, fcntl.LOCK_EX)
            json.dump(status, f, ensure_ascii=False, indent=2)
            f.flush()
            os.fsync(f.fileno())
            fcntl.flock(f, fcntl.LOCK_UN)
        os.replace(tmp_path, STATUS_PATH)
    except Exception:
        # Clean up temp file on failure
        try:
            os.unlink(tmp_path)
        except OSError:
            pass
        raise


def main():
    try:
        raw = sys.stdin.read()
        data = json.loads(raw) if raw.strip() else {}
    except json.JSONDecodeError:
        sys.exit(0)

    event_name = data.get("hook_event_name", "")
    new_state = EVENT_STATE_MAP.get(event_name)

    # Load existing status and update
    status = read_existing_status()

    # Always update timestamp
    tz = timezone(timedelta(hours=8))
    status["timestamp"] = datetime.now(tz).isoformat()

    # Update session/turn context
    if sid := data.get("session_id"):
        status["session_id"] = sid
    if tid := data.get("turn_id"):
        status["turn_id"] = tid
    if cwd := data.get("cwd"):
        status["cwd"] = cwd
    if model := data.get("model"):
        status["model"] = model

    # Update state if this event maps to one
    if new_state is not None:
        status["state"] = new_state

    # Update tool info from tool-bearing events
    if event_name in TOOL_EVENTS:
        tool, detail = extract_tool_detail(event_name, data)
        if tool:
            status["last_tool"] = tool
        if detail:
            status["last_tool_detail"] = detail

    # For SessionStart, reset to idle and clear tool info
    if event_name == "SessionStart":
        status.pop("last_tool", None)
        status.pop("last_tool_detail", None)

    write_status_atomic(status)


if __name__ == "__main__":
    main()
