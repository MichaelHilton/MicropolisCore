import XCTest
import MicropolisEngine
@testable import MicropolisKit

/// Bulldozing, querying and paying for the big buildings, and the terrain
/// tools (tool.cpp). Lines and crossings are in ConnectTests.
final class BigBuildingToolTests: XCTestCase {
    private typealias F = ToolFixture

    private let buildings: [(tool: Tool, size: Int)] = [
        (.residential, 3), (.commercial, 3), (.industrial, 3),
        (.fireStation, 3), (.policeStation, 3),
        (.stadium, 4), (.seaport, 4), (.coalPower, 4), (.nuclearPower, 4), (.airport, 6),
    ]

    private func isExplosion(_ engine: Engine, _ x: Int, _ y: Int) -> Bool {
        (860...867).contains(F.number(engine, x, y))
    }

    // MARK: Bulldozing from each tile

    func testInvalidZoneFlagOnARoadDoesNotDemolishNearbyTiles() {
        let engine = F.engine()
        let recorder = ZoneReportRecorder()
        engine.delegate = recorder
        F.put(engine, 50, 50, 66, flags: F.zoneCenter | F.bulldozable)
        F.put(engine, 49, 50, 37, flags: F.bulldozable)
        let neighbor = engine.tile(x: 49, y: 50)
        let funds = engine.funds
        XCTAssertEqual(engine.apply(.bulldozer, x: 50, y: 50), .ok)
        XCTAssertEqual(F.number(engine, 50, 50), 0)
        XCTAssertEqual(engine.tile(x: 49, y: 50), neighbor)
        XCTAssertEqual(funds - engine.funds, 1)
        XCTAssertTrue(recorder.sounds.isEmpty)
    }

    func testBulldozingEveryFootprintTileLevelsTheWholeBuilding() {
        for (tool, size) in buildings {
            let engine = F.engine()
            let recorder = ZoneReportRecorder()
            engine.delegate = recorder
            for dy in 0..<size { for dx in 0..<size {
                F.wipe(engine, x: 40...60, y: 40...60)
                XCTAssertEqual(engine.apply(tool, x: 50, y: 50), .ok)
                let funds = engine.funds
                let before = engine.mapSnapshot()
                recorder.sounds.removeAll()
                XCTAssertEqual(engine.apply(.bulldozer, x: 49 + dx, y: 49 + dy), .ok, "\(tool) from (\(dx), \(dy))")
                XCTAssertEqual(funds - engine.funds, 1, "\(tool) from (\(dx), \(dy))")
                for x in 49..<(49 + size) { for y in 49..<(49 + size) {
                    XCTAssertTrue(isExplosion(engine, x, y), "\(tool) from (\(dx), \(dy)) left tile (\(x), \(y)) as \(F.number(engine, x, y))")
                } }
                XCTAssertEqual(F.number(engine, 48, 50), 0)
                XCTAssertEqual(F.number(engine, 49 + size, 50), 0)
                let after = engine.mapSnapshot()
                let changed = Set(zip(before, after).enumerated().compactMap { $0.element.0 != $0.element.1 ? $0.offset : nil })
                let footprint = Set((49..<(49 + size)).flatMap { x in
                    (49..<(49 + size)).map { y in x * Engine.height + y }
                })
                XCTAssertEqual(changed, footprint, "\(tool) from (\(dx),\(dy)) changed cells outside its footprint")
                let expected = size == 6 ? ["Explosion-High", "Explosion-Low"] : [size == 3 ? "Explosion-High" : "Explosion-Low"]
                XCTAssertEqual(recorder.sounds, expected, "\(tool) from (\(dx), \(dy))")
            } }
        }
    }

    func testBulldozingThe3x3CenterMakesAnExplosionSound() {
        let engine = F.engine()
        let recorder = ZoneReportRecorder()
        engine.delegate = recorder
        XCTAssertEqual(engine.apply(.fireStation, x: 50, y: 50), .ok)
        XCTAssertEqual(engine.apply(.bulldozer, x: 50, y: 50), .ok)
        XCTAssertEqual(recorder.sounds, ["Explosion-High"])
        XCTAssertEqual(recorder.tools.last, "Dozr")
    }

