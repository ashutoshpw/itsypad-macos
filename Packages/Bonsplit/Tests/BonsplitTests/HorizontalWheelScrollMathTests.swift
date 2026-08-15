import AppKit
import XCTest
@testable import Bonsplit

final class HorizontalWheelScrollMathTests: XCTestCase {
    func testTranslatesOnlyVerticalDominantMovement() {
        XCTAssertTrue(HorizontalWheelScrollMath.shouldTranslate(horizontalDelta: 0, verticalDelta: 1))
        XCTAssertTrue(HorizontalWheelScrollMath.shouldTranslate(horizontalDelta: 1, verticalDelta: -2))
        XCTAssertFalse(HorizontalWheelScrollMath.shouldTranslate(horizontalDelta: 2, verticalDelta: 1))
        XCTAssertFalse(HorizontalWheelScrollMath.shouldTranslate(horizontalDelta: 1, verticalDelta: 1))
        XCTAssertFalse(HorizontalWheelScrollMath.shouldTranslate(horizontalDelta: 0, verticalDelta: 0))
    }

    func testPreciseDeltaPreservesMagnitudeAndDirection() {
        let target = HorizontalWheelScrollMath.targetOffset(
            currentOffset: 100,
            viewportWidth: 300,
            documentWidth: 900,
            verticalDelta: -12,
            hasPreciseDeltas: true,
            coarseStep: 32
        )

        XCTAssertEqual(target, 112)
    }

    func testCoarseDeltaUsesConfiguredStep() {
        let target = HorizontalWheelScrollMath.targetOffset(
            currentOffset: 100,
            viewportWidth: 300,
            documentWidth: 900,
            verticalDelta: -1,
            hasPreciseDeltas: false,
            coarseStep: 32
        )

        XCTAssertEqual(target, 132)
    }

    func testTargetOffsetClampsAtBothBoundaries() {
        let leftTarget = HorizontalWheelScrollMath.targetOffset(
            currentOffset: 5,
            viewportWidth: 300,
            documentWidth: 900,
            verticalDelta: 20,
            hasPreciseDeltas: true,
            coarseStep: 32
        )
        let rightTarget = HorizontalWheelScrollMath.targetOffset(
            currentOffset: 595,
            viewportWidth: 300,
            documentWidth: 900,
            verticalDelta: -20,
            hasPreciseDeltas: true,
            coarseStep: 32
        )

        XCTAssertEqual(leftTarget, 0)
        XCTAssertEqual(rightTarget, 600)
    }

    func testTargetOffsetDoesNotMoveWhenContentFitsViewport() {
        let target = HorizontalWheelScrollMath.targetOffset(
            currentOffset: 0,
            viewportWidth: 300,
            documentWidth: 250,
            verticalDelta: -10,
            hasPreciseDeltas: true,
            coarseStep: 32
        )

        XCTAssertEqual(target, 0)
    }

    func testBridgeResolvesOnlyItsMatchingScrollViewport() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 300),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        let rootView = NSView(frame: window.contentView?.bounds ?? .zero)
        window.contentView = rootView

        let editorScrollView = makeScrollView(frame: rootView.bounds)
        let tabScrollView = makeScrollView(frame: NSRect(x: 0, y: 268, width: 400, height: 32))
        let bridge = HorizontalScrollWheelView(frame: tabScrollView.frame)

        rootView.addSubview(editorScrollView)
        rootView.addSubview(tabScrollView)
        rootView.addSubview(bridge)

        XCTAssertTrue(
            bridge.scrollViewUnderPointer(at: NSPoint(x: 200, y: 284)) === tabScrollView
        )

        tabScrollView.removeFromSuperview()

        XCTAssertNil(bridge.scrollViewUnderPointer(at: NSPoint(x: 200, y: 284)))
        bridge.stopMonitoring()
    }

    private func makeScrollView(frame: NSRect) -> NSScrollView {
        let scrollView = NSScrollView(frame: frame)
        scrollView.documentView = NSView(
            frame: NSRect(x: 0, y: 0, width: frame.width * 2, height: frame.height)
        )
        return scrollView
    }
}
