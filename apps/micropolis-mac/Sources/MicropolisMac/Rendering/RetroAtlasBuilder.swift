import CoreGraphics
import ImageIO
import Foundation

/// Adapts the preview's building sheet to the engine's existing 1,024 tile IDs.
/// The simulation still uses 16-point square cells; this atlas supplies 32-pixel artwork.
/// Lots are sliced as a whole so adjacent tile fragments join without seams.
enum RetroAtlasBuilder {
    static let tileSize = 32

    struct Building: Equatable {
        let base: Int
        let size: Int
        let sprite: Int
    }

    static var buildings: [Building] {
        var result: [Building] = []
        // Four land-value groups, each with four residential densities.
        for base in stride(from: 261, through: 396, by: 9) {
            let density = ((base - 261) / 9) % 4
            result.append(Building(base: base, size: 3, sprite: density == 0 ? 1 : density == 1 ? 2 : 3))
        }
        for base in stride(from: 432, through: 603, by: 9) {
            let density = ((base - 432) / 9) % 5
            result.append(Building(base: base, size: 3, sprite: density < 2 ? 4 : density < 4 ? 5 : 6))
        }
        for base in stride(from: 621, through: 684, by: 9) {
            result.append(Building(base: base, size: 3, sprite: 7))
        }
        result += [
            Building(base: 405, size: 3, sprite: 15),
            Building(base: 693, size: 4, sprite: 13),
            Building(base: 709, size: 6, sprite: 14),
            Building(base: 745, size: 4, sprite: 10),
            Building(base: 761, size: 3, sprite: 8),
            Building(base: 770, size: 3, sprite: 9),
            Building(base: 779, size: 4, sprite: 12),
            Building(base: 795, size: 4, sprite: 12),
            Building(base: 811, size: 4, sprite: 11),
        ]
        return result
    }

    /// Some engine animation IDs are fragments of larger lots, not separate buildings.
    /// Use the corresponding new fragment until bespoke animated frames are authored.
    static let animationSources: [(Range<Int>, Int)] = [
        (832..<840, 711), (844..<852, 711), (852..<860, 621),
        (884..<888, 641), (888..<892, 644), (892..<896, 649), (896..<900, 650),
        (900..<904, 676), (904..<908, 677), (908..<912, 686), (912..<916, 689),
        (916..<920, 747), (920..<924, 748), (924..<928, 751), (928..<932, 752),
        (932..<940, 797), (940..<948, 798), (952..<956, 820),
    ]