    /// The engine finds a building from the tile the player clicks on. The
    /// middle tile normally has the zone-center flag; if a city's tile lacks
    /// it, the bulldozer must still recognize the building.
    func testCenterTileWithoutTheZoneFlagStillLevelsTheBuilding() {
        let centers: [(tool: Tool, size: Int, tile: Int)] = [
            (.coalPower, 4, 750), (.seaport, 4, 698), (.nuclearPower, 4, 816), (.stadium, 4, 784), (.airport, 6, 716),
        ]
        for (tool, size, tile) in centers {
            let engine = F.engine()
            XCTAssertEqual(engine.apply(tool, x: 50, y: 50), .ok)
            F.put(engine, 50, 50, tile, flags: F.bulldozable)
            XCTAssertEqual(engine.apply(.bulldozer, x: 50, y: 50), .ok, "\(tool)")
            for x in 49..<(49 + size) { for y in 49..<(49 + size) {
                XCTAssertTrue(isExplosion(engine, x, y), "\(tool) left (\(x), \(y)) as \(F.number(engine, x, y))")
            } }
        }
    }

    /// The coal plant's smoke animation replaces one inner tile with four
    /// animation frames. Each must still count as part of the plant.
    func testBulldozingASmokeAnimationFrameLevelsTheCoalPlant() {
        for frame in 924...926 {
            let engine = F.engine()
            XCTAssertEqual(engine.apply(.coalPower, x: 50, y: 50), .ok)
            F.put(engine, 51, 50, frame, flags: F.bulldozable | F.animated)
            XCTAssertEqual(engine.apply(.bulldozer, x: 51, y: 50), .ok, "frame \(frame)")
            for x in 49...52 { for y in 49...52 {
                XCTAssertTrue(isExplosion(engine, x, y), "frame \(frame) left (\(x), \(y)) as \(F.number(engine, x, y))")
            } }
        }
    }

    /// The smoke animation cycles 924, 925, 926, 927, so a click that lands on
    /// the fourth frame is a click on the plant too.
    /// The chimney smoke cycles through four frames, 924 to 927; any of them
    /// levels the plant.
    func testBulldozingTheLastSmokeFrameLevelsTheCoalPlant() {
        let engine = F.engine()
        XCTAssertEqual(engine.apply(.coalPower, x: 50, y: 50), .ok)
        F.put(engine, 51, 50, 927, flags: F.bulldozable | F.animated)
        XCTAssertEqual(engine.apply(.bulldozer, x: 51, y: 50), .ok)
        for x in 49...52 { for y in 49...52 {
            XCTAssertTrue(isExplosion(engine, x, y), "left (\(x), \(y)) as \(F.number(engine, x, y))")
        } }
    }

    func testBulldozingTheAirportCenterLevelsTheAirport() {
        let engine = F.engine()
        XCTAssertEqual(engine.apply(.airport, x: 50, y: 50), .ok)
        let funds = engine.funds
        XCTAssertEqual(engine.apply(.bulldozer, x: 50, y: 50), .ok)
        XCTAssertEqual(funds - engine.funds, 1)
        for x in 49...54 { for y in 49...54 {
            XCTAssertTrue(isExplosion(engine, x, y), "left (\(x), \(y)) as \(F.number(engine, x, y))")
        } }
    }

    func testBulldozingTheEdgeOfABuildingShouldLevelIt() {
        let engine = F.engine()
        XCTAssertEqual(engine.apply(.stadium, x: 50, y: 50), .ok)
        XCTAssertEqual(engine.apply(.residential, x: 70, y: 50), .ok)
        XCTAssertEqual(engine.apply(.bulldozer, x: 49, y: 49), .ok, "stadium corner")
        XCTAssertEqual(engine.apply(.bulldozer, x: 69, y: 50), .ok, "house edge")
    }

    func testBulldozingAnOuterTileWithoutFundsIsAtomic() {
        for (tool, _) in buildings {
            let engine = F.engine()
            XCTAssertEqual(engine.apply(tool, x: 50, y: 50), .ok)
            engine.setFunds(0)
            let map = engine.mapSnapshot()
            XCTAssertEqual(engine.apply(.bulldozer, x: 49, y: 49), .noMoney, "\(tool)")
            XCTAssertEqual(engine.funds, 0)
            XCTAssertEqual(engine.mapSnapshot(), map, "\(tool)")
        }
    }

