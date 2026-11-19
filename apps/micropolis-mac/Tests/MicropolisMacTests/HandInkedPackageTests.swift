import AppKit
import CoreGraphics
import Foundation
import Testing
import MicropolisKit
@testable import MicropolisMac

@MainActor
struct HandInkedPackageTests {
    @Test
    func handInkedAtlasesLoadAtBothRuntimeSizesAndRejectOtherDimensions() throws {
        let cases: [(Int, Int)] = [(32, 1024), (64, 2048)]
        for (tileSize, edge) in cases {
            let atlas = try TileAtlas(
                atlasURL: Assets.handInkedAtlas(tileSize: tileSize),
                graphics: .handInked
            )
            #expect(atlas.tileSize == tileSize)
            #expect(atlas.tileCount == 1024)
            #expect(atlas.tilesPerRow == 32)
            #expect(atlas.bytes.count == edge * edge * 4)
            #expect(atlas.image(for: 1023).width == tileSize)
            #expect(atlas.image(for: 1023).height == tileSize)
        }

        do {
            _ = try TileAtlas(atlasURL: Assets.tileAtlas, graphics: .handInked)
            Issue.record("The 512×512 Classic atlas must not load as Hand-inked Town.")
        } catch TileAtlasError.invalidSize {
            // Expected: Hand-inked runtime atlases are 32 or 64 pixels per tile.
        }
    }

    @Test
    func packageManifestCoversTheCatalogAndPilotReplacements() throws {
        let manifestURL = Self.repositoryRoot
            .appendingPathComponent("content/micropolis/tilesets/hand-inked/manifest.json")
        let data = try Data(contentsOf: manifestURL)
        let root = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(root["schemaVersion"] as? Int == 1)
        #expect(root["tileCount"] as? Int == 1024)

        let tiles = try #require(root["tiles"] as? [[String: Any]])
        #expect(tiles.count == 1024)
        let byID = Dictionary(uniqueKeysWithValues: try tiles.map { tile -> (Int, [String: Any]) in
            let id = try #require(tile["id"] as? Int)
            return (id, tile)
        })
        #expect(byID.count == 1024)
        #expect(Set(byID.keys) == Set(0..<1024))
        for tile in tiles {
            #expect(["replacement", "fallback", "reserved"].contains(tile["status"] as? String ?? ""))
        }

        let expectedReplacementIDs = Set([0, 2, 4, 37] + Array(64...76) + [249])
        for id in expectedReplacementIDs {
            #expect(byID[id]?["status"] as? String == "replacement")
        }

        let groups = try #require(root["groups"] as? [[String: Any]])
        let groupByBase = Dictionary(uniqueKeysWithValues: try groups.map { group -> (Int, [String: Any]) in
            let base = try #require(group["base"] as? Int)
            return (base, group)
        })
        let expectedGroupSizes = [270: 3, 432: 3, 450: 3, 414: 3, 621: 3, 761: 3]
        for (base, size) in expectedGroupSizes {
            #expect(groupByBase[base]?["size"] as? Int == size)
            for id in base..<(base + size * size) {
                #expect(byID[id]?["status"] as? String == "replacement")
            }
        }
    }

    @Test
    func switchingClassicRetroAndHandInkedPreservesCityAndRedrawsOnce() throws {
        let model = GameModel(city: Assets.city("haight"), sound: RecordingSound(), seed: 1, runsTimer: false)
        let initialMap = model.engine.mapSnapshot()
        let initialFunds = model.engine.funds

        for package in [GraphicsPackage.retroSquare, .handInked, .classic, .handInked] {
            model.setGraphicsPackage(package)
            #expect(model.graphicsError == nil)
            #expect(model.graphicsPackage == package)
            #expect(model.engine.mapSnapshot() == initialMap)
            #expect(model.engine.funds == initialFunds)

            let renderer = try #require(model.renderer)
            renderer.update(cells: initialMap)
            #expect(renderer.lastRedrawCount == Engine.width * Engine.height)
            let image = try #require(renderer.makeImage())
            #expect(image.width == Engine.width * model.tileAtlas.tileSize)
            #expect(image.height == Engine.height * model.tileAtlas.tileSize)

            renderer.update(cells: initialMap)
            #expect(renderer.lastRedrawCount == 0)
        }
    }

