import AppKit
import ImageIO
import Testing
@testable import MicropolisKit
@testable import MicropolisMac

/// The code-drawn packages paint each building as one picture and slice it into tiles. These tests
/// check that slicing against buildings the engine actually placed in the bundled cities.
@MainActor
struct ProceduralLotLayoutTests {
    /// The tile a cell shows when it isn't animating, so animation frames count as their lot cell.
    /// A factory's two chimney tiles and both smoke sets turn up in either chimney cell in saved
    /// cities (zone.cpp setSmoke and the animation table), so they all count as the first chimney.
    private static let staticTile: [Int: Int] = {
        var map: [Int: Int] = [:]
        for animation in ProceduralAtlasBuilder.lotAnimations {
            for frame in animation.frames {
                map[frame] = animation.lot + animation.row * animation.size + animation.column
            }
        }
        for pair in ProceduralAtlasBuilder.interchangeableChimneys {
            map[pair.tile] = pair.sameAs
        }
        return map
    }()

    private func cell(_ cells: [UInt16], _ x: Int, _ y: Int) -> Int? {
        guard x >= 0, y >= 0, x < Engine.width, y < Engine.height else { return nil }
        let tile = Int(cells[x * Engine.height + y] & 0x3FF)
        return Self.staticTile[tile] ?? tile
    }

    @Test
    func everyPlacedBuildingMatchesItsDrawnLot() throws {
        var checked: [Int: Int] = [:]
        // bluebird.cty paints a picture with tiles instead of placing buildings, and the Hamburg
        // scenario ships one residential lot drawn over itself three rows down.
        let oddities: Set<String> = ["scenario_hamburg.cty 9,40"]
        for url in Assets.allCities where url.lastPathComponent != "bluebird.cty" {
            let model = GameModel(city: url, sound: RecordingSound(), seed: 1, runsTimer: false)
            let cells = model.engine.mapSnapshot()
            for x in 0..<Engine.width {
                for y in 0..<Engine.height {
                    guard let tile = cell(cells, x, y),
                          let lot = ProceduralAtlasBuilder.lots.first(where: { $0.base == tile }) else { continue }
                    // Skip buildings that are partly rubble, burning or have houses dropped into an empty lot:
                    // only whole buildings say anything about the layout.
                    let range = lot.base..<(lot.base + lot.size * lot.size)
                    let whole = (0..<lot.size).allSatisfy { row in
                        (0..<lot.size).allSatisfy { column in cell(cells, x + column, y + row).map(range.contains) ?? false }
                    }
                    guard whole, !oddities.contains("\(url.lastPathComponent) \(x),\(y)") else { continue }
                    for row in 0..<lot.size {
                        for column in 0..<lot.size {
                            let tile = lot.base + row * lot.size + column
                            let expected = Self.staticTile[tile] ?? tile
                            #expect(cell(cells, x + column, y + row) == expected,
                                    "\(url.lastPathComponent) lot \(lot.base) at \(x),\(y) cell \(column),\(row)")
                        }
                    }
                    checked[lot.size, default: 0] += 1
                }
            }
        }
        // The bundled cities include buildings of every size: 3×3 zones, 4×4 plants and stadiums, 6×6 airports.
        #expect(checked[3, default: 0] > 0)
        #expect(checked[4, default: 0] > 0)
        #expect(checked[6, default: 0] > 0)
    }

    /// The engine puts the sibling chimney tile in the animated chimney cell when a factory loses
    /// power, so the two tiles must be the same picture.
    @Test(arguments: [GraphicsPackage.plannersMap, .toyBlocks])
    func swappedChimneyTilesMatch(_ package: GraphicsPackage) throws {
        let atlas = try TileAtlas(atlasURL: Assets.tileAtlas, graphics: package)
        #expect(ProceduralAtlasBuilder.interchangeableChimneys.map(\.tile) == [644, 650, 677, 689])
        for pair in ProceduralAtlasBuilder.interchangeableChimneys {
            #expect(tilePixels(atlas, pair.tile) == tilePixels(atlas, pair.sameAs), "tile \(pair.tile) vs \(pair.sameAs)")
        }
    }

    private func tilePixels(_ atlas: TileAtlas, _ tile: Int) -> [UInt8] {
        let size = atlas.tileSize
        var out: [UInt8] = []
        for row in 0..<size {
            let start = (((tile / 32) * size + row) * 32 * size + (tile % 32) * size) * 4
            out += atlas.bytes[start..<(start + size * 4)]
        }
        return out
    }

    /// No drawn lot overlaps another, and each one stays inside the engine's tile range.
    @Test
    func lotsDoNotOverlap() {
        var owner: [Int: Int] = [:]
        for lot in ProceduralAtlasBuilder.lots {
            for tile in lot.base..<(lot.base + lot.size * lot.size) {
                #expect(owner[tile] == nil, "tile \(tile) in lots \(owner[tile] ?? -1) and \(lot.base)")
                #expect(tile < 1024)
                owner[tile] = lot.base
            }
        }
    }

    /// Writes a crop around the first stadium found, with and without a match on, for review:
    /// MICROPOLIS_CAPTURE_PROCEDURAL=/some/dir swift test --filter ProceduralLotLayoutTests
    @Test(.enabled(if: ProcessInfo.processInfo.environment["MICROPOLIS_CAPTURE_PROCEDURAL"] != nil))
    func captureBuildingCrops() throws {
        let directory = URL(fileURLWithPath: ProcessInfo.processInfo.environment["MICROPOLIS_CAPTURE_PROCEDURAL"]!)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        for (name, base) in [("stadium", 779), ("fullstadium", 795), ("airport", 709), ("nuclear", 811), ("port", 693)] {
            for url in Assets.allCities where url.lastPathComponent != "bluebird.cty" {
                let model = GameModel(city: url, sound: RecordingSound(), seed: 1, runsTimer: false)
                let cells = model.engine.mapSnapshot()
                guard let index = cells.indices.first(where: { cell(cells, $0 / Engine.height, $0 % Engine.height) == base })
                else { continue }
                let x = index / Engine.height, y = index % Engine.height
                for package in [GraphicsPackage.classic, .plannersMap, .toyBlocks] {
                    model.setGraphicsPackage(package)
                    model.renderer.update(cells: cells)
                    let map = try #require(model.renderer.makeImage())
                    let tile = model.tileAtlas.tileSize
                    let crop = try #require(map.cropping(to: CGRect(x: max(0, x - 3) * tile, y: max(0, y - 3) * tile,
                                                                     width: 12 * tile, height: 12 * tile)))
                    let out = directory.appendingPathComponent("\(name)-\(package.rawValue).png")
                    let destination = try #require(CGImageDestinationCreateWithURL(out as CFURL, "public.png" as CFString, 1, nil))
                    CGImageDestinationAddImage(destination, crop, nil)
                    #expect(CGImageDestinationFinalize(destination))
                }
                break
            }
        }
    }
}
