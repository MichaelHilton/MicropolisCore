import AppKit
import ImageIO
import Testing
import MicropolisKit
@testable import MicropolisMac

@MainActor
struct ProceduralPackageTests {
    static let packages: [GraphicsPackage] = [.plannersMap, .toyBlocks]

    private func pixel(_ atlas: TileAtlas, tile: Int, x: CGFloat, y: CGFloat) -> RGB {
        let size = atlas.tileSize
        let px = (tile % 32) * size + min(Int(x * CGFloat(size)), size - 1)
        let py = (tile / 32) * size + min(Int(y * CGFloat(size)), size - 1)
        let offset = (py * 32 * size + px) * 4
        let bytes = atlas.bytes
        return RGB(r: CGFloat(bytes[offset]) / 255, g: CGFloat(bytes[offset + 1]) / 255, b: CGFloat(bytes[offset + 2]) / 255)
    }

    private func close(_ a: RGB, _ b: RGB, tolerance: CGFloat = 0.08) -> Bool {
        abs(a.r - b.r) < tolerance && abs(a.g - b.g) < tolerance && abs(a.b - b.b) < tolerance
    }

    @Test(arguments: packages)
    func atlasLoadsAtThirtyTwoPixelsAndIsDeterministic(_ package: GraphicsPackage) throws {
        let first = try TileAtlas(atlasURL: Assets.tileAtlas, graphics: package)
        let second = try TileAtlas(atlasURL: Assets.tileAtlas, graphics: package)
        #expect(first.tileSize == 32)
        #expect(first.bytes == second.bytes)
        #expect(throws: TileAtlasError.self) {
            _ = try TileAtlas(atlasURL: Assets.handInkedAtlas(tileSize: 32), graphics: package)
        }
    }

    @Test
    func theTwoStylesProduceDifferentArt() throws {
        let planner = try TileAtlas(atlasURL: Assets.tileAtlas, graphics: .plannersMap)
        let toy = try TileAtlas(atlasURL: Assets.tileAtlas, graphics: .toyBlocks)
        #expect(planner.bytes != toy.bytes)
    }

    /// Road and rail arms must reach the middle of exactly the edges the engine connects,
    /// so neighbouring tiles always join.
    @Test(arguments: packages)
    func networkArmsReachTheirConnectedEdges(_ package: GraphicsPackage) throws {
        let atlas = try TileAtlas(atlasURL: Assets.tileAtlas, graphics: package)
        let style = try #require(package.proceduralStyle)
        let edges: [(Int, CGFloat, CGFloat)] = [(1, 0.6, 0.01), (2, 0.99, 0.6), (4, 0.6, 0.99), (8, 0.01, 0.6)]
        for (offset, mask) in ProceduralAtlasBuilder.networkMasks.enumerated() {
            for (bit, x, y) in edges {
                let road = pixel(atlas, tile: 66 + offset, x: x, y: y)
                #expect(close(road, style.asphalt) == (mask & bit != 0), "road tile \(66 + offset) edge \(bit)")
                // Between the two rails, clear of the sleepers.
                let rail = pixel(atlas, tile: 226 + offset, x: x == 0.6 ? 0.5 : x, y: y == 0.6 ? 0.5 : y)
                #expect(close(rail, style.railBed) == (mask & bit != 0), "rail tile \(226 + offset) edge \(bit)")
            }
        }
    }

    @Test(arguments: packages)
    func shoreTilesPutLandOnTheirLandSides(_ package: GraphicsPackage) throws {
        let atlas = try TileAtlas(atlasURL: Assets.tileAtlas, graphics: package)
        let style = try #require(package.proceduralStyle)
        let edges: [(Int, CGFloat, CGFloat)] = [(1, 0.5, 0.03), (2, 0.97, 0.5), (4, 0.5, 0.97), (8, 0.03, 0.5)]
        for tile in 5...20 {
            let land = ProceduralAtlasBuilder.shoreLand(tile)
            for (bit, x, y) in edges {
                let sample = pixel(atlas, tile: tile, x: x, y: y)
                if land & bit != 0 {
                    #expect(!close(sample, style.water), "shore \(tile) edge \(bit) should be land")
                } else {
                    #expect(close(sample, style.water, tolerance: 0.2), "shore \(tile) edge \(bit) should be water")
                }
            }
        }
    }

    /// Animated cells re-render their own lot, so frames outside the moving part match the static cell.
    @Test(arguments: packages)
    func lotAnimationsStayInsideTheirLots(_ package: GraphicsPackage) throws {
        let atlas = try TileAtlas(atlasURL: Assets.tileAtlas, graphics: package)
        for animation in ProceduralAtlasBuilder.lotAnimations {
            let staticTile = animation.lot + animation.row * animation.size + animation.column
            for frame in animation.frames {
                // A corner of the cell away from smoke, radar and players keeps the lot's art.
                let a = pixel(atlas, tile: frame, x: 0.03, y: 0.97)
                let b = pixel(atlas, tile: staticTile, x: 0.03, y: 0.97)
                #expect(close(a, b, tolerance: 0.02), "frame \(frame) of lot \(animation.lot)")
            }
        }
    }

    /// Built lots carry a border in their type's color along their edges, like the classic tiles;
    /// buildings may overlap it in places, so most of each lot's edge samples must match.
    @Test(arguments: packages)
    func builtLotsHaveTypeColoredBorders(_ package: GraphicsPackage) throws {
        let atlas = try TileAtlas(atlasURL: Assets.tileAtlas, graphics: package)
        let style = try #require(package.proceduralStyle)
        let edge: CGFloat = style.extruded ? 0.06 : 0.05
        var framed = 0
        for lot in ProceduralAtlasBuilder.lots {
            guard let color = ProceduralAtlasBuilder.zoneFrameColor(lot.base, style: style) else {
                #expect([240, 423, 612].contains(lot.base), "lot \(lot.base) has no border color")
                continue
            }
            var hits = 0, samples = 0
            for i in 0..<lot.size {
                // Middle of each edge cell on all four sides: (tile, x, y) in tile units.
                let sides: [(Int, CGFloat, CGFloat)] = [
                    (lot.base + i, 0.5, edge),
                    (lot.base + (lot.size - 1) * lot.size + i, 0.5, 1 - edge),
                    (lot.base + i * lot.size, edge, 0.5),
                    (lot.base + i * lot.size + lot.size - 1, 1 - edge, 0.5),
                ]
                for (tile, x, y) in sides {
                    samples += 1
                    // Toy Blocks' kerb has a lighter face over a darker lip; either counts.
                    let sample = pixel(atlas, tile: tile, x: x, y: y)
                    if close(sample, color, tolerance: 0.12) || close(sample, color.darker(0.18), tolerance: 0.12) {
                        hits += 1
                    }
                }
            }
            #expect(Double(hits) / Double(samples) >= 0.6, "lot \(lot.base): \(hits) of \(samples) edge samples")
            framed += 1
        }
        #expect(framed == ProceduralAtlasBuilder.lots.count - 3)
    }

    @Test
    func borderColorsFollowTheClassicCode() {
        let style = ProceduralTileStyle.toyBlocks
        #expect(ProceduralAtlasBuilder.zoneFrameColor(261, style: style) == style.zoneR)
        #expect(ProceduralAtlasBuilder.zoneFrameColor(405, style: style) == style.zoneR)
        #expect(ProceduralAtlasBuilder.zoneFrameColor(779, style: style) == style.zoneR)
        #expect(ProceduralAtlasBuilder.zoneFrameColor(432, style: style) == style.zoneC)
        #expect(ProceduralAtlasBuilder.zoneFrameColor(770, style: style) == style.zoneC)
        #expect(ProceduralAtlasBuilder.zoneFrameColor(693, style: style) == style.zoneC)
        #expect(ProceduralAtlasBuilder.zoneFrameColor(621, style: style) == style.zoneI)
        #expect(ProceduralAtlasBuilder.zoneFrameColor(811, style: style) == style.zoneI)
        #expect(ProceduralAtlasBuilder.zoneFrameColor(761, style: style) == style.accent)
        #expect(ProceduralAtlasBuilder.zoneFrameColor(240, style: style) == nil)
        #expect(ProceduralAtlasBuilder.zoneFrameOpening(639) == .topOfLastColumn)
        #expect(ProceduralAtlasBuilder.zoneFrameOpening(648) == .rightOfFirstRow)
        #expect(ProceduralAtlasBuilder.zoneFrameOpening(621) == .none)
    }

    @Test(arguments: packages)
    func switchingPreservesTheCity(_ package: GraphicsPackage) throws {
        let model = GameModel(city: Assets.city("haight"), sound: RecordingSound(), seed: 1, runsTimer: false)
        let before = model.engine.mapSnapshot()
        model.setGraphicsPackage(package)
        #expect(model.graphicsError == nil)
        #expect(model.graphicsPackage == package)
        #expect(model.tileAtlas.tileSize == 32)
        #expect(model.engine.mapSnapshot() == before)
        model.renderer.update(cells: before)
        let image = try #require(model.renderer.makeImage())
        #expect(image.width == Engine.width * 32)
        model.setGraphicsPackage(.classic)
        #expect(model.tileAtlas.tileSize == 16)
    }

    /// Writes atlases and city renders for visual review:
    /// MICROPOLIS_CAPTURE_PROCEDURAL=/some/dir swift test --filter ProceduralPackageTests
    @Test(.enabled(if: ProcessInfo.processInfo.environment["MICROPOLIS_CAPTURE_PROCEDURAL"] != nil))
    func capturePreviews() throws {
        let directory = URL(fileURLWithPath: ProcessInfo.processInfo.environment["MICROPOLIS_CAPTURE_PROCEDURAL"]!)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        func write(_ image: CGImage, _ name: String) throws {
            let url = directory.appendingPathComponent(name)
            let destination = try #require(CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil))
            CGImageDestinationAddImage(destination, image, nil)
            #expect(CGImageDestinationFinalize(destination))
        }
        for package in Self.packages {
            let atlas = try TileAtlas(atlasURL: Assets.tileAtlas, graphics: package)
            let provider = try #require(CGDataProvider(data: Data(atlas.bytes) as CFData))
            let edge = atlas.tileSize * 32
            let atlasImage = try #require(CGImage(width: edge, height: edge, bitsPerComponent: 8, bitsPerPixel: 32,
                                                  bytesPerRow: edge * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                                  bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                                                  provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent))
            try write(atlasImage, "\(package.rawValue)-atlas.png")
            for city in ["haight", "kobe", "bern"] {
                let model = GameModel(city: Assets.city(city), sound: RecordingSound(), seed: 1, runsTimer: false)
                model.setGraphicsPackage(package)
                model.renderer.update(cells: model.engine.mapSnapshot())
                let map = try #require(model.renderer.makeImage())
                try write(map, "\(package.rawValue)-\(city).png")
            }
        }
    }
}
