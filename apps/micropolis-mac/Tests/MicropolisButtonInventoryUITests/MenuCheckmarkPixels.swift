import AppKit
import XCTest

/// Detects a native menu checkmark from the item's own screenshot. The probe
/// samples only the left mark gutter and derives its background from the row,
/// so it does not depend on a light/dark palette or a full-screen reference.
enum MenuCheckmarkPixels {
    struct Evidence: CustomStringConvertible {
        let isMarked: Bool
        let contrastPixelCount: Int
        let largestContrastComponent: Int
        let threshold: Int
        let backgroundLuminance: Double
        let scale: Double
        let pixelSize: CGSize
        let gutterSize: CGSize
        let crop: NSImage

        var description: String {
            "marked=\(isMarked), contrastPixels=\(contrastPixelCount), " +
            "largestComponent=\(largestContrastComponent), threshold=\(threshold), " +
            "backgroundLuminance=\(String(format: "%.3f", backgroundLuminance)), " +
            "scale=\(String(format: "%.2f", scale)), pixelSize=\(pixelSize), gutterSize=\(gutterSize)"
        }
    }

    enum DetectionError: Error, CustomStringConvertible {
        case elementNotVisible
        case screenshotUnavailable
        case invalidGeometry(width: Int, height: Int, frame: CGRect)
        case missingPixelData

        var description: String {
            switch self {
            case .elementNotVisible: "Menu item is not visible and hittable"
            case .screenshotUnavailable: "Could not create an image from the menu-item screenshot"
            case let .invalidGeometry(width, height, frame): "Menu-item screenshot geometry is too small: pixels=\(width)x\(height), frame=\(frame)"
            case .missingPixelData: "Menu-item screenshot has no readable pixel data"
            }
        }
    }

    /// Capture and score the checkmark gutter. `isMarked` is evidence from
    /// visible pixels, never a model flag or a native menu item's value field.
    static func inspect(_ element: XCUIElement) throws -> Evidence {
        guard element.exists, element.isHittable else { throw DetectionError.elementNotVisible }
        let frame = element.frame
        let screenshot = element.screenshot()
        var proposed = CGRect(origin: .zero, size: screenshot.image.size)
        guard let image = screenshot.image.cgImage(forProposedRect: &proposed, context: nil, hints: nil) else {
            throw DetectionError.screenshotUnavailable
        }
        let width = image.width
        let height = image.height
        guard width >= 24, height >= 12, frame.width > 0, frame.height > 0 else {
            throw DetectionError.invalidGeometry(width: width, height: height, frame: frame)
        }

        let bitmap = try rgbaPixels(image)
        let scale = Double(width) / Double(frame.width)
        let gutterWidth = min(width - 1, max(8, Int((18.0 * scale).rounded())))
        let topInset = max(2, Int((2.5 * scale).rounded()))
        let bottom = max(topInset + 1, height - topInset)
        let centerTop = max(topInset, Int((Double(height) / 2.0 - 6.0 * scale).rounded()))
        let centerBottom = min(bottom, Int((Double(height) / 2.0 + 6.0 * scale).rounded()))
        guard centerBottom > centerTop else {
            throw DetectionError.invalidGeometry(width: width, height: height, frame: frame)
        }

        // Estimate the row surface from its top and bottom bands plus the
        // gutter's outermost columns. A median tolerates a few mark pixels,
        // menu-edge pixels, antialiasing, and selection-surface variation.
        var backgroundSamples: [Double] = []
        for y in 0..<height {
            for x in 0..<gutterWidth {
                let inOuterColumn = x < max(1, Int(3 * scale))
                let inBorderBand = y < topInset || y >= bottom
                if inOuterColumn || inBorderBand {
                    backgroundSamples.append(luminance(bitmap, x: x, y: y, width: width))
                }
            }
        }
        guard !backgroundSamples.isEmpty else { throw DetectionError.missingPixelData }
        backgroundSamples.sort()
        let background = backgroundSamples[backgroundSamples.count / 2]

        let contrastThreshold = 0.17
        let gutterLeft = max(0, Int((4.0 * scale).rounded()))
        let gutterRight = min(gutterWidth, max(gutterLeft + 1, Int((17.0 * scale).rounded())))
        var mask = Array(repeating: false, count: width * height)
        var contrastCount = 0
        if gutterRight > gutterLeft {
            for y in centerTop..<centerBottom {
                for x in gutterLeft..<gutterRight {
                    if abs(luminance(bitmap, x: x, y: y, width: width) - background) >= contrastThreshold {
                        mask[y * width + x] = true
                        contrastCount += 1
                    }
                }
            }
        }

        let largestComponent = largestEightConnectedComponent(mask, width: width,
                                                               xRange: gutterLeft..<gutterRight,
                                                               yRange: centerTop..<centerBottom)
        // The mark is a compact connected glyph. Requiring both enough ink
        // pixels and a connected component suppresses isolated antialiasing
        // noise while scaling the minimum with the screenshot backing scale.
        let threshold = max(8, Int((3.0 * scale * scale).rounded()))
        let componentThreshold = max(5, Int((1.5 * scale * scale).rounded()))
        let marked = contrastCount >= threshold && largestComponent >= componentThreshold

        let cropRect = CGRect(x: 0, y: 0, width: CGFloat(gutterWidth), height: CGFloat(height))
        guard let cropped = image.cropping(to: cropRect) else { throw DetectionError.screenshotUnavailable }
        let crop = NSImage(cgImage: cropped, size: NSSize(width: CGFloat(Double(gutterWidth) / max(scale, 0.1)),
                                                           height: CGFloat(Double(height) / max(scale, 0.1))))
        return Evidence(isMarked: marked, contrastPixelCount: contrastCount,
                        largestContrastComponent: largestComponent, threshold: threshold,
                        backgroundLuminance: background, scale: scale,
                        pixelSize: CGSize(width: CGFloat(width), height: CGFloat(height)),
                        gutterSize: CGSize(width: CGFloat(gutterWidth), height: CGFloat(height)), crop: crop)
    }

