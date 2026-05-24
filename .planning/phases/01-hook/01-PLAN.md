# Plan: Phase 1 - Hook 调度系统

**Created:** 2026-05-24
**Phase:** 01 - Hook 调度系统
**Requirements:** HOOK-01~05, STAT-01~07, CONF-01~02

## Goal

实现 Python hook 脚本和 hooks.json 配置，能正确响应 Codex 事件并写入状态文件。

## Tasks

### Task 1: 创建状态文件写入模块

**文件:** `hooks/codexbar_dispatch.py` (开发时放在项目内，安装时复制到 `~/.codex/hooks/`)

**实现:**
- `read_existing_status()` — 读取现有 agent-status.json，失败返回空 dict
- `write_status_atomic(status)` — 原子写入：tempfile + fcntl.flock + os.replace
- `extract_tool_detail(event_name, data)` — 从 tool_input 提取操作摘要

**验证:** 手动构造 JSON，运行脚本，检查输出文件内容正确

### Task 2: 实现事件到状态映射

**文件:** `hooks/codexbar_dispatch.py` (main 函数)

**实现:**
- EVENT_STATE_MAP 字典映射 7 个事件到状态
- 从 stdin 读取 JSON，提取 hook_event_name
- PostToolUse 特殊处理：只更新 last_tool，不改 state
- SessionStart 清除 last_tool 信息

**验证:** 模拟所有 7 种事件输入，验证状态文件输出正确

### Task 3: 创建 hooks.json 配置

**文件:** `hooks/hooks.json` (开发时在项目内，安装时复制到 `~/.codex/`)

**实现:**
- 配置 7 个事件的 hook handler
- 每个事件调用 `/usr/bin/python3 ~/.codex/hooks/codexbar_dispatch.py`
- 使用 `~` 路径，不依赖项目目录

**验证:** 检查 JSON 格式正确，Codex 能加载（手动测试）

### Task 4: 创建安装脚本

**文件:** `scripts/install-hooks.sh`

**实现:**
- 复制 `codexbar_dispatch.py` 到 `~/.codex/hooks/`
- 复制 `hooks.json` 到 `~/.codex/` (注意不覆盖现有 config.toml)
- 检查是否已安装，提示用户 review hooks

**验证:** 运行脚本，检查文件复制正确

### Task 5: 创建卸载脚本

**文件:** `scripts/uninstall-hooks.sh`

**实现:**
- 删除 `~/.codex/hooks/codexbar_dispatch.py`
- 从 `~/.codex/hooks.json` 移除 codexbar 相关 hook
- 保留其他 hooks 不动

**验证:** 运行脚本，检查文件删除正确

## Files to Create

```
hooks/
├── codexbar_dispatch.py    # Hook 调度脚本
└── hooks.json              # Hook 配置模板
scripts/
├── install-hooks.sh        # 安装脚本
└── uninstall-hooks.sh      # 卸载脚本
tests/
└── test_dispatch.py        # 单元测试
```

## Verification Criteria

1. 运行 `python3 hooks/codexbar_dispatch.py` + stdin JSON → agent-status.json 正确生成
2. 所有 7 个事件类型映射正确
3. PostToolUse 只更新 last_tool，不改变 state
4. 原子写入无 JSON 损坏（并发测试）
5. hooks.json 格式正确
6. 安装脚本正常工作
7. 卸载脚本正常工作

## Test Cases

```python
# test_dispatch.py

def test_session_start():
    """SessionStart → idle, 清除 last_tool"""
    input_data = {"hook_event_name": "SessionStart", "session_id": "abc"}
    # → state: "idle", last_tool: null

def test_user_prompt_submit():
    """UserPromptSubmit → thinking"""
    input_data = {"hook_event_name": "UserPromptSubmit", "session_id": "abc"}
    # → state: "thinking"

def test_pre_tool_use_bash():
    """PreToolUse (Bash) → developing, 提取命令摘要"""
    input_data = {"hook_event_name": "PreToolUse", "tool_name": "Bash", "tool_input": {"command": "ls -la"}}
    # → state: "developing", last_tool: "Bash", last_tool_detail: "ls -la"

def test_pre_tool_use_apply_patch():
    """PreToolUse (apply_patch) → developing, 提取文件名"""
    input_data = {"hook_event_name": "PreToolUse", "tool_name": "apply_patch", "tool_input": {"command": "--- a/foo.swift\n+++ b/foo.swift"}}
    # → state: "developing", last_tool: "apply_patch", last_tool_detail: "--- a/foo.swift"

def test_permission_request():
    """PermissionRequest → confirming"""
    input_data = {"hook_event_name": "PermissionRequest", "session_id": "abc"}
    # → state: "confirming"

def test_post_tool_use():
    """PostToolUse → 不改 state, 只更新 last_tool"""
    # 前置状态: developing
    input_data = {"hook_event_name": "PostToolUse", "tool_name": "Bash", "tool_response": "output"}
    # → state: "developing" (不变), last_tool: "Bash"

def test_stop():
    """Stop → completed"""
    input_data = {"hook_event_name": "Stop", "session_id": "abc"}
    # → state: "completed"

def test_atomic_write():
    """并发写入不损坏文件"""
    # 多线程同时写入，验证文件始终是有效 JSON
```
