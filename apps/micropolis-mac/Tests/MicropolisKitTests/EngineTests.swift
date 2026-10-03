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
            engine.makeDisaster(3)
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
}
