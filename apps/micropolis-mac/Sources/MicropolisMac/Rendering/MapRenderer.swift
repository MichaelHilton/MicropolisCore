import CoreGraphics
import Foundation

final class MapRenderer {
    private let tileAtlas: TileAtlas
    private var pixelBuffer: [UInt8]
    private var lastCells: [UInt16]
    private(set) var lastRedrawCount: Int = 0

    private let width = 1920
    private let height = 1600
    private let mapWidth = 120
    private let mapHeight = 100
    private let tileSize = 16
    private let bytesPerPixel = 4

    init(tileAtlas: TileAtlas) {
        self.tileAtlas = tileAtlas
        self.pixelBuffer = [UInt8](repeating: 0, count: 1920 * 1600 * 4)
        self.lastCells = [UInt16](repeating: 0xFFFF, count: 120 * 100)
    }

    func update(cells: [UInt16]) {
        let atlasBytes = tileAtlas.bytes
        var redrawCount = 0

        for x in 0..<mapWidth {
            for y in 0..<mapHeight {
                let cellIndex = x * mapHeight + y
                guard cellIndex < cells.count else { continue }

                let currentCell = cells[cellIndex] & 0x3FF
                let lastCell = lastCells[cellIndex] & 0x3FF

                if currentCell != lastCell {
                    redrawCount += 1
                    copyTile(x: x, y: y, tileIndex: Int(currentCell), atlasBytes: atlasBytes)
                    lastCells[cellIndex] = cells[cellIndex]
                }
            }
        }

        lastRedrawCount = redrawCount
    }

    private func copyTile(x: Int, y: Int, tileIndex: Int, atlasBytes: [UInt8]) {
        let tileX = (tileIndex % 32) * tileSize
        let tileY = (tileIndex / 32) * tileSize

        let pixelX = x * tileSize
        let pixelY = y * tileSize

        for row in 0..<tileSize {
            let atlasOffset = (tileY + row) * 512 * bytesPerPixel + tileX * bytesPerPixel
            let bufferOffset = (pixelY + row) * width * bytesPerPixel + pixelX * bytesPerPixel

            guard atlasOffset + tileSize * bytesPerPixel <= atlasBytes.count else { continue }
            guard bufferOffset + tileSize * bytesPerPixel <= pixelBuffer.count else { continue }

            pixelBuffer.replaceSubrange(
                bufferOffset..<(bufferOffset + tileSize * bytesPerPixel),
                with: atlasBytes[atlasOffset..<(atlasOffset + tileSize * bytesPerPixel)]
            )
        }
    }

    func makeImage() -> CGImage? {
        let bytesPerRow = width * bytesPerPixel

        guard let provider = CGDataProvider(data: NSData(bytes: pixelBuffer, length: pixelBuffer.count)) else {
            return nil
        }

        let colorSpace = CGColorSpaceCreateDeviceRGB()

        return CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )
    }
}
