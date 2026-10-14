import XCTest
@testable import MicropolisKit

/// The simulation loop (simulate.cpp), random disasters (disasters.cpp), the
/// terrain scans (scan.cpp) and zone growth (zone.cpp), judged by what the
/// player sees: the date, tiles, messages and overlays.
final class SimulationTests: XCTestCase {
    private func tiles(_ engine: Engine) -> [Int] { engine.mapSnapshot().map { Int($0 & 0x3FF) } }
    private func months(_ engine: Engine) -> Int { engine.year * 12 + engine.month }

    // MARK: Game speed

    /// Speed 1 and 2 run one simulation step in five and in three ticks.
    func testSlowSpeedsAdvanceTheCalendarMoreSlowly() {
        var elapsed: [Int] = []
        for speed in 1...3 {
            let engine = Engine(seed: 1)
            XCTAssertTrue(engine.loadCity(at: Repo.city("haight")))
            engine.setSpeed(speed)
            let start = months(engine)
            for _ in 0..<640 { engine.tick() }
            elapsed.append(months(engine) - start)
        }
        // 640 ticks are 640, 213 and 128 steps; a month is 64 steps.
        XCTAssertEqual(elapsed, [2, 4, 10])
    }

    // MARK: Random disasters

    /// Lays a map every random disaster can act on: a river edge column for
    /// floods, houses for fires, and a block of radioactive tiles whose
    /// pollution (the monster needs an average above 60) never goes away.
    private func disasterField(_ engine: Engine) {
        for x in 0..<Engine.width {
            for y in 0..<Engine.height {
                let cell: UInt16 = x == 60 ? 10 : (x < 25 ? 52 : 250 | 0x3000)
                engine.setTile(x: x, y: y, cell: cell)
            }
        }
    }

    /// The disaster that strikes is a roll of the dice, so this runs a fixed
    /// seed at the hardest level until every kind has been announced. They
    /// all show up within 16,000 ticks; that is also long enough for the
    /// simulation counter to wrap (1,024 steps of 16 ticks).
    func testEveryRandomDisasterIsAnnounced() {
        let engine = ToolFixture.engine()
        disasterField(engine)
        engine.setGameLevel(.hard)
        engine.setEnableDisasters(true)
        engine.setSpeed(3)
        let recorder = FullRecorder()
        engine.delegate = recorder
        let startMonths = months(engine)
        // fire 20, monster 21, tornado 22, earthquake 23, flooding 42
        let wanted: Set<Int> = [20, 21, 22, 23, 42]
        for tick in 0..<16_500 {
            engine.tick()
            // Disasters wreck the field; put it back now and then.
            if tick % 400 == 399 { disasterField(engine) }
        }
        let seen = Set(recorder.messages.map(\.index))
        XCTAssertTrue(wanted.isSubset(of: seen), "missing \(wanted.subtracting(seen))")
        XCTAssertFalse(recorder.earthquakes.isEmpty)
        // 16,500 ticks are more than 1,024 steps, and the calendar kept going.
        XCTAssertGreaterThan(months(engine) - startMonths, 250)
    }

    /// A flood that is over (no flood count left) drains away.
    func testFloodWaterDrainsAwayWhenTheFloodIsOver() {
        let engine = ToolFixture.engine()
        engine.setSpeed(3)
        for x in 10..<20 { for y in 10..<20 { ToolFixture.put(engine, x, y, 48) } }
        for _ in 0..<400 { engine.tick() }
        let left = tiles(engine).filter { (48...51).contains($0) }.count
        XCTAssertLessThan(left, 40, "most of the 100 flood tiles should have dried to dirt")
        XCTAssertEqual(ToolFixture.number(engine, 0, 0), 0)
    }

    // MARK: Roads and rails without upkeep

