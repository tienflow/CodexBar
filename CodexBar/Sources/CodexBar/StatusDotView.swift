import AppKit

/// Three traffic lights inside a white-bordered transparent pill.
final class PillStatusView: NSView {
    private var currentState: AgentState = .idle
    private var animTimer: Timer?
    private var animPhase: CGFloat = 0
    private var isBlinkVisible = true

    private let yellowColor = NSColor(red: 1.0, green: 0.76, blue: 0.03, alpha: 1.0)
    private let greenColor = NSColor(red: 0.20, green: 0.82, blue: 0.35, alpha: 1.0)
    private let redColor = NSColor(red: 1.0, green: 0.22, blue: 0.17, alpha: 1.0)

    private let pillWidth: CGFloat = 50
    private let pillHeight: CGFloat = 18
    private let dotRadius: CGFloat = 5.0
    private let borderWidth: CGFloat = 1.2

    init() {
        super.init(frame: NSRect(x: 0, y: 0, width: 50, height: 18))
    }

    required init?(coder: NSCoder) { fatalError() }

    deinit { stopAnim() }

    func update(state: AgentState) {
        let prev = currentState
        currentState = state
        guard prev != state else { return }
        stopAnim()
        switch state {
        case .thinking, .developing:
            startMarquee()
        case .confirming:
            startBlink()
        default:
            break
        }
        needsDisplay = true
    }

    override var isFlipped: Bool { false }

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        ctx.saveGState()

        let centerY = pillHeight / 2
        let spacing: CGFloat = 13
        let startX = (pillWidth - spacing * 2) / 2

        let pillRect = NSRect(x: 0, y: 0, width: pillWidth, height: pillHeight)
        let pillPath = NSBezierPath(roundedRect: pillRect, xRadius: pillHeight / 2, yRadius: pillHeight / 2)
        NSColor.clear.setFill()
        pillPath.fill()
        pillPath.lineWidth = borderWidth
        NSColor.white.setStroke()
        pillPath.stroke()

        let (ya, ga, ra) = lightAlphas()

        ctx.setFillColor(yellowColor.withAlphaComponent(ya).cgColor)
        ctx.fillEllipse(in: NSRect(x: startX - dotRadius, y: centerY - dotRadius,
                                   width: dotRadius * 2, height: dotRadius * 2))

        ctx.setFillColor(greenColor.withAlphaComponent(ga).cgColor)
        ctx.fillEllipse(in: NSRect(x: startX + spacing - dotRadius, y: centerY - dotRadius,
                                   width: dotRadius * 2, height: dotRadius * 2))

        ctx.setFillColor(redColor.withAlphaComponent(ra).cgColor)
        ctx.fillEllipse(in: NSRect(x: startX + spacing * 2 - dotRadius, y: centerY - dotRadius,
                                   width: dotRadius * 2, height: dotRadius * 2))

        ctx.restoreGState()
    }

    private func lightAlphas() -> (CGFloat, CGFloat, CGFloat) {
        let dim: CGFloat = 0.15
        switch currentState {
        case .idle:
            return (dim, dim, dim)
        case .thinking, .developing:
            let p = animPhase.truncatingRemainder(dividingBy: 2.0)
            let yAlpha: CGFloat = (p < 1.0) ? 1.0 : dim
            let gAlpha: CGFloat = (p >= 1.0) ? 1.0 : dim
            return (yAlpha, gAlpha, dim)
        case .confirming:
            let r = isBlinkVisible ? 1.0 : 0.08
            return (dim, dim, r)
        case .completed:
            return (dim, 1.0, dim)
        }
    }

    private func startMarquee() {
        let timer = Timer(timeInterval: 1.0 / 15.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.animPhase += 0.10
            self.needsDisplay = true
        }
        RunLoop.main.add(timer, forMode: .common)
        animTimer = timer
    }

    private func startBlink() {
        let timer = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.isBlinkVisible.toggle()
            self.needsDisplay = true
        }
        RunLoop.main.add(timer, forMode: .common)
        animTimer = timer
    }

    private func stopAnim() {
        animTimer?.invalidate()
        animTimer = nil
        animPhase = 0
    }
}
