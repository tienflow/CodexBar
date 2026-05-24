import Foundation
import CoreServices

/// Watches ~/.codex/agent-status.json for changes via FSEventStream.
final class StateWatcher {
    private var eventStream: FSEventStreamRef?
    private let statusFilePath: String
    private var onStatusChange: ((AgentStatus) -> Void)?

    init(onStatusChange: @escaping (AgentStatus) -> Void) {
        self.statusFilePath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".codex/agent-status.json").path
        self.onStatusChange = onStatusChange
    }

    func start() {
        let dir = (statusFilePath as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)

        notifyIfChanged()

        let path = dir as CFString
        var context = FSEventStreamContext()
        context.info = Unmanaged.passUnretained(self).toOpaque()

        guard let stream = FSEventStreamCreate(
            nil,
            fileChangeCallback,
            &context,
            [path] as CFArray,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            0.3,
            FSEventStreamCreateFlags(kFSEventStreamCreateFlagFileEvents)
        ) else { return }

        eventStream = stream
        FSEventStreamScheduleWithRunLoop(stream, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
        FSEventStreamStart(stream)
    }

    func stop() {
        if let stream = eventStream {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
            eventStream = nil
        }
    }

    fileprivate func notifyIfChanged() {
        guard let data = FileManager.default.contents(atPath: statusFilePath),
              let status = try? JSONDecoder().decode(AgentStatus.self, from: data) else {
            onStatusChange?(.empty)
            return
        }
        onStatusChange?(status)
    }
}

private func fileChangeCallback(
    _ streamRef: ConstFSEventStreamRef,
    _ clientCallBackInfo: UnsafeMutableRawPointer?,
    _ numEvents: Int,
    _ eventPaths: UnsafeMutableRawPointer,
    _ eventFlags: UnsafePointer<FSEventStreamEventFlags>,
    _ eventIds: UnsafePointer<FSEventStreamEventId>
) {
    guard let info = clientCallBackInfo else { return }
    let watcher = Unmanaged<StateWatcher>.fromOpaque(info).takeUnretainedValue()

    let paths = Unmanaged<CFArray>.fromOpaque(eventPaths).takeUnretainedValue() as! [String]

    for i in 0..<numEvents {
        let flags = eventFlags[i]
        let relevantFlags: UInt32 = UInt32(kFSEventStreamEventFlagItemModified)
            | UInt32(kFSEventStreamEventFlagItemRenamed)
            | UInt32(kFSEventStreamEventFlagItemCreated)

        if (flags & relevantFlags) != 0 && paths[i].hasSuffix("agent-status.json") {
            watcher.notifyIfChanged()
            break
        }
    }
}
