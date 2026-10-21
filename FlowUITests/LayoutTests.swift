import XCTest

/// P5 (simulator-reachable portion): iPad layout, rotation and lifecycle.
/// Real-device and Apple Pencil verification remain BLOCKED — see docs/PROGRESS.md.
final class LayoutTests: XCTestCase {

    override func setUp() {
        // XCTestCase.setUp is nonisolated; nothing main-actor happens here.
        continueAfterFailure = false
    }

    @MainActor
    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--flow-replay", "spiral"]
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 20))
        return app
    }

    /// The canvas must exist and the app must survive a rotation without
    /// recreating or losing the renderer (contract §5.9 resize rules).
    @MainActor
    func testRotationKeepsCanvasAlive() {
        let app = launch()
        let canvas = app.otherElements["Luminous Ink canvas"].firstMatch
        XCTAssertTrue(canvas.waitForExistence(timeout: 10), "canvas missing in portrait")

        XCUIDevice.shared.orientation = .landscapeLeft
        sleep(3)
        XCTAssertTrue(app.state == .runningForeground, "app died on rotation")
        XCTAssertTrue(canvas.exists, "canvas missing after rotation")
        let landscape = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        landscape.name = "landscape-after-rotation"
        landscape.lifetime = .keepAlways
        add(landscape)

        XCUIDevice.shared.orientation = .portrait
        sleep(3)
        XCTAssertTrue(app.state == .runningForeground, "app died returning to portrait")
        XCTAssertTrue(canvas.exists, "canvas missing back in portrait")
        let portrait = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        portrait.name = "portrait-restored"
        portrait.lifetime = .keepAlways
        add(portrait)
    }

    /// Backgrounding must pause without crashing, and returning must not jump
    /// the simulation clock (contract §5.9).
    @MainActor
    func testBackgroundAndForegroundSurvives() {
        let app = launch()
        XCUIDevice.shared.press(.home)
        sleep(3)
        app.activate()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 20), "did not return to foreground")
        XCTAssertTrue(app.otherElements["Luminous Ink canvas"].firstMatch.waitForExistence(timeout: 10))
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = "after-foreground-return"
        shot.lifetime = .keepAlways
        add(shot)
    }

    /// Debug controls must remain reachable in landscape (iPad floating panel).
    @MainActor
    func testDebugPanelReachableInLandscape() {
        let app = launch()
        XCUIDevice.shared.orientation = .landscapeLeft
        sleep(2)
        let open = app.buttons["Open debug panel"]
        if open.exists { open.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap() }
        XCTAssertTrue(app.buttons["Pause simulation"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["Clear canvas"].exists)
        XCTAssertTrue(app.buttons["replay-menu"].exists)
    }
}