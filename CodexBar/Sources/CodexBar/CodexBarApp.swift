import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var controller: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        controller = StatusBarController()
        controller?.start()
    }
}

@main
struct CodexBarApp {
    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}
