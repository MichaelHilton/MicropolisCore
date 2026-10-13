import XCTest
@testable import MicropolisKit

/// How each scenario is judged when its time runs out (`doScenarioScore`).
///
/// A scenario's real clock is 5 to 30 years of play, so these tests shorten it
/// with the `setScoreWait` hook and then put the city into the winning or
/// losing state the scenario checks.
final class ScenarioScoreTests: XCTestCase {
    private let won = 47, lost = 48

    private enum Outcome { case won, lost }

    /// Loads the scenario, runs `prepare`, ends the scenario at the next
    /// advisor round and reports what the player was told.
    private func outcome(of scenario: Scenario, prepare: (Engine) -> Void = { _ in }) -> Outcome? {
        let engine = Engine(seed: 1)
        XCTAssertTrue(engine.loadScenario(scenario, resourceDirectory: Repo.content))
        engine.setSpeed(3)
        let recorder = FullRecorder()
        engine.delegate = recorder
        // The first tick makes the opening evaluation, which would overwrite
        // a score or traffic value set before it.
        engine.tick()
        prepare(engine)
        engine.setScoreWait(1)
        // sendMessages runs once every 16 ticks.
        for _ in 0..<20 { engine.tick() }
        let verdicts = recorder.messages.filter { $0.index == won || $0.index == lost }
        XCTAssertEqual(verdicts.count, 1, "\(scenario)")
        XCTAssertTrue(verdicts.first?.important ?? false)
        // The win callback has no caller in the engine; only a loss is reported.
        XCTAssertEqual(recorder.won, 0)
        XCTAssertEqual(recorder.lost, verdicts.first?.index == lost ? 1 : 0)
        switch verdicts.first?.index {
        case won: return .won
        case lost: return .lost
        default: return nil
        }
    }

    /// Wipes the map and lets the yearly evaluation notice: the city class
    /// is only recomputed once a year, which is at most 768 ticks away.
    private func emptyTheCity(_ engine: Engine) {
        for x in 0..<Engine.width { for y in 0..<Engine.height { engine.setTile(x: x, y: y, cell: 0) } }
        for _ in 0..<800 { engine.tick() }
        XCTAssertEqual(engine.cityClass, 0)
    }

    func testDullsvilleIsWonByReachingMetropolisAndLostOtherwise() {
        XCTAssertEqual(outcome(of: .dullsville), .lost, "the starting town is only a city")
        XCTAssertEqual(outcome(of: .dullsville) { engine in
            var town = Town(engine)
            town.add(.residential, 190)
            for _ in 0..<800 { engine.tick() }
            XCTAssertGreaterThanOrEqual(engine.cityClass, 4)
        }, .won)
    }

    func testSanFranciscoNeedsAMetropolis() {
        XCTAssertEqual(outcome(of: .sanFrancisco), .won)
        XCTAssertEqual(outcome(of: .sanFrancisco, prepare: emptyTheCity), .lost)
    }

    func testHamburgNeedsAMetropolis() {
        XCTAssertEqual(outcome(of: .hamburg), .won)
        XCTAssertEqual(outcome(of: .hamburg, prepare: emptyTheCity), .lost)
    }

    func testBernNeedsTrafficUnderEighty() {
        XCTAssertEqual(outcome(of: .bern), .won)
        XCTAssertEqual(outcome(of: .bern) { $0.setTrafficAverage(80) }, .lost)
        XCTAssertEqual(outcome(of: .bern) { $0.setTrafficAverage(79) }, .won)
    }

    func testTokyoNeedsAScoreOverFiveHundred() {
        XCTAssertEqual(outcome(of: .tokyo), .won)
        XCTAssertEqual(outcome(of: .tokyo) { $0.setCityScore(500) }, .lost)
        XCTAssertEqual(outcome(of: .tokyo) { $0.setCityScore(501) }, .won)
    }

    func testDetroitNeedsCrimeUnderSixty() {
        XCTAssertEqual(outcome(of: .detroit), .lost, "the starting city is too dangerous")
        XCTAssertEqual(outcome(of: .detroit) { $0.setCrimeAverage(59) }, .won)
        XCTAssertEqual(outcome(of: .detroit) { $0.setCrimeAverage(60) }, .lost)
    }

    func testBostonNeedsAScoreOverFiveHundred() {
        XCTAssertEqual(outcome(of: .boston), .lost)
        XCTAssertEqual(outcome(of: .boston) { $0.setCityScore(501) }, .won)
        XCTAssertEqual(outcome(of: .boston) { $0.setCityScore(500) }, .lost)
    }

    func testRioNeedsAScoreOverFiveHundred() {
        XCTAssertEqual(outcome(of: .rio), .won)
        XCTAssertEqual(outcome(of: .rio) { $0.setCityScore(100) }, .lost)
        XCTAssertEqual(outcome(of: .rio) { $0.setCityScore(501) }, .won)
    }
}
