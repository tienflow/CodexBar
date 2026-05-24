import AppKit

/// Manages the NSStatusItem and its dropdown menu.
final class StatusBarController {
    private let statusItem: NSStatusItem
    private let dotView = StatusDotView()
    private var stateWatcher: StateWatcher?
    private var currentStatus: AgentStatus = .empty

    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            button.addSubview(dotView)
            dotView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                dotView.centerXAnchor.constraint(equalTo: button.centerXAnchor),
                dotView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
                dotView.widthAnchor.constraint(equalToConstant: 18),
                dotView.heightAnchor.constraint(equalToConstant: 18),
            ])
            button.frame.size = NSSize(width: 18, height: 18)
        }
    }

    func start() {
        let watcher = StateWatcher { [weak self] status in
            self?.handleStatusChange(status)
        }
        stateWatcher = watcher
        watcher.start()
    }

    private func handleStatusChange(_ status: AgentStatus) {
        currentStatus = status
        dotView.update(state: status.state)
        updateMenu()
    }

    private func updateMenu() {
        let menu = NSMenu()

        let titleItem = NSMenuItem(title: "CodexBar", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)
        menu.addItem(.separator())

        let statusItem = NSMenuItem(title: "● \(currentStatus.state.label)", action: nil, keyEquivalent: "")
        statusItem.isEnabled = false
        menu.addItem(statusItem)

        if let model = currentStatus.model {
            let item = NSMenuItem(title: "模型: \(model)", action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.addItem(item)
        }

        if let cwd = currentStatus.cwd {
            let short = cwd.replacingOccurrences(of: FileManager.default.homeDirectoryForCurrentUser.path, with: "~")
            let item = NSMenuItem(title: "目录: \(short)", action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.addItem(item)
        }

        menu.addItem(.separator())

        if let tool = currentStatus.last_tool {
            let detail = currentStatus.last_tool_detail ?? tool
            let item = NSMenuItem(title: "最近操作: \(tool) \(detail)", action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.addItem(item)
            menu.addItem(.separator())
        }

        let quitItem = NSMenuItem(title: "退出", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
