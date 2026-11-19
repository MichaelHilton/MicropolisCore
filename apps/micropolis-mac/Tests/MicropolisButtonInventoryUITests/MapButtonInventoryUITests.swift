import AppKit
import XCTest

final class MapButtonInventoryUITests: ButtonInventoryTestCase {
    private let toolCases: [(id: String, raw: Int, cost: Int, x: Int, y: Int, width: Int)] = [
        ("tool.q", 5, 0, 10, 10, 1), ("tool.b", 7, 1, 10, 10, 1),
        ("tool.r", 9, 10, 20, 20, 1), ("tool.w", 6, 5, 20, 20, 1),
        ("tool.l", 8, 20, 20, 20, 1), ("tool.p", 11, 10, 20, 20, 1),
        ("tool.u", 0, 100, 20, 20, 3), ("tool.e", 1, 100, 20, 20, 3),
        ("tool.t", 2, 100, 20, 20, 3), ("tool.k", 4, 500, 20, 20, 3),
        ("tool.f", 3, 500, 20, 20, 3), ("tool.s", 10, 5000, 20, 20, 4),
        ("tool.y", 13, 3000, 20, 20, 4), ("tool.n", 14, 5000, 20, 20, 4),
        ("tool.h", 12, 3000, 20, 20, 4), ("tool.a", 15, 10000, 20, 20, 6)
    ]

    func test_B078_SelectAndUseQuery() throws {
        for appearance in ["classic", "retro"] {
            launch(fixture: "tools", appearance: appearance)
            let before = state()
            element("tool.q").click()
            XCTAssertEqual(state()["selectedTool"] as? Int, 5)
            XCTAssertEqual(state()["mapFingerprint"] as? String, before["mapFingerprint"] as? String)
            XCTAssertEqual(try displayedFunds(), before["funds"] as? Int)
            centerMapOn(x: 15, y: 15)
            clickTile(x: 16, y: 16)
            let category = element("zoneStatus.category")
            XCTAssertTrue(category.waitForExistence(timeout: 5))
            XCTAssertEqual(text(of: category), "Residential")
            assertUnchanged(before)
        }
    }

    func test_B079_SelectAndUseBulldozer() throws {
        for appearance in ["classic", "retro"] {
            launch(fixture: "tools", appearance: appearance)
            let before = state()
            element("tool.b").click()
            XCTAssertEqual(state()["selectedTool"] as? Int, 7)
            XCTAssertEqual(state()["mapFingerprint"] as? String, before["mapFingerprint"] as? String)
            XCTAssertEqual(state()["funds"] as? Int, before["funds"] as? Int)
            centerMapOn(x: 15, y: 15)
            clickTile(x: 15, y: 15)
            waitState("funds", equals: (before["funds"] as! Int) - 1)
            let tiles = state()["tiles"] as! [Int]
            let oldTiles = before["tiles"] as! [Int]
            for x in 15...17 { for y in 15...17 {
                let index = x * 100 + y
                let id = tiles[index] & 0x3ff
                XCTAssertNotEqual(tiles[index], oldTiles[index], "Bulldozing must change every tile in the footprint")
                XCTAssertFalse((240..<840).contains(id), "The residential zone must be removed from its full footprint")
            } }
        }
    }

    func test_B080_SelectAndUseRoad() throws { runTool(toolCases[2]) }
    func test_B081_SelectAndUsePowerLines() throws { runTool(toolCases[3]) }
    func test_B082_SelectAndUseRail() throws { runTool(toolCases[4]) }
    func test_B083_SelectAndUsePark() throws { runTool(toolCases[5]) }
    func test_B084_SelectAndUseResidential() throws { runTool(toolCases[6]) }
    func test_B085_SelectAndUseCommercial() throws { runTool(toolCases[7]) }
    func test_B086_SelectAndUseIndustrial() throws { runTool(toolCases[8]) }
    func test_B087_SelectAndUsePolice() throws { runTool(toolCases[9]) }
    func test_B088_SelectAndUseFire() throws { runTool(toolCases[10]) }
    func test_B089_SelectAndUseStadium() throws { runTool(toolCases[11]) }
    func test_B090_SelectAndUseCoal() throws { runTool(toolCases[12]) }
    func test_B091_SelectAndUseNuclear() throws { runTool(toolCases[13]) }
    func test_B092_SelectAndUseSeaport() throws { runTool(toolCases[14]) }
    func test_B093_SelectAndUseAirport() throws { runTool(toolCases[15]) }

