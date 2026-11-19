import XCTest

final class OptionsButtonInventoryUITests: ButtonInventoryTestCase {
    private func options(_ command: String) {
        if command == "Speed" {
            element("menu.options").click()
            let speed = menuChoice("Speed", under: "menu.options")
            XCTAssertTrue(speed.waitForExistence(timeout: 5)); speed.hover()
        } else {
            choose(command == "Appearance" ? "options.appearance" : command, from: "menu.options")
        }
    }
    private func disasters(_ command: String) {
        let ids = ["Fire": "fire", "Flood": "flood", "Air Crash": "airCrash", "Tornado": "tornado",
                   "Earthquake": "earthquake", "Monster": "monster", "Nuclear Meltdown": "meltdown", "Disable": "disable"]
        choose("disaster.\(ids[command] ?? command)", from: "menu.disasters")
    }
    private func windows(_ command: String) {
        let ids = ["Maps": "maps", "Graphs": "graphs", "Budget": "budget", "Edit": "edit",
                   "Evaluation": "evaluation", "Terrain Edit": "terrainEdit"]
        choose("window.\(ids[command] ?? command)", from: "menu.windows")
    }

    private func number(_ key: String, _ snapshot: [String: Any]? = nil) -> Int {
        let value = (snapshot ?? state())[key]
        return (value as? NSNumber)?.intValue ?? (value as? Int) ?? Int(String(describing: value ?? "")) ?? Int.min
    }

    private func flag(_ key: String, _ snapshot: [String: Any]? = nil) -> Bool {
        ((snapshot ?? state())[key] as? NSNumber)?.boolValue ?? ((snapshot ?? state())[key] as? Bool ?? false)
    }

    private func assertToggle(_ id: String, key: String) {
        let titles = ["options.autoBulldoze": "Auto-Bulldoze", "options.autoBudget": "Auto-Budget",
                      "options.autoGoto": "Auto-Goto", "options.sound": "Sound On",
                      "options.animateAll": "Animate All", "options.frequentAnimation": "Frequent Animation"]
        let title = titles[id]!
        element("menu.options").click()
        let control = element(id)
        XCTAssertTrue(control.waitForExistence(timeout: 5), "Missing option \(id)")
        let before = flag(key)
        control.click()
        XCTAssertEqual(flag(key), !before, "Engine state should follow the first click")
        element("menu.options").click()
        let reopened = element(id)
        XCTAssertTrue(reopened.waitForExistence(timeout: 5))
        NativeMenuAssertions.assertMarked(!before, title: title, identifier: id, under: "menu.options", in: app)
        reopened.click()
        XCTAssertEqual(flag(key), before)
        element("menu.options").click()
        NativeMenuAssertions.assertMarked(before, title: title, identifier: id, under: "menu.options", in: app)
        app.typeKey(XCUIKeyboardKey.escape, modifierFlags: [])
    }

