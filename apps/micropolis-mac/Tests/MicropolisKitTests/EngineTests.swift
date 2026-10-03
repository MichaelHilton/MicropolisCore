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
}