    func testBuildingDemolitionAtAllFourMapCorners() {
        for (tool, size) in buildings {
            let corners = [(1, 1, 0, 0), (Engine.width - size + 1, 1, size - 1, 0),
                           (1, Engine.height - size + 1, 0, size - 1),
                           (Engine.width - size + 1, Engine.height - size + 1, size - 1, size - 1)]
            for (cx, cy, dx, dy) in corners {
                let engine = F.engine()
                XCTAssertEqual(engine.apply(tool, x: cx, y: cy), .ok)
                engine.setFunds(1)
                XCTAssertEqual(engine.apply(.bulldozer, x: cx - 1 + dx, y: cy - 1 + dy), .ok, "\(tool) at (\(cx),\(cy))")
                XCTAssertEqual(engine.funds, 0)
                let footprint = Set(((cx - 1)..<(cx - 1 + size)).flatMap { x in
                    ((cy - 1)..<(cy - 1 + size)).map { y in x * Engine.height + y }
                })
                let occupied = Set(engine.mapSnapshot().enumerated().compactMap { $0.element != 0 ? $0.offset : nil })
                XCTAssertEqual(occupied, footprint, "\(tool) damaged tiles outside its footprint")
                for x in (cx - 1)..<(cx - 1 + size) { for y in (cy - 1)..<(cy - 1 + size) {
                    XCTAssertTrue(isExplosion(engine, x, y))
                } }
            }
        }
    }

    func testAdjacentBuildingIsNotDemolished() {
        let engine = F.engine()
        XCTAssertEqual(engine.apply(.residential, x: 50, y: 50), .ok)
        XCTAssertEqual(engine.apply(.airport, x: 53, y: 50), .ok)
        let neighbor = (49...51).flatMap { x in (49...51).map { engine.tile(x: x, y: $0) } }
        XCTAssertEqual(engine.apply(.bulldozer, x: 52, y: 49), .ok)
        XCTAssertEqual((49...51).flatMap { x in (49...51).map { engine.tile(x: x, y: $0) } }, neighbor)
        for x in 52...57 { for y in 49...54 {
            XCTAssertTrue(isExplosion(engine, x, y))
        } }
    }

    func testRoadOutsideBuildingFootprintDoesNotDemolishIt() {
        let engine = F.engine()
        XCTAssertEqual(engine.apply(.coalPower, x: 50, y: 50), .ok)
        F.put(engine, 53, 50, 66, flags: F.bulldozable)
        var expected = engine.mapSnapshot()
        expected[53 * Engine.height + 50] = 0
        let funds = engine.funds
        XCTAssertEqual(engine.apply(.bulldozer, x: 53, y: 50), .ok)
        XCTAssertEqual(engine.mapSnapshot(), expected)
        XCTAssertEqual(engine.funds, funds - 1)
    }

    func testAnimatedTilesStillBelongToTheirBuilding() {
        var cases: [(tool: Tool, size: Int, frame: Int, dx: Int, dy: Int)] = []
        for frame in 916...931 { // Four coal chimneys, four frames each.
            let chimney = (frame - 916) / 4
            cases.append((.coalPower, 4, frame, 1 + chimney % 2, -1 + chimney / 2))
        }
        for frame in 832...839 { cases.append((.airport, 6, frame, 1, -1)) }
        for frame in 932...947 { cases.append((.stadium, 4, frame, 1, frame < 940 ? 0 : 1)) }
        for (tool, size, frame, dx, dy) in cases {
            let engine = F.engine()
            XCTAssertEqual(engine.apply(tool, x: 50, y: 50), .ok)
            if tool == .stadium {
                F.put(engine, 50, 50, 800, flags: F.zoneCenter | F.burnable | F.conductive)
            }
            F.put(engine, 50 + dx, 50 + dy, frame, flags: F.animated | F.burnable | F.conductive)
            let funds = engine.funds
            XCTAssertEqual(engine.apply(.bulldozer, x: 50 + dx, y: 50 + dy), .ok, "frame \(frame)")
            XCTAssertEqual(engine.funds, funds - 1)
            for x in 49..<(49 + size) { for y in 49..<(49 + size) {
                XCTAssertTrue(isExplosion(engine, x, y), "frame \(frame) left (\(x),\(y))")
            } }
        }
    }

    func testResidentialHouseTilesUseTheOwningZone() {
        for tile in 249...260 {
            let engine = F.engine()
            XCTAssertEqual(engine.apply(.residential, x: 50, y: 50), .ok)
            F.put(engine, 51, 50, tile, flags: F.bulldozable | F.burnable)
            XCTAssertEqual(engine.apply(.bulldozer, x: 51, y: 50), .ok)
            for x in 49...51 { for y in 49...51 {
                XCTAssertTrue(isExplosion(engine, x, y), "house \(tile) left (\(x),\(y))")
            } }
        }
    }

