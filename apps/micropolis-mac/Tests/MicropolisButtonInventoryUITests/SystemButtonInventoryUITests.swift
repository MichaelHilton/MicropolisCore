import AppKit
import XCTest

/// Opt-in checks for the shared menus and system commands in BUTTON-INVENTORY.md.
final class SystemButtonInventoryUITests: ButtonInventoryTestCase {
    func test_B001_OpenSystemMenu() { checkMenu("menu.system", items: ["system.about", "system.loadCity", "system.save"]) }
    func test_B002_OpenOptionsMenu() { checkMenu("menu.options", items: ["options.appearance", "options.autoBulldoze"]) }
    func test_B003_OpenDisastersMenu() { checkMenu("menu.disasters", items: ["disaster.fire", "disaster.flood", "disaster.disable"]) }
    func test_B004_OpenWindowsMenu() { checkMenu("menu.windows", items: ["window.maps", "window.graphs", "window.budget", "window.terrainEdit"]) }

    func test_B005_PlayPause() {
        launch(fixture: "default", appearance: "retro", timers: true)
        let play = app.buttons.matching(NSPredicate(format: "label == %@", "Resume simulation")).firstMatch
        XCTAssertTrue(play.waitForExistence(timeout: 5))
        let start = state()
        play.click()
        let pause = app.buttons.matching(NSPredicate(format: "label == %@", "Pause simulation")).firstMatch
        XCTAssertTrue(pause.waitForExistence(timeout: 5))
        XCTAssertEqual(state()["speed"] as? Int, 1)
        XCTAssertEqual(state()["paused"] as? Bool, false)
        let initialTick = start["tickCount"] as? Int ?? 0
        let progressed = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            (self.state()["tickCount"] as? Int ?? initialTick) > initialTick
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [progressed], timeout: 5), .completed, "Resume should advance simulation")
        pause.click()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label == %@", "Resume simulation")).firstMatch.waitForExistence(timeout: 5))
        XCTAssertEqual(state()["paused"] as? Bool, true)
        waitForStableState("tickCount")
    }

    func test_B006_OpenRetroAppearanceMenu() {
        launch(fixture: "default", appearance: "retro", timers: false)
        let before = state()
        let appearance = element("menu.appearance")
        XCTAssertTrue(appearance.waitForExistence(timeout: 5)); appearance.click()
        let picker = menuChoice("Appearance", under: "menu.appearance")
        XCTAssertTrue(picker.waitForExistence(timeout: 5)); picker.hover()
        let classic = menuChoice("Classic", under: "menu.appearance")
        let retro = menuChoice("Retro Borough (Preview)", under: "menu.appearance")
        XCTAssertTrue(classic.waitForExistence(timeout: 5))
        XCTAssertTrue(retro.waitForExistence(timeout: 5))
        let current = state()["graphicsPackage"] as? String
        XCTAssertNotNil(current)
        NativeMenuAssertions.assertMarked(current == "classic", title: "Classic", under: "menu.appearance", in: app)
        NativeMenuAssertions.assertMarked(current == "retroSquare", title: "Retro Borough (Preview)", under: "menu.appearance", in: app)
        app.typeKey(XCUIKeyboardKey.escape.rawValue, modifierFlags: [])
        XCTAssertEqual(state()["graphicsPackage"] as? String, before["graphicsPackage"] as? String)
    }

    func test_B007_SystemAbout() { about(inNativeMenu: false) }
    func test_B008_PrintCity() {
        let before = state()
        choose("system.print", from: "menu.system")
        let printPanel = app.sheets["PDPrintPanel"]
        XCTAssertTrue(printPanel.waitForExistence(timeout: 10), app.debugDescription)
        let printState = state()
        let previewSize = printState["printImageSize"] as? [Int] ?? []
        XCTAssertEqual(previewSize.count, 2)
        XCTAssertGreaterThan(previewSize[0], 0)
        XCTAssertGreaterThan(previewSize[1], 0)
        XCTAssertEqual(printState["printImageHasContent"] as? Bool, true)
        XCTAssertTrue(printPanel.buttons["PDCancel"].exists)
        XCTAssertTrue(printPanel.images.firstMatch.exists, "The native panel should display the prepared city preview")
        printPanel.buttons["PDCancel"].click()
        waitFor("exists == false", on: printPanel)
        assertUnchanged(before)
    }
    func test_B009_OpenNewCitySheet() {
        let before = state()
        choose("system.newCity", from: "menu.system")
        XCTAssertTrue(element("newCity.name").waitForExistence(timeout: 5))
        XCTAssertTrue(element("newCity.level.0").exists); XCTAssertTrue(element("newCity.level.1").exists)
        XCTAssertTrue(element("newCity.level.2").exists); XCTAssertTrue(element("newCity.ok").exists)
        app.typeKey(XCUIKeyboardKey.escape.rawValue, modifierFlags: [])
        waitFor("exists == false", on: element("newCity.name")); assertUnchanged(before)
    }
    func test_B010_LoadCity() throws {
        let paths = try scratchFiles()
        prepareRoad()
        let saved = state()
        XCTAssertNotNil(saved["funds"]); XCTAssertNotNil(saved["mapFingerprint"])
        saveAs(paths.city)
        bulldozeRoad()
        XCTAssertNotEqual(state()["mapFingerprint"] as? String, saved["mapFingerprint"] as? String)
        open(paths.city)
        XCTAssertEqual(state()["cityName"] as? String, "InventoryLoad")
        XCTAssertEqual(state()["funds"] as? Int, saved["funds"] as? Int)
        XCTAssertEqual(state()["mapFingerprint"] as? String, saved["mapFingerprint"] as? String)
        let beforeCancel = state()
        choose("system.loadCity", from: "menu.system")
        cancelOpenPanel()
        assertUnchanged(beforeCancel)
    }
    func test_B011_SaveCityAs() throws {
        let paths = try scratchFiles()
        prepareRoad()
        let firstPath = paths.directory.appendingPathComponent("InventoryFirst.cty")
        saveAs(firstPath)
        let first = state()
        XCTAssertNotNil(first["funds"]); XCTAssertNotNil(first["mapFingerprint"])
        XCTAssertEqual(first["currentFileURL"] as? String, firstPath.path)
        bulldozeRoad()
        let modified = state()
        XCTAssertNotNil(modified["funds"]); XCTAssertNotNil(modified["mapFingerprint"])
        XCTAssertNotEqual(modified["mapFingerprint"] as? String, first["mapFingerprint"] as? String)
        saveAs(paths.city)
        let afterSave = state()
        XCTAssertEqual(afterSave["currentFileURL"] as? String, paths.city.path)
        XCTAssertEqual(afterSave["mapFingerprint"] as? String, modified["mapFingerprint"] as? String)
        XCTAssertEqual(afterSave["funds"] as? Int, modified["funds"] as? Int)
        XCTAssertEqual(afterSave["cityName"] as? String, modified["cityName"] as? String)
        open(paths.city)
        XCTAssertEqual(state()["mapFingerprint"] as? String, modified["mapFingerprint"] as? String)
        XCTAssertEqual(state()["funds"] as? Int, modified["funds"] as? Int)
        XCTAssertEqual(state()["cityName"] as? String, "InventoryLoad")
        let currentPath = afterSave["currentFileURL"] as? String
        choose("system.saveAs", from: "menu.system")
        cancelSavePanel()
        XCTAssertEqual(state()["currentFileURL"] as? String, currentPath)
    }
    func test_B012_SaveCity() throws {
        let paths = try scratchFiles()
        prepareRoad()
        choose("system.save", from: "menu.system")
        savePanel(paths.city)
        XCTAssertEqual(state()["currentFileURL"] as? String, paths.city.path)
        let saved = state()
        XCTAssertNotNil(saved["funds"]); XCTAssertNotNil(saved["mapFingerprint"])
        bulldozeRoad()
        let modified = state()
        XCTAssertNotNil(modified["funds"]); XCTAssertNotNil(modified["mapFingerprint"])
        XCTAssertNotEqual(modified["mapFingerprint"] as? String, saved["mapFingerprint"] as? String)
        choose("system.save", from: "menu.system")
        XCTAssertFalse(app.buttons["Save"].waitForExistence(timeout: 1), "Saving to the established path should not reopen a panel")
        XCTAssertEqual(state()["mapFingerprint"] as? String, modified["mapFingerprint"] as? String)
        open(paths.city)
        XCTAssertEqual(state()["mapFingerprint"] as? String, modified["mapFingerprint"] as? String)
        XCTAssertEqual(state()["funds"] as? Int, modified["funds"] as? Int)
    }
    func test_B013_Exit() {
        choose("system.exit", from: "menu.system")
        let terminated = XCTNSPredicateExpectation(predicate: NSPredicate(format: "state == %d", XCUIApplication.State.notRunning.rawValue), object: app)
        XCTAssertEqual(XCTWaiter.wait(for: [terminated], timeout: 10), .completed)
    }
    func test_B014_OpenScenarioSubmenu() {
        let before = state(); openSubmenu("Load Scenario")
        let names = ["Dullsville 1900", "San Francisco 1906", "Hamburg 1944", "Bern 1965", "Tokyo 1957", "Detroit 1972", "Boston 2010", "Rio de Janeiro 2047"]
        for name in names { XCTAssertTrue(menuChoice(name, under: "menu.system").waitForExistence(timeout: 5), name) }
        XCTAssertEqual(names.filter { menuChoice($0, under: "menu.system").exists }.count, 8)
        app.typeKey(XCUIKeyboardKey.escape.rawValue, modifierFlags: []); assertUnchanged(before)
    }
    func test_B015_OpenSampleCitySubmenu() {
        let before = state(); openSubmenu("Load Sample City")
        for name in sampleNames { XCTAssertTrue(menuChoice(name, under: "menu.system").waitForExistence(timeout: 5), name) }
        XCTAssertEqual(sampleNames.filter { menuChoice($0, under: "menu.system").exists }.count, 24)
        app.typeKey(XCUIKeyboardKey.escape.rawValue, modifierFlags: []); assertUnchanged(before)
    }

    func test_B016_LoadScenario1() { loadScenario("Dullsville 1900", id: 1) }
    func test_B017_LoadScenario2() { loadScenario("San Francisco 1906", id: 2) }
    func test_B018_LoadScenario3() { loadScenario("Hamburg 1944", id: 3) }
    func test_B019_LoadScenario4() { loadScenario("Bern 1965", id: 4) }
    func test_B020_LoadScenario5() { loadScenario("Tokyo 1957", id: 5) }
    func test_B021_LoadScenario6() { loadScenario("Detroit 1972", id: 6) }
    func test_B022_LoadScenario7() { loadScenario("Boston 2010", id: 7) }
    func test_B023_LoadScenario8() { loadScenario("Rio de Janeiro 2047", id: 8) }

    func test_B024_LoadSample_about() { loadSample("about") }
    func test_B025_LoadSample_badnews() { loadSample("badnews") }
    func test_B026_LoadSample_bluebird() { loadSample("bluebird") }
    func test_B027_LoadSample_bruce() { loadSample("bruce") }
    func test_B028_LoadSample_deadwood() { loadSample("deadwood") }
    func test_B029_LoadSample_finnigan() { loadSample("finnigan") }
    func test_B030_LoadSample_freds() { loadSample("freds") }
    func test_B031_LoadSample_haight() { loadSample("haight") }
    func test_B032_LoadSample_happisle() { loadSample("happisle") }
    func test_B033_LoadSample_joffburg() { loadSample("joffburg") }
    func test_B034_LoadSample_kamakura() { loadSample("kamakura") }
    func test_B035_LoadSample_kobe() { loadSample("kobe") }
    func test_B036_LoadSample_kowloon() { loadSample("kowloon") }
    func test_B037_LoadSample_kyoto() { loadSample("kyoto") }
    func test_B038_LoadSample_linecity() { loadSample("linecity") }
    func test_B039_LoadSample_med_isle() { loadSample("med_isle") }
    func test_B040_LoadSample_ndulls() { loadSample("ndulls") }
    func test_B041_LoadSample_neatmap() { loadSample("neatmap") }
    func test_B042_LoadSample_radial() { loadSample("radial") }
    func test_B043_LoadSample_senri() { loadSample("senri") }
    func test_B044_LoadSample_southpac() { loadSample("southpac") }
    func test_B045_LoadSample_splats() { loadSample("splats") }
    func test_B046_LoadSample_wetcity() { loadSample("wetcity") }
    func test_B047_LoadSample_yokohama() { loadSample("yokohama") }

    func test_B137_ApplicationMenuAbout() { about(inNativeMenu: true) }

    private let sampleNames = ["about", "badnews", "bluebird", "bruce", "deadwood", "finnigan", "freds", "haight", "happisle", "joffburg", "kamakura", "kobe", "kowloon", "kyoto", "linecity", "med_isle", "ndulls", "neatmap", "radial", "senri", "southpac", "splats", "wetcity", "yokohama"]

    private func checkMenu(_ menu: String, items: [String]) {
        for variant in ["classic", "retro"] {
            launch(fixture: "default", appearance: variant, timers: false)
            let before = state(); let trigger = element(menu)
            XCTAssertTrue(trigger.waitForExistence(timeout: 5)); trigger.click()
            for id in items { XCTAssertTrue(element(id).waitForExistence(timeout: 5), id) }
            if menu == "menu.options" {
                XCTAssertTrue(menuChoice("Speed", under: "menu.options").exists)
            }
            app.typeKey(XCUIKeyboardKey.escape.rawValue, modifierFlags: []); assertUnchanged(before)
        }
    }
    private func openSubmenu(_ title: String) {
        let menu = element("menu.system"); XCTAssertTrue(menu.waitForExistence(timeout: 5)); menu.click()
        let item = menuChoice(title, under: "menu.system"); XCTAssertTrue(item.waitForExistence(timeout: 5)); item.hover()
    }
    private func labeledElement(_ label: String) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", label)).firstMatch
    }
    private func loadScenario(_ name: String, id: Int) {
        launch(fixture: "scenario.\(id)", appearance: "classic", timers: false)
        let expected = state()
        for key in ["cityName", "year", "funds", "mapFingerprint"] { XCTAssertNotNil(expected[key], "Missing fixture value: \(key)") }
        launch(fixture: "empty", appearance: "classic", timers: false)
        choose("system.scenario.\(id)", from: "menu.system")
        let observed = state()
        for key in ["year", "funds", "mapFingerprint"] { XCTAssertNotNil(observed[key], "Missing scenario value: \(key)") }
        XCTAssertEqual(observed["year"] as? Int, expected["year"] as? Int)
        XCTAssertEqual(observed["funds"] as? Int, expected["funds"] as? Int)
        XCTAssertEqual(observed["mapFingerprint"] as? String, expected["mapFingerprint"] as? String)
        XCTAssertEqual(text(of: app.staticTexts["hud.cityName"]), expected["cityName"] as? String,
                       "\(name) should display the canonical name from its city resource")
    }
    private func loadSample(_ name: String) {
        launch(fixture: "sample.\(name)", appearance: "classic", timers: false)
        let expected = state()
        for key in ["cityName", "funds", "mapFingerprint"] { XCTAssertNotNil(expected[key], "Missing fixture value: \(key)") }
        launch(fixture: "empty", appearance: "classic", timers: false)
        choose("system.sample.\(name)", from: "menu.system")
        let observed = state()
        for key in ["cityName", "funds", "mapFingerprint"] { XCTAssertNotNil(observed[key], "Missing sample value: \(key)") }
        XCTAssertEqual(observed["cityName"] as? String, expected["cityName"] as? String)
        XCTAssertEqual(observed["funds"] as? Int, expected["funds"] as? Int)
        XCTAssertEqual(observed["mapFingerprint"] as? String, expected["mapFingerprint"] as? String)
        XCTAssertEqual(text(of: app.staticTexts["hud.cityName"]), name)
    }
    private func cancelPanel(_ command: String) {
        let before = state(); choose(command, from: "menu.system")
        let cancel = app.buttons["Cancel"].firstMatch
        XCTAssertTrue(cancel.waitForExistence(timeout: 10)); cancel.click()
        waitFor("exists == false", on: cancel); assertUnchanged(before)
    }
    private func scratchFiles() throws -> (directory: URL, city: URL) {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("MicropolisInventory-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: directory) }
        return (directory, directory.appendingPathComponent("InventoryLoad.cty"))
    }
    private func prepareRoad() {
        launch(fixture: "empty", appearance: "classic", timers: false)
        let road = element("tool.r"); XCTAssertTrue(road.waitForExistence(timeout: 5)); road.click()
        clickTile(x: 10, y: 10)
        XCTAssertNotEqual(state()["mapFingerprint"] as? String, "empty")
    }
    private func bulldozeRoad() {
        let bulldozer = element("tool.b"); XCTAssertTrue(bulldozer.waitForExistence(timeout: 5)); bulldozer.click()
        clickTile(x: 10, y: 10)
    }
    private func saveAs(_ file: URL) {
        choose("system.saveAs", from: "menu.system")
        savePanel(file)
    }
    private func savePanel(_ file: URL) {
        let save = app.buttons["Save"].firstMatch
        XCTAssertTrue(save.waitForExistence(timeout: 10), app.debugDescription)
        let filename = app.textFields["saveAsNameTextField"].firstMatch
        XCTAssertTrue(filename.waitForExistence(timeout: 5), app.debugDescription)
        filename.click(); filename.typeKey("a", modifierFlags: .command); filename.typeText(file.lastPathComponent)
        goToPath(file.deletingLastPathComponent().path)
        save.click()
        waitFor("exists == false", on: save)
        XCTAssertTrue(FileManager.default.fileExists(atPath: file.path), "Save should create the requested scratch city")
    }
    private func open(_ file: URL) {
        choose("system.loadCity", from: "menu.system")
        let open = app.buttons["Open"].firstMatch
        XCTAssertTrue(open.waitForExistence(timeout: 10), app.debugDescription)
        goToPath(file.path); open.click(); waitFor("exists == false", on: open)
    }
    private func cancelOpenPanel() {
        let cancel = app.buttons["Cancel"].firstMatch
        XCTAssertTrue(cancel.waitForExistence(timeout: 5)); cancel.click()
        waitFor("exists == false", on: cancel)
    }
    private func cancelSavePanel() {
        let cancel = app.buttons["Cancel"].firstMatch
        XCTAssertTrue(cancel.waitForExistence(timeout: 5)); cancel.click()
        waitFor("exists == false", on: cancel)
    }
    private func about(inNativeMenu: Bool) {
        let before = state()
        if inNativeMenu {
            let appMenu = app.menuBars.menuBarItems["Micropolis"].firstMatch
            XCTAssertTrue(appMenu.waitForExistence(timeout: 5)); appMenu.click()
            let about = appMenu.menuItems["About Micropolis"].firstMatch
            XCTAssertTrue(about.waitForExistence(timeout: 5)); about.click()
        } else { choose("system.about", from: "menu.system") }
        let panel = app.dialogs.firstMatch
        XCTAssertTrue(panel.waitForExistence(timeout: 10), app.debugDescription)
        XCTAssertTrue(panel.staticTexts.allElementsBoundByIndex.contains { text(of: $0) == "Micropolis" }, panel.debugDescription)
        panel.buttons[XCUIIdentifierCloseWindow].click()
        waitFor("exists == false", on: panel)
        assertUnchanged(before)
    }
}
