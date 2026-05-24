import AppKit

/// Custom NSView that draws a colored dot with optional breathing/blink animation.
final class StatusDotView: NSView {
    private var currentState: AgentState = .idle
    private var displayLink: CVDisplayLink?
    private var animationStartTime: CFTimeInterval = 0
    private var blinkTimer: Timer?
    private var isBlinkVisible = true

    private let dotRadius: CGFloat = 4
    private let viewSize: CGFloat = 18

    private static let colors: [AgentState: NSColor] = [
        .idle:       NSColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0),
        .thinking:   NSColor(red: 0.96, green: 0.65, blue: 0.14, alpha: 1.0),
        .developing: NSColor(red: 0.30, green: 0.85, blue: 0.39, alpha: 1.0),
        .confirming: NSColor(red: 1.0, green: 0.23, blue: 0.19, alpha: 1.0),
        .completed:  NSColor(red: 0.30, green: 0.85, blue: 0.39, alpha: 1.0),
    ]

    init() {
        super.init(frame: NSRect(x: 0, y: 0, width: viewSize, height: viewSize))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        stopAllAnimations()
    }

    func update(state: AgentState) {
        let prev = currentState
        currentState = state

        guard prev != state else { return }

        stopAllAnimations()

        switch state {
        case .thinking, .developing:
            startBreathing(period: state.pulsePeriod)
        case .confirming:
            startBlinking()
        default:
            break
        }

        needsDisplay = true
    }

    override var isFlipped: Bool { false }

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        ctx.saveGState()

        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let color = Self.colors[currentState] ?? Self.colors[.idle]!

        var alpha: CGFloat = 1.0
        if currentState == .confirming {
            alpha = isBlinkVisible ? 1.0 : 0.0
        }

        ctx.setFillColor(color.withAlphaComponent(alpha).cgColor)
        ctx.fillEllipse(in: CGRect(
            x: center.x - dotRadius,
            y: center.y - dotRadius,
            width: dotRadius * 2,
            height: dotRadius * 2
        ))

        ctx.restoreGState()
    }

    // MARK: - Breathing Animation

    private func startBreathing(period: Double) {
        animationStartTime = CACurrentMediaTime()

        var displayLinkRef: CVDisplayLink?
        CVDisplayLinkCreateWithActiveCGDisplays(&displayLinkRef)
        guard let link = displayLinkRef else { return }

        let linkSelf = Unmanaged.passUnretained(self).toOpaque()
        CVDisplayLinkSetOutputCallback(link, { _, _, _, _, _, userInfo -> CVReturn in
            guard let info = userInfo else { return kCVReturnSuccess }
            let view = Unmanaged<StatusDotView>.fromOpaque(info).takeUnretainedValue()
            DispatchQueue.main.async {
                view.needsDisplay = true
            }
            return kCVReturnSuccess
        }, linkSelf)

        CVDisplayLinkStart(link)
        displayLink = link
    }

    private func stopAllAnimations() {
        if let link = displayLink {
            CVDisplayLinkStop(link)
            CVDisplayLinkSetOutputCallback(link, nil, nil)
            displayLink = nil
        }
        blinkTimer?.invalidate()
        blinkTimer = nil
    }

    // MARK: - Blink Animation

    private func startBlinking() {
        blinkTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.isBlinkVisible.toggle()
            self.needsDisplay = true
        }
    }
}