    func test_B094_TerrainDirt() throws { terrainBrush("dirt", raw: 0) }
    func test_B095_TerrainTrees() throws { terrainBrush("trees", raw: 0x3025) }
    func test_B096_TerrainWater() throws { terrainBrush("water", raw: 2) }
    func test_B097_TerrainChannel() throws { terrainBrush("channel", raw: 4) }

    func test_B098_TerrainFill() throws {
        launch(fixture: "terrain")
        choose("window.terrainEdit", from: "menu.windows")
        let fill = element("terrain.fill")
        fill.click()
        XCTAssertEqual(state()["terrainFill"] as? Bool, true)
        let before = state()["tiles"] as! [Int]
        element("terrain.trees").click()
        centerMapOn(x: 10, y: 10)
        clickTile(x: 10, y: 10)
        waitState("canUndo", equals: true)
        let after = state()["tiles"] as! [Int]
        XCTAssertNotEqual(after[10 * 100 + 10], before[10 * 100 + 10])
        XCTAssertEqual(after[7 * 100 + 10], before[7 * 100 + 10], "Fill must stop at the seeded water boundary")
        fill.click()
        XCTAssertEqual(state()["terrainFill"] as? Bool, false)
        element("terrain.dirt").click()
        let beforeBrush = state()["tiles"] as! [Int]
        clickTile(x: 10, y: 10)
        let afterBrush = state()["tiles"] as! [Int]
        XCTAssertEqual(afterBrush[10 * 100 + 10], 0)
        XCTAssertEqual(afterBrush[11 * 100 + 10], beforeBrush[11 * 100 + 10], "Fill off must paint only the selected tile")
        XCTAssertEqual(state()["funds"] as? Int, 100000)
    }

    func test_B099_TerrainUndo() throws {
        launch(fixture: "terrain")
        choose("window.terrainEdit", from: "menu.windows")
        let undo = element("terrain.undo")
        XCTAssertFalse(undo.isEnabled)
        let before = state()["tiles"] as! [Int]
        element("terrain.dirt").click()
        centerMapOn(x: 10, y: 10)
        clickTile(x: 10, y: 10)
        waitState("canUndo", equals: true)
        undo.click()
        waitState("canUndo", equals: false)
        XCTAssertEqual(state()["tiles"] as? [Int], before)
        XCTAssertEqual(state()["funds"] as? Int, 100000)
    }

    func test_B100_TerrainSmooth() throws {
        launch(fixture: "terrain")
        choose("window.terrainEdit", from: "menu.windows")
        let before = state()["tiles"] as! [Int]
        element("terrain.smooth").click()
        waitState("canUndo", equals: true)
        XCTAssertNotEqual(state()["tiles"] as? [Int], before, "Smoothing must alter the seeded land/water edge")
        element("terrain.undo").click()
        XCTAssertEqual(state()["tiles"] as? [Int], before)
    }

    func test_B101_ToggleGraphResidential() throws { graphSeries("RES") }
    func test_B102_ToggleGraphCommercial() throws { graphSeries("COM") }
    func test_B103_ToggleGraphIndustrial() throws { graphSeries("IND") }
    func test_B104_ToggleGraphCash() throws { graphSeries("CASH") }
    func test_B105_ToggleGraphCrime() throws { graphSeries("CRIME") }
    func test_B106_ToggleGraphPollution() throws { graphSeries("POLL") }

    func test_B107_GraphTenYears() throws { graphRange(from: "120Year", to: "10Year", title: "Last 10 years") }
    func test_B108_GraphHundredTwentyYears() throws { graphRange(from: "10Year", to: "120Year", title: "Last 120 years") }