    @Test
    func handInkedBuildingLotsReassembleTheirRowMajorRuntimeFragments() throws {
        for tileSize in [32, 64] {
            let atlas = try TileAtlas(
                atlasURL: Assets.handInkedAtlas(tileSize: tileSize),
                graphics: .handInked
            )
            for base in [270, 432, 450, 414, 621, 761] {
                let composite = try #require(atlas.buildingImage(base: base, size: 3))
                #expect(composite.width == 3 * tileSize)
                #expect(composite.height == 3 * tileSize)
                for row in 0..<3 {
                    for column in 0..<3 {
                        let rect = CGRect(
                            x: column * tileSize,
                            y: row * tileSize,
                            width: tileSize,
                            height: tileSize
                        )
                        let assembledFragment = try #require(composite.cropping(to: rect))
                        let atlasFragment = atlas.image(for: base + row * 3 + column)
                        #expect(Self.rgbaBytes(assembledFragment) == Self.rgbaBytes(atlasFragment))
                    }
                }
            }
        }
    }

    @Test
    func handInkedPlacementAndHitTestingKeepLogicalSixteenPointCells() throws {
        let model = GameModel(city: nil, sound: RecordingSound(), seed: 1, runsTimer: false)
        model.setGraphicsPackage(.handInked)
        #expect(model.graphicsError == nil)
        model.engine.setFunds(100_000)

        let view = MapNSView(gameModel: model)
        view.zoom = 2
        view.offset = CGPoint(x: 64, y: 32)
        model.selectedTool = .fireStation
        view.hover(at: CGPoint(x: 100, y: 80))

        #expect(view.tile(at: CGPoint(x: 100, y: 80))?.x == 5)
        #expect(view.tile(at: CGPoint(x: 100, y: 80))?.y == 3)
        #expect(view.toolOutline.frame == CGRect(x: 64, y: 32, width: 96, height: 96))
        #expect(model.engine.apply(.fireStation, x: 20, y: 20) == .ok)
        #expect(model.engine.tile(x: 19, y: 19) & 0x3FF == 761)
        #expect(model.engine.tile(x: 21, y: 21) & 0x3FF == 769)
        let fireStationPreview = try #require(model.tileAtlas.buildingImage(base: 761, size: 3))
        #expect(fireStationPreview.width == 96)
    }

    @Test
    func generatedLandscapeRendersAndOptionallySavesAHandInkedCrop() throws {
        let engine = Engine(seed: 42)
        engine.generateMap(seed: 42)
        let atlas = try TileAtlas(atlasURL: Assets.handInkedAtlas(tileSize: 32), graphics: .handInked)
        let renderer = MapRenderer(tileAtlas: atlas)
        renderer.update(cells: engine.mapSnapshot())
        #expect(renderer.lastRedrawCount == Engine.width * Engine.height)
        let image = try #require(renderer.makeImage())
        #expect(image.width == Engine.width * 32)
        #expect(image.height == Engine.height * 32)

        if let directory = ProcessInfo.processInfo.environment["MICROPOLIS_HAND_INKED_OUTPUT_DIR"] {
            let outputDirectory = URL(fileURLWithPath: directory, isDirectory: true)
            try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
            try Self.saveCrop(image, tileSize: 32, cellsWide: 48, name: "generated-landscape-hand-inked-32", to: outputDirectory)
        }
    }

