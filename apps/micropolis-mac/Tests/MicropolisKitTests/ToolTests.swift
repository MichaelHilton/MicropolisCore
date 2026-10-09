import XCTest
@testable import MicropolisKit

/// The building tools and the auto-connecting lines (tool.cpp, connect.cpp),
/// driven through the Swift wrapper on a map cleared to dirt.
final class ToolTests: XCTestCase {
    private func clearEngine(autoBulldoze: Bool = false) -> Engine {
        let engine = Engine(seed: 1)
        engine.generateMap(seed: 1)
        for x in 0..<Engine.width { for y in 0..<Engine.height { engine.setTile(x: x, y: y, cell: 0) } }
        engine.setFunds(1_000_000)
        engine.setAutoBulldoze(autoBulldoze)
        return engine
    }

    private func number(_ engine: Engine, _ x: Int, _ y: Int) -> Int { Int(engine.tile(x: x, y: y) & 0x3FF) }

    private func lay(_ tool: Tool, _ engine: Engine, xs: ClosedRange<Int>, y: Int) {
        for x in xs { XCTAssertEqual(engine.apply(tool, x: x, y: y), .ok, "\(tool) at (\(x), \(y))") }
    }

    private func layColumn(_ tool: Tool, _ engine: Engine, x: Int, ys: ClosedRange<Int>, skipping skip: Int? = nil) {
        for y in ys where y != skip { XCTAssertEqual(engine.apply(tool, x: x, y: y), .ok, "\(tool) at (\(x), \(y))") }
    }

    // MARK: Every tool

    /// Tool, width of what it builds, and what it costs. The prices are the
    /// ones ToolSpec shows in the app.
    private let buildings: [(tool: Tool, size: Int, cost: Int)] = [
        (.residential, 3, 100), (.commercial, 3, 100), (.industrial, 3, 100),
        (.fireStation, 3, 500), (.policeStation, 3, 500),
        (.stadium, 4, 5000), (.seaport, 4, 3000), (.coalPower, 4, 3000), (.nuclearPower, 4, 5000),
        (.airport, 6, 10000),
    ]
    private let singles: [(tool: Tool, cost: Int)] = [
        (.road, 10), (.wire, 5), (.railroad, 20), (.park, 10),
    ]

    func testBuildingsFillTheirWholeFootprint() {
        for (tool, size, _) in buildings {
            let engine = clearEngine()
            XCTAssertEqual(engine.apply(tool, x: 50, y: 50), .ok, "\(tool)")
            for x in 49..<(49 + size) {
                for y in 49..<(49 + size) {
                    XCTAssertNotEqual(number(engine, x, y), 0, "\(tool) left (\(x), \(y)) as dirt")
                }
            }
            XCTAssertEqual(number(engine, 48, 50), 0, "\(tool) built outside its footprint")
            XCTAssertEqual(number(engine, 49 + size, 50), 0, "\(tool) built outside its footprint")
        }
    }

    func testSingleTileToolsChangeOnlyTheClickedTile() {
        for (tool, _) in singles {
            let engine = clearEngine()
            XCTAssertEqual(engine.apply(tool, x: 50, y: 50), .ok, "\(tool)")
            XCTAssertNotEqual(number(engine, 50, 50), 0, "\(tool)")
            let changed = engine.mapSnapshot().filter { $0 & 0x3FF != 0 }.count
            XCTAssertEqual(changed, 1, "\(tool)")
        }
    }

    func testToolsChargeTheDisplayedPrice() {
        for (tool, size, cost) in buildings {
            let engine = clearEngine()
            _ = size
            let before = engine.funds
            XCTAssertEqual(engine.apply(tool, x: 50, y: 50), .ok)
            XCTAssertEqual(before - engine.funds, cost, "\(tool)")
        }
        for (tool, cost) in singles {
            let engine = clearEngine()
            let before = engine.funds
            XCTAssertEqual(engine.apply(tool, x: 50, y: 50), .ok)
            XCTAssertEqual(before - engine.funds, cost, "\(tool)")
        }
    }

    func testQueryCostsAndChangesNothing() {
        let engine = clearEngine()
        let (funds, map) = (engine.funds, engine.mapSnapshot())
        XCTAssertEqual(engine.apply(.query, x: 50, y: 50), .ok)
        XCTAssertEqual(engine.funds, funds)
        XCTAssertEqual(engine.mapSnapshot(), map)
    }

    func testNetworkAndForestOnDirt() {
        let engine = clearEngine()
        let before = engine.funds
        XCTAssertEqual(engine.apply(.network, x: 40, y: 40), .ok)
        XCTAssertEqual(before - engine.funds, 100)
        XCTAssertNotEqual(number(engine, 40, 40), 0)
        XCTAssertEqual(engine.apply(.forest, x: 60, y: 60), .ok)
        XCTAssertTrue((21...43).contains(number(engine, 60, 60)), "forest plants trees")
    }