    /// A water tile that carries the bulldozable flag can be dug out to dirt,
    /// at the bulldozer's $1 plus $5 for changing the water.
    func testBulldozingBulldozableWaterCostsExtra() {
        for water in [2, 3, 4] {
            let engine = F.engine()
            F.put(engine, 50, 50, water, flags: F.bulldozable)
            let funds = engine.funds
            XCTAssertEqual(engine.apply(.bulldozer, x: 50, y: 50), .ok, "tile \(water)")
            XCTAssertEqual(F.number(engine, 50, 50), 0, "tile \(water)")
            XCTAssertEqual(funds - engine.funds, 6, "tile \(water)")
        }
    }

    // MARK: Paying

    func testToolsRefuseWhenTheyCostMoreThanTheFunds() {
        let priced: [(Tool, Int)] = [
            (.residential, 100), (.commercial, 100), (.industrial, 100), (.fireStation, 500), (.policeStation, 500),
            (.stadium, 5000), (.seaport, 3000), (.coalPower, 3000), (.nuclearPower, 5000), (.airport, 10000),
            (.road, 10), (.wire, 5), (.railroad, 20), (.park, 10), (.network, 100),
        ]
        for (tool, cost) in priced {
            let engine = F.engine()
            engine.setFunds(cost - 1)
            let map = engine.mapSnapshot()
            XCTAssertEqual(engine.apply(tool, x: 50, y: 50), .noMoney, "\(tool)")
            XCTAssertEqual(engine.funds, cost - 1, "\(tool) charged anyway")
            XCTAssertEqual(engine.mapSnapshot(), map, "\(tool) built anyway")
        }
    }

    func testToolsWorkWhenTheFundsExactlyCoverTheCost() {
        let engine = F.engine()
        engine.setFunds(10)
        XCTAssertEqual(engine.apply(.road, x: 50, y: 50), .ok)
        XCTAssertEqual(engine.funds, 0)
        XCTAssertEqual(engine.apply(.road, x: 51, y: 50), .noMoney)
        XCTAssertEqual(F.number(engine, 51, 50), 0)
    }

    func testEveryToolFailsOffTheMap() {
        for tool in Tool.allCases {
            let engine = F.engine()
            let (funds, map) = (engine.funds, engine.mapSnapshot())
            for (x, y) in [(-1, 50), (Engine.width, 50), (50, -1), (50, Engine.height)] {
                XCTAssertEqual(engine.apply(tool, x: x, y: y), .failed, "\(tool) at (\(x), \(y))")
            }
            XCTAssertEqual(engine.funds, funds, "\(tool)")
            XCTAssertEqual(engine.mapSnapshot(), map, "\(tool)")
        }
    }

    /// The Swift enum cannot name an unknown tool, but the C function takes
    /// any number.
    func testAnUnknownToolNumberDoesNothing() {
        let handle = mp_create()!
        defer { mp_destroy(handle) }
        mp_set_funds(handle, 1_000_000)
        for tool: Int32 in [21, 99, -1] {
            XCTAssertEqual(mp_do_tool(handle, tool, 50, 50), Int32(ToolResult.failed.rawValue), "tool \(tool)")
        }
    }

    // MARK: Park and network

    func testParksPlantTreesOrAFountain() {
        let engine = F.engine()
        var fountains = 0
        // Each park rolls its picture at random. 100 parks from the fixed
        // seed are enough to include a fountain.
        for i in 0..<100 {
            let (x, y) = (10 + i % 50, 10 + i / 50 * 2)
            XCTAssertEqual(engine.apply(.park, x: x, y: y), .ok)
            let cell = engine.tile(x: x, y: y)
            let tile = Int(cell & 0x3FF)
            XCTAssertTrue((40...43).contains(tile) || tile == 840, "park showed tile \(tile)")
            if tile == 840 {
                fountains += 1
                XCTAssertNotEqual(cell & F.animated, 0, "a fountain animates")
            }
        }
        XCTAssertGreaterThan(fountains, 0)
    }

    func testParkNeedsBareDirt() {
        let engine = F.engine()
        F.put(engine, 50, 50, 66, flags: F.bulldozable)
        let (funds, map) = (engine.funds, engine.mapSnapshot())
        XCTAssertEqual(engine.apply(.park, x: 50, y: 50), .needBulldoze)
        XCTAssertEqual(engine.funds, funds)
        XCTAssertEqual(engine.mapSnapshot(), map)
    }