    /// With no money for roads, roads and rails slowly fall apart: a straight
    /// road tile washes away or turns to rubble.
    func testUnfundedRoadsAndRailsDeteriorate() {
        let engine = Engine.blankTown()
        var town = Town(engine)
        town.add(.residential, 5)
        // A river crosses both lines, so each has bridge tiles, which are
        // the ones that wash away rather than turn to rubble.
        for x in 40...49 { for y in 58...66 { ToolFixture.put(engine, x, y, 2) } }
        for x in 5...110 {
            XCTAssertEqual(engine.apply(.road, x: x, y: 60), .ok)
            XCTAssertEqual(engine.apply(.railroad, x: x, y: 64), .ok)
        }
        func intact(_ y: Int, _ range: ClosedRange<Int>) -> Int {
            (5...110).filter { range.contains(ToolFixture.number(engine, $0, y)) }.count
        }
        XCTAssertEqual(intact(60, 64...77), 106)
        XCTAssertEqual(intact(64, 224...239), 106)
        // The budget pays nothing for roads; the road effect follows the
        // year's spending once the percentage is set again.
        engine.setAutoBudget(false)
        engine.setRoadPercent(0)
        let year = engine.year
        var ticks = 0
        while engine.year == year && ticks < 2000 { engine.tick(); ticks += 1 }
        for _ in 0..<40 { engine.tick() }
        engine.setRoadPercent(0)
        for _ in 0..<3000 { engine.tick() }
        XCTAssertLessThan(intact(60, 64...77), 106, "some road should have crumbled")
        XCTAssertLessThan(intact(64, 224...239), 106, "some rail should have crumbled")
    }

    // MARK: Zones

    /// A tile above the last church with the zone bit set matches no kind of
    /// zone. The simulation reports it and leaves the tile alone.
    func testAZoneOfNoKnownKindIsLeftAlone() {
        let engine = ToolFixture.engine()
        let odd: UInt16 = 1020 | ToolFixture.zoneCenter | ToolFixture.bulldozable
        engine.setTile(x: 50, y: 50, cell: odd)
        engine.setSpeed(3)
        for _ in 0..<40 { engine.tick() }
        XCTAssertEqual(ToolFixture.number(engine, 50, 50), 1020)
    }

    /// Lays a powered strip of jobs and a road for new homes to grow beside.
    private func jobTown(_ engine: Engine) {
        XCTAssertEqual(engine.apply(.coalPower, x: 20, y: 44), .ok)
        for y in 44...48 { _ = engine.apply(.wire, x: 23, y: y) }
        for x in 23...75 { _ = engine.apply(.wire, x: x, y: 48) }
        for x in 20...75 { _ = engine.apply(.road, x: x, y: 52) }
        // Fully grown zones: industry on the left, shops in the middle.
        func grown(_ x: Int, base: Int) {
            var tile = base
            for dy in -1...1 { for dx in -1...1 {
                engine.setTile(x: x + dx, y: 50 + dy, cell: UInt16(tile) | 0x6000)
                tile += 1
            } }
            engine.setTile(x: x, y: 50, cell: engine.tile(x: x, y: 50) | 0x1400)
        }
        for x in stride(from: 40, through: 52, by: 3) { grown(x, base: 648) }
        for x in stride(from: 66, through: 72, by: 3) { grown(x, base: 468) }
    }

    /// Homes do not move into a zone whose air is thick with pollution, while
    /// an identical zone in clean air fills up with houses.
    func testNobodyMovesIntoAHeavilyPollutedZone() {
        let engine = Engine.blankTown()
        jobTown(engine)
        let clean = 30, dirty = 58
        XCTAssertEqual(engine.apply(.residential, x: clean, y: 50), .ok)
        XCTAssertEqual(engine.apply(.residential, x: dirty, y: 50), .ok)
        for _ in 0..<300 { engine.tick() }
        // Radioactive ground around the second site.
        for x in 54...62 { for y in 46...54 where ToolFixture.number(engine, x, y) == 0 { ToolFixture.put(engine, x, y, 52) } }
        for _ in 0..<1200 { engine.tick() }
        // A new home is a house on one of the eight tiles around an empty zone.
        func houses(_ cx: Int) -> Int {
            (-1...1).flatMap { dy in (-1...1).map { dx in ToolFixture.number(engine, cx + dx, 50 + dy) } }
                .filter { $0 >= 249 && $0 < 261 }.count
        }
        XCTAssertGreaterThan(houses(clean), 0, "homes should be built in the clean zone")
        XCTAssertEqual(houses(dirty), 0, "nobody moves into the polluted zone")
        XCTAssertGreaterThan(engine.overlay(.pollution)[dirty * Engine.height + 50], 128)
    }

