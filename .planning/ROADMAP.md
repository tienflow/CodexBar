# Roadmap: CodexBar

**Created:** 2026-05-24
**Phases:** 2
**Requirements:** 24 (all mapped)

## Phase 1: Hook 调度系统
**Goal:** 实现 Python hook 脚本和配置，能正确响应 Codex 事件并写入状态文件
**Success Criteria:**
1. 运行 dispatch 脚本，stdin 输入 JSON，agent-status.json 正确生成
2. 所有 7 个事件类型正确映射到对应状态
3. PostToolUse 只更新 last_tool，不改变状态
4. 原子写入无 JSON 损坏
5. hooks.json 配置正确，Codex 能加载

**Requirements:** HOOK-01, HOOK-02, HOOK-03, HOOK-04, HOOK-05, STAT-01, STAT-02, STAT-03, STAT-04, STAT-05, STAT-06, STAT-07, CONF-01, CONF-02

## Phase 2: Swift 菜单栏 App
**Goal:** 实现 macOS 菜单栏 app，监听状态文件并用彩色圆点显示状态
**Success Criteria:**
1. App 编译通过，启动后菜单栏显示灰色圆点
2. 手动修改 agent-status.json，圆点颜色和动画正确切换
3. thinking 黄色呼吸 1.5s，developing 绿色呼吸 2.5s，confirming 红色闪烁 1Hz
4. 状态切换时颜色渐变过渡
5. 点击下拉菜单正确显示状态信息和退出按钮

**Requirements:** APP-01, APP-02, APP-03, APP-04, APP-05, APP-06, APP-07, FSMN-01, FSMN-02, FSMN-03

## Phase Details

### Phase 1: Hook 调度系统
**Goal:** 实现 Python hook 脚本和配置，能正确响应 Codex 事件并写入状态文件
**Success Criteria:**
1. 运行 dispatch 脚本，stdin 输入 JSON，agent-status.json 正确生成
2. 所有 7 个事件类型正确映射到对应状态
3. PostToolUse 只更新 last_tool，不改变状态
4. 原子写入无 JSON 损坏
5. hooks.json 配置正确，Codex 能加载

### Phase 2: Swift 菜单栏 App
**Goal:** 实现 macOS 菜单栏 app，监听状态文件并用彩色圆点显示状态
**Success Criteria:**
1. App 编译通过，启动后菜单栏显示灰色圆点
2. 手动修改 agent-status.json，圆点颜色和动画正确切换
3. thinking 黄色呼吸 1.5s，developing 绿色呼吸 2.5s，confirming 红色闪烁 1Hz
4. 状态切换时颜色渐变过渡
5. 点击下拉菜单正确显示状态信息和退出按钮

---
*Roadmap created: 2026-05-24*
