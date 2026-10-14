import Darwin
import Foundation
import XCTest
import MicropolisEngine
@testable import MicropolisKit

/// Records the demand gauge and the advisor messages, which FullRecorder does not keep.
private final class GaugeRecorder: EngineDelegate {
    var demands: [(r: Float, c: Float, i: Float)] = []
    var messages: [Int] = []
    func engineUpdateDemand(residential: Float, commercial: Float, industrial: Float) {
        demands.append((residential, commercial, industrial))
    }
    func engineSendMessage(index: Int, x: Int, y: Int, picture: Bool, important: Bool) {
        messages.append(index)
    }
}

/// Small engine files: the city file reader and writer (fileio.cpp), the graph
/// ranges (graph.cpp), the valve gauge (update.cpp), the year rollover
/// (utilities.cpp), terrain generation (generate.cpp), and the C API (micropolis_c.cpp).
final class SmallFilesTests: XCTestCase {
    private var scratch: URL!

    override func setUp() {
        super.setUp()
        scratch = FileManager.default.temporaryDirectory
            .appendingPathComponent("SmallFiles-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: scratch, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: scratch)
        super.tearDown()
    }

    // MARK: Helpers

    /// Saves a generated map as a city file and returns its bytes, so a test can edit them.
    private func savedCityBytes() throws -> Data {
        let engine = Engine(seed: 1)
        engine.generateMap(seed: 1)
        let url = scratch.appendingPathComponent("base.cty")
        XCTAssertTrue(engine.saveCity(at: url))
        return try Data(contentsOf: url)
    }

    /// Byte offsets in a city file. Each history array holds 240 big-endian shorts,
    /// in the order residential, commercial, industrial, crime, pollution, money,
    /// and the misc array (valves, starting at index 5) follows them.
    private static func historyOffset(_ series: Int, index: Int) -> Int { series * 480 + index * 2 }
    private static func miscOffset(_ index: Int) -> Int { 6 * 480 + index * 2 }

    private func writeShort(_ data: inout Data, at offset: Int, _ value: Int) {
        let bits = UInt16(bitPattern: Int16(value))
        data[offset] = UInt8(bits >> 8)
        data[offset + 1] = UInt8(bits & 0xFF)
    }

    private func loadEdited(_ data: Data, seed: Int = 1) throws -> Engine {
        let url = scratch.appendingPathComponent("edited-\(UUID().uuidString).cty")
        try data.write(to: url)
        let engine = Engine(seed: seed)
        XCTAssertTrue(engine.loadCity(at: url))
        return engine
    }

    private func count(_ engine: Engine, tiles: ClosedRange<Int>) -> Int {
        engine.mapSnapshot().filter { tiles.contains(Int($0 & 0x3FF)) }.count
    }

    // MARK: Saving

    func testSaveToAnUnwritablePathFails() {
        let engine = Engine(seed: 1)
        engine.generateMap(seed: 1)
        let url = scratch.appendingPathComponent("no-such-folder/city.cty")
        XCTAssertFalse(engine.saveCity(at: url))
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
    }

    /// A file-size limit makes a write fail part way through, as a full disk does.
    /// The limit is restored and SIGXFSZ put back afterwards, so later tests are unaffected.
    func testSaveStopsWhenTheDiskRefusesAWrite() {
        let engine = Engine(seed: 1)
        engine.generateMap(seed: 2)
        let url = scratch.appendingPathComponent("full.cty")

        var original = rlimit()
        XCTAssertEqual(getrlimit(RLIMIT_FSIZE, &original), 0)
        var small = rlimit(rlim_cur: rlim_t(1024), rlim_max: original.rlim_max)
        let previousHandler = signal(SIGXFSZ, SIG_IGN)
        XCTAssertEqual(setrlimit(RLIMIT_FSIZE, &small), 0)
        defer {
            setrlimit(RLIMIT_FSIZE, &original)
            signal(SIGXFSZ, previousHandler)
        }

        XCTAssertFalse(engine.saveCity(at: url), "a short write should report failure")
    }

    // MARK: Loading a hand-edited city

    /// Negative history values are clamped to zero when a city loads, in both
    /// halves of the 240-point history (the 10-year and the 120-year ranges).
    func testNegativeHistoryIsClampedWhenACityLoads() throws {
        var data = try savedCityBytes()
        for series in 0..<3 {
            writeShort(&data, at: Self.historyOffset(series, index: 0), -5)
            writeShort(&data, at: Self.historyOffset(series, index: 120), -7)
            writeShort(&data, at: Self.historyOffset(series, index: 1), 9)
        }
        let engine = try loadEdited(data)

        for kind in [HistoryKind.residential, .commercial, .industrial] {
            let values = engine.history(kind)
            XCTAssertEqual(values[0], 0, "\(kind) 10-year range")
            XCTAssertEqual(values[120], 0, "\(kind) 120-year range")
            XCTAssertEqual(values[1], 9, "\(kind) positive values are kept")
        }
    }

    /// A residential valve outside the gauge's limit of 1500 is drawn at the limit,
    /// low and high. The residential range is 2000, so the saved value survives the
    /// load. Commercial and industrial are clamped to 1500 when the city loads, so
    /// their gauge clamps cannot be reached from a file.
    func testResidentialValveBeyondTheGaugeIsDrawnAtItsLimit() throws {
        for (setting, expected) in [(-1900, -1500), (1900, 1500)] {
            var data = try savedCityBytes()
            writeShort(&data, at: Self.miscOffset(5), setting)
            let recorder = GaugeRecorder()
            let engine = Engine(seed: 1)
            engine.delegate = recorder
            let url = scratch.appendingPathComponent("valves-\(setting).cty")
            try data.write(to: url)
            XCTAssertTrue(engine.loadCity(at: url))
            // At speed 0 the valves are not simulated, so one tick only redraws the gauge.
            engine.setSpeed(0)
            engine.tick()

            let drawn = try XCTUnwrap(recorder.demands.last, "the gauge was not redrawn")
            XCTAssertEqual(drawn.r, Float(expected), "residential valve \(setting)")
        }
    }

    // MARK: Scenarios

    /// The C API checks the resource folder before the engine opens its files.
    func testScenarioFailsWithoutItsCitiesFolder() {
        let engine = Engine(seed: 1)
        let yearBefore = engine.year
        XCTAssertFalse(engine.loadScenario(.dullsville, resourceDirectory: scratch))
        XCTAssertEqual(engine.year, yearBefore, "a failed load leaves the city alone")
    }

    // MARK: Year rollover

    /// Reaching year 1,000,000 sends the city back to its starting year with
    /// a message. The game clock stores 48 units per year.
    func testYearRollsBackToTheStartAtAMillion() {
        let engine = Engine(seed: 1)
        let recorder = GaugeRecorder()
        engine.delegate = recorder
        engine.setCityTime((1_000_000 - 1900) * 48)
        engine.tick()

        XCTAssertEqual(engine.year, 1900)
        XCTAssertEqual(engine.month, 0)
        // MESSAGE_NOT_ENOUGH_POWER, index 40 in text.h (the engine sends it on rollover).
        XCTAssertTrue(recorder.messages.contains(40), "rollover should send message 40")
    }

    // MARK: Terrain generation

    func testNoTerrainOptionsMakesAnEmptyMap() {
        let engine = Engine(seed: 1)
        setTerrain(engine, curve: 0, lake: 0, tree: 0, island: 0)
        engine.generateMap(seed: 3)
        XCTAssertEqual(count(engine, tiles: 2...20), 0, "no water")
        XCTAssertEqual(count(engine, tiles: 21...39), 0, "no trees")
    }

    func testLakeLevelMakesLakes() {
        let engine = Engine(seed: 1)
        setTerrain(engine, curve: 0, lake: 20, tree: 0, island: 0)
        engine.generateMap(seed: 3)
        XCTAssertGreaterThan(count(engine, tiles: 2...20), 0, "lake level 20 should make water")
    }

    func testRiverCurveLevelMakesRivers() {
        let engine = Engine(seed: 1)
        setTerrain(engine, curve: 5, lake: 0, tree: 0, island: 0)
        engine.generateMap(seed: 3)
        XCTAssertGreaterThan(count(engine, tiles: 2...20), 0, "curve level 5 should make rivers")
    }

    /// Splashes near the map edge walk off the map and stop early. A high tree
    /// level makes many splashes, so several seeds exercise that edge case.
    func testTreeLevelMakesTrees() {
        let engine = Engine(seed: 1)
        setTerrain(engine, curve: 0, lake: 0, tree: 100, island: 0)
        for seed in 1...3 {
            engine.generateMap(seed: seed)
            XCTAssertGreaterThan(count(engine, tiles: 21...39), 0, "seed \(seed) should have trees")
        }
    }

    /// The C API ignores a history kind it does not know, leaving the buffer alone.
    func testUnknownHistoryKindLeavesTheBufferUntouched() {
        let handle = mp_create()!
        defer { mp_destroy(handle) }
        var buffer = [Int16](repeating: 77, count: Int(MP_HISTORY_LENGTH))
        mp_get_history(handle, 99, &buffer)
        XCTAssertEqual(buffer, [Int16](repeating: 77, count: Int(MP_HISTORY_LENGTH)))
    }

    func testNakedIslandIsRingedByWaterWithLandInside() {
        let engine = Engine(seed: 1)
        setTerrain(engine, curve: 0, lake: 0, tree: 0, island: 1)
        engine.generateMap(seed: 1)
        XCTAssertTrue((2...20).contains(Int(engine.tile(x: 0, y: 0) & 0x3FF)), "map edge is water")
        XCTAssertGreaterThan(count(engine, tiles: 0...0), 1000, "the island is mostly dirt")
    }

    private func setTerrain(_ engine: Engine, curve: Int, lake: Int, tree: Int, island: Int) {
        engine.setTerrainCurve(curve)
        engine.setTerrainLake(lake)
        engine.setTerrainTree(tree)
        engine.setTerrainIsland(island)
    }
}
