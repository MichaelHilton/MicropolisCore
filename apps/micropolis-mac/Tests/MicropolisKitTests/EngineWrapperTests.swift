import XCTest
@testable import MicropolisKit

/// The Swift wrapper's settings, defaults and callbacks.
final class EngineWrapperTests: XCTestCase {
    private func haight() -> Engine {
        let engine = Engine()
        XCTAssertTrue(engine.loadCity(at: Repo.city("haight")))
        return engine
    }

    // MARK: Setting round trips

    func testPassesRoundTrip() {
        let engine = Engine()
        engine.setPasses(5)
        XCTAssertEqual(engine.passes, 5)
    }

    func testSpeedRoundTripAndClamp() {
        let engine = Engine()
        for speed in 0...3 {
            engine.setSpeed(speed)
            XCTAssertEqual(engine.speed, speed)
        }
        engine.setSpeed(-1)
        XCTAssertEqual(engine.speed, 0)
        engine.setSpeed(9)
        XCTAssertEqual(engine.speed, 3)
    }

    func testSpeedSurvivesPause() {
        let engine = Engine()
        engine.setSpeed(2)
        engine.pause()
        XCTAssertTrue(engine.isPaused)
        XCTAssertEqual(engine.speed, 0, "pausing sets the speed to 0")
        engine.resume()
        XCTAssertFalse(engine.isPaused)
        XCTAssertEqual(engine.speed, 2, "resuming restores the speed from before the pause")
    }

    func testSettingTheSpeedWhilePausedTakesEffectOnResume() {
        let engine = Engine()
        engine.setSpeed(1)
        engine.pause()
        engine.setSpeed(3)
        XCTAssertEqual(engine.speed, 3, "speed reports the speed last set, even while paused")
        engine.resume()
        XCTAssertEqual(engine.speed, 3)
    }

    func testFlagsRoundTrip() {
        let engine = Engine()
        for value in [true, false] {
            engine.setAutoBudget(value)
            XCTAssertEqual(engine.autoBudget, value)
            engine.setAutoBulldoze(value)
            XCTAssertEqual(engine.autoBulldoze, value)
            engine.setEnableDisasters(value)
            XCTAssertEqual(engine.disastersEnabled, value)
        }
    }

    func testAnimationSettingsAreIndependent() {
        let engine = Engine()
        engine.setAnimation(animateAll: true, frequent: false)
        XCTAssertTrue(engine.animateAll)
        XCTAssertFalse(engine.frequentAnimation)
        engine.setAnimation(animateAll: false, frequent: true)
        XCTAssertFalse(engine.animateAll)
        XCTAssertTrue(engine.frequentAnimation)
    }

    // MARK: Demands

    func testDemandsStayWithinMinusOneAndOne() {
        let engine = haight()
        for step in 0..<10 {
            for _ in 0..<100 { engine.tick() }
            let d = engine.getDemands()
            for value in [d.residential, d.commercial, d.industrial] {
                XCTAssertTrue((-1...1).contains(value), "demand \(value) after \(step * 100 + 100) ticks")
            }
        }
    }

    // MARK: Delegate defaults

    /// A delegate that ignores every event must be safe: this runs each
    /// default implementation in the protocol extension.
    func testEngineWithAnEmptyDelegateKeepsRunning() {
        let engine = Engine()
        let delegate = MinimalDelegate()
        engine.delegate = delegate
        XCTAssertTrue(engine.loadCity(at: Repo.city("haight")))
        engine.generateMap(seed: 4)
        engine.setFunds(100_000)
        engine.setGameLevel(.medium)
        engine.setCityName("Quiet")
        engine.setTax(9)
        engine.setSpeed(2)
        engine.pause()
        engine.resume()
        XCTAssertEqual(engine.apply(.road, x: 10, y: 10), .ok)
        XCTAssertTrue(engine.loadCity(at: Repo.city("haight")))
        let zone = engine.mapSnapshot().enumerated().first { $0.element & 0x0400 != 0 }!.offset
        _ = engine.apply(.query, x: zone / Engine.height, y: zone % Engine.height)
        let yearBefore = engine.year
        for _ in 0..<500 { engine.tick() }
        engine.makeDisaster(.earthquake)
        engine.makeDisaster(.fire)
        engine.makeDisaster(.monster)
        engine.setTax(5)
        for _ in 0..<2000 { engine.tick() }
        XCTAssertGreaterThan(engine.year, yearBefore)
    }

    // MARK: Callbacks