    @Test(.enabled(
        if: ProcessInfo.processInfo.environment["MICROPOLIS_REPORT_SHORE_PROFILES"] == "1",
        "Set MICROPOLIS_REPORT_SHORE_PROFILES=1 to report generated shore-neighbor profiles."
    ))
    func reportSeededLandscapeShoreNeighborProfiles() {
        let engine = Engine(seed: 42)
        engine.generateMap(seed: 42)
        let directions = [("N", 0, -1), ("E", 1, 0), ("S", 0, 1), ("W", -1, 0)]
        for wantedID in [5, 9, 13, 17] {
            var occurrences = 0
            var dirtNeighbors = [String: Int](uniqueKeysWithValues: directions.map { ($0.0, 0) })
            var waterNeighbors = [String: Int](uniqueKeysWithValues: directions.map { ($0.0, 0) })
            for x in 0..<Engine.width {
                for y in 0..<Engine.height where Int(engine.tile(x: x, y: y) & 0x3FF) == wantedID {
                    occurrences += 1
                    for (side, dx, dy) in directions {
                        let nx = x + dx, ny = y + dy
                        guard nx >= 0, nx < Engine.width, ny >= 0, ny < Engine.height else { continue }
                        let neighbor = Int(engine.tile(x: nx, y: ny) & 0x3FF)
                        if neighbor == 0 { dirtNeighbors[side, default: 0] += 1 }
                        if neighbor == 2 || neighbor == 4 { waterNeighbors[side, default: 0] += 1 }
                    }
                }
            }
            print("SHORE_PROFILE id=\(wantedID) count=\(occurrences) dirt=\(dirtNeighbors) water=\(waterNeighbors)")
        }
    }

    @Test
    func pilotFixtureBanksShowWaterOnTheExpectedSides() {
        let engine = Self.makePilotFixture()
        let y = 5
        let westBank = Int(engine.tile(x: 18, y: y) & 0x3FF)
        let westBankWaterEast = Int(engine.tile(x: 19, y: y) & 0x3FF)
        let westBankWestNeighbor = Int(engine.tile(x: 17, y: y) & 0x3FF)
        #expect(westBank == 17)
        #expect(westBankWaterEast == 2)
        // Road tiles are non-DIRT and outside the woodland range, so they qualify
        // in the same source neighbor predicate as water. This bank also touches
        // the north-south road at x17.
        #expect(westBankWestNeighbor == 67)

        let eastBank = Int(engine.tile(x: 24, y: y) & 0x3FF)
        let eastBankWaterWest = Int(engine.tile(x: 23, y: y) & 0x3FF)
        let eastBankEastNeighbor = Int(engine.tile(x: 25, y: y) & 0x3FF)
        #expect(eastBank == 9)
        #expect(eastBankWaterWest == 2)
        #expect(eastBankEastNeighbor == 0)
    }

    @Test
    func seededGeneratedBanksUseNeighborMasksFromTheEngineTable() {
        let engine = Engine(seed: 42)
        engine.generateMap(seed: 42)
        let offsets = [(0, -1), (1, 0), (0, 1), (-1, 0)]
        let sourceMasks: [Int: Set<Int>] = [
            5: [4, 14], 9: [8, 13], 13: [0, 1, 11], 17: [2, 7]
        ]
        var observed: [Int: Int] = [:]
        let bankDirections: [Int: (water: Int, land: Int)] = [
            5: (2, 0), 9: (3, 1), 13: (0, 2), 17: (1, 3)
        ]
        var waterFacingClearland: [Int: Int] = [:]

        for x in 0..<Engine.width {
            for y in 0..<Engine.height {
                let tile = Int(engine.tile(x: x, y: y) & 0x3FF)
                let outputBase: Int
                switch tile {
                case 5, 6: outputBase = 5
                case 9, 10: outputBase = 9
                case 13, 14: outputBase = 13
                case 17, 18: outputBase = 17
                default: continue
                }
                guard let acceptedMasks = sourceMasks[outputBase] else { continue }
                var neighborMask = 0
                for (index, (dx, dy)) in offsets.enumerated() {
                    let nx = x + dx, ny = y + dy
                    guard nx >= 0, nx < Engine.width, ny >= 0, ny < Engine.height else { continue }
                    let neighbor = Int(engine.tile(x: nx, y: ny) & 0x3FF)
                    let isWoodland = (21...39).contains(neighbor)
                    if neighbor != 0 && !isWoodland { neighborMask |= 1 << index }
                }
                if acceptedMasks.contains(neighborMask) {
                    observed[outputBase, default: 0] += 1
                }
                let directions = bankDirections[outputBase]!
                let waterOffset = offsets[directions.water]
                let landOffset = offsets[directions.land]
                let wx = x + waterOffset.0, wy = y + waterOffset.1
                let lx = x + landOffset.0, ly = y + landOffset.1
                if wx >= 0, wx < Engine.width, wy >= 0, wy < Engine.height,
                   lx >= 0, lx < Engine.width, ly >= 0, ly < Engine.height {
                    let waterNeighbor = Int(engine.tile(x: wx, y: wy) & 0x3FF)
                    let oppositeLandNeighbor = Int(engine.tile(x: lx, y: ly) & 0x3FF)
                    if (waterNeighbor == 2 || waterNeighbor == 4) && oppositeLandNeighbor == 0 {
                        waterFacingClearland[outputBase, default: 0] += 1
                    }
                }
            }
        }

        for tile in sourceMasks.keys {
            #expect(observed[tile, default: 0] > 0)
            #expect(waterFacingClearland[tile, default: 0] > 0)
        }
    }

