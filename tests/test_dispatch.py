#!/usr/bin/env python3
"""Unit tests for codexbar_dispatch.py"""
import json
import os
import sys
import tempfile
import time
import unittest
from unittest.mock import patch

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "hooks"))

import codexbar_dispatch as dispatch


class TestExtractToolDetail(unittest.TestCase):
    def test_bash_command(self):
        data = {"tool_name": "Bash", "tool_input": {"command": "ls -la"}}
        tool, detail = dispatch.extract_tool_detail("PreToolUse", data)
        self.assertEqual(tool, "Bash")
        self.assertEqual(detail, "ls -la")

    def test_bash_long_command(self):
        cmd = "x" * 100
        data = {"tool_name": "Bash", "tool_input": {"command": cmd}}
        tool, detail = dispatch.extract_tool_detail("PreToolUse", data)
        self.assertEqual(tool, "Bash")
        self.assertEqual(len(detail), 63)

    def test_apply_patch(self):
        data = {
            "tool_name": "apply_patch",
            "tool_input": {"command": "--- a/foo.swift\n+++ b/foo.swift\n@@ -1,5 +1,5 @@"}
        }
        tool, detail = dispatch.extract_tool_detail("PreToolUse", data)
        self.assertEqual(tool, "apply_patch")
        self.assertEqual(detail, "--- a/foo.swift")

    def test_mcp_tool(self):
        data = {"tool_name": "mcp__filesystem__read_file", "tool_input": {}}
        tool, detail = dispatch.extract_tool_detail("PreToolUse", data)
        self.assertEqual(tool, "mcp__filesystem__read_file")
        self.assertEqual(detail, "mcp__filesystem__read_file")

    def test_no_tool_name(self):
        data = {"tool_input": {}}
        tool, detail = dispatch.extract_tool_detail("PreToolUse", data)
        self.assertIsNone(tool)
        self.assertIsNone(detail)


class TestEventStateMap(unittest.TestCase):
    def test_session_start(self):
        self.assertEqual(dispatch.EVENT_STATE_MAP["SessionStart"], "idle")

    def test_user_prompt_submit(self):
        self.assertEqual(dispatch.EVENT_STATE_MAP["UserPromptSubmit"], "developing")

    def test_subagent_start(self):
        self.assertEqual(dispatch.EVENT_STATE_MAP["SubagentStart"], "developing")

    def test_pre_tool_use(self):
        self.assertEqual(dispatch.EVENT_STATE_MAP["PreToolUse"], "developing")

    def test_permission_request(self):
        self.assertEqual(dispatch.EVENT_STATE_MAP["PermissionRequest"], "confirming")

    def test_post_tool_use_no_state(self):
        self.assertIsNone(dispatch.EVENT_STATE_MAP["PostToolUse"])

    def test_stop(self):
        self.assertEqual(dispatch.EVENT_STATE_MAP["Stop"], "completed")


class TestAtomicWrite(unittest.TestCase):
    def setUp(self):
        self.test_dir = tempfile.mkdtemp()
        self.test_status_path = os.path.join(self.test_dir, "test-status.json")

    def tearDown(self):
        import shutil
        shutil.rmtree(self.test_dir, ignore_errors=True)

    def test_write_and_read(self):
        status = {"state": "thinking", "timestamp": "2026-05-24T14:30:00+08:00"}
        with patch.object(dispatch, "STATUS_PATH", self.test_status_path):
            dispatch.write_status_atomic(status)
            with open(self.test_status_path) as f:
                loaded = json.load(f)
        self.assertEqual(loaded["state"], "thinking")

    def test_atomic_write_no_corruption(self):
        with patch.object(dispatch, "STATUS_PATH", self.test_status_path):
            for i in range(10):
                status = {"state": "thinking", "counter": i}
                dispatch.write_status_atomic(status)
            with open(self.test_status_path) as f:
                loaded = json.load(f)
        self.assertIn("state", loaded)


class TestReadExistingStatus(unittest.TestCase):
    def setUp(self):
        self.test_dir = tempfile.mkdtemp()
        self.test_status_path = os.path.join(self.test_dir, "test-status.json")

    def tearDown(self):
        import shutil
        shutil.rmtree(self.test_dir, ignore_errors=True)

    def test_read_existing(self):
        status = {"state": "thinking", "model": "gpt-5.4"}
        with open(self.test_status_path, "w") as f:
            json.dump(status, f)
        with patch.object(dispatch, "STATUS_PATH", self.test_status_path):
            loaded = dispatch.read_existing_status()
        self.assertEqual(loaded["state"], "thinking")

    def test_read_nonexistent(self):
        with patch.object(dispatch, "STATUS_PATH", "/nonexistent/path"):
            loaded = dispatch.read_existing_status()
        self.assertEqual(loaded, {})

    def test_read_invalid_json(self):
        with open(self.test_status_path, "w") as f:
            f.write("not json {{{")
        with patch.object(dispatch, "STATUS_PATH", self.test_status_path):
            loaded = dispatch.read_existing_status()
        self.assertEqual(loaded, {})


