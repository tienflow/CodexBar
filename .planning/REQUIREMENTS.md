# Requirements: CodexBar

**Defined:** 2026-05-24
**Core Value:** 实时、准确地反映 Codex 的工作状态，让用户一眼知道 Codex 在做什么、是否需要自己介入。

## v1 Requirements

### Hook 调度

- [ ] **HOOK-01**: Python 脚本从 stdin 读取 Codex hook JSON 数据
- [ ] **HOOK-02**: 根据 hook_event_name 映射到对应状态枚举
- [ ] **HOOK-03**: 原子写入 ~/.codex/agent-status.json（先写临时文件再 rename）
- [ ] **HOOK-04**: 从 PreToolUse 提取工具名和操作详情（apply_patch 文件名、Bash 命令前60字符）
- [ ] **HOOK-05**: PostToolUse 只更新 last_tool_detail，不改变状态

### 状态映射

- [ ] **STAT-01**: SessionStart → idle，清除 last_tool 信息
- [ ] **STAT-02**: UserPromptSubmit → thinking
- [ ] **STAT-03**: SubagentStart → thinking
- [ ] **STAT-04**: PreToolUse → developing
- [ ] **STAT-05**: PermissionRequest → confirming
- [ ] **STAT-06**: Stop → completed，保持到下次 SessionStart
- [ ] **STAT-07**: 状态文件包含 session_id, turn_id, cwd, model, last_tool, last_tool_detail, timestamp

### Hook 配置

- [ ] **CONF-01**: ~/.codex/hooks.json 配置所有事件的 hook handler
- [ ] **CONF-02**: Hook 命令指向 ~/.codex/hooks/codexbar_dispatch.py

### Swift 菜单栏 App

- [ ] **APP-01**: NSStatusItem 常驻菜单栏，无 Dock 图标
- [ ] **APP-02**: 18x18pt 圆点指示灯，五种状态颜色
- [ ] **APP-03**: thinking 状态黄色呼吸脉冲，周期 1.5s，alpha 0.4↔1.0
- [ ] **APP-04**: developing 状态绿色呼吸脉冲，周期 2.5s，alpha 0.4↔1.0
- [ ] **APP-05**: confirming 状态红色闪烁，1Hz
- [ ] **APP-06**: 状态切换时颜色渐变过渡 0.3s
- [ ] **APP-07**: 点击下拉菜单显示：状态文字、模型、目录、最近操作、退出按钮

### 文件监听

- [ ] **FSMN-01**: FSEventStream 监听 ~/.codex/agent-status.json 变化
- [ ] **FSMN-02**: 文件变化时解析 JSON 并更新 UI
- [ ] **FSMN-03**: 应用启动时读取初始状态文件

## v2 Requirements

- [ ] **MENU-01**: 下拉菜单显示 token 用量和上下文占比
- [ ] **MENU-02**: 声音提醒（需要确认时响一下）
- [ ] **MULTI-01**: 支持多个 Codex 会话同时显示
- [ ] **DIST-01**: Homebrew cask 分发

## Out of Scope

| Feature | Reason |
|---------|--------|
| 多会话同时显示 | v1 只显示最近一个会话，降低复杂度 |
| Windows/Linux | macOS only，利用原生 FSEventStream |
| Token 用量显示 | v2，需要额外的解析逻辑 |
| 声音提醒 | v2，非核心功能 |
| 自动更新 | v2，MVP 先手动安装 |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| HOOK-01 | Phase 1 | Pending |
| HOOK-02 | Phase 1 | Pending |
| HOOK-03 | Phase 1 | Pending |
| HOOK-04 | Phase 1 | Pending |
| HOOK-05 | Phase 1 | Pending |
| STAT-01 | Phase 1 | Pending |
| STAT-02 | Phase 1 | Pending |
| STAT-03 | Phase 1 | Pending |
| STAT-04 | Phase 1 | Pending |
| STAT-05 | Phase 1 | Pending |
| STAT-06 | Phase 1 | Pending |
| STAT-07 | Phase 1 | Pending |
| CONF-01 | Phase 1 | Pending |
| CONF-02 | Phase 1 | Pending |
| APP-01 | Phase 2 | Pending |
| APP-02 | Phase 2 | Pending |
| APP-03 | Phase 2 | Pending |
| APP-04 | Phase 2 | Pending |
| APP-05 | Phase 2 | Pending |
| APP-06 | Phase 2 | Pending |
| APP-07 | Phase 2 | Pending |
| FSMN-01 | Phase 2 | Pending |
| FSMN-02 | Phase 2 | Pending |
| FSMN-03 | Phase 2 | Pending |

**Coverage:**
- v1 requirements: 24 total
- Mapped to phases: 24
- Unmapped: 0 ✓

---
*Requirements defined: 2026-05-24*
*Last updated: 2026-05-24 after initial definition*
