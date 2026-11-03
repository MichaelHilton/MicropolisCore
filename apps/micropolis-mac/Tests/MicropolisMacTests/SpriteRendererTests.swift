import AppKit
import Foundation
import Testing
@testable import MicropolisKit
@testable import MicropolisMac

struct SpriteSheetTests {
    @Test
    func loadsAndCropsEveryBoundaryFrame() throws {
        let sheet = try SpriteSheet(atlasURL: Assets.spriteSheet("train"))

        #expect(sheet.frameSize > 0)
        #expect(sheet.frameCount > 1)

        let first = try #require(sheet.image(for: 1))
        let last = try #require(sheet.image(for: sheet.frameCount))
        #expect(first.width == sheet.frameSize)
        #expect(first.height == sheet.frameSize)
        #expect(last.width == sheet.frameSize)
        #expect(last.height == sheet.frameSize)
    }

    @Test
    func refusesFramesOutsideTheSheet() throws {
        let sheet = try SpriteSheet(atlasURL: Assets.spriteSheet("train"))

        #expect(sheet.image(for: 0) == nil)
        #expect(sheet.image(for: sheet.frameCount + 1) == nil)
    }

    @Test
    func rejectsAMissingImage() {
        #expect(throws: SpriteSheetError.failedToLoadImage) {
            try SpriteSheet(atlasURL: URL(fileURLWithPath: "/tmp/micropolis-missing-sprite.png"))
        }
    }
}

@MainActor
struct SpriteRendererTests {
    private func sprite(frame: Int = 1, x: Int = 20, y: Int = 30, xHot: Int = 2, yHot: Int = 3) -> Sprite {
        Sprite(type: 1, frame: frame, x: x, y: y, xHot: xHot, yHot: yHot)
    }

    @Test
    func createsALayerAtTheSpriteHotspot() throws {
        let renderer = SpriteRenderer()
        let parent = CALayer()
        let sprite = sprite()
        let frameSize = CGFloat(try SpriteSheet(atlasURL: Assets.spriteSheet("train")).frameSize)

        renderer.updateSprites([sprite], in: parent)

        let layer = try #require(parent.sublayers?.first)
        #expect(!layer.isHidden)
        #expect(layer.contents != nil)
        #expect(layer.frame == CGRect(
            x: CGFloat(sprite.x + sprite.xHot) - frameSize / 2,
            y: CGFloat(sprite.y + sprite.yHot) - frameSize / 2,
            width: frameSize,
            height: frameSize
        ))
    }

    @Test
    func reusesLayersAndHidesThoseNoLongerNeeded() throws {
        let renderer = SpriteRenderer()
        let parent = CALayer()

        renderer.updateSprites([sprite(), sprite(x: 50)], in: parent)
        let original = try #require(parent.sublayers?.first)

        renderer.updateSprites([sprite(frame: 2, x: 40)], in: parent)

        #expect(parent.sublayers?.count == 2)
        #expect(parent.sublayers?.first === original)
        #expect(parent.sublayers?[1].isHidden == true)
        #expect(original.frame.origin.x != 0)
    }

    @Test
    func clearLayersRemovesEveryLayerFromTheParent() {
        let renderer = SpriteRenderer()
        let parent = CALayer()
        renderer.updateSprites([sprite(), sprite(x: 50)], in: parent)

        renderer.clearLayers()

        #expect(parent.sublayers?.isEmpty != false)
    }

}