    func testNetworkClearsRubbleFirstButNotRoads() {
        let engine = F.engine()
        F.put(engine, 50, 50, 44, flags: F.bulldozable)
        let funds = engine.funds
        XCTAssertEqual(engine.apply(.network, x: 50, y: 50), .ok)
        XCTAssertEqual(funds - engine.funds, 101, "$100 network plus $1 to clear the rubble")
        XCTAssertEqual(F.number(engine, 50, 50), 844)

        F.put(engine, 60, 60, 66, flags: F.bulldozable)
        XCTAssertEqual(engine.apply(.network, x: 60, y: 60), .needBulldoze)
        XCTAssertEqual(F.number(engine, 60, 60), 66)
    }

    // MARK: Water, land and forest

    func testWaterToolFloodsARoadAndChargesTheBulldozer() {
        let engine = F.engine()
        XCTAssertEqual(engine.apply(.road, x: 50, y: 50), .ok)
        let funds = engine.funds
        XCTAssertEqual(engine.apply(.water, x: 50, y: 50), .ok)
        XCTAssertEqual(F.number(engine, 50, 50), 2)
        XCTAssertEqual(funds - engine.funds, 1)
    }

    func testWaterToolOnTreesMakesWater() {
        let engine = F.engine()
        F.put(engine, 50, 50, 37, flags: F.bulldozable | F.burnable)
        XCTAssertEqual(engine.apply(.water, x: 50, y: 50), .ok)
        XCTAssertEqual(F.number(engine, 50, 50), 2)
    }

    /// Dozing a bridge leaves water, and there is nothing more to flood.
    func testWaterToolOnABridgeChangesNothing() {
        let engine = F.engine()
        F.put(engine, 50, 50, 64, flags: F.bulldozable)
        let (funds, map) = (engine.funds, engine.mapSnapshot())
        XCTAssertEqual(engine.apply(.water, x: 50, y: 50), .failed)
        XCTAssertEqual(engine.funds, funds)
        XCTAssertEqual(engine.mapSnapshot(), map)
    }

    func testLandToolDrainsWaterForFree() {
        let engine = F.engine()
        engine.setFunds(0)
        for tile in 2...20 {
            for flags: UInt16 in [0, F.bulldozable] {
                F.put(engine, 50, 50, tile, flags: flags)
                XCTAssertEqual(engine.apply(.land, x: 50, y: 50), .ok, "water tile \(tile), flags \(flags)")
                XCTAssertEqual(F.number(engine, 50, 50), 0)
                XCTAssertEqual(engine.funds, 0)
            }
        }
    }

    func testLandToolClearsARoadAndChargesTheBulldozer() {
        let engine = F.engine()
        XCTAssertEqual(engine.apply(.road, x: 50, y: 50), .ok)
        let funds = engine.funds
        XCTAssertEqual(engine.apply(.land, x: 50, y: 50), .ok)
        XCTAssertEqual(F.number(engine, 50, 50), 0)
        XCTAssertEqual(funds - engine.funds, 1)
    }

    func testLandToolRequiresExactlyTheBulldozerCostForARoad() {
        for funds in [0, 1] {
            let engine = F.engine()
            XCTAssertEqual(engine.apply(.road, x: 50, y: 50), .ok)
            engine.setFunds(funds)
            let before = engine.mapSnapshot()
            let result = engine.apply(.land, x: 50, y: 50)
            if funds == 0 {
                XCTAssertEqual(result, .noMoney)
                XCTAssertEqual(engine.mapSnapshot(), before)
                XCTAssertEqual(engine.funds, 0)
            } else {
                XCTAssertEqual(result, .ok)
                XCTAssertEqual(F.number(engine, 50, 50), 0)
                XCTAssertEqual(engine.funds, 0)
            }
        }
    }

    func testLandToolRejectsBareDirtProtectedTilesAndOffMapClicks() {
        let engine = F.engine()
        F.put(engine, 60, 50, 66) // A road without the bulldozable flag.
        let before = engine.mapSnapshot()
        let funds = engine.funds
        for (x, y) in [(50, 50), (60, 50), (-1, 50), (Engine.width, 50),
                       (50, -1), (50, Engine.height)] {
            XCTAssertEqual(engine.apply(.land, x: x, y: y), .failed, "(\(x),\(y))")
            XCTAssertEqual(engine.mapSnapshot(), before)
            XCTAssertEqual(engine.funds, funds)
        }
    }

