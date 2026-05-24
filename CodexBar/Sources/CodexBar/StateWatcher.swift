import Foundation

final class StateWatcher {
    private let filePath: String
    private var callback: ((AgentStatus) -> Void)?
    private var lastFileState: String = ""
    private var idleTimer: Timer?

    init(callback: @escaping (AgentStatus) -> Void) {
        self.filePath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".codex/agent-status.json").path
        self.callback = callback
    }

    func start() {
        let dir = (filePath as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)

        // Start in idle
        callback?(.empty)

        let timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(timer, forMode: .common)
    }

    private func tick() {
        let status = readStatus()
        let fileState = status.state.rawValue

        // Skip if file state hasn't changed
        guard fileState != lastFileState else { return }
        lastFileState = fileState

        cancelIdleReset()

        if fileState == "idle" {
            // Only go idle if we're not already waiting for completed timeout
            callback?(.empty)
        } else if fileState == "completed" {
            callback?(status)
            // Only go idle after Stop event
            scheduleIdleReset()
        } else {
            // thinking, developing, confirming
            callback?(status)
        }
    }

    private func scheduleIdleReset() {
        cancelIdleReset()
        idleTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            guard let self else { return }
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
