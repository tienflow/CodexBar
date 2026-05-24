# 交接文档：CodexBar 项目

## 项目概述

CodexBar 是一个 macOS 菜单栏状态指示灯 app，通过 Codex hooks 机制实时显示 Codex 的工作状态。

**GitHub**: https://github.com/tienflow/CodexBar
**最新 Release**: v1.0.0 (DMG 安装包)

## 当前状态

项目已完成 v1.0.0 发布，包含：
- Python hook 调度脚本 (`codexbar_dispatch.py`)
- Swift 菜单栏 app（三盏信号灯在透明胶囊药丸中）
- DMG 安装包
- GitHub Release

## 已解决的问题

1. **completed/idle 循环**：Codex 桌面端后台运行时，状态文件被反复更新，导致绿灯闪烁。解决：只在 `Stop` 事件后才回 idle，移除不活动超时。

2. **运行中熄灯**：Codex 读文件时 hook 之间有较长间隔，导致灯熄灭。解决：移除不活动超时，灯只在状态变化时切换。

3. **菜单弹出时动画暂停**：macOS RunLoop 切换导致 Timer 暂停。解决：Timer 使用 `.common` 模式。

4. **用户交互工具检测**：`request_user_input` 不触发 hooks，无法显示红灯闪烁。已知限制，接受。

5. **后台误触发黄绿跑马灯**：Codex 无任务时，后台 `PreToolUse`/`SubagentStart` 等事件仍会写入 `developing` 状态，导致黄绿跑马灯误启动。解决：在状态文件中引入 `active_session` 标记，只在 `UserPromptSubmit` 后授予活跃状态，`Stop` 后撤销。无活跃会话时，`PreToolUse`、`PermissionRequest`、`SubagentStart` 事件不改变状态。详情见 `codexbar_dispatch.py` 的 `ACTIVE_SESSION_GATED` 集合。

## 技术细节

### 状态映射
- `SessionStart` → idle，`active_session` → false
- `UserPromptSubmit` → thinking，`active_session` → true
- `SubagentStart` → thinking（仅当 active_session 为 true）
- `PreToolUse` → developing（或 confirming，仅当 active_session 为 true）
- `PermissionRequest` → confirming（仅当 active_session 为 true）
- `PostToolUse` → 不改状态
- `Stop` → completed，`active_session` → false

### 动画效果
- thinking: 黄灯呼吸脉冲 (20fps)
- developing: 黄绿跑马灯 (15fps)
- confirming: 红灯闪烁 (2Hz)
- completed: 绿灯常亮 3 秒 → 回灰色

### 文件位置
- 状态文件: `~/.codex/agent-status.json`
- Hook 脚本: `~/.codex/hooks/codexbar_dispatch.py`
- Hook 配置: `~/.codex/hooks.json`
- 调试日志: `~/.codex/hooks/codexbar_tool_trace.log`

## 已知限制

1. `request_user_input` 工具不触发 hooks，无法显示红灯闪烁
2. 只显示最近一个会话的状态
3. `active_session` 标记仅在 dispatch 脚本内维护，不随 Codex 重启保留

## 下一步建议

1. 如果需要更精确的状态检测，可以研究 Codex 是否有其他事件可以区分「活跃处理」和「后台运行」
2. 可以考虑添加开机自启功能
3. 可以考虑添加状态历史记录

## 建议技能

- `frontend-design`: 如果需要改进 UI 设计
- `tavily-search`: 如果需要搜索 Codex hooks 相关文档
