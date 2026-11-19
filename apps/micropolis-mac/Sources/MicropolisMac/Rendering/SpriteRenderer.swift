import CoreGraphics
import CoreImage
import AppKit
import MicropolisKit

final class SpriteRenderer {
    private var spriteSheets: [Int: SpriteSheet] = [:]
    private var spriteLayers: [CALayer] = []
    private let maxSprites = 256
    private(set) var graphics: GraphicsPackage = .classic
    /// Where each layer's sprite was last frame, so a train on a bridge can keep facing its track.
    private var lastPositions: [Int: (x: Int, y: Int, frame: Int)] = [:]

    init() {
        loadSpriteSheets()
    }

    /// Code-drawn packages draw their own sprites; the others keep the classic sheets.
    func setGraphics(_ package: GraphicsPackage) throws {
        guard package != graphics else { return }
        if let style = package.proceduralStyle {
            spriteSheets = try ProceduralSpriteBuilder.makeSheets(style: style)
        } else {
            spriteSheets = [:]
            loadSpriteSheets()
        }
        graphics = package
        let filter: CALayerContentsFilter = package.smoothScaling ? .linear : .nearest
        for layer in spriteLayers {
            layer.magnificationFilter = filter
            layer.minificationFilter = filter
        }
    }

    func sheet(for type: Int) -> SpriteSheet? { spriteSheets[type] }

    private func loadSpriteSheets() {
        let spriteNames: [(type: Int, name: String)] = [
            (1, "train"),
            (2, "chopper"),
            (3, "plane"),
            (4, "ship"),
            (5, "monster"),
            (6, "tornado"),
            (7, "explode"),
        ]

        for (type, name) in spriteNames {
            do {
                let sheet = try SpriteSheet(atlasURL: Assets.spriteSheet(name))
                spriteSheets[type] = sheet
            } catch {
                print("Failed to load sprite sheet \(name): \(error)")
            }
        }
    }

    func updateSprites(_ sprites: [Sprite], in parent: CALayer) {
        // Remove old layers if we have too many
        if spriteLayers.count > maxSprites {
            spriteLayers.dropFirst().forEach { $0.removeFromSuperlayer() }
            spriteLayers.removeFirst()
        }

        // Update or create layers for each sprite
        for (index, sprite) in sprites.enumerated() {
            let layer: CALayer
            if index < spriteLayers.count {
                layer = spriteLayers[index]
            } else {
                layer = CALayer()
                let filter: CALayerContentsFilter = graphics.smoothScaling ? .linear : .nearest
                layer.magnificationFilter = filter
                layer.minificationFilter = filter
                spriteLayers.append(layer)
                parent.addSublayer(layer)
            }

            updateSpriteLayer(layer, sprite: sprite, index: index)
        }

        // Hide unused layers
        for i in sprites.count..<spriteLayers.count {
            spriteLayers[i].isHidden = true
        }
    }

    private func updateSpriteLayer(_ layer: CALayer, sprite: Sprite, index: Int) {
        guard let sheet = spriteSheets[sprite.type] else { return }
        guard let image = sheet.image(for: displayFrame(for: sprite, index: index)) else { return }

        layer.isHidden = false
        layer.contents = image

        // Position: sprite center is at (x, y), with offset by hot spot
        // Position should be at pixel (x + xHot - frameSize/2, y + yHot - frameSize/2)
        let frameSize = CGFloat(sheet.frameSize)
        let posX = CGFloat(sprite.x + sprite.xHot) - frameSize / 2
        let posY = CGFloat(sprite.y + sprite.yHot) - frameSize / 2

        layer.frame = CGRect(x: posX, y: posY, width: frameSize, height: frameSize)
    }

    /// The engine shows a train crossing a bridge as frame 5, which has no direction.
    /// The drawn packages turn it to match the way the train is moving.
    private func displayFrame(for sprite: Sprite, index: Int) -> Int {
        guard sprite.type == 1, graphics.proceduralStyle != nil else { return sprite.frame }
        let last = lastPositions[index]
        var frame = sprite.frame
        if frame == 5 {
            if let last, last.x != sprite.x || last.y != sprite.y {
                frame = abs(sprite.x - last.x) > abs(sprite.y - last.y) ? 2 : 1
            } else if let last, last.frame == 2 {
                frame = 2
            } else {
                frame = 1
            }
        }
        lastPositions[index] = (sprite.x, sprite.y, frame)
        return frame
    }

    func clearLayers() {
        spriteLayers.forEach { $0.removeFromSuperlayer() }
        spriteLayers.removeAll()
    }
}
