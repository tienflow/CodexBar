# CodexBar

macOS 菜单栏状态指示灯，实时显示 Codex 的工作状态。

## 功能

- 常驻 macOS 菜单栏，不占 Dock 栏位置
- 三盏信号灯（黄、绿、红）同时展示在透明胶囊药丸中
- 实时响应 Codex 的工作状态变化
- 点击药丸弹出菜单，显示当前状态、模型、目录和最近操作

## 状态灯效

| 状态 | 灯效 | 触发时机 |
|---|---|---|
| 空闲 | 三灯暗淡 | Codex 未运行或空闲 |
| 运行中 | 黄绿跑马灯（15fps） | 用户提交任务起，持续到任务结束 |
| 思考中 | 黄灯呼吸脉冲（20fps） | 对话压缩（PreCompact/PostCompact） |
| 需确认 | 红灯闪烁（2Hz） | Codex 请求权限确认或需要用户输入 |
| 已完成 | 绿灯常亮 5 秒 | Codex 完成当前回合，然后自动回灰 |

## 技术架构

```
Codex 进程
    │
    ├─ hooks (Python 脚本)
    │   每个生命周期事件触发时，读取 stdin JSON
    │   将状态写入 ~/.codex/agent-status.json
    │
    └─ ~/.codex/agent-status.json  ← 共享状态文件
            │
            └─ CodexBar.app (Swift/SwiftUI)
                Timer 轮询监听状态文件变化
                更新 NSStatusItem 圆点颜色和动画
                点击下拉显示最近操作摘要
```

### Hook 原理

Codex 提供了完整的生命周期 hooks 机制。每个 hook 事件触发时，外部脚本通过 stdin 接收 JSON 数据，包含事件类型、会话信息、工具调用详情等。

CodexBar 的 Python 调度脚本（`codexbar_dispatch.py`）监听以下 9 个事件：

| 事件 | 说明 | 状态映射 |
|---|---|---|
| `SessionStart` | 新会话开始 | idle，重置会话 |
| `UserPromptSubmit` | 用户发送消息 | developing（跑马灯立刻亮起） |
| `SubagentStart` | 子 agent 启动 | developing（仅活跃会话） |
| `PreToolUse` | 工具调用前 | developing（仅活跃会话） |
| `PostToolUse` | 工具调用后 | 不改状态，仅更新工具信息 |
| `PermissionRequest` | 需要权限确认 | confirming（仅活跃会话） |
| `PreCompact` | 对话压缩前 | thinking（黄灯呼吸） |
| `PostCompact` | 对话压缩后 | thinking（黄灯呼吸） |
| `Stop` | 当前回合结束 | completed |

### 会话门禁（active_session）

为防止 Codex 桌面端后台运行时误触发跑马灯，引入 `active_session` 标记：

- `UserPromptSubmit` 激活会话
- `Stop` / `SessionStart` 关闭会话
- `PreToolUse`、`PostToolUse`、`PermissionRequest`、`SubagentStart`、`PreCompact`、`PostCompact` 在无活跃会话时被静默跳过

### 状态文件

状态文件位于 `~/.codex/agent-status.json`：

```json
{
  "state": "developing",
  "timestamp": "2026-05-24T14:30:00+08:00",
  "active_session": true,
  "session_id": "abc123",
  "turn_id": "t_456",
  "cwd": "/Users/you/project",
  "model": "gpt-5.4",
  "last_tool": "Bash",
  "last_tool_detail": "ls -la src/"
}
```

### 动画实现

- **跑马灯**：三个灯依次亮起，使用 `truncatingRemainder` 循环切换
- **呼吸脉冲**：使用 `sin()` 函数计算 alpha 值，在 0.3 和 1.0 之间平滑过渡
- **闪烁**：简单的 0.5 秒定时器切换 `isHidden`

所有动画 Timer 都添加到 `RunLoop.main` 的 `.common` 模式，确保菜单弹出时动画不会暂停。

