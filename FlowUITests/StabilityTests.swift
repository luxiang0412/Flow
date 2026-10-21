import XCTest

/// P6 (simulator-reachable portion): long-run stability.
/// Numbers produced here are SIMULATOR measurements and must never be reported
/// as device performance (contract §7 / §9).
final class StabilityTests: XCTestCase {

    override func setUp() {
        continueAfterFailure = false
    }

    /// 100 pause/resume + clear cycles must not crash, leak the renderer, or
    /// leave the canvas permanently blank (contract §6.5 / P6 task 4).
    @MainActor
    func testHundredPauseClearResumeCycles() {
        let app = XCUIApplication()
        app.launchArguments = ["--flow-replay", "slow-stroke"]
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 20))

        let open = app.buttons["Open debug panel"]
        if open.exists { open.tap() }
        let pause = app.buttons["Pause simulation"]
        XCTAssertTrue(pause.waitForExistence(timeout: 10))
        let resume = app.buttons["Resume simulation"]
        let clear = app.buttons["Clear canvas"]
        let canvas = app.otherElements["Luminous Ink canvas"].firstMatch

        for i in 0..<100 {
            (pause.exists ? pause : resume).tap()
            if i % 10 == 0 { clear.tap() }
            if i % 25 == 0 {
                XCTAssertTrue(app.state == .runningForeground, "app died at cycle \(i)")
            }
        }
        XCTAssertTrue(app.state == .runningForeground, "app died during cycles")
        XCTAssertTrue(canvas.exists, "canvas disappeared after 100 cycles")

        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = "after-100-pause-clear-cycles"
        shot.lifetime = .keepAlways
        add(shot)
    }

    /// Continuous interaction for a sustained period; asserts the process stays
    /// alive and responsive (a cheap stand-in for the 10-minute device run).
    @MainActor
    func testSustainedRunStaysResponsive() {
        let app = XCUIApplication()
        app.launchArguments = ["--flow-replay", "spiral"]
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 20))
        let canvas = app.otherElements["Luminous Ink canvas"].firstMatch
        XCTAssertTrue(canvas.waitForExistence(timeout: 10))

        let start = Date()
        while Date().timeIntervalSince(start) < 90 {
            // drag on the canvas to keep producing input
            let origin = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            let target = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.3))
            origin.press(forDuration: 0.05, thenDragTo: target)
            XCTAssertTrue(app.state == .runningForeground, "app died mid run")
        }
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = "after-90s-sustained-run"
        shot.lifetime = .keepAlways
        add(shot)
    }
}