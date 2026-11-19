import AppKit
import Testing
import MicropolisKit
@testable import MicropolisMac

@MainActor
struct GraphicsPackageTests {
    @Test
    func switchingPackagesPreservesTheCityAndInvalidatesRendering() throws {
        let model = GameModel(city: Assets.city("haight"), sound: RecordingSound(), seed: 1, runsTimer: false)
        let before = model.engine.mapSnapshot()
        let funds = model.engine.funds
        let renderer = model.renderer
        model.setGraphicsPackage(.retroSquare)
        #expect(model.graphicsError == nil)
        #expect(model.graphicsPackage == .retroSquare)
        #expect(model.tileAtlas.tileSize == 32)
        #expect(model.renderer !== renderer)
        #expect(model.engine.mapSnapshot() == before)
        #expect(model.engine.funds == funds)
        model.renderer.update(cells: before)
        let image = try #require(model.renderer.makeImage())
        #expect(image.width == Engine.width * 32)
        #expect(image.height == Engine.height * 32)
        #expect(model.renderer.lastRedrawCount == Engine.width * Engine.height)
        model.renderer.update(cells: before)
        #expect(model.renderer.lastRedrawCount == 0)
        model.setGraphicsPackage(.classic)
        #expect(model.tileAtlas.tileSize == 16)
        #expect(model.engine.mapSnapshot() == before)
    }

    @Test
    func retroAnimationFragmentsDoNotRevertToClassicBuildings() throws {
        let atlas = try TileAtlas(atlasURL: Assets.tileAtlas, graphics: .retroSquare)
        let bytes = atlas.bytes
        func fragment(_ index: Int) -> [UInt8] {
            let stride = 32 * atlas.tileSize * 4
            let start = (index / 32) * atlas.tileSize * stride + (index % 32) * atlas.tileSize * 4
            return (0..<atlas.tileSize).flatMap { row in
                Array(bytes[(start + row * stride)..<(start + row * stride + atlas.tileSize * 4)])
            }
        }
        for (frames, source) in RetroAtlasBuilder.animationSources {
            for frame in frames { #expect(fragment(frame) == fragment(source)) }
        }
    }

    @Test
    func retroBuildingPlacementAndHitTestingUseLogicalSquareCells() throws {
        let model = GameModel(city: nil, sound: RecordingSound(), seed: 1, runsTimer: false)
        model.setGraphicsPackage(.retroSquare)
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
        // Top-left and bottom-right of the lot still use the original simulation tile IDs.
        #expect(model.engine.tile(x: 19, y: 19) & 0x3FF == 761)
        #expect(model.engine.tile(x: 21, y: 21) & 0x3FF == 769)
        #expect(try #require(model.tileAtlas.buildingImage(base: 761, size: 3)).width == 96)
    }

    @Test
    func firstFrameDrawsTile1023() throws {
        let atlas = try TileAtlas(atlasURL: Assets.tileAtlas)
        let renderer = MapRenderer(tileAtlas: atlas)
        renderer.update(cells: [UInt16](repeating: 1023, count: Engine.width * Engine.height))
        #expect(renderer.lastRedrawCount == Engine.width * Engine.height)
    }
}
