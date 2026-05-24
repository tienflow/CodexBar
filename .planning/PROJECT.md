# CodexBar

## What This Is

macOS 菜单栏状态指示灯 app，通过 Codex hooks 机制实时感知 Codex 的工作状态（思考中、开发中、需要确认、已完成），用彩色圆点显示当前状态。点击图标可查看最近一次操作摘要。

## Core Value

实时、准确地反映 Codex 的工作状态，让用户一眼知道 Codex 在做什么、是否需要自己介入。

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] 菜单栏常驻显示彩色圆点指示灯
- [ ] 五种状态映射：idle(灰)、thinking(黄呼吸)、developing(绿呼吸)、confirming(红闪)、completed(绿常亮)
- [ ] Python hook 脚本读取 Codex 事件并写入状态文件
- [ ] Swift app 通过 FSEventStream 监听状态文件变化
- [ ] 点击下拉菜单显示：状态、模型、目录、最近操作
- [ ] 状态切换时颜色渐变过渡 (0.3s)
- [ ] SessionStart 重置状态到 idle

### Out of Scope

- 多会话同时显示 — 只显示最近一个会话
- 声音提醒 — v1 不做
- Token 用量显示 — v1 不做
- Homebrew 分发 — MVP 先本地编译
- Windows/Linux — macOS only

## Context

- Codex hooks 机制：每个生命周期事件触发时，外部脚本通过 stdin 接收 JSON，可执行命令
- 可用事件：SessionStart, UserPromptSubmit, SubagentStart, PreToolUse, PostToolUse, PermissionRequest, Stop
- 用户已在使用 Codex 桌面端 (macOS, Swift 6.3, Apple Silicon)
- 状态传递机制：Python hook 脚本 → ~/.codex/agent-status.json → Swift app FSEventStream

## Constraints

- **Hooks 执行时间**: <1s，不阻塞 Codex 主流程
- **macOS 版本**: 13+ (Ventura)，支持 FSEventStream
- **构建工具**: Swift Package Manager，不依赖 Xcode project
- **状态文件**: ~/.codex/agent-status.json，不与现有 Codex 文件冲突
- **Hook 信任**: Codex hooks 需要用户 review 和 trust 后才执行

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Python hook 脚本 | Codex hooks 支持命令执行，Python 无需额外依赖 | — Pending |
| FSEventStream 监听 | macOS 原生文件监听，高效且低延迟 | — Pending |
| 原子写入状态文件 | 防止读写竞争导致 JSON 损坏 | — Pending |
| 呼吸脉冲 vs 跑马灯 | 菜单栏图标尺寸小，呼吸脉冲更清晰 | — Pending |
| 黄色=思考 绿色=开发 | 符合交通灯直觉：黄灯过渡→绿灯行动 | — Pending |
| completed 保持不回落 | 无定时器，纯事件驱动，更简单 | — Pending |

---
*Last updated: 2026-05-24 after initialization*
