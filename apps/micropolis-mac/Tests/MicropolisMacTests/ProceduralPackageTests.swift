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