    /// Pollution above 128 stops new homes even where the land value is high.
    /// The land value scan already subtracts pollution, so play never makes
    /// both high at once; the hooks pin both for the zone's centre tile before
    /// every tick. The control zone has the same land value and a clean sky.
    func testPollutionOverTheLimitStopsHomesEvenOnValuableLand() {
        let engine = Engine.blankTown()
        jobTown(engine)
        let clean = 30, dirty = 58
        XCTAssertEqual(engine.apply(.residential, x: clean, y: 50), .ok)
        XCTAssertEqual(engine.apply(.residential, x: dirty, y: 50), .ok)
        for _ in 0..<1500 {
            for (x, pollution) in [(clean, 100), (dirty, 129)] {
                engine.setLandValue(x: x, y: 50, 250)
                engine.setPollution(x: x, y: 50, pollution)
            }
            engine.tick()
        }
        func houses(_ cx: Int) -> Int {
            (-1...1).flatMap { dy in (-1...1).map { dx in ToolFixture.number(engine, cx + dx, 50 + dy) } }
                .filter { $0 >= 249 && $0 < 261 }.count
        }
        XCTAssertGreaterThan(houses(clean), 0, "homes should be built on valuable, clean land")
        XCTAssertEqual(houses(dirty), 0, "nobody moves into the polluted zone, however valuable the land")
    }

    // MARK: Fire and flood on a zone at the edge of the map

    /// Fire next to an airport at the east edge: the airport is a 6x6 zone, so
    /// burning it looks past the edge of the map. The airport goes up in flames
    /// and explodes.
    func testFireSpreadsToAnAirportAtTheEdgeOfTheMap() {
        let engine = ToolFixture.engine()
        // Only the zone centre matters to a fire: the airport tile with its
        // zone and burnable flags, one tile from the east edge.
        let cx = 117, cy = 50
        ToolFixture.put(engine, cx, cy, 716, flags: ToolFixture.zoneCenter | ToolFixture.burnable)
        engine.setSpeed(3)
        var exploded = false
        for tick in 0..<4000 {
            // Keep fires burning on three sides until one catches the airport.
            if tick % 50 == 0 {
                for (dx, dy) in [(-1, 0), (0, -1), (0, 1)] where ToolFixture.number(engine, cx + dx, cy + dy) < 56 {
                    ToolFixture.put(engine, cx + dx, cy + dy, 56)
                }
            }
            engine.tick()
            if (56...63).contains(ToolFixture.number(engine, cx, cy)) {
                exploded = engine.sprites().contains { $0.type == 7 }
                break
            }
        }
        XCTAssertTrue(exploded, "the airport should burn and explode")
    }

    // MARK: Loading odd city files

    /// Rewrites one 16-bit field of a city file's miscellaneous block (it
    /// begins after six 480-byte histories).
    private func patchedCity(_ fields: [Int: UInt16]) throws -> URL {
        var data = try Data(contentsOf: Repo.city("haight"))
        for (index, value) in fields {
            data[2880 + 2 * index] = UInt8(value >> 8)
            data[2880 + 2 * index + 1] = UInt8(value & 0xFF)
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("patched-\(UUID().uuidString).cty")
        try data.write(to: url)
        return url
    }

    /// A damaged file with nonsense in its header still loads, with sane values.
    func testLoadingACityWithNonsenseHeaderValuesRepairsThem() throws {
        let url = try patchedCity([
            1: 0,                       // external market
            8: 0xFFFF, 9: 0xFFFF, 10: 0xFFFF, 11: 0xFFFF,   // city time -1
            15: 99,                     // game level
            16: 99,                     // city class
            17: 0,                      // city score
        ])
        defer { try? FileManager.default.removeItem(at: url) }
        let engine = Engine(seed: 1)
        XCTAssertTrue(engine.loadCity(at: url))
        XCTAssertEqual(engine.year, 1900, "negative city time starts the clock over")
        XCTAssertEqual(engine.gameLevel, .easy)
        XCTAssertEqual(engine.cityClass, 0)
        XCTAssertEqual(engine.score, 500)
    }

    // MARK: Terrain smoothing with dithering

    /// The dithered terrain and pollution smoothing are an alternative to the
    /// plain one. Both give the same picture of a polluted spot: pollution
    /// peaks at the radioactive patch and is zero far away.
    func testDitheredSmoothingStillShowsPollutionNearItsSource() {
        for flags in [0, 1, 2, 4, 7] {
            let engine = ToolFixture.engine()
            for x in 60..<64 { for y in 50..<54 { ToolFixture.put(engine, x, y, 52) } }
            engine.setDonDither(flags)
            engine.setSpeed(3)
            for _ in 0..<400 { engine.tick() }
            let pollution = engine.overlay(.pollution)
            XCTAssertGreaterThan(pollution[61 * Engine.height + 51], 0, "dither \(flags)")
            XCTAssertEqual(pollution[5 * Engine.height + 5], 0, "dither \(flags)")
        }
    }
}