    /// Make an XCTest assertion and retain the measured gutter crop on a
    /// mismatch. Call this only while the menu item is open and visible.
    static func assertMarked(
        _ expected: Bool,
        in element: XCUIElement,
        testCase: XCTestCase,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        do {
            let evidence = try inspect(element)
            if evidence.isMarked != expected {
                let attachment = XCTAttachment(image: evidence.crop)
                attachment.name = "Menu mark gutter: \(element.label)"
                attachment.lifetime = .keepAlways
                testCase.add(attachment)
                XCTFail("Menu checkmark pixels disagreed for '\(element.label)'; expected marked=\(expected). \(evidence)",
                        file: file, line: line)
            }
        } catch {
            XCTFail("Could not inspect native menu checkmark for '\(element.label)': \(error)", file: file, line: line)
        }
    }

    private static func rgbaPixels(_ image: CGImage) throws -> [UInt8] {
        let width = image.width
        let height = image.height
        let bytesPerRow = width * 4
        var bytes = [UInt8](repeating: 0, count: bytesPerRow * height)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let info = CGBitmapInfo.byteOrder32Big.union(CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue))
        let drewImage = bytes.withUnsafeMutableBytes { storage -> Bool in
            guard let context = CGContext(data: storage.baseAddress, width: width, height: height,
                                          bitsPerComponent: 8, bytesPerRow: bytesPerRow,
                                          space: colorSpace, bitmapInfo: info.rawValue) else { return false }
            context.draw(image, in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
            return true
        }
        guard drewImage else { throw DetectionError.missingPixelData }
        return bytes
    }

    private static func luminance(_ bytes: [UInt8], x: Int, y: Int, width: Int) -> Double {
        let index = (y * width + x) * 4
        let red = Double(bytes[index]) / 255.0
        let green = Double(bytes[index + 1]) / 255.0
        let blue = Double(bytes[index + 2]) / 255.0
        return 0.2126 * red + 0.7152 * green + 0.0722 * blue
    }

    private static func largestEightConnectedComponent(_ mask: [Bool], width: Int,
                                                        xRange: Range<Int>, yRange: Range<Int>) -> Int {
        guard !xRange.isEmpty, !yRange.isEmpty else { return 0 }
        var seen = Set<Int>()
        var largest = 0
        for y in yRange {
            for x in xRange {
                let start = y * width + x
                guard mask[start], seen.insert(start).inserted else { continue }
                var queue = [start]
                var head = 0
                while head < queue.count {
                    let current = queue[head]
                    head += 1
                    let px = current % width
                    let py = current / width
                    for dy in -1...1 {
                        for dx in -1...1 where dx != 0 || dy != 0 {
                            let nx = px + dx
                            let ny = py + dy
                            guard xRange.contains(nx), yRange.contains(ny) else { continue }
                            let candidate = ny * width + nx
                            if mask[candidate], seen.insert(candidate).inserted { queue.append(candidate) }
                        }
                    }
                }
                largest = max(largest, queue.count)
            }
        }
        return largest
    }
}
