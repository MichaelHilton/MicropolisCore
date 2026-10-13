import XCTest
@testable import MicropolisKit

/// The yearly city evaluation: population and class, and the score the
/// player sees in the evaluation window (`cityEvaluation`, `getScore`).
final class EvaluationTests: XCTestCase {
    func testTheFirstEvaluationOfANewCityReportsNoMigration() {
        let engine = Engine(seed: 1)
        engine.generateMap(seed: 1)
        engine.setSpeed(3)
        engine.tick()
        let evaluation = engine.evaluation()
        XCTAssertEqual(evaluation.populationDelta, 0)
        XCTAssertEqual(evaluation.cityClass, 0)
    }

    func testAHalfMillionCityIsAMegalopolis() {
        let engine = Engine.blankTown()
        var town = Town(engine)
        town.add(.residential, 800)
        // The class is worked out once a year, at most 768 ticks away.
        for _ in 0..<800 { engine.tick() }
        XCTAssertEqual(engine.cityClass, 5)
        XCTAssertGreaterThan(engine.evaluation().population, 500_000)
    }

    func testAnEmptyCityIsAVillageWithAFairScore() {
        let engine = Engine.blankTown()
        for _ in 0..<800 { engine.tick() }
        let evaluation = engine.evaluation()
        XCTAssertEqual(evaluation.population, 0)
        XCTAssertEqual(evaluation.cityClass, 0)
        XCTAssertEqual(evaluation.score, 500)
        XCTAssertEqual(evaluation.yes, 50, "nobody to vote: the engine reports 50/50")
    }

    // MARK: Score

    /// Haight, run for two years. `landmarks: false` bulldozes its stadium,
    /// seaport and airport, which the city has outgrown without; `funding`
    /// is the share of the road, fire and police budget paid.
    private func haightScoreAfterTwoYears(landmarks: Bool, funding: Float) -> Int {
        let engine = Engine(seed: 1)
        XCTAssertTrue(engine.loadCity(at: Repo.city("haight")))
        engine.setSpeed(3)
        if !landmarks {
            for x in 0..<Engine.width {
                for y in 0..<Engine.height {
                    let tile = Int(engine.tile(x: x, y: y) & 0x3FF)
                    if (693...744).contains(tile) || (779...810).contains(tile) { engine.setTile(x: x, y: y, cell: 0) }
                }
            }
        }
        // With auto-budget off the year-end budget pays only what the
        // percentages say; setting them again afterwards (as the budget
        // window does) turns the payment into road, fire and police effects.
        engine.setAutoBudget(false)
        func fund() {
            engine.setRoadPercent(funding)
            engine.setFirePercent(funding)
            engine.setPolicePercent(funding)
        }
        fund()
        for _ in 0..<800 { engine.tick() }
        fund()
        for _ in 0..<800 { engine.tick() }
        return engine.score
    }

    func testMissingStadiumSeaportAndAirportHoldTheScoreDown() {
        let capped = haightScoreAfterTwoYears(landmarks: false, funding: 1)
        let free = haightScoreAfterTwoYears(landmarks: true, funding: 1)
        XCTAssertLessThan(capped, free, "the stadium, seaport and airport lift the growth caps")
    }

    func testUnderfundedRoadsPoliceAndFireHoldTheScoreDown() {
        let starved = haightScoreAfterTwoYears(landmarks: true, funding: 0.2)
        let paid = haightScoreAfterTwoYears(landmarks: true, funding: 1)
        XCTAssertLessThan(starved, paid)
    }
}
