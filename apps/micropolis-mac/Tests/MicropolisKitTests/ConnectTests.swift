import XCTest
@testable import MicropolisKit

/// The auto-connecting road, rail and wire tools and the bulldozer's handling
/// of them (connect.cpp). Tile numbers are from the engine's Tiles enum.
final class ConnectTests: XCTestCase {
    private typealias F = ToolFixture

    // Tile numbers used below.
    private let hBridge = 64, vBridge = 65, roadH = 66, roadV = 67
    private let hRoadPower = 77, vRoadPower = 78
    private let hPower = 208, vPower = 209, wireH = 210, wireV = 211
    private let railHPowerV = 221, railVPowerH = 222
    private let hRail = 224, vRail = 225, railH = 226, railV = 227
    private let hRailRoad = 237, vRailRoad = 238
    private let line: UInt16 = 0x1000 | 0x2000   // bulldozable + burnable
    private let live: UInt16 = 0x1000 | 0x2000 | 0x4000   // plus conductive

    private func flags(for tile: Int) -> UInt16 {
        [wireH, wireV, hRoadPower, vRoadPower, railHPowerV, railVPowerH].contains(tile) ? live : line
    }

    // MARK: Auto-bulldoze before laying a line

    private let lines: [(tool: Tool, cost: Int, piece: Int)] = [
        (.road, 10, 66), (.railroad, 20, 226), (.wire, 5, 210),
    ]

    /// Trees, rubble and the explosion that follows a bulldozed building.
    private let clearable: [(name: String, tile: Int, flags: UInt16)] = [
        ("trees", 37, 0x3000), ("rubble", 44, 0x1000), ("rubble 47", 47, 0x1000),
        ("explosion", 860, 0x1800), ("explosion 867", 867, 0x1800),
    ]

    func testLinesLaidOverClearableTilesWithAutoBulldozeCostOneDollarMore() {
        for (tool, cost, piece) in lines {
            for (name, tile, tileFlags) in clearable {
                let engine = F.engine(autoBulldoze: true)
                F.put(engine, 50, 50, tile, flags: tileFlags)
                let funds = engine.funds
                XCTAssertEqual(engine.apply(tool, x: 50, y: 50), .ok, "\(tool) over \(name)")
                XCTAssertEqual(funds - engine.funds, cost + 1, "\(tool) over \(name)")
                XCTAssertEqual(F.number(engine, 50, 50), piece, "\(tool) over \(name)")
            }
        }
    }

    func testLinesCannotBeLaidOverClearableTilesWithoutAutoBulldoze() {
        for (tool, _, _) in lines {
            for (name, tile, tileFlags) in clearable {
                let engine = F.engine(autoBulldoze: false)
                F.put(engine, 50, 50, tile, flags: tileFlags)
                let (funds, map) = (engine.funds, engine.mapSnapshot())
                XCTAssertEqual(engine.apply(tool, x: 50, y: 50), .failed, "\(tool) over \(name)")
                XCTAssertEqual(engine.funds, funds)
                XCTAssertEqual(engine.mapSnapshot(), map)
            }
        }
    }

    /// Auto-bulldoze only clears tiles the bulldozer could clear.
    func testAutoBulldozeLeavesTilesThatAreNotBulldozable() {
        for (tool, _, _) in lines {
            let engine = F.engine(autoBulldoze: true)
            F.put(engine, 50, 50, 37, flags: 0x2000)   // trees without the bulldozable bit
            XCTAssertEqual(engine.apply(tool, x: 50, y: 50), .failed, "\(tool)")
            XCTAssertEqual(F.number(engine, 50, 50), 37)
        }
    }

    func testLinesNeverReplaceAnExistingRoadWithAutoBulldoze() {
        let engine = F.engine(autoBulldoze: true)
        F.put(engine, 50, 50, roadH, flags: line)
        XCTAssertEqual(engine.apply(.road, x: 50, y: 50), .failed)
        XCTAssertEqual(F.number(engine, 50, 50), roadH)
    }

    // MARK: Dozing lines

    func testBulldozingBridgesAndUnderwaterLinesLeavesWater() {
        // Bridges, drawbridge pieces, and underwater power and rail.
        let overWater = [64, 65, 79, 95, 828, 829, 830, 831, 948, 949, 950, 951, 208, 209, 224, 225]
        for tile in overWater {
            let engine = F.engine()
            F.put(engine, 50, 50, tile, flags: line)
            let funds = engine.funds
            XCTAssertEqual(engine.apply(.bulldozer, x: 50, y: 50), .ok, "tile \(tile)")
            XCTAssertEqual(F.number(engine, 50, 50), 2, "tile \(tile) should leave water")
            XCTAssertEqual(funds - engine.funds, 1, "tile \(tile)")
        }
    }

