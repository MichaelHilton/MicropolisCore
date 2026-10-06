import CoreGraphics
import CoreImage

final class TileAtlas {
    let tileSize: Int = 16
    let tilesPerRow: Int = 32
    let tileCount: Int = 1024

    private var tileImages: [CGImage]
    private var atlasBytes: [UInt8]
    private var buildingCache: [Int: CGImage] = [:]

    init(atlasURL: URL) throws {
        guard let imageSource = CGImageSourceCreateWithURL(atlasURL as CFURL, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            throw TileAtlasError.failedToLoadImage
        }

        guard cgImage.width == 512 && cgImage.height == 512 else {
            throw TileAtlasError.invalidSize
        }

        // Extract raw RGBA bytes
        self.atlasBytes = try Self.extractBytes(from: cgImage)

        // Create and cache all tile images
        var tiles: [CGImage] = []
        for tileIndex in 0..<tileCount {
            let tile = try Self.cropTile(from: cgImage, index: tileIndex)
            tiles.append(tile)
        }
        self.tileImages = tiles
    }

    func image(for tile: Int) -> CGImage {
        guard tile >= 0 && tile < tileImages.count else {
            return tileImages[0]
        }
        return tileImages[tile]
    }

    var bytes: [UInt8] {
        atlasBytes
    }

    /// Draws a `size`×`size` building whose tiles run row-major from `base`,
    /// the same layout the engine uses when it places a building.
    func buildingImage(base: Int, size: Int) -> CGImage? {
        if let cached = buildingCache[base] { return cached }
        let pixels = size * tileSize
        guard let context = CGContext(
            data: nil,
            width: pixels,
            height: pixels,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        context.interpolationQuality = .none
        for row in 0..<size {
            for col in 0..<size {
                // CoreGraphics' origin is bottom-left, so the first row goes on top.
                let rect = CGRect(x: col * tileSize, y: (size - 1 - row) * tileSize,
                                  width: tileSize, height: tileSize)
                context.draw(image(for: base + row * size + col), in: rect)
            }
        }
        let image = context.makeImage()
        buildingCache[base] = image
        return image
    }

    private static func cropTile(from atlas: CGImage, index: Int) throws -> CGImage {
        let x = (index % 32) * 16
        let y = (index / 32) * 16
        let cropRect = CGRect(x: x, y: y, width: 16, height: 16)

        guard let croppedImage = atlas.cropping(to: cropRect) else {
            throw TileAtlasError.failedToCrop
        }
        return croppedImage
    }

    private static func extractBytes(from image: CGImage) throws -> [UInt8] {
        let width = image.width
        let height = image.height
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let totalBytes = width * height * bytesPerPixel

        var bytes = [UInt8](repeating: 0, count: totalBytes)

        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                data: &bytes,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ) else {
            throw TileAtlasError.failedToCreateContext
        }

        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        context.draw(image, in: rect)

        return bytes
    }
}

enum TileAtlasError: Error {
    case failedToLoadImage
    case invalidSize
    case failedToCrop
    case failedToCreateContext
}