    /// The land and water tools run the bulldozer first, which has nothing to
    /// do on bare dirt, so they report failure there.
    func testLandAndWaterToolsNeedSomethingToClear() {
        let engine = clearEngine()
        let map = engine.mapSnapshot()
        XCTAssertEqual(engine.apply(.land, x: 50, y: 50), .failed)
        XCTAssertEqual(engine.apply(.water, x: 50, y: 50), .failed)
        XCTAssertEqual(engine.mapSnapshot(), map)
    }

    // MARK: Auto-connecting lines

    func testCrossingRoadsGetACrossingTile() {
        let engine = clearEngine()
        lay(.road, engine, xs: 48...52, y: 50)
        layColumn(.road, engine, x: 50, ys: 48...52, skipping: 50)
        let straight = number(engine, 49, 50)
        let vertical = number(engine, 50, 49)
        let crossing = number(engine, 50, 50)
        XCTAssertNotEqual(straight, vertical, "horizontal and vertical roads look different")
        XCTAssertNotEqual(crossing, straight)
        XCTAssertNotEqual(crossing, vertical)
        XCTAssertEqual(number(engine, 51, 50), straight, "the arm beyond the crossing is straight again")
    }

    func testCrossingRailGetsACrossingTile() {
        let engine = clearEngine()
        lay(.railroad, engine, xs: 48...52, y: 50)
        layColumn(.railroad, engine, x: 50, ys: 48...52, skipping: 50)
        XCTAssertNotEqual(number(engine, 50, 50), number(engine, 49, 50))
        XCTAssertNotEqual(number(engine, 50, 50), number(engine, 50, 49))
        XCTAssertNotEqual(number(engine, 49, 50), number(engine, 50, 49))
    }

    func testCrossingPowerLinesGetACrossingTileAndStayConductive() {
        let engine = clearEngine()
        lay(.wire, engine, xs: 48...52, y: 50)
        layColumn(.wire, engine, x: 50, ys: 48...52, skipping: 50)
        XCTAssertNotEqual(number(engine, 50, 50), number(engine, 49, 50))
        XCTAssertNotEqual(number(engine, 50, 50), number(engine, 50, 49))
        for x in 48...52 { XCTAssertNotEqual(engine.tile(x: x, y: 50) & 0x4000, 0, "wire at x=\(x) conducts") }
    }

    func testRoadAcrossAPowerLineIsAConductiveCrossing() {
        let engine = clearEngine()
        lay(.wire, engine, xs: 48...52, y: 50)
        layColumn(.road, engine, x: 50, ys: 48...52, skipping: 50)
        XCTAssertEqual(engine.apply(.road, x: 50, y: 50), .ok)
        let crossing = engine.tile(x: 50, y: 50)
        XCTAssertNotEqual(crossing & 0x3FF, 210, "no longer a bare power line")
        XCTAssertNotEqual(Int(crossing & 0x3FF), number(engine, 50, 49), "no longer a bare road")
        XCTAssertNotEqual(crossing & 0x4000, 0, "still conducts power")
    }

    func testPowerLineAcrossARoadIsAConductiveCrossing() {
        let engine = clearEngine()
        lay(.road, engine, xs: 48...52, y: 50)
        XCTAssertEqual(engine.apply(.wire, x: 50, y: 50), .ok)
        let crossing = engine.tile(x: 50, y: 50)
        XCTAssertNotEqual(Int(crossing & 0x3FF), number(engine, 49, 50))
        XCTAssertNotEqual(crossing & 0x4000, 0)
    }

    func testRailAcrossARoadMakesACrossing() {
        let engine = clearEngine()
        lay(.road, engine, xs: 48...52, y: 50)
        let road = number(engine, 49, 50)
        XCTAssertEqual(engine.apply(.railroad, x: 50, y: 50), .ok)
        XCTAssertNotEqual(number(engine, 50, 50), road)
        XCTAssertNotEqual(number(engine, 50, 50), 226, "not plain rail either")
    }

    func testRoadAcrossWaterIsABridge() {
        let engine = clearEngine()
        for x in 48...56 { for y in 48...56 { engine.setTile(x: x, y: y, cell: 2) } }
        lay(.road, engine, xs: 46...58, y: 52)
        let road = number(engine, 46, 52)
        let bridge = number(engine, 52, 52)
        XCTAssertNotEqual(bridge, 2, "water under the road is replaced")
        XCTAssertNotEqual(bridge, road, "a bridge looks different from a road")
        XCTAssertEqual(number(engine, 58, 52), road)
    }

    // MARK: Bulldozer

    func testBulldozerClearsARoad() {
        let engine = clearEngine()
        _ = engine.apply(.road, x: 50, y: 50)
        let before = engine.funds
        XCTAssertEqual(engine.apply(.bulldozer, x: 50, y: 50), .ok)
        XCTAssertEqual(number(engine, 50, 50), 0)
        XCTAssertEqual(before - engine.funds, 1)
    }

