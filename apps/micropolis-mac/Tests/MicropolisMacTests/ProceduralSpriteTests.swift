import AppKit
import ImageIO
import Testing
@testable import MicropolisKit
@testable import MicropolisMac

@MainActor
struct ProceduralSpriteTests {
    static let packages: [GraphicsPackage] = [.plannersMap, .toyBlocks]

    private func opaquePixels(_ image: CGImage) -> Int {
        let width = image.width, height = image.height
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        let context = CGContext(data: &bytes, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                                space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        return stride(from: 3, to: bytes.count, by: 4).filter { bytes[$0] > 40 }.count
    }

    /// Every frame the engine can ask for has art, including the plane's take-off frames 9–11
    /// that the classic sheet lacks.
    @Test(arguments: packages)
    func everyEngineFrameIsDrawn(_ package: GraphicsPackage) throws {
        let sheets = try ProceduralSpriteBuilder.makeSheets(style: try #require(package.proceduralStyle))
        for kind in ProceduralSpriteBuilder.kinds {
            let sheet = try #require(sheets[kind.type])
            #expect(sheet.frameCount == kind.frames)
            #expect(sheet.frameSize == kind.size)
            for frame in 1...kind.frames {
                let image = try #require(sheet.image(for: frame))
                #expect(image.width == kind.size * ProceduralSpriteBuilder.scale)
                #expect(opaquePixels(image) > image.width * image.height / 40, "type \(kind.type) frame \(frame)")
            }
            #expect(sheet.image(for: kind.frames + 1) == nil)
        }
    }

    @Test
    func directionalFramesFollowTheEngine() {
        #expect(ProceduralSpriteBuilder.heading(1) == 0)
        #expect(ProceduralSpriteBuilder.heading(3) == .pi / 2)
        #expect(ProceduralSpriteBuilder.heading(7) == 3 * .pi / 2)
        #expect(ProceduralSpriteBuilder.trainAngle(1) == 0)
        #expect(ProceduralSpriteBuilder.trainAngle(2) == .pi / 2)
        // Monster: 1–3 NE, 4–6 SE, 7–9 SW, 10–12 NW, then N, E, S, W.
        #expect(ProceduralSpriteBuilder.monsterPose(2) == (.pi / 4, 0))
        #expect(ProceduralSpriteBuilder.monsterPose(5).heading == 3 * .pi / 4)
        #expect(ProceduralSpriteBuilder.monsterPose(11).heading == 7 * .pi / 4)
        #expect(ProceduralSpriteBuilder.monsterPose(14).heading == .pi / 2)
        #expect(ProceduralSpriteBuilder.monsterPose(1).step == -ProceduralSpriteBuilder.monsterPose(3).step)
    }

    @Test
    func sheetsAreDeterministicAndDifferByStyle() throws {
        let kind = ProceduralSpriteBuilder.kinds[2]
        let a = try ProceduralSpriteBuilder.makeImage(kind, style: .plannersMap)
        let b = try ProceduralSpriteBuilder.makeImage(kind, style: .plannersMap)
        let toy = try ProceduralSpriteBuilder.makeImage(kind, style: .toyBlocks)
        #expect(a.dataProvider?.data == b.dataProvider?.data)
        #expect(a.dataProvider?.data != toy.dataProvider?.data)
    }

    /// High-resolution frames still cover their engine size on the map.
    @Test(arguments: packages)
    func spritesKeepTheirMapSize(_ package: GraphicsPackage) throws {
        let renderer = SpriteRenderer()
        try renderer.setGraphics(package)
        let parent = CALayer()
        let plane = Sprite(type: 3, frame: 10, x: 100, y: 80, xHot: 48, yHot: 16)
        renderer.updateSprites([plane], in: parent)
        let layer = try #require(parent.sublayers?.first)
        #expect(!layer.isHidden)
        #expect(layer.frame == CGRect(x: 148 - 24, y: 96 - 24, width: 48, height: 48))
        #expect(layer.magnificationFilter == .linear)

        try renderer.setGraphics(.classic)
        #expect(renderer.sheet(for: 3)?.frameCount == 8)
        #expect(layer.magnificationFilter == .nearest)
    }

    @Test
    func switchingThePackageSwapsTheSprites() throws {
        let model = GameModel(city: Assets.city("haight"), sound: RecordingSound(), seed: 1, runsTimer: false)
        model.setGraphicsPackage(.toyBlocks)
        #expect(model.spriteRenderer.graphics == .toyBlocks)
        #expect(model.spriteRenderer.sheet(for: 3)?.frameCount == 11)
        model.setGraphicsPackage(.classic)
        #expect(model.spriteRenderer.graphics == .classic)
    }

    /// Writes every sprite sheet on grass and water for review:
    /// MICROPOLIS_CAPTURE_PROCEDURAL=/some/dir swift test --filter ProceduralSpriteTests
    @Test(.enabled(if: ProcessInfo.processInfo.environment["MICROPOLIS_CAPTURE_PROCEDURAL"] != nil))
    func captureSpriteSheets() throws {
        let directory = URL(fileURLWithPath: ProcessInfo.processInfo.environment["MICROPOLIS_CAPTURE_PROCEDURAL"]!)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        for package in Self.packages {
            let style = try #require(package.proceduralStyle)
            let scale = ProceduralSpriteBuilder.scale
            let rows = ProceduralSpriteBuilder.kinds
            let width = 16 * 48 * scale
            let height = rows.reduce(0) { $0 + $1.size * scale }
            let context = try #require(CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
                                                 bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                                 bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
            var top = height
            for kind in rows {
                let image = try ProceduralSpriteBuilder.makeImage(kind, style: style)
                let rowHeight = kind.size * scale
                top -= rowHeight
                let background = kind.type == 4 ? style.water : style.grass
                context.setFillColor(background.cg)
                context.fill(CGRect(x: 0, y: top, width: width, height: rowHeight))
                context.draw(image, in: CGRect(x: 0, y: top, width: image.width, height: rowHeight))
            }
            let output = try #require(context.makeImage())
            let url = directory.appendingPathComponent("\(package.rawValue)-sprites.png")
            let destination = try #require(CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil))
            CGImageDestinationAddImage(destination, output, nil)
            #expect(CGImageDestinationFinalize(destination))
        }
    }
}
