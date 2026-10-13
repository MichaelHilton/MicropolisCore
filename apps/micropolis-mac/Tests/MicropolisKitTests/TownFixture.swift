import XCTest
@testable import MicropolisKit

/// Builds big cities by writing fully grown zones straight into the map, so
/// that the advisor and score tests do not have to wait for growth.
///
/// Zones are packed in blocks of seven rows: a row of 3x3 zones, a road, and
/// another row of zones. Every zone touches the road, which stops the engine
/// from shrinking it for having no road access. A block holds 60 zones.
struct Town {
    enum Kind { case residential, commercial, industrial }

    /// Population units of one grown zone: 40 residential, 5 commercial
    /// (counted eight times in the city population), 4 industrial.
    static let zonesPerBlock = 60
    static let blocks = 14

    let engine: Engine
    private(set) var placed = 0

    init(_ engine: Engine) { self.engine = engine }

    /// The top-left tile of the densest zone of each kind.
    private static func base(_ kind: Kind) -> Int {
        switch kind {
        case .residential: return 288
        case .commercial: return 468
        case .industrial: return 648
        }
    }

    private static func centre(slot: Int) -> (x: Int, y: Int) {
        let block = slot / zonesPerBlock
        let within = slot % zonesPerBlock
        let row = within / 30
        let col = within % 30
        return (3 + 3 * col, block * 7 + (row == 0 ? 1 : 5))
    }

    /// Adds `count` grown zones, and the road beside each new block.
    mutating func add(_ kind: Kind, _ count: Int, roads: Bool = true) {
        for _ in 0..<count {
            precondition(placed < Town.zonesPerBlock * Town.blocks, "the map is full")
            if roads && placed % Town.zonesPerBlock == 0 { layRoad(block: placed / Town.zonesPerBlock) }
            let c = Town.centre(slot: placed)
            var tile = Town.base(kind)
            for dy in -1...1 {
                for dx in -1...1 {
                    engine.setTile(x: c.x + dx, y: c.y + dy, cell: UInt16(tile) | 0x6000)
                    tile += 1
                }
            }
            let cell = engine.tile(x: c.x, y: c.y)
            engine.setTile(x: c.x, y: c.y, cell: cell | 0x1400)
            placed += 1
        }
    }

    private func layRoad(block: Int) {
        let y = block * 7 + 3
        for x in 2...92 { _ = engine.apply(.road, x: x, y: y) }
    }
}

extension Engine {
    /// A cleared map with plenty of money and the simulation running.
    static func blankTown(autoBulldoze: Bool = false) -> Engine {
        let engine = ToolFixture.engine(autoBulldoze: autoBulldoze)
        engine.setSpeed(3)
        return engine
    }

    /// Ticks and returns the advisor message numbers sent meanwhile.
    func messageNumbers(ticks: Int, recorder: FullRecorder) -> [Int] {
        let first = recorder.messages.count
        for _ in 0..<ticks { tick() }
        return recorder.messages[first...].map(\.index)
    }
}