class TestActiveSessionLifecycle(unittest.TestCase):
    """Tests for the active_session gating logic in main()."""

    def setUp(self):
        self.test_dir = tempfile.mkdtemp()
        self.test_status_path = os.path.join(self.test_dir, "test-status.json")
        self.debug_log = os.path.join(self.test_dir, "test-trace.log")

    def _simulate(self, event_name, **extra):
        payload = {"hook_event_name": event_name, **extra}
        with patch.object(dispatch, "STATUS_PATH", self.test_status_path), \
             patch.object(dispatch, "DEBUG_LOG", self.debug_log), \
             patch.object(sys, 'stdin') as mock_stdin:
            mock_stdin.read.return_value = json.dumps(payload)
            dispatch.main()
        with open(self.test_status_path) as f:
            return json.load(f)

    def test_background_pretooluse_suppressed(self):
        status = self._simulate("SessionStart")
        self.assertEqual(status["state"], "idle")
        self.assertFalse(status["active_session"])

        status = self._simulate("PreToolUse", tool_name="Bash")
        self.assertEqual(status["state"], "idle")
        self.assertFalse(status["active_session"])

    def test_background_posttooluse_suppressed(self):
        self._simulate("SessionStart")
        status = self._simulate("PostToolUse", tool_name="Bash")
        self.assertEqual(status["state"], "idle")
        self.assertFalse(status["active_session"])

    def test_userprompt_starts_session(self):
        self._simulate("SessionStart")
        status = self._simulate("UserPromptSubmit", session_id="s1")
        self.assertEqual(status["state"], "developing")
        self.assertTrue(status["active_session"])

        status = self._simulate("PreToolUse", tool_name="apply_patch", session_id="s1")
        self.assertEqual(status["state"], "developing")
        self.assertTrue(status["active_session"])

    def test_posttooluse_preserves_state(self):
        """PostToolUse does NOT change state — StateWatcher handles timeout."""
        self._simulate("SessionStart")
        self._simulate("UserPromptSubmit", session_id="s1")
        self._simulate("PreToolUse", tool_name="Bash", session_id="s1")

        status = self._simulate("PostToolUse", tool_name="Bash", session_id="s1")
        # State stays developing — the Swift app will revert after timeout
        self.assertEqual(status["state"], "developing")
        self.assertTrue(status["active_session"])

    def test_last_tool_time_recorded(self):
        """PreToolUse and PostToolUse both record last_tool_time."""
        self._simulate("SessionStart")
        self._simulate("UserPromptSubmit", session_id="s1")

        status = self._simulate("PreToolUse", tool_name="Bash", session_id="s1")
        self.assertIsNotNone(status.get("last_tool_time"))
        t1 = status["last_tool_time"]

        time.sleep(0.01)
        status = self._simulate("PostToolUse", tool_name="Bash", session_id="s1")
        self.assertIsNotNone(status.get("last_tool_time"))
        t2 = status["last_tool_time"]
        self.assertGreater(t2, t1)

    def test_stop_ends_session(self):
        self._simulate("SessionStart")
        self._simulate("UserPromptSubmit", session_id="s1")
        self._simulate("PreToolUse", tool_name="Bash", session_id="s1")

        status = self._simulate("Stop", session_id="s1")
        self.assertEqual(status["state"], "completed")
        self.assertFalse(status["active_session"])

        status = self._simulate("PreToolUse", tool_name="Bash")
        self.assertEqual(status["state"], "completed")
        self.assertFalse(status["active_session"])

    def test_subagent_start_gated(self):
        self._simulate("SessionStart")
        status = self._simulate("SubagentStart")
        self.assertEqual(status["state"], "idle")
        self.assertFalse(status["active_session"])

        self._simulate("UserPromptSubmit", session_id="s1")
        status = self._simulate("SubagentStart", session_id="s1")
        self.assertEqual(status["state"], "developing")
        self.assertTrue(status["active_session"])

    def test_permission_request_gated(self):
        self._simulate("SessionStart")
        status = self._simulate("PermissionRequest")
        self.assertEqual(status["state"], "idle")

        self._simulate("UserPromptSubmit", session_id="s1")
        status = self._simulate("PermissionRequest")
        self.assertEqual(status["state"], "confirming")

    def test_user_interaction_tool_during_session(self):
        self._simulate("SessionStart")
        self._simulate("UserPromptSubmit", session_id="s1")
        status = self._simulate("PreToolUse", tool_name="request_user_input", session_id="s1")
        self.assertEqual(status["state"], "confirming")

    def test_second_task_after_stop(self):
        self._simulate("SessionStart")
        self._simulate("UserPromptSubmit", session_id="s1")
        self._simulate("PreToolUse", tool_name="Bash", session_id="s1")
        self._simulate("Stop", session_id="s1")

        status = self._simulate("UserPromptSubmit", session_id="s2")
        self.assertTrue(status["active_session"])
        self.assertEqual(status["state"], "developing")

        status = self._simulate("PreToolUse", tool_name="apply_patch", session_id="s2")
        self.assertEqual(status["state"], "developing")

    def test_full_tool_cycle(self):
        """PreToolUse sets developing, PostToolUse preserves it (timeout in Swift)."""
        self._simulate("SessionStart")
        self._simulate("UserPromptSubmit", session_id="s1")

        status = self._simulate("PreToolUse", tool_name="Bash", session_id="s1")
        self.assertEqual(status["state"], "developing")

        status = self._simulate("PostToolUse", tool_name="Bash", session_id="s1")
        self.assertEqual(status["state"], "developing")

        status = self._simulate("PreToolUse", tool_name="apply_patch", session_id="s1")
        self.assertEqual(status["state"], "developing")

        status = self._simulate("PostToolUse", tool_name="apply_patch", session_id="s1")
        self.assertEqual(status["state"], "developing")

    def test_session_start_clears_tool_time(self):
        """SessionStart clears stale last_tool_time."""
        self._simulate("SessionStart")
        self._simulate("UserPromptSubmit", session_id="s1")
        self._simulate("PreToolUse", tool_name="Bash", session_id="s1")
        self._simulate("Stop", session_id="s1")

        status = self._simulate("SessionStart")
        self.assertIsNone(status.get("last_tool_time"))


if __name__ == "__main__":
    unittest.main()