    @Test
    func runtimeShoreTilesKeepSourceOrientedGroundAndWaterPortsAtBothSizes() throws {
        // Seed-42 generated-map counts corroborate the source table: ID5 occurrences have
        // 65 south-water vs 15 north-DIRT neighbors; ID13 has 38 north-water vs 32 south-DIRT.
        // ID9 has 25 west-water vs 18 east-DIRT; ID17 has 45 east-water vs 35 west-DIRT.
        // The unusual extra neighbors come from source's non-DIRT/non-woods qualifier.
        let grass: [UInt8] = [180, 190, 166, 255]
        let water: [UInt8] = [159, 182, 200, 255]
        for tileSize in [32, 64] {
            let atlas = try TileAtlas(
                atlasURL: Assets.handInkedAtlas(tileSize: tileSize),
                graphics: .handInked
            )
            func pixel(tile: Int, x: Int, y: Int) -> [UInt8] {
                let tileX = (tile % 32) * tileSize
                let tileY = (tile / 32) * tileSize
                let offset = ((tileY + y) * 32 * tileSize + tileX + x) * 4
                return Array(atlas.bytes[offset..<(offset + 4)])
            }
            let middle = tileSize / 2
            #expect(pixel(tile: 17, x: 0, y: middle) == grass)
            #expect(pixel(tile: 17, x: tileSize - 1, y: middle) == water)
            #expect(pixel(tile: 9, x: 0, y: middle) == water)
            #expect(pixel(tile: 9, x: tileSize - 1, y: middle) == grass)
            #expect(pixel(tile: 5, x: middle, y: 0) == grass)
            #expect(pixel(tile: 5, x: middle, y: tileSize - 1) == water)
            #expect(pixel(tile: 13, x: middle, y: 0) == water)
            #expect(pixel(tile: 13, x: middle, y: tileSize - 1) == grass)
        }
    }

