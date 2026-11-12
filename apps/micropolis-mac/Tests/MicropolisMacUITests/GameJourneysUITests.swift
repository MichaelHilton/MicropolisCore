import XCTest

/// Exercises the production menu actions and AppKit event path with a fresh,
/// paused city for every journey. No sleeps or dependence on test order.
final class GameJourneysUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchEnvironment["MICROPOLIS_UI_TESTING"] = "1"
        app.launch()
        XCTAssertTrue(element("map.canvas").waitForExistence(timeout: 10))
    }

    override func tearDownWithError() throws {
        app.terminate()
        app = nil
    }

    func testWindowsMenuOpensMapsGraphsAndBudget() {
        choose("window.maps", from: "menu.windows")
        let maps = app.windows["Maps"]
        XCTAssertTrue(maps.waitForExistence(timeout: 5))
        XCTAssertTrue(maps.buttons["overlay.power"].exists)
        maps.buttons[XCUIIdentifierCloseWindow].click()

        choose("window.graphs", from: "menu.windows")
        let graphs = app.windows["Graphs"]
        XCTAssertTrue(graphs.waitForExistence(timeout: 5))
        XCTAssertTrue(graphs.buttons["graph.10year"].exists)
        graphs.buttons[XCUIIdentifierCloseWindow].click()

        choose("window.budget", from: "menu.windows")
        let apply = element("budget.apply")
        XCTAssertTrue(apply.waitForExistence(timeout: 5))
        apply.click()
        waitFor("exists == false", on: apply)
        XCTAssertTrue(element("map.canvas").isHittable)
    }

    func testStartingANewCityUpdatesTheDisplayedName() {
        choose("system.newCity", from: "menu.system")
        let name = app.textFields["newCity.name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.click()
        name.typeKey("a", modifierFlags: .command)
        name.typeText("UITESTCITY")
        element("newCity.level.0").click()
        element("newCity.ok").click()

        waitFor("exists == false", on: name)
        let cityName = app.staticTexts["hud.cityName"]
        let renamed = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            self.text(of: cityName) == "UITESTCITY"
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [renamed], timeout: 5), .completed)
        XCTAssertTrue(element("map.canvas").isHittable)
    }

    func testCancellingOpenPreservesTheCurrentCity() {
        cancelFilePanel("system.loadCity")
    }

    func testCancellingSaveAsPreservesTheCurrentCity() {
        cancelFilePanel("system.saveAs")
    }

    func testPlacingARoadOnClearedTerrainCostsTenDollars() throws {
        // Use the real terrain editor to prepare a known dirt tile instead of
        // depending on the contents of a bundled city at a chosen coordinate.
        choose("window.terrainEdit", from: "menu.windows")
        let dirt = element("terrain.dirt")
        XCTAssertTrue(dirt.waitForExistence(timeout: 5))
        dirt.click()
        let canvas = element("map.canvas")
        clickPreparedTile(on: canvas)
        choose("window.edit", from: "menu.windows")
        let road = app.buttons["tool.r"]
        XCTAssertTrue(road.waitForExistence(timeout: 5))
        let funds = app.staticTexts["hud.funds"]
        let before = try XCTUnwrap(Int(text(of: funds).filter(\.isNumber)), funds.debugDescription)
        road.click()
        clickPreparedTile(on: canvas)
        let changed = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            Int(self.text(of: funds).filter(\.isNumber)) == before - 10
        }, object: nil)
        let result = XCTWaiter.wait(for: [changed], timeout: 5)
        let status = text(of: element("hud.statusLine"))
        XCTAssertEqual(result, .completed,
                       "Expected funds \(before - 10), got \(text(of: funds)); status: \(status)")
    }

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier].firstMatch
    }

    private func cancelFilePanel(_ command: String) {
        let cityName = app.staticTexts["hud.cityName"]
        let funds = app.staticTexts["hud.funds"]
        let beforeName = text(of: cityName)
        let beforeFunds = text(of: funds)
        choose(command, from: "menu.system")
        let cancel = app.buttons["Cancel"].firstMatch
        XCTAssertTrue(cancel.waitForExistence(timeout: 10))
        cancel.click()
        waitFor("exists == false", on: cancel)
        XCTAssertEqual(text(of: cityName), beforeName)
        XCTAssertEqual(text(of: funds), beforeFunds)
        XCTAssertTrue(element("map.canvas").isHittable)
    }

    private func clickPreparedTile(on canvas: XCUIElement) {
        app.activate()
        XCTAssertTrue(canvas.isHittable, "Map must be visible before clicking; frame: \(canvas.frame)")
        canvas.click()
    }

    private func choose(_ identifier: String, from menu: String) {
        let trigger = element(menu)
        XCTAssertTrue(trigger.waitForExistence(timeout: 5))
        trigger.click()
        let item = element(identifier)
        XCTAssertTrue(item.waitForExistence(timeout: 5))
        item.click()
    }

    private func text(of element: XCUIElement) -> String {
        // macOS static text commonly exposes its content as AXValue.
        (element.value as? String).flatMap { $0.isEmpty ? nil : $0 } ?? element.label
    }

    private func waitFor(_ format: String, on element: XCUIElement) {
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: format), object: element)
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 5), .completed)
    }
}
