import XCTest
@testable import MicropolisKit

/// The year-end budget (budget.cpp), the advisor messages (message.cpp), the
/// end of a scenario and the history graphs (graph.cpp).
final class BudgetMessageTests: XCTestCase {
    private func haight() -> Engine {
        let engine = Engine()
        XCTAssertTrue(engine.loadCity(at: Repo.city("haight")))
        return engine
    }

    /// Ticks until the year changes, then a little longer: the budget runs
    /// a few ticks into the new year. Returns how many ticks that took.
    private func tickThroughYearEnd(_ engine: Engine, limit: Int = 2000) -> Int {
        let year = engine.year
        var ticks = 0
        while engine.year == year && ticks < limit {
            engine.tick()
            ticks += 1
        }
        XCTAssertLessThan(ticks, limit, "the year never ended")
        for _ in 0..<40 { engine.tick() }
        return ticks
    }

    func testYearEndAsksForTheBudgetWhenAutoBudgetIsOff() {
        let engine = haight()
        engine.setAutoBudget(false)
        let recorder = FullRecorder()
        engine.delegate = recorder
        _ = tickThroughYearEnd(engine)
        XCTAssertEqual(recorder.budgetRequests, 1)
        _ = tickThroughYearEnd(engine)
        XCTAssertEqual(recorder.budgetRequests, 2, "once every year")
    }

    func testAutoBudgetSettlesTheYearWithoutAsking() {
        let engine = haight()
        engine.setAutoBudget(true)
        let recorder = FullRecorder()
        engine.delegate = recorder
        let before = engine.funds
        _ = tickThroughYearEnd(engine)
        XCTAssertEqual(recorder.budgetRequests, 0)
        XCTAssertNotEqual(engine.funds, before, "the year's taxes and spending were applied")
    }

    func testAutoBudgetChargesTaxesMinusSpending() {
        let engine = haight()
        engine.setAutoBudget(true)
        // The budget runs at the start of January: find the tick where the
        // funds jump and compare with the figures the engine holds then.
        var last = engine.funds
        for _ in 0..<2000 {
            engine.tick()
            if engine.funds != last, abs(engine.funds - last) > 50 {
                let figures = engine.budgetFigures()
                let spending = figures.roadRequested + figures.policeRequested + figures.fireRequested
                XCTAssertEqual(engine.funds - last, figures.taxesCollected - spending)
                return
            }
            last = engine.funds
        }
        XCTFail("funds never changed")
    }

    func testNotEnoughMoneyCutsFundingAndSwitchesOffAutoBudget() {
        let engine = haight()
        engine.setAutoBudget(true)
        engine.setFunds(0)
        engine.setTax(0)
        let recorder = FullRecorder()
        engine.delegate = recorder
        XCTAssertEqual(engine.roadPercent, 1)
        _ = tickThroughYearEnd(engine)
        XCTAssertLessThan(engine.roadPercent, 1)
        XCTAssertLessThan(engine.policePercent, 1)
        XCTAssertLessThan(engine.firePercent, 1)
        XCTAssertFalse(engine.autoBudget, "the engine forces the budget window open")
        XCTAssertTrue(recorder.messages.contains { $0.index == 29 }, "your city has gone broke")
        XCTAssertEqual(recorder.budgetRequests, 1)
    }

    func testPartialFundingScalesTheDepartmentsInOrder() {
        let engine = haight()
        engine.setAutoBudget(true)
        engine.setFunds(0)
        engine.setTax(0)
        // Roads are funded first, then fire, then police, so with a few
        // dollars only roads get anything.
        engine.setFunds(1000)
        _ = tickThroughYearEnd(engine)
        XCTAssertGreaterThan(engine.roadPercent, 0)
        XCTAssertLessThan(engine.roadPercent, 1)
        XCTAssertEqual(engine.firePercent, 0)
        XCTAssertEqual(engine.policePercent, 0)
    }

    // MARK: Messages

    func testACityWithoutPowerPlantsAsksForOne() {
        let engine = haight()
        // Remove the plants: coal (745...760) and nuclear (811...826) tiles.
        for x in 0..<Engine.width {
            for y in 0..<Engine.height {
                let tile = Int(engine.tile(x: x, y: y) & 0x3FF)
                if (745...760).contains(tile) || (811...826).contains(tile) { engine.setTile(x: x, y: y, cell: 0) }
            }
        }
        let recorder = FullRecorder()
        engine.delegate = recorder
        // The advisor checks for power once every 64 city-time units, about 1000 ticks.
        for _ in 0..<3000 { engine.tick() }
        XCTAssertTrue(recorder.messages.contains { $0.index == 6 }, "\(recorder.messages.map(\.index))")
    }

    // MARK: Scenario end

    /// San Francisco gives the player until 1913; a city that has not met
    /// the goal by then has lost, and the engine says so.
    func testLettingAScenarioRunOutIsALoss() {
        let engine = Engine()
        XCTAssertTrue(engine.loadScenario(.sanFrancisco, resourceDirectory: Repo.content))
        let recorder = FullRecorder()
        engine.delegate = recorder
        var ticks = 0
        while recorder.lost == 0 && ticks < 6000 {
            engine.tick()
            ticks += 1
        }
        XCTAssertEqual(recorder.lost, 1, "no loss in \(ticks) ticks")
        XCTAssertEqual(recorder.won, 0)
    }

    // MARK: History

    func testHistoryFillsAsTheCityRuns() {
        let engine = haight()
        XCTAssertTrue(engine.history(.residential).contains { $0 > 0 }, "a loaded city starts with history")
        for _ in 0..<5000 { engine.tick() }
        for kind in HistoryKind.allCases {
            let values = engine.history(kind)
            XCTAssertEqual(values.count, 480, "\(kind)")
            XCTAssertTrue(values.contains { $0 != 0 }, "\(kind) is all zeros")
        }
    }
}
