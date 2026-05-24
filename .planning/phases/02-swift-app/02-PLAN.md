# Plan: Phase 2 - Swift 菜单栏 App

**Created:** 2026-05-24
**Phase:** 02 - Swift 菜单栏 App
**Requirements:** APP-01~07, FSMN-01~03

## Goal

实现 macOS 菜单栏 app，监听状态文件并用彩色圆点显示 Codex 状态。

## Tasks

### Task 1: 创建 Swift Package 项目

**文件:** `CodexBar/Package.swift`

**实现:**
- 定义 executable target "CodexBar"
- macOS 13+ platform requirement
- 无外部依赖

**验证:** `swift build` 编译通过

### Task 2: 实现状态模型

**文件:** `CodexBar/Sources/CodexBar/StatusModels.swift`

**实现:**
- `AgentState` enum: idle, thinking, developing, confirming, completed
- `AgentStatus` struct: 解析 agent-status.json
- label 属性返回中文状态名
- pulsePeriod 属性返回呼吸周期
- isBlinking 属性判断是否闪烁

**验证:** 单元测试 JSON 解析

### Task 3: 实现状态文件监听

**文件:** `CodexBar/Sources/CodexBar/StateWatcher.swift`

**实现:**
- FSEventStream 监听 ~/.codex/agent-status.json
- 文件变化时解析 JSON 并回调
- 启动时读取初始状态
- 300ms 延迟合并频繁变更

**验证:** 手动修改 JSON，确认回调触发

### Task 4: 实现圆点视图

**文件:** `CodexBar/Sources/CodexBar/StatusDotView.swift`

**实现:**
- 18x18pt NSView
- draw(_:) 绘制 8pt 半径实心圆
- 5 种状态颜色
- CADisplayLink 驱动呼吸脉冲
  - thinking: 周期 1.5s，alpha 0.4↔1.0
  - developing: 周期 2.5s，alpha 0.4↔1.0
- Timer 驱动 1Hz 闪烁 (confirming)
- 状态切换 0.3s CABasicAnimation 渐变

**验证:** 手动修改状态文件，观察动画效果

### Task 5: 实现菜单栏控制器

**文件:** `CodexBar/Sources/CodexBar/StatusBarController.swift`

**实现:**
- NSStatusItem with NSStatusBar.system.statusItem
- 持有 StatusDotView 作为 button.image
- 点击弹出 NSMenu
- 菜单内容：状态文字、模型、目录、最近操作、退出

**验证:** 点击菜单正确显示信息

### Task 6: 实现 App 入口

**文件:** `CodexBar/Sources/CodexBar/CodexBarApp.swift`

**实现:**
- NSApplication.shared.setActivationPolicy(.accessory)
- 创建 StatusBarController 实例
- 启动状态监听
- app.run()

**验证:** App 启动，菜单栏显示灰色圆点

### Task 7: 创建构建脚本

**文件:** `scripts/build-app.sh`

**实现:**
- `swift build` 编译项目
- 复制 binary 到 ~/Downloads/dev1/build/
- 提示用户运行

**验证:** 脚本执行成功，binary 可运行

## Files to Create

```
CodexBar/
├── Package.swift
└── Sources/
    └── CodexBar/
        ├── CodexBarApp.swift
        ├── StatusBarController.swift
        ├── StatusDotView.swift
        ├── StateWatcher.swift
        └── StatusModels.swift
scripts/
└── build-app.sh
```

## Verification Criteria

1. `swift build` 编译通过
2. App 启动后菜单栏显示灰色圆点
3. 手动修改 agent-status.json，圆点颜色和动画正确切换
4. thinking 黄色呼吸 1.5s，developing 绿色呼吸 2.5s，confirming 红色闪烁 1Hz
5. 状态切换时颜色渐变过渡
6. 点击下拉菜单正确显示状态信息和退出按钮
7. 退出按钮正常退出 App

## Test Cases

手动测试流程：

```bash
# 1. 构建
./scripts/build-app.sh

# 2. 启动 App
./build/CodexBar &

# 3. 模拟状态变化
echo '{"hook_event_name":"SessionStart","session_id":"s1"}' | python3 hooks/codexbar_dispatch.py
# → 灰色圆点

echo '{"hook_event_name":"UserPromptSubmit","session_id":"s1"}' | python3 hooks/codexbar_dispatch.py
# → 黄色呼吸

echo '{"hook_event_name":"PreToolUse","session_id":"s1","tool_name":"Bash","tool_input":{"command":"ls"}}' | python3 hooks/codexbar_dispatch.py
# → 绿色呼吸

echo '{"hook_event_name":"PermissionRequest","session_id":"s1"}' | python3 hooks/codexbar_dispatch.py
# → 红色闪烁

echo '{"hook_event_name":"Stop","session_id":"s1"}' | python3 hooks/codexbar_dispatch.py
# → 绿色常亮

# 4. 点击菜单栏图标，验证信息显示
# 5. 点击退出，验证 App 正常退出
```
