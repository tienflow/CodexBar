import AppKit

final class StatusBarController {
    private let statusItem: NSStatusItem
    private let pillView = PillStatusView()
    private var stateWatcher: StateWatcher?
    private var currentStatus: AgentStatus = .empty
    private let debugPath: String

    init() {
        self.debugPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".codex/codexbar-debug.log").path
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.addSubview(pillView)
            pillView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                pillView.centerXAnchor.constraint(equalTo: button.centerXAnchor),
                pillView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
                pillView.widthAnchor.constraint(equalToConstant: 52),
                pillView.heightAnchor.constraint(equalToConstant: 18),
            ])
            button.frame.size = NSSize(width: 56, height: 22)
        }
        log("StatusBarController init")
    }

    func start() {
        rebuildMenu()
        log("Menu rebuilt")

        let watcher = StateWatcher { [weak self] status in
            self?.log("Callback received: \(status.state.rawValue)")
            self?.currentStatus = status
            self?.pillView.update(state: status.state)
            self?.rebuildMenu()
            self?.log("UI updated")
        }
        stateWatcher = watcher
        watcher.start()
        log("Watcher started")
    }

    private func rebuildMenu() {
        let menu = NSMenu()

        let title = NSMenuItem(title: "CodexBar", action: nil, keyEquivalent: "")
        title.isEnabled = false
        menu.addItem(title)
        menu.addItem(.separator())

        let s = NSMenuItem(title: "● \(currentStatus.state.label)", action: nil, keyEquivalent: "")
        s.isEnabled = false
        menu.addItem(s)

        if let model = currentStatus.model {
            let m = NSMenuItem(title: "模型: \(model)", action: nil, keyEquivalent: "")
            m.isEnabled = false
            menu.addItem(m)
        }

        if let cwd = currentStatus.cwd {
            let short = cwd.replacingOccurrences(of: FileManager.default.homeDirectoryForCurrentUser.path, with: "~")
            let d = NSMenuItem(title: "目录: \(short)", action: nil, keyEquivalent: "")
            d.isEnabled = false
            menu.addItem(d)
        }

        menu.addItem(.separator())

        if let tool = currentStatus.last_tool {
            let detail = currentStatus.last_tool_detail ?? tool
            let t = NSMenuItem(title: "最近: \(tool) \(detail)", action: nil, keyEquivalent: "")
            t.isEnabled = false
            menu.addItem(t)
            menu.addItem(.separator())
        }

        let quit = NSMenuItem(title: "退出", action: #selector(quitApp), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        statusItem.menu = menu
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    private func log(_ msg: String) {
        let ts = ISO8601DateFormatter().string(from: Date())
        let line = "[\(ts)] [Controller] \(msg)\n"
        if let data = line.data(using: .utf8) {
            if let fh = FileHandle(forWritingAtPath: debugPath) {
                fh.seekToEndOfFile()
                fh.write(data)
                fh.closeFile()
            } else {
                try? data.write(to: URL(fileURLWithPath: debugPath))
            }
        }
    }
}
