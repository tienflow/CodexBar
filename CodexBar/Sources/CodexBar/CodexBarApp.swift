import AppKit

@main
struct CodexBarApp {
    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)

        let controller = StatusBarController()
        controller.start()

        app.run()
    }
}
