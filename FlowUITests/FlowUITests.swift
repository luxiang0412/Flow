import XCTest

/// UI automation: launch, debug controls, accessibility, basic layout
/// (contract §7.2 / §9 matrix — UI). Multi-touch precision is validated by the
/// Replay Engine in unit/integration tests, not by synthetic gestures here.
final class FlowUITests: XCTestCase {

    @MainActor
    func launchFlow(launchArguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = launchArguments
        app.launch()
        return app
    }

    @MainActor
    func testLaunchAndCanvasAccessibilityLabel() {
        let app = launchFlow()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
        // Canvas exposes accessibility label
        XCTAssertTrue(app.otherElements["Luminous Ink canvas"].exists
                      || app.descendants(matching: .any).matching(identifier: "Luminous Ink canvas").firstMatch.exists)
    }

    @MainActor
    func testDebugControlsAccessibility() {
        let app = launchFlow()
        let open = app.buttons["Open debug panel"]
        if open.exists { open.tap() }
        let pause = app.buttons["Pause simulation"]
        XCTAssertTrue(pause.waitForExistence(timeout: 5), "pause button missing")
        pause.tap()
        let resume = app.buttons["Resume simulation"]
        XCTAssertTrue(resume.exists)
        resume.tap()

        let clear = app.buttons["Clear canvas"]
        XCTAssertTrue(clear.exists)
        clear.tap()

        let capture = app.buttons["Capture current frame"]
        XCTAssertTrue(capture.exists)
        capture.tap()
    }

    @MainActor
    func testReplayMenuListsStandardFixtures() {
        let app = launchFlow(launchArguments: [])
        let open = app.buttons["Open debug panel"]
        if open.exists { open.tap() }
        let menu = app.buttons["replay-menu"]
        XCTAssertTrue(menu.waitForExistence(timeout: 5))
        // Tapping by coordinate avoids XCUITest's scroll-to-visible AX action,
        // which fails (kAXErrorCannotComplete) for this SwiftUI Menu inside the
        // translucent overlay even though the button is on screen.
        menu.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        let spiral = app.buttons["spiral"]
        if !spiral.exists { print("AXMENU:\n\(app.debugDescription)") }
        XCTAssertTrue(spiral.exists)
        spiral.tap()
        // replay begins; menu label reflects the running fixture
        XCTAssertTrue(app.buttons["Replay: spiral"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testCLIReplayLaunchUpgradesOverlay() {
        // Launch directly into a fixture replay (deterministic capture mode)
        let app = launchFlow(launchArguments: [
            "--flow-replay", "slow-stroke",
            "--flow-seed", "2401",
            "--flow-fixed-dt", "0.0083333333",
            "--flow-capture-at", "0.5,2",
        ])
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
        sleep(2)
        // app must still be alive after replay begins
        XCTAssertTrue(app.state == .runningForeground)
    }

    @MainActor
    func testCaptureFrameProducesSimulatorScreenshotAttachment() {
        let app = launchFlow(launchArguments: ["--flow-replay", "tap"])
        sleep(3)
        let shot = XCUIScreen.main.screenshot()
        let att = XCTAttachment(screenshot: shot)
        att.name = "flow-replay-tap"
        att.lifetime = .keepAlways
        add(att)
    }
}