    static func makeImage(classic: CGImage) throws -> CGImage {
        let sheetURL = Assets.root.appendingPathComponent("tiles/retro-square/buildings.png")
        guard let source = CGImageSourceCreateWithURL(sheetURL as CFURL, nil),
              let sheet = CGImageSourceCreateImageAtIndex(source, 0, nil),
              sheet.width >= 512, sheet.width == sheet.height else {
            throw TileAtlasError.failedToLoadImage
        }
        let edge = tileSize * 32
        guard let context = CGContext(data: nil, width: edge, height: edge, bitsPerComponent: 8,
                                      bytesPerRow: edge * 4, space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            throw TileAtlasError.failedToCreateContext
        }
        context.interpolationQuality = .none
        // Keep the original connection geometry, disaster states and unsupported specialty art.
        context.draw(classic, in: CGRect(x: 0, y: 0, width: edge, height: edge))
        harmonizePalette(context)

        // A flipped drawing space lets the atlas coordinates match the engine's top-left indexing.
        context.translateBy(x: 0, y: CGFloat(edge))
        context.scaleBy(x: 1, y: -1)
        func draw(_ image: CGImage, in rect: CGRect) {
            context.saveGState()
            context.translateBy(x: rect.minX, y: rect.maxY)
            context.scaleBy(x: 1, y: -1)
            context.draw(image, in: CGRect(origin: .zero, size: rect.size))
            context.restoreGState()
        }
        func tileRect(_ index: Int) -> CGRect {
            CGRect(x: (index % 32) * tileSize, y: (index / 32) * tileSize,
                   width: tileSize, height: tileSize)
        }
        // The generated sheet can have a fractional cell width. Partition by rounded
        // boundaries, rather than accumulating integer-division drift across the sheet.
        func sprite(_ index: Int) -> CGImage? {
            let unit = Double(sheet.width) / 4
            let x = Int((Double(index % 4) * unit).rounded())
            let y = Int((Double(index / 4) * unit).rounded())
            let right = Int((Double(index % 4 + 1) * unit).rounded())
            let bottom = Int((Double(index / 4 + 1) * unit).rounded())
            return sheet.cropping(to: CGRect(x: x, y: y, width: right - x, height: bottom - y))
        }
        for building in buildings {
            guard let original = sprite(building.sprite),
                  let lotContext = CGContext(data: nil, width: building.size * tileSize,
                                             height: building.size * tileSize, bitsPerComponent: 8,
                                             bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
                                             bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
                throw TileAtlasError.failedToCreateContext
            }
            lotContext.interpolationQuality = .none
            lotContext.draw(original, in: CGRect(x: 0, y: 0, width: building.size * tileSize,
                                                 height: building.size * tileSize))
            guard let lot = lotContext.makeImage() else { throw TileAtlasError.failedToCreateContext }
            for row in 0..<building.size {
                for col in 0..<building.size {
                    guard let fragment = lot.cropping(to: CGRect(x: col * tileSize, y: row * tileSize,
                                                                 width: tileSize, height: tileSize)) else {
                        throw TileAtlasError.failedToCrop
                    }
                    draw(fragment, in: tileRect(building.base + row * building.size + col))
                }
            }
        }
        if let house = sprite(0) {
            for index in 249...260 { draw(house, in: tileRect(index)) }
        }
        // Empty zoning stays visibly empty: zoning must not imply buildings already exist.
        for (base, accent) in [(240, rgb(97, 184, 112)), (423, rgb(90, 165, 193)), (612, rgb(211, 176, 95))] {
            for row in 0..<3 {
                for col in 0..<3 {
                    let rect = tileRect(base + row * 3 + col)
                    context.setFillColor(rgb(103, 136, 66))
                    context.fill(rect)
                    context.setStrokeColor(accent)
                    context.setLineWidth(2)
                    context.setLineDash(phase: 0, lengths: [3, 3])
                    context.beginPath()
                    if row == 0 { context.move(to: CGPoint(x: rect.minX, y: rect.minY + 1)); context.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + 1)) }
                    if row == 2 { context.move(to: CGPoint(x: rect.minX, y: rect.maxY - 1)); context.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - 1)) }
                    if col == 0 { context.move(to: CGPoint(x: rect.minX + 1, y: rect.minY)); context.addLine(to: CGPoint(x: rect.minX + 1, y: rect.maxY)) }
                    if col == 2 { context.move(to: CGPoint(x: rect.maxX - 1, y: rect.minY)); context.addLine(to: CGPoint(x: rect.maxX - 1, y: rect.maxY)) }
                    context.strokePath()
                    context.setLineDash(phase: 0, lengths: [])
                }
            }
        }
        // Flat land and open water get quieter pixel textures at the new resolution.
        for index in [0, 2, 3] {
            let rect = tileRect(index)
            context.setFillColor(index == 0 ? rgb(103, 136, 66) : rgb(28, 113, 123))
            context.fill(rect)
            context.setFillColor(index == 0 ? rgb(112, 144, 73) : rgb(48, 137, 143))
            for n in 0..<9 {
                let x = (n * 13 + index * 3) % 29
                let y = (n * 7 + index * 5) % 30
                context.fill(CGRect(x: rect.minX + CGFloat(x), y: rect.minY + CGFloat(y),
                                    width: index == 0 ? 1 : 3, height: 1))
            }
        }
        // Snapshot after all base tiles are ready, so animation frames never reveal
        // fragments of the old buildings when the simulation advances.
        guard let staticAtlas = context.makeImage() else { throw TileAtlasError.failedToCreateContext }
        for (frames, sourceIndex) in animationSources {
            guard let fragment = staticAtlas.cropping(to: tileRect(sourceIndex)) else { continue }
            for frame in frames { draw(fragment, in: tileRect(frame)) }
        }
        guard let image = context.makeImage() else { throw TileAtlasError.failedToCreateContext }
        return image
    }

    private static func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> CGColor {
        CGColor(red: r / 255, green: g / 255, blue: b / 255, alpha: 1)
    }

    private static func harmonizePalette(_ context: CGContext) {
        guard let data = context.data else { return }
        let pixels = data.bindMemory(to: UInt8.self, capacity: context.bytesPerRow * context.height)
        for i in stride(from: 0, to: context.bytesPerRow * context.height, by: 4) {
            let r = Int(pixels[i]), g = Int(pixels[i + 1]), b = Int(pixels[i + 2])
            let color: (UInt8, UInt8, UInt8)?
            if g > r + 25 && g > b + 25 {
                color = g > 190 ? (105, 144, 65) : (45, 91, 58)
            } else if b > r + 30 && b > g + 15 {
                color = b > 190 ? (47, 132, 143) : (26, 93, 110)
            } else if r > 125 && r > g + 35 && g > b + 15 {
                color = (103, 136, 66)
            } else if r == g && g == b {
                color = r < 50 ? (32, 47, 54) : r < 130 ? (78, 89, 95) : r < 210 ? (158, 160, 145) : (227, 222, 197)
            } else {
                color = nil
            }
            if let color { pixels[i] = color.0; pixels[i + 1] = color.1; pixels[i + 2] = color.2 }
        }
    }
}