    func test_B048_AppearancePicker() {
        launch(fixture: "default", appearance: "classic")
        let before = state()
        options("Appearance")
        XCTAssertTrue(app.menuItems["Classic"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.menuItems["Retro Borough (Preview)"].exists)
        app.typeKey(XCUIKeyboardKey.escape, modifierFlags: [])
        XCTAssertEqual(state()["graphicsPackage"] as? String, "classic")
        XCTAssertEqual(state()["graphicsPreference"] as? String, before["graphicsPreference"] as? String)
        launch(fixture: "default", appearance: "retro")
        let retro = state()
        options("Appearance")
        XCTAssertTrue(app.menuItems["Classic"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.menuItems["Retro Borough (Preview)"].exists)
        app.typeKey(XCUIKeyboardKey.escape, modifierFlags: [])
        XCTAssertEqual(state()["graphicsPackage"] as? String, "retroSquare")
        XCTAssertEqual(state()["graphicsPreference"] as? String, retro["graphicsPreference"] as? String)
        XCTAssertUnchangedCity(between: retro, and: state())
        element("menu.appearance").click()
        let picker = menuChoice("Appearance", under: "menu.appearance")
        XCTAssertTrue(picker.waitForExistence(timeout: 5)); picker.hover()
        XCTAssertTrue(app.menuItems["Classic"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.menuItems["Retro Borough (Preview)"].exists)
        app.typeKey(XCUIKeyboardKey.escape, modifierFlags: [])
        XCTAssertEqual(state()["graphicsPackage"] as? String, "retroSquare")
    }

    func test_B049_SelectClassic() { appearanceSelection(from: "retro", to: "Classic", expected: "classic") }
    func test_B050_SelectRetro() { appearanceSelection(from: "classic", to: "Retro Borough (Preview)", expected: "retroSquare") }

    private func appearanceSelection(from: String, to label: String, expected: String) {
        launch(fixture: "default", appearance: from)
        let before = state()
        options("Appearance")
        let choice = menuChoice(label, under: "menu.options")
        XCTAssertTrue(choice.waitForExistence(timeout: 5))
        choice.click()
        waitState("graphicsPackage", equals: expected)
        XCTAssertEqual(state()["graphicsPreference"] as? String, expected)
        XCTAssertEqual(state()["cityName"] as? String, before["cityName"] as? String)
        XCTAssertEqual(state()["funds"] as? Int, before["funds"] as? Int)
        if expected == "retroSquare" {
            XCTAssertTrue(element("menu.appearance").exists, "Retro HUD appearance control should be visible")
        } else {
            XCTAssertFalse(element("menu.appearance").exists, "Classic HUD should replace the Retro appearance control")
        }
        XCTAssertTrue(element("tool.q").exists, "The main city tools should remain usable after changing appearance")
        launch(fixture: "default", appearance: "saved")
        XCTAssertEqual(state()["graphicsPackage"] as? String, expected)
    }

    func test_B051_ToggleAutoBulldoze() {
        launch(fixture: "empty", appearance: "classic")
        windows("Terrain Edit"); element("terrain.trees").click(); clickTile(x: 10, y: 10)
        windows("Edit")
        let beforeTiles = state()["tiles"] as? [Int] ?? []
        guard beforeTiles.count > 1010 else { XCTFail("Map tile telemetry is unavailable"); return }
        let tree = beforeTiles[1010] & 1023
        XCTAssertEqual(tree, 37, "Terrain tree fixture should place woods at the requested tile")
        if flag("autoBulldoze") { element("menu.options").click(); element("options.autoBulldoze").click() }
        let funds = number("funds")
        element("tool.r").click(); clickTile(x: 10, y: 10)
        XCTAssertEqual((state()["tiles"] as? [Int] ?? [])[1010] & 1023, tree, "With auto-bulldoze off, road placement over trees must be rejected")
        XCTAssertEqual(number("funds"), funds)
        element("menu.options").click(); element("options.autoBulldoze").click()
        XCTAssertTrue(flag("autoBulldoze"))
        element("tool.r").click(); clickTile(x: 10, y: 10)
        XCTAssertNotEqual((state()["tiles"] as? [Int] ?? [])[1010] & 1023, tree)
        XCTAssertLessThan(number("funds"), funds)
    }
    func test_B052_ToggleAutoBudget() {
        launch(fixture: "budgetYearEnd", appearance: "classic", timers: true)
        assertToggle("options.autoBudget", key: "autoBudget")
        for expectedEnabled in [false, true] {
            launch(fixture: "budgetYearEnd", appearance: "classic", timers: true)
            if flag("autoBudget") != expectedEnabled {
                element("menu.options").click(); element("options.autoBudget").click()
            }
            options("Speed"); menuChoice("Fast", under: "menu.options").click()
            waitUntil("year-end budget behavior", timeout: 12) {
                (self.state()["year"] as? Int ?? 0) >= 1901 || self.app.sheets.firstMatch.exists
            }
            XCTAssertEqual(app.sheets.firstMatch.exists, !expectedEnabled, "Auto-Budget should suppress the year-end budget sheet")
        }
    }
    func test_B053_ToggleAutoGoto() {
        launch(fixture: "disaster.monster", appearance: "classic", timers: true)
        assertToggle("options.autoGoto", key: "autoGoto")
        for enabled in [false, true] {
            launch(fixture: "disaster.monster", appearance: "classic", timers: true)
            if flag("autoGoto") != enabled { element("menu.options").click(); element("options.autoGoto").click() }
            let initialViewport = state()["viewport"] as? [Double] ?? []
            let initialScroll = state()["scrollRequest"] as? [Int] ?? []
            disasters("Monster")
            waitUntil("monster navigation result") {
                (self.state()["importantMessageGoTo"] as? [Int])?.count == 2
            }
            let after = state()
            if enabled {
                waitUntil("auto-goto scroll request") {
                    let request = self.state()["scrollRequest"] as? [Int] ?? []
                    return request.count == 3 && (initialScroll.count != 3 || request[2] > initialScroll[2])
                }
                XCTAssertNotEqual(state()["viewport"] as? [Double], initialViewport)
            } else {
                XCTAssertEqual(after["viewport"] as? [Double], initialViewport)
                XCTAssertEqual(after["scrollRequest"] as? [Int], initialScroll)
            }
        }
    }
    func test_B054_ToggleSound() {
        for enabled in [false, true] {
            launch(fixture: "disaster.airCrash", appearance: "classic")
            if flag("soundOn") != enabled { element("menu.options").click(); element("options.sound").click() }
            let before = state()["audioEvents"] as? [String] ?? []
            disasters("Air Crash")
            waitUntil("air crash sound result") {
                ((self.state()["audioEvents"] as? [String]) ?? []).count > before.count || !enabled
            }
            let after = state()["audioEvents"] as? [String] ?? []
            if enabled { XCTAssertTrue(after.contains("ExplosionHigh"), "Enabled sound should deliver the air-crash explosion event") }
            else { XCTAssertEqual(after, before, "Disabled sound must not deliver audio") }
        }
        launch(); assertToggle("options.sound", key: "soundOn")
    }
    func test_B055_ToggleAnimateAll() { togglePreservingCity(id: "options.animateAll", key: "animateAll") }
    func test_B056_ToggleFrequentAnimation() { togglePreservingCity(id: "options.frequentAnimation", key: "frequentAnimation") }

    private func togglePreservingCity(id: String, key: String) {
        launch(); let before = state(); assertToggle(id, key: key)
        let after = state()
        XCTAssertEqual(after["mapFingerprint"] as? String, before["mapFingerprint"] as? String)
        XCTAssertEqual(after["funds"] as? Int, before["funds"] as? Int)
        XCTAssertEqual(after["speed"] as? Int, before["speed"] as? Int)
    }

    func test_B057_OpenSpeedPicker() {
        launch(); let before = state(); options("Speed")
        for label in ["Pause", "Slow", "Medium", "Fast"] { XCTAssertTrue(app.menuItems[label].waitForExistence(timeout: 5), "Missing speed \(label)") }
        let currentLabel = ["Pause", "Slow", "Medium", "Fast"][max(0, min(3, number("speed")))]
        NativeMenuAssertions.assertMarked(true, title: currentLabel, under: "menu.options", in: app)
        app.typeKey(XCUIKeyboardKey.escape, modifierFlags: [])
        XCTAssertEqual(state()["speed"] as? Int, before["speed"] as? Int)
        XCTAssertEqual(state()["paused"] as? Bool, before["paused"] as? Bool)
    }

    private func chooseSpeed(_ label: String, speed: Int, paused: Bool) {
        launch(fixture: "default", appearance: "classic", timers: true); options("Speed")
        let option = menuChoice(label, under: "menu.options")
        XCTAssertTrue(option.waitForExistence(timeout: 5)); option.click()
        waitState("speed", equals: speed)
        XCTAssertEqual(state()["paused"] as? Bool, paused)
        options("Speed")
        NativeMenuAssertions.assertMarked(true, title: label, under: "menu.options", in: app)
        app.typeKey(XCUIKeyboardKey.escape, modifierFlags: [])
        let initial = number("tickCount")
        if paused {
            waitForStableState("tickCount", duration: 0.5)
            XCTAssertEqual(number("tickCount"), initial, "Paused simulation must not advance")
        } else {
            waitUntil("simulation tick progress", timeout: 10) { self.number("tickCount") > initial }
            XCTAssertGreaterThan(number("tickCount"), initial)
            XCTAssertEqual(state()["speed"] as? Int, speed)
        }
    }
    func test_B058_SpeedPause() { chooseSpeed("Pause", speed: 0, paused: true) }
    func test_B059_SpeedSlow() { chooseSpeed("Slow", speed: 1, paused: false) }
    func test_B060_SpeedMedium() { chooseSpeed("Medium", speed: 2, paused: false) }
    func test_B061_SpeedFast() { chooseSpeed("Fast", speed: 3, paused: false) }

    private func disaster(_ command: String, fixture: String, resultKey: String, disabledCheck: Bool = true) {
        launch(fixture: fixture)
        let before = state()
        disasters(command)
        XCTAssertTrue(flag("disastersEnabled"))
        let result = state()
        if let baseline = before[resultKey] as? Int, let after = result[resultKey] as? Int {
            XCTAssertGreaterThan(after, baseline, "\(command) should produce its expected world result")
        } else if resultKey == "sprites" {
            let oldSprites = before["sprites"] as? [[String: Any]] ?? []
            let sprites = result["sprites"] as? [[String: Any]] ?? []
            let type: Int = switch command { case "Air Crash": 7; case "Tornado": 6; default: 5 }
            let previous = oldSprites.filter { ($0["type"] as? Int) == type }.count
            let current = sprites.filter { ($0["type"] as? Int) == type }.count
            XCTAssertGreaterThan(current, previous, "\(command) should create or advance its expected sprite")
        }
        if disabledCheck {
            disasters("Disable")
            XCTAssertFalse(flag("disastersEnabled"))
            let disabledSnapshot = state()
            let id = ["Fire": "fire", "Flood": "flood", "Air Crash": "airCrash", "Tornado": "tornado",
                      "Earthquake": "earthquake", "Monster": "monster", "Nuclear Meltdown": "meltdown"][command] ?? command
            element("menu.disasters").click()
            let disabledCommand = element("disaster.\(id)")
            XCTAssertTrue(disabledCommand.waitForExistence(timeout: 5))
            XCTAssertFalse(disabledCommand.isEnabled, "Disable should prevent invoking \(command)")
            app.typeKey(XCUIKeyboardKey.escape, modifierFlags: [])
            waitForStableState("mapFingerprint", duration: 0.4)
            XCTAssertEqual(disabledSnapshot["mapFingerprint"] as? String, result["mapFingerprint"] as? String)
            XCTAssertEqual(disabledSnapshot[resultKey] as? Int, result[resultKey] as? Int)
        }
    }
    func test_B062_TriggerFire() { disaster("Fire", fixture: "disaster.fire", resultKey: "fireTileCount") }
    func test_B063_TriggerFlood() { disaster("Flood", fixture: "disaster.flood", resultKey: "floodTileCount") }
    func test_B064_TriggerAirCrash() { disaster("Air Crash", fixture: "disaster.airCrash", resultKey: "sprites") }
    func test_B065_TriggerTornado() { disaster("Tornado", fixture: "disaster.tornado", resultKey: "sprites") }
    func test_B066_TriggerEarthquake() { disaster("Earthquake", fixture: "disaster.earthquake", resultKey: "earthquakeCount") }
    func test_B067_TriggerMonster() { disaster("Monster", fixture: "disaster.monster", resultKey: "sprites") }
    func test_B068_TriggerNuclearMeltdown() { disaster("Nuclear Meltdown", fixture: "disaster.meltdown", resultKey: "radiationTileCount") }

    func test_B069_DisableDisasters() {
        launch(); disasters("Disable")
        XCTAssertFalse(flag("disastersEnabled"))
        element("menu.disasters").click()
        for id in ["fire", "flood", "airCrash", "tornado", "earthquake", "monster", "meltdown"] {
            XCTAssertTrue(element("disaster.\(id)").exists)
            XCTAssertFalse(element("disaster.\(id)").isEnabled)
        }
        app.typeKey(XCUIKeyboardKey.escape, modifierFlags: [])
        disasters("Disable"); XCTAssertTrue(flag("disastersEnabled"))
        element("menu.disasters").click()
        for id in ["fire", "flood", "airCrash", "tornado", "earthquake", "monster", "meltdown"] {
            XCTAssertTrue(element("disaster.\(id)").exists)
            XCTAssertTrue(element("disaster.\(id)").isEnabled)
        }
        app.typeKey(XCUIKeyboardKey.escape, modifierFlags: [])
    }

    func test_B070_OpenMaps() { openWindow("Maps", title: "Maps", repeated: true) }
    func test_B071_OpenGraphs() { openWindow("Graphs", title: "Graphs", repeated: true) }
    func test_B072_OpenBudget() {
        launch(); let before = state(); windows("Budget")
        let sheet = app.sheets.firstMatch
        XCTAssertTrue(sheet.waitForExistence(timeout: 5))
        XCTAssertTrue(sheet.staticTexts["Tax Rate"].exists)
        for key in ["taxRate", "roadPercent", "firePercent", "policePercent"] {
            XCTAssertEqual(number(key), before[key].map { Int((($0 as? NSNumber)?.doubleValue ?? Double(String(describing: $0)) ?? 0).rounded()) } ?? Int.min,
                           "Budget draft should start from current \(key)")
        }
        for (id, key) in [("budget.tax.value", "taxRate"), ("budget.trans.value", "roadPercent"),
                          ("budget.police.value", "policePercent"), ("budget.fire.value", "firePercent")] {
            let raw = (before[key] as? NSNumber)?.doubleValue ?? -1
            let percentage = Int((raw * (key == "taxRate" ? 1 : 100)).rounded())
            XCTAssertEqual(text(of: element(id)), "\(percentage)%", "Budget field \(id) should display current engine value")
        }
    }
    func test_B073_SwitchToCityEdit() {
        launch(); windows("Terrain Edit"); XCTAssertEqual(state()["editMode"] as? String, "terrain")
        windows("Edit"); XCTAssertEqual(state()["editMode"] as? String, "city")
        XCTAssertTrue(element("tool.q").waitForExistence(timeout: 5))
        XCTAssertFalse(element("terrain.dirt").exists)
    }
    func test_B074_OpenEvaluation() { openWindow("Evaluation", title: "Evaluation", repeated: true) }
    func test_B075_SwitchToTerrainEdit() {
        launch(); windows("Terrain Edit"); XCTAssertEqual(state()["editMode"] as? String, "terrain")
        XCTAssertTrue(element("terrain.dirt").waitForExistence(timeout: 5))
        XCTAssertFalse(element("tool.q").exists)
    }
    func test_B076_CloseKeyWindow() {
        launch(); let mainTitle = state()["cityName"] as? String ?? ""
        windows("Graphs")
        let graph = app.windows.matching(NSPredicate(format: "title == %@", "Graphs")).firstMatch
        XCTAssertTrue(graph.waitForExistence(timeout: 5))
        app.menuBars.menuBarItems["Window"].click()
        app.menuBars.menuBarItems["Window"].menuItems
            .matching(identifier: "Close")
            .matching(NSPredicate(format: "identifier == %@", "menuAction:")).firstMatch.click()
        XCTAssertFalse(graph.waitForExistence(timeout: 2))
        XCTAssertTrue(app.windows.matching(NSPredicate(format: "title == %@", mainTitle)).firstMatch.exists)
        XCTAssertTrue(element("tool.q").exists)
    }
    func test_B077_HideApplication() {
        launch(); let before = state()
        element("menu.windows").click()
        let hide = menuChoice("Hide", under: "menu.windows")
        XCTAssertTrue(hide.waitForExistence(timeout: 5)); hide.click()
        XCTAssertNotEqual(app.state, .notRunning)
        app.activate()
        XCTAssertTrue(element("menu.options").waitForExistence(timeout: 5))
        XCTAssertEqual(state()["cityName"] as? String, before["cityName"] as? String)
        XCTAssertEqual(state()["funds"] as? Int, before["funds"] as? Int)
    }

    func test_B138_DismissGraphicsError() {
        launch(fixture: "graphicsError", appearance: "retro")
        let ok = app.buttons["OK"].firstMatch
        XCTAssertTrue(ok.waitForExistence(timeout: 5), app.debugDescription)
        XCTAssertTrue(app.staticTexts.allElementsBoundByIndex.contains { text(of: $0) == "Graphics unavailable" }, app.debugDescription)
        XCTAssertFalse((state()["graphicsError"] as? String ?? "").isEmpty)
        ok.click()
        waitFor("exists == false", on: ok)
        XCTAssertTrue((state()["graphicsError"] as? String ?? "").isEmpty)
        XCTAssertEqual(state()["graphicsPackage"] as? String, "retroSquare")
        XCTAssertTrue(element("menu.options").exists)
    }

    func test_B139_DismissScenarioOutcome() {
        for (fixture, title, outcome) in [("won", "You Win!", "won"), ("lost", "Game Over", "lost")] {
            launch(fixture: fixture)
            let before = state()
            XCTAssertEqual(state()["outcome"] as? String, outcome)
            let ok = app.buttons["OK"].firstMatch
            XCTAssertTrue(ok.waitForExistence(timeout: 5), app.debugDescription)
            XCTAssertTrue(app.staticTexts.allElementsBoundByIndex.contains { text(of: $0) == title }, app.debugDescription)
            ok.click()
            waitFor("exists == false", on: ok)
            XCTAssertTrue((state()["outcome"] as? String ?? "").isEmpty)
            XCTAssertEqual(state()["cityName"] as? String, before["cityName"] as? String)
            XCTAssertTrue(element("menu.options").exists)
        }
    }

    private func openWindow(_ command: String, title: String, repeated: Bool) {
        launch(); windows(command)
        let window = app.windows.matching(NSPredicate(format: "title == %@", title)).firstMatch
        XCTAssertTrue(window.waitForExistence(timeout: 5), "\(title) window should open")
        XCTAssertTrue(window.staticTexts.firstMatch.exists)
        if title == "Maps" {
            XCTAssertTrue(window.buttons["overlay.power"].exists, "Maps should expose its city overview layers")
        } else if title == "Graphs" {
            XCTAssertTrue(window.buttons["graph.10year"].exists, "Graphs should expose history range controls")
            XCTAssertTrue(window.buttons["graph.120year"].exists)
        }
        if title == "Evaluation" {
            let snapshot = state()
            let population = (snapshot["population"] as? NSNumber)?.intValue ?? -1
            let score = (snapshot["cityScore"] as? NSNumber)?.intValue ?? -1
            XCTAssertEqual(text(of: element("evaluation.population")), population.formatted())
            XCTAssertEqual(text(of: element("evaluation.score")).trimmingCharacters(in: .whitespaces), String(score))
        }
        if repeated {
            windows(command)
            XCTAssertEqual(app.windows.matching(NSPredicate(format: "title == %@", title)).count, 1)
        }
    }

    private func XCTAssertUnchangedCity(between before: [String: Any], and after: [String: Any], file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(before["cityName"] as? String, after["cityName"] as? String, file: file, line: line)
        XCTAssertEqual(before["funds"] as? Int, after["funds"] as? Int, file: file, line: line)
        XCTAssertEqual(before["mapFingerprint"] as? String, after["mapFingerprint"] as? String, file: file, line: line)
    }
}