    @Test(.enabled(
        if: ProcessInfo.processInfo.environment["MICROPOLIS_RUN_HAND_INKED_BENCHMARKS"] == "1",
        "Set MICROPOLIS_RUN_HAND_INKED_BENCHMARKS=1 to run Hand-inked Town rendering benchmarks."
    ))
    func benchmarkHandInkedRuntimeSizesAndSaveOptionalCityCrops() throws {
        let outputDirectory = ProcessInfo.processInfo.environment["MICROPOLIS_HAND_INKED_OUTPUT_DIR"]
            .map { URL(fileURLWithPath: $0, isDirectory: true) }
        if let outputDirectory {
            try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
        }

        let variants: [(String, Int, URL)] = [
            ("classic", 16, Assets.tileAtlas),
            ("hand-inked", 32, Assets.handInkedAtlas(tileSize: 32)),
            ("hand-inked", 64, Assets.handInkedAtlas(tileSize: 64))
        ]
        for (name, tileSize, atlasURL) in variants {
            let atlas = try TileAtlas(atlasURL: atlasURL, graphics: name == "classic" ? .classic : .handInked)
            let engine = Engine(seed: 1)
            _ = engine.loadCity(at: Assets.city("haight"))
            let cells = engine.mapSnapshot()

            let redrawSamples = (0..<3).map { _ -> Double in
                let renderer = MapRenderer(tileAtlas: atlas)
                let start = Date()
                renderer.update(cells: cells)
                let elapsed = Date().timeIntervalSince(start) * 1_000
                #expect(renderer.lastRedrawCount == Engine.width * Engine.height)
                return elapsed
            }.sorted()

            let renderer = MapRenderer(tileAtlas: atlas)
            renderer.update(cells: cells)
            var incrementalSamples: [Double] = []
            var finalCells = cells
            for _ in 0..<12 {
                engine.tick()
                finalCells = engine.mapSnapshot()
                let start = Date()
                renderer.update(cells: finalCells)
                incrementalSamples.append(Date().timeIntervalSince(start) * 1_000)
            }
            let medianIncremental = incrementalSamples.sorted()[incrementalSamples.count / 2]
            let rendererBytes = Engine.width * Engine.height * tileSize * tileSize * 4
            print("METRIC hand_inked.\(name).\(tileSize).full_redraw_ms.median \(redrawSamples[1])")
            print("METRIC hand_inked.\(name).\(tileSize).incremental_update_ms.median \(medianIncremental)")
            print("METRIC hand_inked.\(name).\(tileSize).renderer_raw_bytes \(rendererBytes)")
            print("METRIC hand_inked.\(name).\(tileSize).atlas_raw_bytes \(atlas.bytes.count)")

            if let outputDirectory, let image = renderer.makeImage() {
                try Self.saveCrop(image, tileSize: tileSize, cellsWide: 48, name: "haight-\(name)-\(tileSize)", to: outputDirectory)
            }
        }

        if let outputDirectory {
            let fixture = Self.makePilotFixture()
            for tileSize in [32, 64] {
                let atlas = try TileAtlas(atlasURL: Assets.handInkedAtlas(tileSize: tileSize), graphics: .handInked)
                let renderer = MapRenderer(tileAtlas: atlas)
                renderer.update(cells: fixture.mapSnapshot())
                #expect(renderer.lastRedrawCount == Engine.width * Engine.height)
                if let image = renderer.makeImage() {
                    try Self.saveCrop(image, tileSize: tileSize, cellsWide: 26, cellsHigh: 18, name: "pilot-engine-\(tileSize)", to: outputDirectory, originCells: (0, 0))
                }
            }
            try Self.saveStaticFamilyBoards(to: outputDirectory)
            try Self.saveNetworkBoard(to: outputDirectory)
        }
    }

    /// Optional review artifacts use real engine tile IDs and road connections,
    /// so completed static building layouts can be judged at game size.
    private static func saveStaticFamilyBoards(to directory: URL) throws {
        let families = [
            ("commercial", Array(stride(from: 432, through: 603, by: 9)), 5, 3),
            ("industrial", Array(stride(from: 621, through: 684, by: 9)), 4, 3),
            ("civic-services", [405, 770, 761], 3, 3),
            ("power-stadium", [745, 811, 779, 795], 2, 4),
            ("seaport", [693], 1, 4),
            ("airport", [709], 1, 6),
            ("extended-churches", [956, 965, 974, 983, 992, 1001, 1010, 414], 4, 3)
        ]
        for (name, bases, columns, size) in families {
            let engine = Engine(seed: 42)
            engine.setFunds(1_000_000)
            let rows = (bases.count + columns - 1) / columns
            let stride = size + 2
            let width = columns * stride + 1, height = rows * stride + 1
            for x in 0..<Engine.width {
                for y in 0..<Engine.height { engine.setTile(x: x, y: y, cell: 0) }
            }
            for x in 0..<width {
                for y in 0..<height where x % stride == 0 || y % stride == 0 {
                    #expect(engine.apply(.road, x: x, y: y) == .ok)
                }
            }
            for (index, base) in bases.enumerated() {
                let x = (index % columns) * stride + 1, y = (index / columns) * stride + 2
                for row in 0..<size {
                    for col in 0..<size {
                        engine.setTile(x: x + col, y: y + row, cell: UInt16(base + row * size + col))
                    }
                }
            }
            for edge in [32, 64] {
                let atlas = try TileAtlas(atlasURL: Assets.handInkedAtlas(tileSize: edge), graphics: .handInked)
                let renderer = MapRenderer(tileAtlas: atlas)
                renderer.update(cells: engine.mapSnapshot())
                let image = try #require(renderer.makeImage())
                let crop = try #require(image.cropping(to: CGRect(x: 0, y: 0, width: width * edge, height: height * edge)))
                let png = try #require(NSBitmapImageRep(cgImage: crop).representation(using: .png, properties: [:]))
                try png.write(to: directory.appendingPathComponent("\(name)-family-engine-\(edge).png"), options: .atomic)
            }
        }
    }

