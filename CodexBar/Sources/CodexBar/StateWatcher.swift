import Foundation

final class StateWatcher {
    private let filePath: String
    private var callback: ((AgentStatus) -> Void)?
    private var lastFileState: String = ""
    private var idleTimer: Timer?
    private var lastHookTime: Date = Date.distantPast
    private var inactivityTimer: Timer?
    private var currentDisplayedState: AgentState = .idle

    init(callback: @escaping (AgentStatus) -> Void) {
        self.filePath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".codex/agent-status.json").path
        self.callback = callback
    }

    func start() {
        let dir = (filePath as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)

        // Reset status file on app start
        resetStatusFile()

        callback?(.empty)

        let timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(timer, forMode: .common)

        // Check inactivity every 3 seconds
        inactivityTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.checkInactivity()
        }
        RunLoop.main.add(inactivityTimer!, forMode: .common)
    }

    private func resetStatusFile() {
        let emptyStatus: [String: Any] = [
            "state": "idle",
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        if let data = try? JSONSerialization.data(withJSONObject: emptyStatus, options: .prettyPrinted) {
            try? data.write(to: URL(fileURLWithPath: filePath))
        }
        lastFileState = "idle"
    }

    private func tick() {
        let status = readStatus()
        let fileState = status.state.rawValue

        guard fileState != lastFileState else { return }
        lastFileState = fileState

        // Update last hook time when we detect a real state change
        lastHookTime = Date()

        cancelIdleReset()

        if fileState == "idle" {
            currentDisplayedState = .idle
            callback?(.empty)
        } else if fileState == "completed" {
            currentDisplayedState = .completed
            callback?(status)
            scheduleIdleReset()
        } else {
            currentDisplayedState = AgentState(rawValue: fileState) ?? .idle
            callback?(status)
        }
    }

    private func checkInactivity() {
        let timeSinceLastHook = Date().timeIntervalSince(lastHookTime)

        // If no hook activity for 8 seconds and not idle, force idle
        if timeSinceLastHook > 8 && currentDisplayedState != .idle {
            lastFileState = "idle"
            currentDisplayedState = .idle
            callback?(.empty)
        }
    }

    private func scheduleIdleReset() {
        cancelIdleReset()
        idleTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            guard let self else { return }
            self.currentDisplayedState = .idle
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
