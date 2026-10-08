import XCTest
@testable import MicropolisKit

/// Disasters (disasters.cpp) triggered by hand and by the scenarios, judged
/// by what they do to the map. The engine seeds its random numbers from the
/// clock, so these assert "some tile changed", never where.
final class DisasterTests: XCTestCase {
    private func tiles(_ engine: Engine) -> [Int] { engine.mapSnapshot().map { Int($0 & 0x3FF) } }
    private func fires(_ engine: Engine) -> Int { tiles(engine).filter { (56...63).contains($0) }.count }
    private func floods(_ engine: Engine) -> Int { tiles(engine).filter { (48...51).contains($0) }.count }
    private func radiation(_ engine: Engine) -> Int { tiles(engine).filter { $0 == 52 }.count }
    private func rubble(_ engine: Engine) -> Int { tiles(engine).filter { (44...47).contains($0) }.count }

    private func city(_ name: String) -> Engine {
        let engine = Engine()
        XCTAssertTrue(engine.loadCity(at: Repo.city(name)), name)
        engine.setEnableDisasters(true)
        return engine
    }

    /// Triggers `disaster` until `seen` is true, up to `attempts` times, each
    /// followed by a few ticks. A disaster picks its spot at random and can
    /// miss, as in the game.
    private func provoke(_ disaster: Disaster, in engine: Engine, attempts: Int = 20,
                         until seen: () -> Bool) -> Bool {
        for _ in 0..<attempts {
            engine.makeDisaster(disaster)
            for _ in 0..<5 { engine.tick() }
            if seen() { return true }
        }
        return false
    }

    func testFireStartsFires() {
        let engine = city("haight")
        XCTAssertEqual(fires(engine), 0)
        XCTAssertTrue(provoke(.fire, in: engine) { fires(engine) > 0 }, "no fire tile appeared")
    }

    func testFloodFloodsNextToWater() {
        let engine = city("wetcity")
        XCTAssertEqual(floods(engine), 0)
        XCTAssertTrue(provoke(.flood, in: engine) { floods(engine) > 0 }, "no flood tile appeared")
    }

    func testEarthquakeAnnouncesItselfAndWrecksZones() {
        let engine = city("haight")
        let recorder = FullRecorder()
        engine.delegate = recorder
        let rubbleBefore = rubble(engine)
        engine.makeDisaster(.earthquake)
        XCTAssertEqual(recorder.earthquakes.count, 1)
        for _ in 0..<100 { engine.tick() }
        XCTAssertGreaterThan(rubble(engine) + fires(engine), rubbleBefore, "an earthquake leaves rubble or fire")
    }

    func testMeltdownSpreadsRadiationFromANuclearPlant() {
        let engine = Engine()
        engine.generateMap(seed: 2)
        for x in 40..<70 { for y in 40..<70 { engine.setTile(x: x, y: y, cell: 0) } }
        engine.setFunds(100_000)
        XCTAssertEqual(engine.apply(.nuclearPower, x: 50, y: 50), .ok)
        XCTAssertEqual(radiation(engine), 0)
        engine.makeDisaster(.meltdown)
        for _ in 0..<20 { engine.tick() }
        XCTAssertGreaterThan(radiation(engine), 0, "radioactive tiles should appear around the plant")
    }

    func testMeltdownWithoutAPlantChangesNothing() {
        let engine = Engine()
        engine.generateMap(seed: 2)
        for x in 0..<Engine.width { for y in 0..<Engine.height { engine.setTile(x: x, y: y, cell: 0) } }
        let map = engine.mapSnapshot()
        engine.makeDisaster(.meltdown)
        XCTAssertEqual(engine.mapSnapshot(), map)
    }

    func testNoRandomDisastersWhenDisabled() {
        let engine = city("haight")
        engine.setEnableDisasters(false)
        let recorder = FullRecorder()
        engine.delegate = recorder
        // About six game years. Fires are sampled every 50 ticks, and the
        // message and earthquake checks cover the rest.
        for tick in 0..<6000 {
            engine.tick()
            if tick % 50 == 0 { XCTAssertEqual(fires(engine), 0, "fire at tick \(tick)") }
        }
        let disasterMessages = recorder.messages.map(\.index).filter { [20, 21, 22, 23, 24].contains($0) }
        XCTAssertTrue(disasterMessages.isEmpty, "\(disasterMessages)")
        XCTAssertTrue(recorder.earthquakes.isEmpty)
    }

    // MARK: Scenario disasters

    /// Each scenario schedules its disaster early on.
    private func scenario(_ scenario: Scenario) -> (Engine, FullRecorder) {
        let engine = Engine()
        XCTAssertTrue(engine.loadScenario(scenario, resourceDirectory: Repo.content))
        let recorder = FullRecorder()
        engine.delegate = recorder
        return (engine, recorder)
    }

    private func run(_ engine: Engine, upTo limit: Int = 1000, until done: () -> Bool) -> Bool {
        for _ in 0..<limit {
            engine.tick()
            if done() { return true }
        }
        return false
    }

    func testSanFranciscoHasAnEarthquake() {
        let (engine, recorder) = scenario(.sanFrancisco)
        XCTAssertTrue(run(engine) { !recorder.earthquakes.isEmpty })
    }

    func testHamburgIsFirebombed() {
        let (engine, _) = scenario(.hamburg)
        XCTAssertEqual(fires(engine), 0)
        XCTAssertTrue(run(engine) { fires(engine) > 0 })
    }

    /// Judged by the "monster sighted" message (21), which always comes. The
    /// monster sprite itself is only visible in about a third of the runs;
    /// in the rest it is gone before it can be seen.
    func testTokyoHasAMonster() {
        let (engine, recorder) = scenario(.tokyo)
        XCTAssertTrue(run(engine) { recorder.messages.contains { $0.index == 21 } })
    }

    func testBostonHasAMeltdown() {
        let (engine, _) = scenario(.boston)
        XCTAssertEqual(radiation(engine), 0)
        XCTAssertTrue(run(engine) { radiation(engine) > 0 })
    }

    func testRioFloods() {
        let (engine, _) = scenario(.rio)
        XCTAssertEqual(floods(engine), 0)
        XCTAssertTrue(run(engine) { floods(engine) > 0 })
    }
}