    func test_B109_MapOverlayCityForm() throws { mapOverlay("form", raw: "cityForm") }
    func test_B110_MapOverlayPowerGrid() throws { mapOverlay("power", raw: "powerGrid") }
    func test_B111_MapOverlayTransportation() throws { mapOverlay("roads", raw: "transportation") }
    func test_B112_MapOverlayTraffic() throws { mapOverlay("traff", raw: "traffic") }
    func test_B113_MapOverlayPollution() throws { mapOverlay("poll", raw: "pollution") }
    func test_B114_MapOverlayCrime() throws { mapOverlay("crime", raw: "crime") }
    func test_B115_MapOverlayLandValue() throws { mapOverlay("value", raw: "landValue") }

    func test_B116_OpenPopulationMenu() throws { overlayMenu("pop", options: ["Population Density", "Population Growth"]) }
    func test_B117_PopulationDensity() throws { chooseOverlayMenu("pop", item: "Population Density", raw: "populationDensity") }
    func test_B118_PopulationGrowth() throws { chooseOverlayMenu("pop", item: "Population Growth", raw: "populationGrowth") }
    func test_B119_OpenServicesMenu() throws { overlayMenu("serv", options: ["Police Coverage", "Fire Coverage"]) }
    func test_B120_PoliceCoverage() throws { chooseOverlayMenu("serv", item: "Police Coverage", raw: "police") }
    func test_B121_FireCoverage() throws { chooseOverlayMenu("serv", item: "Fire Coverage", raw: "fire") }

    func test_B122_BudgetTaxIncrease() throws { budgetStepper("tax", direction: "increase", limits: 20) }
    func test_B123_BudgetTaxDecrease() throws { budgetStepper("tax", direction: "decrease", limits: 20) }
    func test_B124_BudgetTransportIncrease() throws { budgetStepper("trans", direction: "increase", limits: 100) }
    func test_B125_BudgetTransportDecrease() throws { budgetStepper("trans", direction: "decrease", limits: 100) }
    func test_B126_BudgetPoliceIncrease() throws { budgetStepper("police", direction: "increase", limits: 100) }
    func test_B127_BudgetPoliceDecrease() throws { budgetStepper("police", direction: "decrease", limits: 100) }
    func test_B128_BudgetFireIncrease() throws { budgetStepper("fire", direction: "increase", limits: 100) }
    func test_B129_BudgetFireDecrease() throws { budgetStepper("fire", direction: "decrease", limits: 100) }

    func test_B130_ApplyBudget() throws {
        launch(fixture: "tools")
        choose("window.budget", from: "menu.windows")
        var expected = [String: Int]()
        for field in ["tax", "trans", "police", "fire"] {
            element("budget.\(field).\(field == "tax" ? "increase" : "decrease")").click()
            expected[field] = Int(text(of: element("budget.\(field).value")).filter(\.isNumber))
        }
        element("budget.apply").click()
        waitFor("exists == false", on: element("budget.apply"))
        for field in expected {
            let actual = (state()[budgetEngineKey(field.key)] as? NSNumber)?.doubleValue ?? -1
            XCTAssertEqual(actual, field.key == "tax" ? Double(field.value) : Double(field.value) / 100, accuracy: 0.001)
        }
        XCTAssertTrue(element("map.canvas").isHittable)
        XCTAssertEqual(state()["paused"] as? Bool, true)
        XCTAssertEqual(state()["speed"] as? Int, 0)
        launch(fixture: "budgetPaused")
        XCTAssertEqual(state()["speed"] as? Int, 2)
        XCTAssertEqual(state()["paused"] as? Bool, true)
        choose("window.budget", from: "menu.windows")
        app.typeKey(XCUIKeyboardKey.return.rawValue, modifierFlags: [])
        waitFor("exists == false", on: element("budget.apply"))
        XCTAssertEqual(state()["paused"] as? Bool, false)
        XCTAssertEqual(state()["speed"] as? Int, 2)
    }

    func test_B131_NewCityEasy() throws { selectNewCityLevel(0) }
    func test_B132_NewCityMedium() throws { selectNewCityLevel(1) }
    func test_B133_NewCityHard() throws { selectNewCityLevel(2) }