    @Test
    func railAndPowerToolsProduceEverySourceShapeAndCrossing() throws {
        let cases: [(Tool, [Int])] = [
            (.railroad, [226,227,226,228,227,227,229,233,226,231,226,232,230,235,234,236]),
            (.wire, [210,211,210,212,211,211,213,217,210,215,210,216,214,219,218,220])
        ]
        for (tool, expected) in cases {
            let engine = Self.emptyNetworkEngine()
            for mask in 0..<16 {
                let x = 3 + mask % 4 * 5, y = 3 + mask / 4 * 5
                #expect(engine.apply(tool, x: x, y: y) == .ok)
                for (bit, dx, dy) in [(1,0,-1),(2,1,0),(4,0,1),(8,-1,0)] where mask & bit != 0 {
                    #expect(engine.apply(tool, x: x + dx, y: y + dy) == .ok)
                }
                #expect(Int(engine.tile(x: x, y: y) & 0x03ff) == expected[mask])
            }
        }
        let fixture = Self.networkFixture()
        for (x,y,id) in [(6,13,238),(22,13,77),(2,16,237),(8,16,221),(28,16,78),(24,16,222),
                         (6,21,224),(22,21,209),(3,22,225),(19,22,208)] {
            #expect(Int(fixture.tile(x: x, y: y) & 0x03ff) == id)
        }
    }

    private static func emptyNetworkEngine() -> Engine {
        let engine = Engine(seed: 42)
        engine.setFunds(1_000_000)
        for x in 0..<Engine.width { for y in 0..<Engine.height { engine.setTile(x: x, y: y, cell: 0) } }
        return engine
    }

    private static func networkFixture() -> Engine {
        let engine = Self.emptyNetworkEngine()
        var laid = Set<String>()
        func lay(_ tool: Tool, _ x: Int, _ y: Int) {
            let key = "\(tool)-\(x)-\(y)"
            guard laid.insert(key).inserted else { return }
            #expect(engine.apply(tool, x: x, y: y) == .ok)
        }
        for (tool,left,right,center) in [(Tool.railroad,2,10,6),(Tool.wire,18,26,22)] {
            for x in left...right { lay(tool,x,2); lay(tool,x,9) }
            for y in 3..<9 { lay(tool,left,y); lay(tool,right,y) }
            for y in 0...16 { lay(tool,center,y) }
        }
        for x in 1...29 { lay(.road,x,13) }
        for y in 10...17 { lay(.road,2,y); lay(.road,28,y) }
        for x in 1...10 { lay(.railroad,x,16) }
        for y in 14...18 { lay(.wire,8,y) }
        for x in 19...29 { lay(.wire,x,16) }
        for y in 14...18 { lay(.railroad,24,y) }
        for x in 6...8 { engine.setTile(x: x,y:21,cell:2) }
        for x in 22...24 { engine.setTile(x: x,y:21,cell:2) }
        for y in 22...23 { engine.setTile(x:3,y:y,cell:2); engine.setTile(x:19,y:y,cell:2) }
        for x in 1...13 { lay(.railroad,x,21) }
        for x in 17...29 { lay(.wire,x,21) }
        for y in 19...24 { lay(.railroad,3,y); lay(.wire,19,y) }
        return engine
    }

