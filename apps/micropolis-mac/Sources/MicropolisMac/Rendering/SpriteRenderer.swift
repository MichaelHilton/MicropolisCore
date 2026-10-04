import CoreGraphics
import CoreImage
import AppKit
import MicropolisKit

final class SpriteRenderer {
    private var spriteSheets: [Int: SpriteSheet] = [:]
    private var spriteLayers: [CALayer] = []
    private let maxSprites = 256

    init() {
        loadSpriteSheets()
    }

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
                spriteLayers.append(layer)
                parent.addSublayer(layer)
            }

            updateSpriteLayer(layer, sprite: sprite)
        }

        // Hide unused layers
        for i in sprites.count..<spriteLayers.count {
            spriteLayers[i].isHidden = true
        }
    }

    private func updateSpriteLayer(_ layer: CALayer, sprite: Sprite) {
        guard let sheet = spriteSheets[sprite.type] else { return }
        guard let image = sheet.image(for: sprite.frame) else { return }

        layer.isHidden = false
        layer.contents = image

        // Position: sprite center is at (x, y), with offset by hot spot
        // Position should be at pixel (x + xHot - frameSize/2, y + yHot - frameSize/2)
        let frameSize = CGFloat(sheet.frameSize)
        let posX = CGFloat(sprite.x + sprite.xHot) - frameSize / 2
        let posY = CGFloat(sprite.y + sprite.yHot) - frameSize / 2

        layer.frame = CGRect(x: posX, y: posY, width: frameSize, height: frameSize)
    }

    func clearLayers() {
        spriteLayers.forEach { $0.removeFromSuperlayer() }
        spriteLayers.removeAll()
    }
}