    func test_B134_ConfirmNewCity() throws {
        launch(fixture: "tools")
        choose("system.newCity", from: "menu.system")
        let before = state()
        let name = element("newCity.name")
        name.click(); name.typeKey("a", modifierFlags: .command); name.typeText("Button Inventory City")
        element("newCity.level.2").click()
        element("newCity.ok").click()
        waitFor("exists == false", on: name)
        XCTAssertEqual(state()["cityName"] as? String, "Button Inventory City")
        XCTAssertEqual(state()["gameLevel"] as? Int, 2)
        XCTAssertNotEqual(state()["mapFingerprint"] as? String, before["mapFingerprint"] as? String)
        XCTAssertEqual(state()["funds"] as? Int, 5000)
        choose("system.newCity", from: "menu.system")
        let second = element("newCity.name")
        second.click(); second.typeKey("a", modifierFlags: .command); second.typeText("Return City West")
        element("newCity.level.1").click()
        app.typeKey(XCUIKeyboardKey.return.rawValue, modifierFlags: [])
        waitFor("exists == false", on: second)
        XCTAssertEqual(state()["cityName"] as? String, "Return City West")
    }

    func test_B135_CancelNewCity() throws {
        launch(fixture: "tools")
        let before = state()
        choose("system.newCity", from: "menu.system")
        element("newCity.name").click(); element("newCity.name").typeText("Discard Me")
        element("newCity.level.2").click()
        app.typeKey(XCUIKeyboardKey.escape.rawValue, modifierFlags: [])
        waitFor("exists == false", on: element("newCity.name"))
        assertUnchanged(before)
    }

    func test_B136_CloseZoneStatus() throws {
        launch(fixture: "tools")
        let before = state()
        element("tool.q").click()
        clickTile(x: 16, y: 16)
        XCTAssertTrue(element("zoneStatus.category").waitForExistence(timeout: 5))
        element("zoneStatus.close").click()
        waitFor("exists == false", on: element("zoneStatus.category"))
        XCTAssertEqual(state()["queryOpen"] as? Bool, false)
        assertUnchanged(before)
        clickTile(x: 16, y: 16)
        XCTAssertTrue(element("zoneStatus.category").waitForExistence(timeout: 5))
        app.typeKey(XCUIKeyboardKey.escape.rawValue, modifierFlags: [])
        waitFor("exists == false", on: element("zoneStatus.category"))
        XCTAssertEqual(state()["queryOpen"] as? Bool, false)
    }

    private func runTool(_ spec: (id: String, raw: Int, cost: Int, x: Int, y: Int, width: Int)) {
        let expectedBase: [String: Int] = ["tool.r": 66, "tool.w": 210, "tool.l": 226, "tool.p": 840,
                                          "tool.u": 240, "tool.e": 423, "tool.t": 612, "tool.k": 770,
                                          "tool.f": 761, "tool.s": 779, "tool.y": 745, "tool.n": 811,
                                          "tool.h": 693, "tool.a": 709]
        for appearance in ["classic", "retro"] {
            launch(fixture: "tools", appearance: appearance)
            let before = state()
            let funds = before["funds"] as! Int
            element(spec.id).click()
            XCTAssertEqual(state()["selectedTool"] as? Int, spec.raw)
            XCTAssertEqual(state()["funds"] as? Int, funds, "Selecting a tool must be free")
            XCTAssertEqual(state()["mapFingerprint"] as? String, before["mapFingerprint"] as? String)
            centerMapOn(x: spec.x, y: spec.y)
            clickTile(x: spec.x, y: spec.y)
            waitState("funds", equals: funds - spec.cost)
            let tiles = state()["tiles"] as! [Int]
            let x0 = spec.x - (spec.width > 1 ? 1 : 0)
            let y0 = spec.y - (spec.width > 1 ? 1 : 0)
            let expected = expectedBase[spec.id]!..<(expectedBase[spec.id]! + spec.width * spec.width)
            for x in x0..<x0 + spec.width { for y in y0..<y0 + spec.width {
                let id = tiles[x * 100 + y] & 0x3ff
                if spec.id == "tool.p" {
                    XCTAssertTrue((37...43).contains(id) || id == 840, "Unexpected park tile at (\(x),\(y))")
                } else {
                    XCTAssertTrue(expected.contains(id), "Unexpected tile at (\(x),\(y))")
                }
            } }
        }
    }

