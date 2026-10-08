import Foundation
import XCTest
@testable import MicropolisKit

class RecordingDelegate: EngineDelegate {
    var didLoadCityFilename: String?
    var didGenerateMapSeed: Int?
    var didToolEvents: [(name: String, x: Int, y: Int)] = []
    var updateDateEvents: [(year: Int, month: Int)] = []
    var updateFundsValues: [Int] = []
    var noDelegateTestActive = false

    func engineDidLoadCity(filename: String) {
        didLoadCityFilename = filename
    }

    func engineDidGenerateMap(seed: Int) {
        didGenerateMapSeed = seed
    }

    func engineDidTool(name: String, x: Int, y: Int) {
        didToolEvents.append((name, x, y))
    }

    func engineUpdateDate(year: Int, month: Int) {
        if !noDelegateTestActive {
            updateDateEvents.append((year, month))
        }
    }

    func engineUpdateFunds(funds: Int) {
        updateFundsValues.append(funds)
    }
}

final class EngineTests: XCTestCase {

    var repoRoot: URL {
        let file = URL(fileURLWithPath: #filePath)
        return file.deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    func testLoadHaight() {
        let engine = Engine()
        let cityPath = repoRoot.appendingPathComponent("content/micropolis/cities/haight.cty")
        let result = engine.loadCity(at: cityPath)
        XCTAssertTrue(result, "Failed to load haight.cty")
    }

    func testSimulationAdvances() {
        let engine = Engine()
        let cityPath = repoRoot.appendingPathComponent("content/micropolis/cities/haight.cty")
        let loaded = engine.loadCity(at: cityPath)
        XCTAssertTrue(loaded, "Failed to load city")

        let yearBefore = engine.year
        let fundsBefore = engine.funds

        for _ in 0..<2000 {
            engine.tick()
        }

        let yearAfter = engine.year
        let fundsAfter = engine.funds

        if yearAfter <= yearBefore {
            XCTFail("Year should advance after ticks: \(yearBefore) -> \(yearAfter)")
        }
        if fundsAfter == fundsBefore {
            XCTFail("Funds should change after ticks: \(fundsBefore) -> \(fundsAfter)")
        }
    }

    func testLoadMissingFails() {
        let engine = Engine()
        let result = engine.loadCity(at: URL(fileURLWithPath: "/nonexistent.cty"))
        XCTAssertFalse(result, "Loading nonexistent file should fail")
    }

    func testGenerateMapChangesTiles() {
        let engine = Engine()
        engine.generateMap(seed: 1)
        let snapshot1 = engine.mapSnapshot()

        engine.generateMap(seed: 2)
        let snapshot2 = engine.mapSnapshot()

        if snapshot1 == snapshot2 {
            XCTFail("Different seeds should generate different maps")
        }

        engine.generateMap(seed: 1)
        let snapshot3 = engine.mapSnapshot()

        if snapshot1 != snapshot3 {
            XCTFail("Same seed should generate identical maps")
        }
    }

    func testBulldozeThenRoad() {
        let engine = Engine()
        engine.generateMap(seed: 1)
        engine.setFunds(100000)

        var dirtTile = -1
        for x in 0..<Engine.width {
            for y in 0..<Engine.height {
                if (engine.tile(x: x, y: y) & 0x3FF) == 0 {
                    dirtTile = x * 100 + y
                    let result = engine.apply(.road, x: x, y: y)
                    if result == .ok {
                        let newTile = engine.tile(x: x, y: y)
                        if (newTile & 0x3FF) != 0 {
                            return
                        }
                    }
                }
            }
        }

        if dirtTile == -1 {
            XCTFail("No dirt tiles found in generated map")
        } else {
            XCTFail("Could not build road on dirt tile")
        }
    }

    func testNoMoney() {
        let engine = Engine()
        engine.generateMap(seed: 1)
        engine.setFunds(0)

        let result = engine.apply(.nuclearPower, x: 60, y: 50)
        if result == .ok {
            XCTFail("Building with 0 funds should not succeed")
        }
    }

    func testTaxRoundTrip() {
        let engine = Engine()
        engine.setTax(12)
        let tax = engine.tax
        if tax != 12 {
            XCTFail("Tax should round-trip: set 12, got \(tax)")
        }
    }

    func testSaveAndReload() {
        let engine1 = Engine()
        let cityPath = repoRoot.appendingPathComponent("content/micropolis/cities/haight.cty")
        let loaded = engine1.loadCity(at: cityPath)

        if !loaded {
            XCTFail("Failed to load haight city")
            return
        }

        let tempDir = FileManager.default.temporaryDirectory
        let tempFile = tempDir.appendingPathComponent("test_save.cty")

        if !engine1.saveCity(at: tempFile) {
            XCTFail("Failed to save city")
            return
        }

        let engine2 = Engine()
        let reloaded = engine2.loadCity(at: tempFile)

        if !reloaded {
            XCTFail("Failed to load saved city")
            try? FileManager.default.removeItem(at: tempFile)
            return
        }

        let year1 = engine1.year
        let year2 = engine2.year

        if year1 != year2 {
            XCTFail("Year should be preserved: \(year1) vs \(year2)")
        }

        try? FileManager.default.removeItem(at: tempFile)
    }

    func testDidLoadCityFires() {
        let engine = Engine()
        let delegate = RecordingDelegate()
        engine.delegate = delegate

        let cityPath = repoRoot.appendingPathComponent("content/micropolis/cities/haight.cty")
        engine.loadCity(at: cityPath)

        if delegate.didLoadCityFilename == nil {
            XCTFail("didLoadCity callback should have fired")
        } else if !delegate.didLoadCityFilename!.contains("haight") {
            XCTFail("didLoadCity filename should contain 'haight', got: \(delegate.didLoadCityFilename!)")
        }
    }

    func testUpdateDateFires() {
        let engine = Engine()
        let delegate = RecordingDelegate()
        engine.delegate = delegate

        let cityPath = repoRoot.appendingPathComponent("content/micropolis/cities/haight.cty")
        engine.loadCity(at: cityPath)

        for _ in 0..<2000 {
            engine.tick()
        }

        if delegate.updateDateEvents.isEmpty {
            XCTFail("updateDate callback should have fired at least once")
        }
    }

    func testDidToolFires() {
        let engine = Engine()
        let delegate = RecordingDelegate()
        engine.delegate = delegate

        engine.generateMap(seed: 1)
        engine.setFunds(100000)

        var dirtX = -1, dirtY = -1
        for x in 0..<Engine.width {
            for y in 0..<Engine.height {
                if (engine.tile(x: x, y: y) & 0x3FF) == 0 {
                    dirtX = x
                    dirtY = y
                    break
                }
            }
            if dirtX != -1 { break }
        }

        if dirtX == -1 {
            XCTFail("No dirt tiles found")
            return
        }

        engine.apply(.road, x: dirtX, y: dirtY)

        var found = false
        for event in delegate.didToolEvents {
            if event.x == dirtX && event.y == dirtY {
                found = true
                break
            }
        }

        if !found {
            XCTFail("didTool callback should have fired for tool at (\(dirtX), \(dirtY))")
        }
    }

    func testNoDelegateNoCrash() {
        let engine = Engine()
        engine.delegate = nil

        let cityPath = repoRoot.appendingPathComponent("content/micropolis/cities/haight.cty")
        engine.loadCity(at: cityPath)

        for _ in 0..<500 {
            engine.tick()
        }
    }

    func testSpritesAppear() {
        let engine = Engine()
        let cityPath = repoRoot.appendingPathComponent("content/micropolis/cities/scenario_tokyo.cty")
        let loaded = engine.loadCity(at: cityPath)

        if !loaded {
            XCTFail("Failed to load scenario_tokyo.cty")
            return
        }

        var spriteFound = false
        for _ in 0..<5000 {
            let sprites = engine.sprites()
            if !sprites.isEmpty {
                spriteFound = true
                break
            }
            engine.tick()
        }

        if !spriteFound {
            engine.makeDisaster(.monster)
            for _ in 0..<100 {
                engine.tick()
                let sprites = engine.sprites()
                if !sprites.isEmpty {
                    spriteFound = true
                    break
                }
            }
        }

        if !spriteFound {
            XCTFail("No sprites appeared within 5000 ticks or after monster disaster")
        }
    }

    func testHistoryData() {
        let engine = Engine()
        let cityPath = repoRoot.appendingPathComponent("content/micropolis/cities/haight.cty")
        let loaded = engine.loadCity(at: cityPath)

        if !loaded {
            XCTFail("Failed to load haight.cty")
            return
        }

        for _ in 0..<3000 {
            engine.tick()
        }

        let resHistory = engine.history(.residential)

        if resHistory.count != 480 {
            XCTFail("Residential history should have 480 entries, got \(resHistory.count)")
            return
        }

        let hasNonZero = resHistory.contains { $0 != 0 }
        if !hasNonZero {
            XCTFail("Residential history should have at least one non-zero entry")
        }
    }

    // MARK: - Data for the DOS windows

    private func loadedHaight(ticks: Int) -> Engine? {
        let engine = Engine()
        guard engine.loadCity(at: repoRoot.appendingPathComponent("content/micropolis/cities/haight.cty")) else {
            XCTFail("Failed to load haight.cty")
            return nil
        }
        for _ in 0..<ticks { engine.tick() }
        return engine
    }

    func testEveryHistorySeriesIsReadable() throws {
        let engine = try XCTUnwrap(loadedHaight(ticks: 3000))
        for kind in HistoryKind.allCases {
            XCTAssertEqual(engine.history(kind).count, 480, "\(kind)")
        }
        XCTAssertTrue(engine.history(.commercial).contains { $0 != 0 })
    }

    func testOverlaysHaveDataForABuiltCity() throws {
        let engine = try XCTUnwrap(loadedHaight(ticks: 600))
        for kind: OverlayKind in [.population, .traffic, .landValue, .crime, .police, .fire] {
            let values = engine.overlay(kind)
            XCTAssertEqual(values.count, Engine.width * Engine.height)
            XCTAssertTrue(values.contains { $0 > 0 }, "\(kind) overlay is empty")
        }
    }

    func testEvaluationMatchesCityState() throws {
        let engine = try XCTUnwrap(loadedHaight(ticks: 3000))
        let eval = engine.evaluation()
        XCTAssertEqual(eval.population, engine.population)
        XCTAssertEqual(eval.score, engine.score)
        XCTAssertEqual(eval.cityClass, engine.cityClass)
        XCTAssertTrue((0...100).contains(eval.yes))
        XCTAssertLessThanOrEqual(eval.problems.count, 4)
        for problem in eval.problems {
            XCTAssertTrue((0..<7).contains(problem.id))
            XCTAssertTrue((0...100).contains(problem.votes))
        }
    }

    func testBudgetFiguresAreNonNegative() throws {
        let engine = try XCTUnwrap(loadedHaight(ticks: 3000))
        let figures = engine.budgetFigures()
        XCTAssertGreaterThanOrEqual(figures.taxesCollected, 0)
        XCTAssertGreaterThan(figures.roadRequested + figures.policeRequested + figures.fireRequested, 0)
    }

    func testGameLevelSetsStartingFunds() {
        let engine = Engine()
        engine.generateMap(seed: 42)
        let expected: [GameLevel: Int] = [.easy: 20000, .medium: 10000, .hard: 5000]
        for (level, funds) in expected {
            engine.setGameLevel(level)
            XCTAssertEqual(engine.gameLevel, level)
            XCTAssertEqual(engine.funds, funds)
        }
    }

    func testEveryScenarioLoads() {
        let content = repoRoot.appendingPathComponent("content/micropolis")
        for scenario in Scenario.allCases {
            let engine = Engine()
            XCTAssertTrue(engine.loadScenario(scenario, resourceDirectory: content), "\(scenario)")
            // Population is only counted at the first census, so look for zones.
            let zones = engine.mapSnapshot().filter { $0 & 0x0400 != 0 }.count
            XCTAssertGreaterThan(zones, 20, "\(scenario) has no city")
        }
        XCTAssertEqual(Engine().loadScenario(.tokyo, resourceDirectory: URL(fileURLWithPath: "/nonexistent")), false)
    }

    func testSetTileAndSmoothTerrain() {
        let engine = Engine()
        engine.generateMap(seed: 7)
        // A 5x5 lake of plain river tiles; smoothing should give it edge tiles.
        for x in 50..<55 { for y in 50..<55 { engine.setTile(x: x, y: y, cell: 2) } }
        for x in 48..<57 { engine.setTile(x: x, y: 49, cell: 0); engine.setTile(x: x, y: 55, cell: 0) }
        XCTAssertEqual(engine.tile(x: 52, y: 52) & 0x3FF, 2)
        engine.smoothTerrain()
        let edge = engine.tile(x: 50, y: 50) & 0x3FF
        XCTAssertTrue((3...20).contains(edge), "corner should become a river edge, got \(edge)")
        XCTAssertEqual(engine.tile(x: 52, y: 52) & 0x3FF, 2, "middle of the lake stays open water")
    }

    func testAirCrashWithoutAPlaneDoesNothing() throws {
        let engine = Engine()
        engine.generateMap(seed: 3)
        let before = engine.mapSnapshot()
        engine.makeDisaster(.airCrash)
        XCTAssertEqual(engine.mapSnapshot(), before)
    }
}