    /// The engine's category is a 1-based index into its tile-category list,
    /// in which residential, commercial and industrial are 11, 12 and 13.
    func testQueryOnAZoneReportsItsStatus() {
        let engine = haight()
        let recorder = FullRecorder()
        engine.delegate = recorder
        let cells = engine.mapSnapshot()
        // Zone centers of the first residential, commercial and industrial
        // tile ranges (RESBASE 240, COMBASE 423, INDBASE 612).
        for (range, category) in [(240..<423, 11), (423..<612, 12), (612..<693, 13)] {
            let center = cells.firstIndex { $0 & 0x0400 != 0 && range.contains(Int($0 & 0x3FF)) }
            guard let center else { XCTFail("no zone in \(range)"); continue }
            recorder.zoneStatuses.removeAll()
            _ = engine.apply(.query, x: center / Engine.height, y: center % Engine.height)
            XCTAssertEqual(recorder.zoneStatuses.count, 1, "\(range)")
            XCTAssertEqual(recorder.zoneStatuses.first?.category, category, "\(range)")
            XCTAssertEqual(recorder.zoneStatuses.first?.x, center / Engine.height)
            XCTAssertEqual(recorder.zoneStatuses.first?.y, center % Engine.height)
        }
    }

    func testEarthquakeIsAnnounced() {
        let engine = haight()
        let recorder = FullRecorder()
        engine.delegate = recorder
        engine.makeDisaster(.earthquake)
        XCTAssertEqual(recorder.earthquakes.count, 1)
        XCTAssertGreaterThan(recorder.earthquakes[0], 0)
    }

    func testSettingTheTaxReportsTheRate() {
        let engine = Engine()
        let recorder = FullRecorder()
        engine.delegate = recorder
        engine.setTax(13)
        XCTAssertEqual(recorder.taxRates, [13])
    }

    func testPauseAndSpeedChangesAreReported() {
        let engine = Engine()
        let recorder = FullRecorder()
        engine.delegate = recorder
        engine.setSpeed(2)
        engine.pause()
        engine.resume()
        XCTAssertEqual(recorder.pausedUpdates, [true, false])
        XCTAssertEqual(recorder.speedUpdates, [2, 0, 2])
    }

    func testAGrowingCitySendsMessages() {
        let engine = haight()
        let recorder = FullRecorder()
        engine.delegate = recorder
        var ticks = 0
        while recorder.messages.isEmpty && ticks < 5000 {
            engine.tick()
            ticks += 1
        }
        XCTAssertFalse(recorder.messages.isEmpty, "no message in \(ticks) ticks")
    }

    func testDisastersMakeSounds() {
        let engine = haight()
        let recorder = FullRecorder()
        engine.delegate = recorder
        engine.makeDisaster(.monster)
        var ticks = 0
        while recorder.sounds.isEmpty && ticks < 1000 {
            engine.tick()
            ticks += 1
        }
        XCTAssertFalse(recorder.sounds.isEmpty, "no sound in \(ticks) ticks of a monster attack")
    }

    // MARK: ToolResult

    func testApplyReportsEachResult() {
        let engine = Engine()
        engine.generateMap(seed: 1)
        engine.setAutoBulldoze(false)
        engine.setFunds(100_000)

        // Find a tree tile and a dirt tile.
        let cells = engine.mapSnapshot()
        // Away from the edge, so the 3x3 building fits on the map.
        let tree = cells.indices.first { i in
            (21...43).contains(cells[i] & 0x3FF) && (2..<117).contains(i / Engine.height)
                && (2..<97).contains(i % Engine.height)
        }
        let dirt = cells.firstIndex { ($0 & 0x3FF) == 0 }
        let treeAt = tree.map { ($0 / Engine.height, $0 % Engine.height) }
        let dirtAt = dirt.map { ($0 / Engine.height, $0 % Engine.height) }

        if let (x, y) = dirtAt {
            XCTAssertEqual(engine.apply(.road, x: x, y: y), .ok)
        } else {
            XCTFail("no dirt on the map")
        }
        if let (x, y) = treeAt {
            XCTAssertEqual(engine.apply(.residential, x: x, y: y), .needBulldoze)
        } else {
            XCTFail("no trees on the map")
        }
        for x in 58...62 { for y in 48...52 { engine.setTile(x: x, y: y, cell: 0) } }
        engine.setFunds(0)
        XCTAssertEqual(engine.apply(.nuclearPower, x: 60, y: 50), .noMoney)
    }

    func testApplyOffTheMapFailsWithoutCrashing() {
        let engine = Engine()
        engine.generateMap(seed: 1)
        engine.setFunds(100_000)
        let before = engine.mapSnapshot()
        for tool in Tool.allCases {
            for (x, y) in [(-1, -1), (500, 500), (-1, 50), (50, 500)] {
                XCTAssertEqual(engine.apply(tool, x: x, y: y), .failed, "\(tool) at (\(x), \(y))")
            }
        }
        XCTAssertEqual(engine.mapSnapshot(), before)
    }
}