    private func terrainBrush(_ brush: String, raw: Int) {
        launch(fixture: "terrain")
        let before = state()
        choose("window.terrainEdit", from: "menu.windows")
        element("terrain.\(brush)").click()
        XCTAssertEqual(state()["terrainTool"] as? String, brush)
        XCTAssertEqual(state()["tiles"] as? [Int], before["tiles"] as? [Int])
        let funds = state()["funds"] as? Int
        centerMapOn(x: 10, y: brush == "dirt" ? 7 : 10)
        let y = brush == "dirt" ? 7 : 10
        clickTile(x: 10, y: y)
        waitState("canUndo", equals: true)
        XCTAssertEqual((state()["tiles"] as! [Int])[10 * 100 + y], raw)
        XCTAssertEqual(state()["funds"] as? Int, funds)
    }

    private func graphSeries(_ series: String) {
        launch(fixture: "graphHistories")
        choose("window.graphs", from: "menu.windows")
        let button = element("graph.\(series.lowercased())")
        XCTAssertTrue(button.waitForExistence(timeout: 5))
        let chart = app.windows["Graphs"].descendants(matching: .any).matching(identifier: "graph.chart").firstMatch
        for other in ["RES", "COM", "IND", "CASH", "CRIME", "POLL"] where other != series {
            let control = element("graph.\(other.lowercased())")
            if control.value as? String == "on" { control.click() }
        }
        let before = chart.screenshot().pngRepresentation
        button.click()
        XCTAssertEqual(button.value as? String, "off")
        let hidden = chart.screenshot().pngRepresentation
        XCTAssertNotEqual(hidden, before, "Hiding a seeded series must change the rendered plot")
        button.click()
        XCTAssertEqual(button.value as? String, "on")
        XCTAssertEqual(chart.screenshot().pngRepresentation, before)
    }

    private func graphRange(from: String, to: String, title: String) {
        launch(fixture: "graphHistories")
        choose("window.graphs", from: "menu.windows")
        element("graph.\(from.lowercased())").click()
        let chart = element("graph.chart")
        let before = chart.screenshot().pngRepresentation
        element("graph.\(to.lowercased())").click()
        XCTAssertEqual(text(of: element("graph.rangeTitle")), title)
        XCTAssertEqual(element("graph.\(to.lowercased())").value as? String, "on")
        XCTAssertNotEqual(chart.screenshot().pngRepresentation, before, "The selected history range must change the plotted years")
    }

    private func mapOverlay(_ label: String, raw: String) {
        launch(fixture: "graphHistories")
        choose("window.maps", from: "menu.windows")
        element(raw == "powerGrid" ? "overlay.roads" : "overlay.power").click()
        let before = state()
        let beforePixels = element("map.overview").screenshot().pngRepresentation
        let button = element("overlay.\(label)")
        button.click()
        waitState("mapOverlay", equals: raw)
        XCTAssertNotEqual(element("map.overview").screenshot().pngRepresentation, beforePixels,
                           "Choosing a different overlay must change the overview rendering")
        XCTAssertEqual(state()["tiles"] as? [Int], before["tiles"] as? [Int])
        XCTAssertEqual(state()["funds"] as? Int, before["funds"] as? Int)
    }

    private func overlayMenu(_ label: String, options: [String]) {
        launch(fixture: "graphHistories")
        choose("window.maps", from: "menu.windows")
        element("overlay.\(label)").click()
        app.menuItems[options[0]].click()
        let before = state()["mapOverlay"] as? String
        element("overlay.\(label)").click()
        for option in options { XCTAssertTrue(app.menuItems[option].waitForExistence(timeout: 5)) }
        NativeMenuAssertions.assertMarked(true, title: options[0], under: "overlay.\(label)", in: app)
        app.typeKey(XCUIKeyboardKey.escape.rawValue, modifierFlags: [])
        XCTAssertEqual(state()["mapOverlay"] as? String, before)
    }

