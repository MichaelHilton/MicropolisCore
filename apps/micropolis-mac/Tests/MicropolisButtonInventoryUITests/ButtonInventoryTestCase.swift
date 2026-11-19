import AppKit
import XCTest

/// Shared support for the optional inventory target, never part of SwiftPM or
/// the everyday eight-journey UI scheme.
class ButtonInventoryTestCase: XCTestCase {
    var app: XCUIApplication!
    private var directory: URL!
    private var stateURL: URL!
    private var preferenceSuite = ""

    override func setUpWithError() throws {
        continueAfterFailure = false
        directory = FileManager.default.temporaryDirectory.appendingPathComponent("micropolis-inventory-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        stateURL = directory.appendingPathComponent("state.json")
        preferenceSuite = "org.micropolis.inventory." + UUID().uuidString
        launch()
    }

    override func tearDownWithError() throws {
        app?.terminate()
        if !preferenceSuite.isEmpty {
            UserDefaults(suiteName: preferenceSuite)?.removePersistentDomain(forName: preferenceSuite)
        }
        if let directory { try FileManager.default.removeItem(at: directory) }
        app = nil
    }

    func launch(fixture: String = "default", appearance: String = "classic", timers: Bool = false) {
        app?.terminate()
        try? FileManager.default.removeItem(at: stateURL)
        app = XCUIApplication()
        app.launchEnvironment = [
            "MICROPOLIS_UI_TESTING": "1",
            "MICROPOLIS_INVENTORY_STATE": stateURL.path,
            "MICROPOLIS_INVENTORY_FIXTURE": fixture,
            "MICROPOLIS_INVENTORY_APPEARANCE": appearance == "retro" ? "retroSquare" : appearance,
            "MICROPOLIS_INVENTORY_PREFERENCES": preferenceSuite,
            "MICROPOLIS_INVENTORY_TIMERS": timers ? "1" : "0"
        ]
        app.launch()
        app.activate()
        XCTAssertTrue(element("map.canvas").waitForExistence(timeout: 15), app.debugDescription)
        _ = state()
    }

    func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    func menuChoice(_ title: String, under identifier: String) -> XCUIElement {
        element(identifier).descendants(matching: .menuItem).matching(identifier: title).firstMatch
    }

    func choose(_ command: String, from menu: String) {
        app.activate()
        let trigger = element(menu)
        waitFor("exists == true AND hittable == true", on: trigger)
        trigger.click()
        if command.hasPrefix("system.scenario.") || command.hasPrefix("system.sample.") {
            let title = command.hasPrefix("system.scenario.") ? "Load Scenario" : "Load Sample City"
            let submenu = menuChoice(title, under: menu)
            XCTAssertTrue(submenu.waitForExistence(timeout: 5), app.debugDescription)
            submenu.hover()
        }
        // SwiftUI's generated nested menu actions expose menuAction: rather
        // than their declared identifiers on macOS. Scope their exact titles
        // to the opened in-window menu so native menu copies cannot match.
        var lookup = command
        if command.hasPrefix("system.sample.") {
            lookup = String(command.dropFirst("system.sample.".count))
        } else if command.hasPrefix("system.scenario.") {
            let names = ["Dullsville 1900", "San Francisco 1906", "Hamburg 1944", "Bern 1965",
                         "Tokyo 1957", "Detroit 1972", "Boston 2010", "Rio de Janeiro 2047"]
            guard let raw = Int(command.split(separator: ".").last ?? ""), (1...8).contains(raw) else {
                return XCTFail("Invalid scenario command " + command)
            }
            lookup = names[raw - 1]
        }
        let item = trigger.descendants(matching: .menuItem).matching(identifier: lookup).firstMatch
        XCTAssertTrue(item.waitForExistence(timeout: 5), "Missing command: " + command + "\n" + app.debugDescription)
        XCTAssertTrue(item.isEnabled, "Command is disabled: " + command)
        if command == "options.appearance" { item.hover() }
        else { item.click() }
    }

    func text(of item: XCUIElement) -> String {
        if let value = item.value as? String, !value.isEmpty { return value }
        return item.label
    }

    func waitFor(_ predicate: String, on item: XCUIElement) {
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: predicate), object: item)
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 10), .completed,
                       predicate + "\n" + item.debugDescription)
    }

    func waitUntil(_ description: String, timeout: TimeInterval = 5, _ condition: () -> Bool) {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() {
            guard Date() < deadline else { return XCTFail(description) }
            _ = RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.01))
        }
    }

    /// Require an observation produced after this call began, so an immediate
    /// post-click read cannot accidentally assert against the previous frame.
    func state() -> [String: Any] {
        let requested = Date()
        var result: [String: Any]?
        waitUntil("No fresh inventory observation. The fixture/app may have failed to launch.", timeout: 10) {
            guard let attributes = try? FileManager.default.attributesOfItem(atPath: self.stateURL.path),
                  let modified = attributes[.modificationDate] as? Date, modified >= requested,
                  let data = try? Data(contentsOf: self.stateURL),
                  let snapshot = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return false }
            result = snapshot
            return true
        }
        return result ?? [:]
    }

    func waitState(_ key: String, equals expected: Any) {
        waitUntil("Expected " + key + " = " + String(describing: expected)) {
            guard let actual = self.state()[key] as? NSObject, let value = expected as? NSObject else { return false }
            return actual == value
        }
    }

    func waitForStableState(_ key: String, duration: TimeInterval = 0.4) {
        let start = Date()
        let value = state()[key] as? NSObject
        repeat {
            XCTAssertEqual(state()[key] as? NSObject, value, key + " changed while expected to remain stable")
        } while Date().timeIntervalSince(start) < duration
    }

    func assertUnchanged(_ before: [String: Any]) {
        let after = state()
        for key in ["cityName", "funds", "mapFingerprint", "currentFileURL", "gameLevel"] {
            XCTAssertNotNil(before[key], "Missing baseline: " + key)
            XCTAssertEqual(after[key] as? NSObject, before[key] as? NSObject, key + " unexpectedly changed")
        }
    }

    func displayedFunds() throws -> Int {
        try XCTUnwrap(Int(text(of: app.staticTexts["hud.funds"]).filter(\.isNumber)))
    }

    func goToPath(_ path: String) {
        app.typeKey("g", modifierFlags: [.command, .shift])
        app.typeText(path)
        app.typeKey(XCUIKeyboardKey.return.rawValue, modifierFlags: [])
    }

    /// Convert an engine tile into a visible canvas point using the live
    /// viewport. Failing for an offscreen tile is preferable to a blind click.
    func clickTile(x: Int, y: Int) {
        app.activate()
        let canvas = element("map.canvas")
        waitFor("exists == true AND hittable == true", on: canvas)
        let viewport = state()["viewport"] as? [Double] ?? []
        guard viewport.count == 4, viewport[2] > 0, viewport[3] > 0 else {
            return XCTFail("Missing visible-tile geometry")
        }
        let dx = (Double(x) + 0.5 - viewport[0]) / viewport[2]
        let dy = (Double(y) + 0.5 - viewport[1]) / viewport[3]
        guard dx > 0, dx < 1, dy > 0, dy < 1 else {
            return XCTFail("Requested tile is offscreen: \(x),\(y), viewport \(viewport)")
        }
        canvas.coordinate(withNormalizedOffset: CGVector(dx: dx, dy: dy)).click()
    }
}
