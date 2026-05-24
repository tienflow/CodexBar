#!/usr/bin/env python3
from __future__ import annotations
"""CodexBar hook dispatcher."""
import json
import os
import sys
import time
import tempfile
import fcntl
from datetime import datetime, timezone, timedelta

STATUS_PATH = os.path.expanduser("~/.codex/agent-status.json")
DEBUG_LOG = os.path.expanduser("~/.codex/hooks/codexbar_tool_trace.log")

EVENT_STATE_MAP = {
    "SessionStart":       "idle",
    "UserPromptSubmit":   "developing",
    "SubagentStart":      "developing",
    "PreToolUse":         "developing",
    "PostToolUse":        None,
    "PermissionRequest":  "confirming",
    "PreCompact":         "thinking",
    "PostCompact":        "thinking",
    "Stop":               "completed",
}

USER_INTERACTION_TOOLS = {
    "request_user_input",
    "AskUser",
}

TOOL_EVENTS = {"PreToolUse", "PostToolUse"}

# Events that don't require an active session
ACTIVE_SESSION_GATED = {"PreToolUse", "PostToolUse", "PermissionRequest", "SubagentStart", "PreCompact", "PostCompact"}


def trace(msg: str) -> None:
    try:
        ts = datetime.now().strftime("%H:%M:%S.%f")[:-3]
        with open(DEBUG_LOG, "a") as f:
            f.write(f"[{ts}] {msg}\n")
    except Exception:
        pass


def extract_tool_detail(event_name: str, data: dict) -> tuple[str | None, str | None]:
    tool_name = data.get("tool_name")
    tool_input = data.get("tool_input") or {}

    if tool_name:
        trace(f"EVENT={event_name} TOOL={tool_name}")

    if not tool_name:
        return None, None

    if tool_name == "apply_patch":
        cmd = tool_input.get("command", "")
        detail = cmd.split("\n")[0][:80] if cmd else "apply_patch"
        return tool_name, detail

    if tool_name == "Bash":
        cmd = tool_input.get("command", "")
        detail = cmd[:60] + ("..." if len(cmd) > 60 else "")
        return tool_name, detail

    return tool_name, tool_name


def read_existing_status() -> dict:
    try:
        with open(STATUS_PATH, "r") as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return {}


def write_status_atomic(status: dict) -> None:
    dir_name = os.path.dirname(STATUS_PATH) or "."
    fd, tmp_path = tempfile.mkstemp(dir=dir_name, suffix=".tmp")
    try:
        with os.fdopen(fd, "w") as f:
            fcntl.flock(f, fcntl.LOCK_EX)
            json.dump(status, f, ensure_ascii=False, indent=2)
            f.flush()
            os.fsync(f.fileno())
            fcntl.flock(f, fcntl.LOCK_UN)
        os.replace(tmp_path, STATUS_PATH)
    except Exception:
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

    trace(f"HOOK={event_name} state={new_state} tool={data.get('tool_name','')} mode={data.get('permission_mode','')}")

    status = read_existing_status()

    # -- Session lifecycle tracking --
    active_session = status.get("active_session", False)

    if event_name == "SessionStart":
        active_session = False
    elif event_name == "UserPromptSubmit":
        active_session = True
    elif event_name == "Stop":
        active_session = False

    status["active_session"] = active_session

    # -- Gate active states behind session --
    if event_name in ACTIVE_SESSION_GATED and not active_session:
        trace(f"BACKGROUND: {event_name} suppressed (no active session)")
        new_state = None

    # For PreToolUse, check if tool requires user interaction
    if event_name == "PreToolUse" and new_state is not None:
        tool_name = data.get("tool_name", "")
        if tool_name in USER_INTERACTION_TOOLS:
            new_state = "confirming"
            trace(f"USER_INTERACTION: {tool_name} -> confirming")

    # For PermissionRequest, always confirming (if session is active)
    if event_name == "PermissionRequest" and new_state is not None:
        new_state = "confirming"
        trace(f"PERMISSION_REQUEST -> confirming")

    tz = timezone(timedelta(hours=8))
    status["timestamp"] = datetime.now(tz).isoformat()

    if sid := data.get("session_id"):
        status["session_id"] = sid
    if tid := data.get("turn_id"):
        status["turn_id"] = tid
    if cwd := data.get("cwd"):
        status["cwd"] = cwd
    if model := data.get("model"):
        status["model"] = model

    if new_state is not None:
        status["state"] = new_state
        trace(f"STATE -> {new_state}")

    if event_name in TOOL_EVENTS:
        status["last_tool_time"] = time.time()
        tool, detail = extract_tool_detail(event_name, data)
        if tool:
            status["last_tool"] = tool
        if detail:
            status["last_tool_detail"] = detail

    if event_name == "SessionStart":
        status.pop("last_tool", None)
        status.pop("last_tool_detail", None)
        status.pop("last_tool_time", None)

    write_status_atomic(status)


if __name__ == "__main__":
    main()
