import AppKit
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
        app.activate()
        waitFor("exists == true AND hittable == true", on: name)
        name.click()
        name.typeKey("a", modifierFlags: .command)
        name.typeText("UI Test_City-West")
        element("newCity.level.0").click()
        element("newCity.ok").click()

        waitFor("exists == false", on: name)
        let cityName = app.staticTexts["hud.cityName"]
        let renamed = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            self.text(of: cityName) == "UI Test_City-West"
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

    func testQueryingARoadShowsStatusAndCanBeReopened() {
        choose("window.terrainEdit", from: "menu.windows")
        let dirt = element("terrain.dirt")
        XCTAssertTrue(dirt.waitForExistence(timeout: 5))
        dirt.click()
        let canvas = element("map.canvas")
        clickPreparedTile(on: canvas)
        choose("window.edit", from: "menu.windows")
        app.activate()
        let road = app.buttons["tool.r"]
        XCTAssertTrue(road.waitForExistence(timeout: 10))
        waitFor("hittable == true", on: road)
        road.click()
        clickPreparedTile(on: canvas)
        app.buttons["tool.q"].click()
        let funds = text(of: app.staticTexts["hud.funds"])

        for cycle in 0..<2 {
            clickPreparedTile(on: canvas)
            let category = app.staticTexts["zoneStatus.category"]
            XCTAssertTrue(category.waitForExistence(timeout: 5))
            XCTAssertEqual(text(of: category), "Road")
            for field in ["density", "value", "crime", "pollution", "growth"] {
                let value = app.staticTexts["zoneStatus.\(field)"]
                XCTAssertTrue(value.exists)
                XCTAssertFalse(text(of: value).isEmpty)
                XCTAssertNotEqual(text(of: value), "Unknown", "\(field) should decode an engine text ID")
            }
            if cycle == 0 {
                element("zoneStatus.close").click()
            } else {
                app.typeKey(XCUIKeyboardKey.escape.rawValue, modifierFlags: [])
            }
            waitFor("exists == false", on: category)
            XCTAssertEqual(text(of: app.staticTexts["hud.funds"]), funds)
        }
    }

    func testSavingAndReopeningRestoresRoadAndFunds() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent("RoundTripCity.cty")

        choose("window.terrainEdit", from: "menu.windows")
        let dirt = element("terrain.dirt")
        XCTAssertTrue(dirt.waitForExistence(timeout: 5))
        dirt.click()
        let canvas = element("map.canvas")
        clickPreparedTile(on: canvas)
        choose("window.edit", from: "menu.windows")
        app.buttons["tool.r"].click()
        let initialFunds = try displayedFunds()
        clickPreparedTile(on: canvas)
        waitForFunds(initialFunds - 10)
        app.buttons["tool.q"].click() // Move the pointer off the canvas before capturing pixels.
        let savedMap = try centerMapPixels()
        let savedFunds = try displayedFunds()

        choose("system.saveAs", from: "menu.system")
        let save = app.buttons["Save"].firstMatch
        XCTAssertTrue(save.waitForExistence(timeout: 10))
        let filename = app.textFields["saveAsNameTextField"]
        XCTAssertTrue(filename.waitForExistence(timeout: 5), app.debugDescription)
        filename.click()
        filename.typeKey("a", modifierFlags: .command)
        filename.typeText(file.lastPathComponent)
        goToPath(directory.path)
        save.click()
        waitFor("exists == false", on: save)
        XCTAssertTrue(FileManager.default.fileExists(atPath: file.path))

        // Change both map and balance after saving. Otherwise a broken Open
        // action could leave the current city untouched and falsely pass.
        app.buttons["tool.b"].click()
        clickPreparedTile(on: canvas)
        waitForFunds(savedFunds - 1)
        app.buttons["tool.q"].click()
        XCTAssertTrue(try centerMapPixels() != savedMap, "Bulldozing must visibly change the saved road")

        choose("system.loadCity", from: "menu.system")
        let open = app.buttons["Open"].firstMatch
        XCTAssertTrue(open.waitForExistence(timeout: 10))
        goToPath(file.path)
        open.click()
        waitFor("exists == false", on: open)
        waitForFunds(savedFunds)
        XCTAssertEqual(text(of: app.staticTexts["hud.cityName"]), "RoundTripCity")
        app.buttons["tool.q"].click()
        XCTAssertTrue(try centerMapPixels() == savedMap, "Opening must restore the saved road pixels")
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

    private func goToPath(_ path: String) {
        app.typeKey("g", modifierFlags: [.command, .shift])
        app.typeText(path)
        app.typeKey(XCUIKeyboardKey.return.rawValue, modifierFlags: [])
    }

    private func displayedFunds() throws -> Int {
        try XCTUnwrap(Int(text(of: app.staticTexts["hud.funds"]).filter(\.isNumber)))
    }

    private func waitForFunds(_ expected: Int) {
        let changed = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            (try? self.displayedFunds()) == expected
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [changed], timeout: 5), .completed)
    }

    private func centerMapPixels() throws -> Data {
        let bitmap = try XCTUnwrap(NSBitmapImageRep(data: element("map.canvas").screenshot().pngRepresentation))
        let image = try XCTUnwrap(bitmap.cgImage)
        let region = CGRect(x: image.width / 2 - 32, y: image.height / 2 - 32, width: 64, height: 64)
        let crop = try XCTUnwrap(image.cropping(to: region))
        let context = try XCTUnwrap(CGContext(data: nil, width: 64, height: 64, bitsPerComponent: 8,
                                             bytesPerRow: 256, space: CGColorSpaceCreateDeviceRGB(),
                                             bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.draw(crop, in: CGRect(x: 0, y: 0, width: 64, height: 64))
        return Data(bytes: try XCTUnwrap(context.data), count: 64 * 256)
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
        app.activate()
        let trigger = element(menu)
        XCTAssertTrue(trigger.waitForExistence(timeout: 5))
        waitFor("hittable == true", on: trigger)
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
