import XCTest
@testable import MicropolisKit

/// Shared setup for the tool and line-connection tests: a map cleared to
/// dirt, plenty of money, and the tile flags the tests set by hand.
enum ToolFixture {
    static let bulldozable: UInt16 = 0x1000
    static let burnable: UInt16 = 0x2000
    static let conductive: UInt16 = 0x4000
    static let animated: UInt16 = 0x0800
    static let zoneCenter: UInt16 = 0x0400

    static func engine(autoBulldoze: Bool = false) -> Engine {
        let engine = Engine(seed: 1)
        engine.generateMap(seed: 1)
        for x in 0..<Engine.width { for y in 0..<Engine.height { engine.setTile(x: x, y: y, cell: 0) } }
        engine.setFunds(1_000_000)
        engine.setAutoBulldoze(autoBulldoze)
        return engine
    }

    static func number(_ engine: Engine, _ x: Int, _ y: Int) -> Int { Int(engine.tile(x: x, y: y) & 0x3FF) }

    /// Puts a bare tile on the map, as a loaded city or an earlier tool would have.
    static func put(_ engine: Engine, _ x: Int, _ y: Int, _ tile: Int, flags: UInt16 = 0) {
        engine.setTile(x: x, y: y, cell: UInt16(tile) | flags)
    }

    /// Resets a square of the map to dirt.
    static func wipe(_ engine: Engine, x: ClosedRange<Int>, y: ClosedRange<Int>) {
        for xx in x { for yy in y { engine.setTile(x: xx, y: yy, cell: 0) } }
    }
}

/// Records what the query tool reports for a tile.
final class ZoneReportRecorder: EngineDelegate {
    struct Report { let category, density, landValue, crime, pollution, growth: Int }
    var reports: [Report] = []
    var sounds: [String] = []
    var tools: [String] = []
    func engineShowZoneStatus(category: Int, density: Int, landValue: Int, crime: Int, pollution: Int, growth: Int, x: Int, y: Int) {
        reports.append(Report(category: category, density: density, landValue: landValue, crime: crime, pollution: pollution, growth: growth))
    }
    func engineMakeSound(channel: String, sound: String, x: Int, y: Int) { sounds.append(sound) }
    func engineDidTool(name: String, x: Int, y: Int) { tools.append(name) }
}
