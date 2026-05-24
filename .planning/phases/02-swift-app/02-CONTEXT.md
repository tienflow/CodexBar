# Phase 2 Context: Swift 菜单栏 App

**Created:** 2026-05-24
**Phase:** 2 - Swift 菜单栏 App
**Status:** Captured (skipped discuss, carried forward from earlier discussion)

## Domain

macOS 菜单栏 app，监听 ~/.codex/agent-status.json，用彩色圆点显示 Codex 状态，点击下拉查看操作摘要。

## Decisions

### 技术栈
- Swift/SwiftUI 原生，无 Dock 图标
- NSStatusItem 常驻菜单栏
- FSEventStream 监听状态文件变化

### 视觉设计
- 18x18pt 圆点指示灯
- idle: 深灰 (#666) 无动画
- thinking: 黄色 (#F5A623) 呼吸脉冲 1.5s
- developing: 绿色 (#4CD964) 呼吸脉冲 2.5s
- confirming: 红色 (#FF3B30) 1Hz 闪烁
- completed: 绿色 (#4CD964) 实心常亮
- 状态切换 0.3s 渐变过渡

### 下拉菜单
- 状态文字 + 模型 + 目录 + 最近操作 + 退出按钮
- 点击触发，非 hover

### 构建
- Swift Package Manager，不依赖 Xcode project
- macOS 13+ (Ventura)

## Canonical Refs

- `.planning/ROADMAP.md` — Phase 2 目标和成功标准
- `.planning/REQUIREMENTS.md` — APP-01~07, FSMN-01~03
- `.planning/phases/01-hook/01-CONTEXT.md` — Phase 1 决策（状态文件格式）

## Code Context

Phase 1 交付的状态文件格式：
```json
{
  "state": "thinking|developing|confirming|completed|idle",
  "timestamp": "ISO8601",
  "session_id": "...",
  "turn_id": "...",
  "cwd": "...",
  "model": "...",
  "last_tool": "...",
  "last_tool_detail": "..."
}
```

---
*Context captured: 2026-05-24*
