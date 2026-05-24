# Phase 1 Context: Hook 调度系统

**Created:** 2026-05-24
**Phase:** 1 - Hook 调度系统
**Status:** Captured

## Domain

Python hook 脚本 + hooks.json 配置，将 Codex 生命周期事件映射到状态枚举并写入共享状态文件。

## Decisions

### Hook 脚本位置
- 脚本放在 `~/.codex/hooks/codexbar_dispatch.py`
- 理由：Codex hooks 标准位置，项目级 `.codex/hooks.json` 可引用
- 不放在项目内，因为 Codex hooks 需要全局可用

### 状态文件格式
- 位置：`~/.codex/agent-status.json`
- 字段命名：snake_case（Python 惯例，与 Codex hooks JSON 风格一致）
- 无 version 字段（v1 简单实现，未来可加）

### 错误处理
- Hook 脚本失败时静默退出（exit 0），不阻塞 Codex 主流程
- 不写错误状态到文件（避免污染 UI）
- stderr 被 Codex 捕获但不影响执行

### 多会话处理
- v1 只显示最近一个会话
- 新 session 的 hook 写入覆盖旧状态
- session_id 字段帮助用户辨识哪个实例

### 原子写入
- 使用 tempfile + rename 实现原子写入
- fcntl.flock 加文件锁防止读写竞争
- 写入失败时不更新状态文件

## Canonical Refs

- `.planning/ROADMAP.md` — Phase 1 目标和成功标准
- `.planning/REQUIREMENTS.md` — HOOK-01~05, STAT-01~07, CONF-01~02

## Code Context

无现有代码，绿色项目。

---
*Context captured: 2026-05-24*