    func testBulldozingALineOnLandLeavesDirt() {
        for tile in [wireH, wireV, railH, railV, hRoadPower, vRailRoad, 70] {
            let engine = F.engine()
            F.put(engine, 50, 50, tile, flags: flags(for: tile))
            let funds = engine.funds
            XCTAssertEqual(engine.apply(.bulldozer, x: 50, y: 50), .ok, "tile \(tile)")
            XCTAssertEqual(F.number(engine, 50, 50), 0, "tile \(tile)")
            XCTAssertEqual(funds - engine.funds, 1, "tile \(tile)")
        }
    }

    func testBulldozingARoadReshapesItsNeighbors() {
        let engine = F.engine()
        for x in 49...51 { XCTAssertEqual(engine.apply(.road, x: x, y: 50), .ok) }
        XCTAssertEqual(F.number(engine, 49, 50), roadH)
        XCTAssertEqual(engine.apply(.bulldozer, x: 50, y: 50), .ok)
        XCTAssertEqual(F.number(engine, 50, 50), 0)
        XCTAssertEqual(F.number(engine, 49, 50), roadH, "a lone road piece is drawn straight")
        XCTAssertEqual(F.number(engine, 51, 50), roadH)
    }

    // MARK: Bridges and tunnels

    private typealias Neighbor = (dx: Int, dy: Int, tile: Int)

    /// Lays `tool` on the water tile at (50, 50) with one neighbor in place.
    private func layOnWater(_ tool: Tool, water: Int = 2, neighbor: Neighbor?) -> (engine: Engine, result: ToolResult, cost: Int) {
        let engine = F.engine()
        F.put(engine, 50, 50, water)
        if let n = neighbor { F.put(engine, 50 + n.dx, 50 + n.dy, n.tile, flags: flags(for: n.tile)) }
        let funds = engine.funds
        let result = engine.apply(tool, x: 50, y: 50)
        return (engine, result, funds - engine.funds)
    }

    func testRoadOverWaterBecomesABridgeAlongTheRoadItJoins() {
        let cases: [(name: String, neighbor: Neighbor, bridge: Int)] = [
            ("road to the east", (1, 0, roadH), hBridge),
            ("road to the west", (-1, 0, roadH), hBridge),
            ("road to the south", (0, 1, roadV), vBridge),
            ("road to the north", (0, -1, roadV), vBridge),
            ("rail crossing to the east", (1, 0, vRailRoad), hBridge),
            ("rail crossing to the south", (0, 1, hRailRoad), vBridge),
            ("power crossing to the north", (0, -1, vRoadPower), vBridge),
        ]
        for water in [2, 3, 4] {
            for (name, neighbor, bridge) in cases {
                let r = layOnWater(.road, water: water, neighbor: neighbor)
                XCTAssertEqual(r.result, .ok, "\(name) over tile \(water)")
                XCTAssertEqual(F.number(r.engine, 50, 50), bridge, "\(name) over tile \(water)")
                XCTAssertEqual(r.cost, 50, "a bridge costs $50, \(name)")
            }
        }
    }

    func testRoadOverWaterNeedsARoadToJoin() {
        for neighbor in [nil, Neighbor(1, 1, roadH), Neighbor(1, 0, wireH)] {
            let r = layOnWater(.road, neighbor: neighbor)
            XCTAssertEqual(r.result, .failed)
            XCTAssertEqual(r.cost, 0)
            XCTAssertEqual(F.number(r.engine, 50, 50), 2)
        }
    }

    func testRailOverWaterBecomesATunnelAlongTheRailItJoins() {
        let cases: [(name: String, neighbor: Neighbor, tunnel: Int)] = [
            ("rail to the east", (1, 0, railH), hRail),
            ("rail to the west", (-1, 0, railH), hRail),
            ("rail to the south", (0, 1, railH), vRail),
            ("rail to the north", (0, -1, railH), vRail),
            ("rail and power to the east", (1, 0, railHPowerV), hRail),
            ("rail crossing to the west", (-1, 0, hRailRoad), hRail),
            ("rail and power to the south", (0, 1, railVPowerH), vRail),
            ("rail crossing to the north", (0, -1, vRailRoad), vRail),
        ]
        for (name, neighbor, tunnel) in cases {
            let r = layOnWater(.railroad, neighbor: neighbor)
            XCTAssertEqual(r.result, .ok, name)
            XCTAssertEqual(F.number(r.engine, 50, 50), tunnel, name)
            XCTAssertEqual(r.cost, 100, "an underwater rail costs $100, \(name)")
        }
    }

    func testRailOverWaterNeedsARailToJoin() {
        for neighbor in [nil, Neighbor(1, 0, roadH), Neighbor(0, 1, wireH)] {
            let r = layOnWater(.railroad, neighbor: neighbor)
            XCTAssertEqual(r.result, .failed)
            XCTAssertEqual(r.cost, 0)
            XCTAssertEqual(F.number(r.engine, 50, 50), 2)
        }
    }

