# Project State: CodexBar

## Project Reference

See: .planning/PROJECT.md (updated 2026-05-24)

**Core value:** 实时、准确地反映 Codex 的工作状态，让用户一眼知道 Codex 在做什么、是否需要自己介入。
**Current focus:** Phase 1 - Hook 调度系统

## Progress

| Phase | Status | Started | Completed |
|-------|--------|---------|-----------|
| Phase 1: Hook 调度系统 | Planned | 2026-05-24 | — |
| Phase 2: Swift 菜单栏 App | Pending | — | — |

## Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Python hook 脚本 | Codex hooks 支持命令执行，Python 无需额外依赖 | ✓ Good |
| FSEventStream 监听 | macOS 原生文件监听，高效且低延迟 | — Pending |
| 原子写入状态文件 | 防止读写竞争导致 JSON 损坏 | ✓ Good |
| 呼吸脉冲 vs 跑马灯 | 菜单栏图标尺寸小，呼吸脉冲更清晰 | ✓ Good |
| 黄色=思考 绿色=开发 | 符合交通灯直觉：黄灯过渡→绿灯行动 | ✓ Good |
| completed 保持不回落 | 无定时器，纯事件驱动，更简单 | ✓ Good |
| Hook 脚本位置 | ~/.codex/hooks/ 标准位置，全局可用 | ✓ Good |
| snake_case 字段名 | Python 惯例，与 Codex hooks JSON 风格一致 | ✓ Good |
| 静默退出错误处理 | 不阻塞 Codex 主流程 | ✓ Good |
| 覆盖式多会话 | v1 只显示最近一个会话 | ✓ Good |

## Sessions

| Session | Phase | Action | File |
|---------|-------|--------|------|
| 2026-05-24 | Phase 1 | Context gathered | .planning/phases/01-hook/01-CONTEXT.md |
| 2026-05-24 | Phase 1 | Plan created | .planning/phases/01-hook/01-PLAN.md |
