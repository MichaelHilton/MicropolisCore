import XCTest

final class AppLaunchUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testDeterministicCityLaunchShowsTheCoreControls() {
        let app = XCUIApplication()
        app.launchEnvironment["MICROPOLIS_UI_TESTING"] = "1"
        app.launch()

        XCTAssertTrue(element("map.canvas", in: app).waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["tool.q"].exists)
        XCTAssertTrue(app.buttons["tool.r"].exists)
        XCTAssertTrue(element("menu.system", in: app).exists)
        XCTAssertTrue(element("menu.options", in: app).exists)
        XCTAssertTrue(element("menu.disasters", in: app).exists)
        XCTAssertTrue(element("menu.windows", in: app).exists)
        XCTAssertTrue(app.staticTexts["hud.cityName"].exists)
        XCTAssertTrue(app.staticTexts["hud.date"].exists)
        XCTAssertTrue(app.staticTexts["hud.funds"].exists)
    }

    private func element(_ identifier: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }
}