    func testBulldozerLevelsAWholeZone() {
        let engine = clearEngine()
        _ = engine.apply(.residential, x: 50, y: 50)
        XCTAssertEqual(engine.apply(.bulldozer, x: 50, y: 50), .ok)
        for x in 49...51 {
            for y in 49...51 {
                let cell = engine.tile(x: x, y: y)
                XCTAssertEqual(cell & 0x0400, 0, "(\(x), \(y)) is still a zone center")
                XCTAssertFalse((240..<423).contains(Int(cell & 0x3FF)), "(\(x), \(y)) is still a house")
            }
        }
    }

    func testBulldozerClearsTrees() {
        let engine = clearEngine()
        engine.setTile(x: 50, y: 50, cell: 37 | 0x3000)
        XCTAssertEqual(engine.apply(.bulldozer, x: 50, y: 50), .ok)
        XCTAssertEqual(number(engine, 50, 50), 0)
    }

    func testBulldozerCannotClearWater() {
        let engine = clearEngine()
        engine.setTile(x: 50, y: 50, cell: 2)
        let funds = engine.funds
        XCTAssertEqual(engine.apply(.bulldozer, x: 50, y: 50), .failed)
        XCTAssertEqual(engine.funds, funds)
        XCTAssertEqual(number(engine, 50, 50), 2)
    }

    func testBulldozerOnDirtDoesNothing() {
        let engine = clearEngine()
        let funds = engine.funds
        XCTAssertEqual(engine.apply(.bulldozer, x: 50, y: 50), .failed)
        XCTAssertEqual(engine.funds, funds)
    }

    // MARK: Query

    func testQueryNamesTheKindOfZone() {
        let engine = clearEngine()
        let recorder = FullRecorder()
        engine.delegate = recorder
        // Category numbers are the engine's 1-based tile categories.
        for (tool, x, category) in [(Tool.residential, 30, 11), (.commercial, 50, 12), (.industrial, 70, 13)] {
            XCTAssertEqual(engine.apply(tool, x: x, y: 50), .ok)
            recorder.zoneStatuses.removeAll()
            XCTAssertEqual(engine.apply(.query, x: x, y: 50), .ok)
            XCTAssertEqual(recorder.zoneStatuses.map(\.category), [category], "\(tool)")
        }
    }

    func testQueryOnDirtStillReports() {
        let engine = clearEngine()
        let recorder = FullRecorder()
        engine.delegate = recorder
        XCTAssertEqual(engine.apply(.query, x: 50, y: 50), .ok)
        XCTAssertEqual(recorder.zoneStatuses.count, 1)
        XCTAssertFalse([11, 12, 13].contains(recorder.zoneStatuses[0].category), "dirt is not a zone")
    }

    // MARK: Placement failures

    func testBuildingsNeedTheirWholeFootprintOnTheMap() {
        let engine = clearEngine()
        // Buildings of size 3 and up put their top-left tile one in from the
        // click, so a click on column 0 hangs off the left edge and a 4x4
        // clicked at column 118 hangs off the right.
        XCTAssertEqual(engine.apply(.stadium, x: 0, y: 50), .failed)
        XCTAssertEqual(engine.apply(.stadium, x: 118, y: 50), .failed)
        XCTAssertEqual(engine.apply(.stadium, x: 50, y: 0), .failed)
        XCTAssertEqual(engine.apply(.stadium, x: 50, y: 98), .failed)
        XCTAssertEqual(engine.apply(.airport, x: 0, y: 20), .failed)
        XCTAssertEqual(engine.apply(.airport, x: 116, y: 20), .failed)
        XCTAssertEqual(engine.mapSnapshot().filter { $0 & 0x3FF != 0 }.count, 0, "failures changed nothing")
    }

    func testBuildingFlushWithTheEdgeSucceeds() {
        let engine = clearEngine()
        XCTAssertEqual(engine.apply(.stadium, x: 1, y: 50), .ok)
        XCTAssertEqual(engine.apply(.stadium, x: 117, y: 50), .ok)
        XCTAssertEqual(engine.apply(.airport, x: 1, y: 20), .ok)
        XCTAssertEqual(engine.apply(.airport, x: 115, y: 20), .ok)
    }

    func testBuildingOverAZoneNeedsTheBulldozer() {
        for autoBulldoze in [false, true] {
            let engine = clearEngine(autoBulldoze: autoBulldoze)
            _ = engine.apply(.residential, x: 50, y: 50)
            let map = engine.mapSnapshot()
            XCTAssertEqual(engine.apply(.commercial, x: 51, y: 50), .needBulldoze, "auto-bulldoze \(autoBulldoze)")
            XCTAssertEqual(engine.mapSnapshot(), map)
        }
    }

    func testAutoBulldozeClearsTreesForABuilding() {
        let engine = clearEngine(autoBulldoze: true)
        engine.setTile(x: 50, y: 50, cell: 37 | 0x3000)
        let before = engine.funds
        XCTAssertEqual(engine.apply(.residential, x: 50, y: 50), .ok)
        XCTAssertEqual(before - engine.funds, 100 + 1, "the building plus one bulldozer charge")
    }
}
