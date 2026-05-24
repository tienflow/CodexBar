import Foundation

final class StateWatcher {
    private let filePath: String
    private var callback: ((AgentStatus) -> Void)?
    private var lastFileState: String = ""
    private var idleTimer: Timer?
    private var isIdle: Bool = true

    init(callback: @escaping (AgentStatus) -> Void) {
        self.filePath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".codex/agent-status.json").path
        self.callback = callback
    }

    func start() {
        let dir = (filePath as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)

        // Start idle
        callback?(.empty)

        let timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(timer, forMode: .common)
    }

    private func tick() {
        let status = readStatus()
        let fileState = status.state.rawValue

        // Only react when file state actually changes
        guard fileState != lastFileState else { return }
        lastFileState = fileState

        // Ignore idle/completed when we're already idle
        if isIdle && (fileState == "idle" || fileState == "completed") {
            return
        }

        cancelIdleReset()

        if fileState == "completed" {
            callback?(status)
            scheduleIdleReset()
        } else if fileState != "idle" {
            isIdle = false
            callback?(status)
        }
    }

    private func scheduleIdleReset() {
        cancelIdleReset()
        idleTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            guard let self else { return }
            self.isIdle = true
            self.lastFileState = ""
            self.callback?(.empty)
        }
    }

    private func cancelIdleReset() {
        idleTimer?.invalidate()
        idleTimer = nil
    }

    private func readStatus() -> AgentStatus {
        guard let data = FileManager.default.contents(atPath: filePath),
              let s = try? JSONDecoder().decode(AgentStatus.self, from: data) else {
            return .empty
        }
        return s
    }
}
