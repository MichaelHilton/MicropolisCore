import Foundation
import XCTest
@testable import MicropolisKit

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
}