## 安装

### 前提条件

- macOS 13+ (Ventura)
- Python 3.9+（系统自带即可）
- [Codex](https://github.com/openai/codex) 已安装

### 方式一：DMG 安装

1. 从 [Releases](https://github.com/tienflow/CodexBar/releases) 下载 `CodexBar.dmg`
2. 打开 DMG，将 `CodexBar.app` 拖到 Applications 文件夹
3. 打开 Terminal，执行以下命令安装 hooks：

```bash
cd CodexBar/scripts
./install-hooks.sh
```

4. 重启 Codex，当提示新 hooks 时点击 **Trust** 信任
5. 从 Applications 启动 CodexBar

### 方式二：源码编译

```bash
git clone https://github.com/tienflow/CodexBar.git
cd CodexBar
cd CodexBar && swift build -c release
cd .. && ./scripts/install-hooks.sh
./CodexBar/.build/release/CodexBar
```

### 验证安装

1. 启动 CodexBar，菜单栏应出现透明胶囊药丸
2. 在 Codex 中发送消息，观察黄绿跑马灯是否立刻亮起
3. 任务完成后，观察绿灯是否常亮 5 秒后回灰
4. 点击药丸，应弹出状态菜单

## 使用

### 日常使用

CodexBar 启动后自动常驻菜单栏。无需手动操作——只要 Codex 在运行，灯效会自动响应状态变化。

### 菜单功能

点击药丸可查看：
- 当前状态（空闲/运行中/需要确认/已完成）
- 使用的模型
- 工作目录
- 最近一次工具调用
- 退出按钮

### 卸载

```bash
rm -rf /Applications/CodexBar.app
rm ~/.codex/hooks/codexbar_dispatch.py
# 从 hooks.json 中移除 CodexBar 相关条目
```

## 项目结构

```
CodexBar/
├── CodexBar/                    # Swift App
│   ├── Package.swift
│   └── Sources/CodexBar/
│       ├── CodexBarApp.swift    # App 入口
│       ├── StatusBarController.swift  # 菜单栏管理
│       ├── StatusDotView.swift  # 信号灯视图（胶囊 + 三灯动画）
│       ├── StateWatcher.swift   # 状态文件监听 + 定时器
│       └── StatusModels.swift   # 状态模型
├── hooks/                       # Hook 脚本
│   ├── codexbar_dispatch.py    # 调度脚本（Python）
│   └── hooks.json              # Hook 配置模板
├── scripts/
│   ├── build-app.sh            # 构建脚本
│   ├── install-hooks.sh        # 安装脚本
│   └── uninstall-hooks.sh      # 卸载脚本
└── tests/
    └── test_dispatch.py        # 单元测试（29 个）
```

## 已知限制

- `request_user_input` 工具不触发 hooks，因此等待用户输入时无法显示红灯闪烁
- 只显示最近一个会话的状态
- 状态文件在 Codex 关闭后保留，App 启动时会重置为空闲

## 开发

### 运行测试

```bash
python3 -m unittest tests/test_dispatch.py -v
```

### 手动测试状态变化

```bash
# 运行中
echo '{"hook_event_name":"UserPromptSubmit","session_id":"test"}' | python3 ~/.codex/hooks/codexbar_dispatch.py

# 对话压缩
echo '{"hook_event_name":"PreCompact","session_id":"test","trigger":"auto"}' | python3 ~/.codex/hooks/codexbar_dispatch.py

# 需确认
echo '{"hook_event_name":"PermissionRequest","session_id":"test"}' | python3 ~/.codex/hooks/codexbar_dispatch.py

# 完成
echo '{"hook_event_name":"Stop","session_id":"test"}' | python3 ~/.codex/hooks/codexbar_dispatch.py
```

### 调试日志

Hook 调用日志：`~/.codex/hooks/codexbar_tool_trace.log`

## License

MIT