    private static func saveNetworkBoard(to directory: URL) throws {
        let engine = Self.networkFixture()
        for edge in [32,64] {
            let atlas = try TileAtlas(atlasURL: Assets.handInkedAtlas(tileSize: edge),graphics: .handInked)
            let renderer = MapRenderer(tileAtlas: atlas)
            renderer.update(cells: engine.mapSnapshot())
            let image = try #require(renderer.makeImage())
            try Self.saveCrop(image,tileSize:edge,cellsWide:31,cellsHigh:26,name:"rail-power-engine-\(edge)",to:directory,originCells:(0,0))
        }
    }

    private static var repositoryRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    private static func rgbaBytes(_ image: CGImage) -> [UInt8] {
        let bytesPerRow = image.width * 4
        var bytes = [UInt8](repeating: 0, count: bytesPerRow * image.height)
        guard let context = CGContext(
            data: &bytes,
            width: image.width,
            height: image.height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return [] }
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        return bytes
    }

    private static func saveCrop(_ image: CGImage, tileSize: Int, cellsWide: Int, cellsHigh: Int? = nil, name: String, to directory: URL, originCells: (Int, Int)? = nil) throws {
        let cropWidth = min(cellsWide * tileSize, image.width)
        let cropHeight = min((cellsHigh ?? cellsWide) * tileSize, image.height)
        let originX = originCells.map { $0.0 * tileSize } ?? (image.width - cropWidth) / 2
        let originY = originCells.map { $0.1 * tileSize } ?? (image.height - cropHeight) / 2
        let crop = try #require(image.cropping(to: CGRect(x: originX, y: originY, width: cropWidth, height: cropHeight)))
        let representation = NSBitmapImageRep(cgImage: crop)
        let png = try #require(representation.representation(using: .png, properties: [:]))
        let output = directory.appendingPathComponent("\(name).png")
        try png.write(to: output, options: .atomic)
        print("ARTIFACT hand_inked.preview \(output.path)")
    }

    private static func makePilotFixture() -> Engine {
        let engine = Engine(seed: 42)
        engine.generateMap(seed: 42)

        // Clear a compact 26×18 scene for the six 3×3 lots, single house, road grid, and shore.
        for x in 0..<26 {
            for y in 0..<20 { engine.setTile(x: x, y: y, cell: 0) }
        }

        // The 3×3 lots use the six pilot groups covered by the manifest test.
        for (base, x, y) in [
            (270, 1, 4), (432, 8, 4), (450, 13, 4),
            (414, 1, 10), (621, 8, 10), (761, 13, 10)
        ] {
            for row in 0..<3 {
                for column in 0..<3 {
                    engine.setTile(x: x + column, y: y + row, cell: UInt16(base + row * 3 + column))
                }
            }
        }
        engine.setTile(x: 4, y: 5, cell: 249)

        // A 5-cell river has banks aligned to the source-derived neighbor masks.
        for x in 19..<24 {
            for y in 0..<18 { engine.setTile(x: x, y: y, cell: 2) }
        }
        for y in 0..<18 {
            engine.setTile(x: 18, y: y, cell: 17) // water is east (mask 2)
            engine.setTile(x: 24, y: y, cell: 9)  // water is west (mask 8)
        }

        // Connected east-west road with a bridge over the river and north-south branches.
        for x in 0..<26 { engine.setTile(x: x, y: 7, cell: 66) }
        for x in 18..<25 { engine.setTile(x: x, y: 7, cell: 64) }
        for y in 0..<18 {
            engine.setTile(x: 6, y: y, cell: 67)
            engine.setTile(x: 17, y: y, cell: 67)
        }
        engine.setTile(x: 6, y: 7, cell: 76)
        engine.setTile(x: 17, y: 7, cell: 76)
        for x in 0..<18 { engine.setTile(x: x, y: 13, cell: 66) }
        engine.setTile(x: 6, y: 13, cell: 76)
        engine.setTile(x: 17, y: 13, cell: 75)

        return engine
    }
}
