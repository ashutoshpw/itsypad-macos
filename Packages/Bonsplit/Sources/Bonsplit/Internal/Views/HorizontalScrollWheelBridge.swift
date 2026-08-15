import AppKit
import SwiftUI

/// Converts vertical wheel movement over a horizontal SwiftUI scroll view into
/// horizontal scrolling without intercepting the view's normal pointer events.
struct HorizontalScrollWheelBridge: NSViewRepresentable {
    func makeNSView(context: Context) -> HorizontalScrollWheelView {
        HorizontalScrollWheelView()
    }

    func updateNSView(_ nsView: HorizontalScrollWheelView, context: Context) {}

    static func dismantleNSView(_ nsView: HorizontalScrollWheelView, coordinator: Void) {
        nsView.stopMonitoring()
    }
}

final class HorizontalScrollWheelView: NSView {
    private var eventMonitor: Any?

    override func hitTest(_ point: NSPoint) -> NSView? {
        nil
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()

        if window != nil {
            startMonitoring()
        } else {
            stopMonitoring()
        }
    }

    func stopMonitoring() {
        guard let eventMonitor else { return }
        NSEvent.removeMonitor(eventMonitor)
        self.eventMonitor = nil
    }

    deinit {
        stopMonitoring()
    }

    private func startMonitoring() {
        guard eventMonitor == nil else { return }

        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
            self?.handleScrollWheel(event) ?? event
        }
    }

    private func handleScrollWheel(_ event: NSEvent) -> NSEvent? {
        guard let window,
              event.window === window,
              !isHiddenOrHasHiddenAncestor,
              alphaValue > 0,
              bounds.contains(convert(event.locationInWindow, from: nil)),
              HorizontalWheelScrollMath.shouldTranslate(
                horizontalDelta: event.scrollingDeltaX,
                verticalDelta: event.scrollingDeltaY
              ),
              let scrollView = scrollViewUnderPointer(at: event.locationInWindow),
              let documentView = scrollView.documentView else {
            return event
        }

        let clipView = scrollView.contentView
        let currentOffset = clipView.bounds.minX
        let targetOffset = HorizontalWheelScrollMath.targetOffset(
            currentOffset: currentOffset,
            viewportWidth: clipView.bounds.width,
            documentWidth: documentView.frame.width,
            verticalDelta: event.scrollingDeltaY,
            hasPreciseDeltas: event.hasPreciseScrollingDeltas,
            coarseStep: TabBarMetrics.tabHeight
        )

        guard targetOffset != currentOffset else { return event }

        var origin = clipView.bounds.origin
        origin.x = targetOffset
        clipView.scroll(to: origin)
        scrollView.reflectScrolledClipView(clipView)
        return nil
    }

    func scrollViewUnderPointer(at locationInWindow: NSPoint) -> NSScrollView? {
        guard let contentView = window?.contentView else { return nil }
        let point = contentView.convert(locationInWindow, from: nil)
        var view = contentView.hitTest(point)

        while let currentView = view {
            if let scrollView = currentView as? NSScrollView,
               owns(scrollView) {
                return scrollView
            }
            view = currentView.superview
        }

        return nil
    }

    private func owns(_ scrollView: NSScrollView) -> Bool {
        let bridgeFrame = convert(bounds, to: nil)
        let viewportFrame = scrollView.contentView.convert(scrollView.contentView.bounds, to: nil)
        let tolerance: CGFloat = 1

        return abs(bridgeFrame.minX - viewportFrame.minX) <= tolerance
            && abs(bridgeFrame.maxX - viewportFrame.maxX) <= tolerance
            && abs(bridgeFrame.minY - viewportFrame.minY) <= tolerance
            && abs(bridgeFrame.maxY - viewportFrame.maxY) <= tolerance
    }
}

enum HorizontalWheelScrollMath {
    static func shouldTranslate(horizontalDelta: CGFloat, verticalDelta: CGFloat) -> Bool {
        verticalDelta != 0 && abs(verticalDelta) > abs(horizontalDelta)
    }

    static func targetOffset(
        currentOffset: CGFloat,
        viewportWidth: CGFloat,
        documentWidth: CGFloat,
        verticalDelta: CGFloat,
        hasPreciseDeltas: Bool,
        coarseStep: CGFloat
    ) -> CGFloat {
        let maximumOffset = max(documentWidth - viewportWidth, 0)
        let scale = hasPreciseDeltas ? 1 : coarseStep
        let proposedOffset = currentOffset - verticalDelta * scale
        return min(max(proposedOffset, 0), maximumOffset)
    }
}
