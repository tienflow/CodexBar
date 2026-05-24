# CodexBar

macOS 菜单栏状态指示灯，实时显示 Codex 的工作状态。

## 安装

1. 打开 `CodexBar.dmg`
2. 拖动 `CodexBar.app` 到 Applications 文件夹
3. 双击运行 `install-hooks.sh`（安装 Codex hooks）
4. 重启 Codex，点击信任新 hooks
5. 启动 CodexBar

## 状态说明

| 状态 | 灯效 |
|---|---|
| 空闲 | 三灯暗淡 |
| 思考中 | 黄灯呼吸脉冲 |
| 开发中 | 黄绿跑马灯 |
| 需确认 | 红灯闪烁 |
| 已完成 | 绿灯常亮 3 秒 |

## 卸载

```bash
# 删除 App
rm -rf /Applications/CodexBar.app

# 删除 hooks
rm ~/.codex/hooks/codexbar_dispatch.py
# 编辑 ~/.codex/hooks.json，移除 codexbar 相关条目
```
