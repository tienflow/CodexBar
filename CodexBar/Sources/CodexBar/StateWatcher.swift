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
        resetStatusFile()
        callback?(.empty)

        let timer = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(timer, forMode: .common)
    }

    private func resetStatusFile() {
        let empty: [String: Any] = ["state": "idle", "timestamp": ISO8601DateFormatter().string(from: Date())]
        if let data = try? JSONSerialization.data(withJSONObject: empty, options: .prettyPrinted) {
            try? data.write(to: URL(fileURLWithPath: filePath))
        }
        lastFileState = "idle"
    }

    private func tick() {
        let status = readStatus()
        let fileState = status.state.rawValue

        guard fileState != lastFileState else { return }
        lastFileState = fileState

        cancelIdleReset()

        if fileState == "idle" {
            callback?(.empty)
        } else if fileState == "completed" {
            callback?(status)
            scheduleIdleReset()
        } else {
            // thinking, developing, confirming
            callback?(status)
        }
    }

    private func scheduleIdleReset() {
        cancelIdleReset()
        let timer = Timer(timeInterval: 5.0, repeats: false) { [weak self] _ in
            guard let self else { return }
            self.resetStatusFile()
            self.callback?(.empty)
        }
        RunLoop.main.add(timer, forMode: .common)
        idleTimer = timer
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