    private func chooseOverlayMenu(_ label: String, item: String, raw: String) {
        launch(fixture: "graphHistories")
        choose("window.maps", from: "menu.windows")
        element("overlay.\(label == "pop" ? "serv" : "pop")").click()
        app.menuItems[label == "pop" ? "Police Coverage" : "Population Density"].click()
        let beforePixels = element("map.overview").screenshot().pngRepresentation
        element("overlay.\(label)").click()
        app.menuItems[item].click()
        waitState("mapOverlay", equals: raw)
        XCTAssertNotEqual(element("map.overview").screenshot().pngRepresentation, beforePixels,
                           "Changing the overlay choice must update the fixture overview")
        element("overlay.\(label)").click()
        XCTAssertTrue(app.menuItems[item].waitForExistence(timeout: 5))
        NativeMenuAssertions.assertMarked(true, title: item, under: "overlay.\(label)", in: app)
        app.menuItems[item].click()
        XCTAssertEqual(state()["mapOverlay"] as? String, raw)
    }

    private func budgetStepper(_ field: String, direction: String, limits: Int) {
        launch(fixture: "tools")
        choose("window.budget", from: "menu.windows")
        let beforeEngine = state()
        let value = element("budget.\(field).value")
        let target = field == "tax" ? (direction == "increase" ? 5 : 15) : (direction == "increase" ? 50 : 60)
        for _ in 0..<100 {
            let current = Int(text(of: value).filter(\.isNumber))!
            if current == target { break }
            element("budget.\(field).\(current < target ? "increase" : "decrease")").click()
        }
        let start = Int(text(of: value).filter(\.isNumber))!
        XCTAssertEqual(start, target, "Budget draft should begin in the interior of its range")
        let button = element("budget.\(field).\(direction)")
        button.click()
        let one = Int(text(of: value).filter(\.isNumber))!
        XCTAssertEqual(one, min(limits, max(0, start + (direction == "increase" ? 1 : -1))))
        XCTAssertEqual((state()[budgetEngineKey(field)] as? NSNumber)?.doubleValue,
                       (beforeEngine[budgetEngineKey(field)] as? NSNumber)?.doubleValue,
                       "Editing a budget draft must not update the engine before Apply")
        XCUIElement.perform(withKeyModifiers: [.option]) { button.click() }
        let ten = Int(text(of: value).filter(\.isNumber))!
        XCTAssertEqual(ten, min(limits, max(0, one + (direction == "increase" ? 10 : -10))))
        for _ in 0..<11 {
            let current = Int(text(of: value).filter(\.isNumber))!
            if direction == "increase" ? current == limits : current == 0 { break }
            XCUIElement.perform(withKeyModifiers: [.option]) {
                element("budget.\(field).\(direction)").click()
            }
        }
        if direction == "increase" {
            XCUIElement.perform(withKeyModifiers: [.option]) { button.click() }
            XCTAssertEqual(Int(text(of: value).filter(\.isNumber)), limits)
        } else {
            XCUIElement.perform(withKeyModifiers: [.option]) { button.click() }
            XCTAssertEqual(Int(text(of: value).filter(\.isNumber)), 0)
        }
    }

    private func selectNewCityLevel(_ level: Int) {
        launch(fixture: "tools")
        let before = state()
        choose("system.newCity", from: "menu.system")
        let otherLevel = level == 0 ? 1 : 0
        element("newCity.level.\(otherLevel)").click()
        let selected = element("newCity.level.\(level)")
        selected.click()
        XCTAssertEqual(selected.value as? String, "1")
        XCTAssertEqual(element("newCity.level.\(otherLevel)").value as? String, "0")
        XCTAssertEqual(state()["mapFingerprint"] as? String, before["mapFingerprint"] as? String)
        element("newCity.ok").click()
        waitState("gameLevel", equals: level)
        XCTAssertEqual(state()["funds"] as? Int, [20000, 10000, 5000][level])
    }

    private func budgetEngineKey(_ field: String) -> String {
        switch field {
        case "tax": "taxRate"
        case "trans": "roadPercent"
        case "police": "policePercent"
        default: "firePercent"
        }
    }

    private func centerMapOn(x: Int, y: Int) {
        choose("window.maps", from: "menu.windows")
        let overview = element("map.overview")
        XCTAssertTrue(overview.waitForExistence(timeout: 5))
        overview.coordinate(withNormalizedOffset: CGVector(dx: (Double(x) + 0.5) / 120,
                                                              dy: (Double(y) + 0.5) / 100)).click()
        app.windows["Maps"].buttons[XCUIIdentifierCloseWindow].click()
        waitFor("hittable == true", on: element("map.canvas"))
    }
}
