import CoreGraphics
import CoreImage

final class SpriteSheet {
    let sheetImage: CGImage
    /// Frame edge in map pixels: the size the sprite covers on the map.
    let frameSize: Int
    let frameCount: Int
    /// Frame edge in image pixels; larger than `frameSize` for high-resolution sheets.
    private let framePixels: Int

    init(atlasURL: URL) throws {
        guard let imageSource = CGImageSourceCreateWithURL(atlasURL as CFURL, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            throw SpriteSheetError.failedToLoadImage
        }

        self.sheetImage = cgImage
        self.frameSize = cgImage.height
        self.framePixels = cgImage.height
        self.frameCount = cgImage.width / cgImage.height
    }

    /// A sheet of square frames laid side by side, each covering `frameSize` map pixels.
    init(image: CGImage, frameSize: Int) {
        self.sheetImage = image
        self.frameSize = frameSize
        self.framePixels = image.height
        self.frameCount = image.width / image.height
    }

    func image(for frame: Int) -> CGImage? {
        guard frame > 0 && frame <= frameCount else { return nil }
        let frameIndex = frame - 1
        let x = frameIndex * framePixels
        let cropRect = CGRect(x: x, y: 0, width: framePixels, height: framePixels)
        return sheetImage.cropping(to: cropRect)
    }
}

enum SpriteSheetError: Error {
    case failedToLoadImage
}
