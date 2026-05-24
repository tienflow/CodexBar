# AGENTS.md - CodexBar Project

## Project Context

macOS 菜单栏状态指示灯 app，通过 Codex hooks 实时感知 Codex 工作状态。

## Workflow

This project uses GSD (Get Shit Done) workflow.

**Planning files:** `.planning/`
- `PROJECT.md` — Project context and decisions
- `config.json` — Workflow preferences
- `REQUIREMENTS.md` — v1 requirements with REQ-IDs
- `ROADMAP.md` — Phase structure and success criteria
- `STATE.md` — Project progress and decisions

**Next step:** Run `/gsd:discuss-phase 1` to gather context for Phase 1.

## Development Conventions

- Language: Python for hooks, Swift for app
- Build: Swift Package Manager
- Testing: Manual verification + unit tests
- Git: Conventional commits, no auto-push