    func testWireOverWaterJoinsAConductiveNeighbor() {
        let cases: [(name: String, neighbor: Neighbor, piece: Int)] = [
            ("wire to the east", (1, 0, wireH), vPower),
            ("wire to the west", (-1, 0, wireH), vPower),
            ("wire to the south", (0, 1, wireH), hPower),
            ("wire to the north", (0, -1, wireH), hPower),
        ]
        for (name, neighbor, piece) in cases {
            let r = layOnWater(.wire, neighbor: neighbor)
            XCTAssertEqual(r.result, .ok, name)
            XCTAssertEqual(F.number(r.engine, 50, 50), piece, name)
            XCTAssertNotEqual(r.engine.tile(x: 50, y: 50) & 0x4000, 0, "\(name) conducts")
            XCTAssertEqual(r.cost, 25, "an underwater wire costs $25, \(name)")
        }
    }

    func testWireOverWaterNeedsAConductiveNeighbor() {
        // A road does not conduct, and the pieces that already run along
        // the same axis as the new wire are not joined from the side.
        let rejected: [Neighbor] = [
            (1, 0, roadH), (1, 0, hPower), (1, 0, hRoadPower), (1, 0, railHPowerV),
            (-1, 0, hPower), (-1, 0, hRoadPower), (-1, 0, railHPowerV),
            (0, 1, vPower), (0, 1, vRoadPower), (0, 1, railVPowerH),
            (0, -1, vPower), (0, -1, vRoadPower), (0, -1, railVPowerH),
        ]
        for neighbor in [nil] + rejected.map({ Optional($0) }) {
            let r = layOnWater(.wire, neighbor: neighbor)
            XCTAssertEqual(r.result, .failed, "\(String(describing: neighbor))")
            XCTAssertEqual(r.cost, 0)
            XCTAssertEqual(F.number(r.engine, 50, 50), 2)
        }
    }

    // MARK: Lines over other lines

    func testLinesLaidOverAnotherLineMakeACrossing() {
        // existing piece, tool, tile that results, cost
        let table: [(existing: Int, tool: Tool, result: Int, cost: Int)] = [
            (wireV, .road, hRoadPower, 10), (wireH, .road, vRoadPower, 10),
            (railH, .road, hRailRoad, 10), (railV, .road, vRailRoad, 10),
            (wireH, .railroad, railVPowerH, 20), (wireV, .railroad, railHPowerV, 20),
            (roadH, .railroad, vRailRoad, 20), (roadV, .railroad, hRailRoad, 20),
            (roadH, .wire, hRoadPower, 5), (roadV, .wire, vRoadPower, 5),
            (railH, .wire, railHPowerV, 5), (railV, .wire, railVPowerH, 5),
        ]
        for (existing, tool, expected, cost) in table {
            let engine = F.engine()
            F.put(engine, 50, 50, existing, flags: flags(for: existing))
            let funds = engine.funds
            XCTAssertEqual(engine.apply(tool, x: 50, y: 50), .ok, "\(tool) over \(existing)")
            XCTAssertEqual(F.number(engine, 50, 50), expected, "\(tool) over \(existing)")
            XCTAssertEqual(funds - engine.funds, cost, "\(tool) over \(existing)")
            let conducts = [hRoadPower, vRoadPower, railHPowerV, railVPowerH].contains(expected)
            XCTAssertEqual(engine.tile(x: 50, y: 50) & 0x4000 != 0, conducts, "\(tool) over \(existing)")
        }
    }

    func testALineCannotBeLaidOverItself() {
        for (tool, existing) in [(Tool.road, roadH), (.road, roadV), (.railroad, railH), (.railroad, railV), (.wire, wireH), (.wire, wireV),
                                 (.road, hRoadPower), (.railroad, hRailRoad), (.wire, vRailRoad)] {
            let engine = F.engine()
            F.put(engine, 50, 50, existing, flags: flags(for: existing))
            let (funds, map) = (engine.funds, engine.mapSnapshot())
            XCTAssertEqual(engine.apply(tool, x: 50, y: 50), .failed, "\(tool) over \(existing)")
            XCTAssertEqual(engine.funds, funds)
            XCTAssertEqual(engine.mapSnapshot(), map)
        }
    }

    func testLinesCannotBeLaidThroughABuilding() {
        for tool in [Tool.road, .railroad, .wire] {
            let engine = F.engine()
            XCTAssertEqual(engine.apply(.residential, x: 50, y: 50), .ok)
            let (funds, map) = (engine.funds, engine.mapSnapshot())
            XCTAssertEqual(engine.apply(tool, x: 50, y: 50), .failed, "\(tool)")
            XCTAssertEqual(engine.funds, funds)
            XCTAssertEqual(engine.mapSnapshot(), map)
        }
    }
}