    func testLandToolClearsTreesAndBridgesForOneDollar() {
        let engine = F.engine()
        for tile in [37, 64] {
            F.put(engine, 50, 50, tile, flags: F.bulldozable)
            let before = engine.funds
            XCTAssertEqual(engine.apply(.land, x: 50, y: 50), .ok)
            XCTAssertEqual(F.number(engine, 50, 50), 0)
            XCTAssertEqual(engine.funds, before - 1)
        }
    }

    func testLandToolUsesWholeBuildingDemolitionBeforeClearingTheCenter() {
        let engine = F.engine()
        XCTAssertEqual(engine.apply(.residential, x: 50, y: 50), .ok)
        let before = engine.funds
        XCTAssertEqual(engine.apply(.land, x: 50, y: 50), .ok)
        XCTAssertEqual(engine.funds, before - 1)
        XCTAssertEqual(F.number(engine, 50, 50), 0)
        for x in 49...51 { for y in 49...51 where x != 50 || y != 50 {
            XCTAssertTrue(isExplosion(engine, x, y), "demolition left tile (\(x),\(y)) intact")
        } }
        XCTAssertEqual(F.number(engine, 48, 50), 0)
        XCTAssertEqual(F.number(engine, 52, 50), 0)
    }

    func testForestToolLeavesExistingTreesAlone() {
        let engine = F.engine()
        F.put(engine, 50, 50, 37, flags: F.bulldozable | F.burnable)
        let (funds, map) = (engine.funds, engine.mapSnapshot())
        XCTAssertEqual(engine.apply(.forest, x: 50, y: 50), .ok)
        XCTAssertEqual(engine.funds, funds)
        XCTAssertEqual(engine.mapSnapshot(), map)
    }

    func testForestToolReplacesARoadWithTrees() {
        let engine = F.engine()
        XCTAssertEqual(engine.apply(.road, x: 50, y: 50), .ok)
        let funds = engine.funds
        XCTAssertEqual(engine.apply(.forest, x: 50, y: 50), .ok)
        XCTAssertTrue((21...43).contains(F.number(engine, 50, 50)))
        XCTAssertEqual(funds - engine.funds, 1)
    }

    func testForestToolCannotPlantOnWaterOrAZone() {
        let engine = F.engine()
        F.put(engine, 50, 50, 2)
        XCTAssertEqual(engine.apply(.residential, x: 70, y: 50), .ok)
        let (funds, map) = (engine.funds, engine.mapSnapshot())
        XCTAssertEqual(engine.apply(.forest, x: 50, y: 50), .failed)
        XCTAssertEqual(engine.apply(.forest, x: 70, y: 50), .failed)
        XCTAssertEqual(engine.funds, funds)
        XCTAssertEqual(engine.mapSnapshot(), map)
    }

    // MARK: Query

    func testQueryingTheCoalPlantSmokeReportsACoalPlant() {
        let engine = F.engine()
        let recorder = ZoneReportRecorder()
        engine.delegate = recorder
        XCTAssertEqual(engine.apply(.coalPower, x: 50, y: 50), .ok)
        XCTAssertEqual(engine.apply(.query, x: 50, y: 50), .ok)
        let plant = recorder.reports[0].category
        for frame in [916, 920, 924, 928] {
            F.put(engine, 51, 50, frame, flags: F.animated)
            XCTAssertEqual(engine.apply(.query, x: 51, y: 50), .ok)
            XCTAssertEqual(recorder.reports.last?.category, plant, "smoke frame \(frame)")
        }
    }

    /// After a city has run for a while, querying its tiles reports every
    /// land-value class and every growth rate (report indexes 5-8 and 17-20).
    func testQueryReportsEveryLandValueAndGrowthRateInARunningCity() {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
        let engine = Engine(seed: 1)
        XCTAssertTrue(engine.loadCity(at: root.appendingPathComponent("content/micropolis/cities/haight.cty")))
        let recorder = ZoneReportRecorder()
        engine.delegate = recorder
        engine.setSpeed(3)
        // Fast growth shows up in this city after about 1,500 steps and fades
        // again, so look every 250 steps until all four have been seen.
        for _ in 0..<8 {
            for _ in 0..<250 { engine.tick() }
            for x in stride(from: 0, to: Engine.width, by: 2) {
                for y in stride(from: 0, to: Engine.height, by: 2) { _ = engine.apply(.query, x: x, y: y) }
            }
            if Set(recorder.reports.map(\.growth)).count == 4 { break }
        }
        XCTAssertEqual(Set(recorder.reports.map(\.landValue)), [5, 6, 7, 8])
        XCTAssertEqual(Set(recorder.reports.map(\.growth)), [17, 18, 19, 20])
    }
}
