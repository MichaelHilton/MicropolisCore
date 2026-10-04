import CoreGraphics
import CoreImage

final class SpriteSheet {
    let sheetImage: CGImage
    let frameSize: Int
    let frameCount: Int

    init(atlasURL: URL) throws {
        guard let imageSource = CGImageSourceCreateWithURL(atlasURL as CFURL, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            throw SpriteSheetError.failedToLoadImage
        }

        self.sheetImage = cgImage
        self.frameSize = cgImage.height
        self.frameCount = cgImage.width / cgImage.height
    }

    func image(for frame: Int) -> CGImage? {
        guard frame > 0 && frame <= frameCount else { return nil }
        let frameIndex = frame - 1
        let x = frameIndex * frameSize
        let cropRect = CGRect(x: x, y: 0, width: frameSize, height: frameSize)
        return sheetImage.cropping(to: cropRect)
    }
}

enum SpriteSheetError: Error {
    case failedToLoadImage
}
