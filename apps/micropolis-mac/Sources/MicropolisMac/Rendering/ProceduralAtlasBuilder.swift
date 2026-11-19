import CoreGraphics
import Foundation

/// Builds a complete 1,024-tile atlas in code for Planner's Map and Toy Blocks.
///
/// Every engine tile ID keeps its meaning: connection tiles follow the engine's road, rail,
/// wire, shore and forest tables, and buildings are drawn as whole lots and then sliced into
/// their row-major fragments. Animation IDs re-render their lot with a frame number and keep
/// only the animated cell, so frames always match the surrounding building.
enum ProceduralAtlasBuilder {
    static let tileSize = 32

    // Engine connection bits, as in connect.cpp and generate.cpp.
    static let north = 1, east = 2, south = 4, west = 8

    /// Connection masks of the 11 tiles that follow ROADS (66), LHPOWER (210) and LHRAIL (226).
    static let networkMasks = [10, 5, 3, 6, 12, 9, 11, 7, 14, 13, 15]

    /// Land sides of river-edge tiles 5–20, derived from `REdTab` in generate.cpp.
    static func shoreLand(_ tile: Int) -> Int {
        switch tile {
        case 5, 6: return north
        case 7, 8: return north | east
        case 9, 10: return east
        case 11, 12: return east | south
        case 13, 14: return south
        case 15, 16: return south | west
        case 17, 18: return west
        case 19, 20: return north | west
        default: return 0
        }
    }

    /// Neighbouring forest sides of tree tiles, from `treeTable` in generate.cpp.
    static func forestSides(_ tile: Int) -> Int {
        let base = (21...28).contains(tile) ? tile + 8 : tile
        switch base {
        case 29: return east | south | west
        case 30: return south | west
        case 31: return north | south | west
        case 32: return north | west
        case 33: return north | east | west
        case 34: return north | east
        case 35: return north | east | south
        case 36: return east | south
        default: return 15
        }
    }

    struct Animation {
        let frames: [Int]
        let lot: Int
        let size: Int
        let row: Int
        let column: Int
    }

    /// Every multi-tile building drawn as one picture, by top-left tile and edge length.
    static var lots: [(base: Int, size: Int)] { Scenes.lots.map { ($0.base, $0.size) } }

    /// Animated cells inside multi-tile lots, from animate.cpp, zone.cpp and simulate.cpp.
    static let lotAnimations: [Animation] = {
        var result: [Animation] = []
        func add(_ first: Int, _ count: Int, lot: Int, size: Int, row: Int, column: Int) {
            result.append(Animation(frames: Array(first..<(first + count)), lot: lot, size: size, row: row, column: column))
        }
        add(852, 8, lot: 621, size: 3, row: 0, column: 0)
        // setSmoke (zone.cpp) animates one chimney cell per factory. Both smoke sets play there:
        // the A set via the tile animation table, the B set when the engine lights the chimney.
        for (lot, first) in [(639, 884), (648, 892), (675, 900), (684, 908)] {
            let chimney = industrialChimneys[lot]![0]
            add(first, 4, lot: lot, size: 3, row: chimney.0, column: chimney.1)
            add(first + 4, 4, lot: lot, size: 3, row: chimney.0, column: chimney.1)
        }
        add(916, 4, lot: 745, size: 4, row: 0, column: 2)
        add(920, 4, lot: 745, size: 4, row: 0, column: 3)
        add(924, 4, lot: 745, size: 4, row: 1, column: 2)
        add(928, 4, lot: 745, size: 4, row: 1, column: 3)
        add(832, 8, lot: 709, size: 6, row: 0, column: 2)
        add(932, 8, lot: 795, size: 4, row: 1, column: 2)
        add(940, 8, lot: 795, size: 4, row: 2, column: 2)
        add(952, 4, lot: 811, size: 4, row: 2, column: 1)
        return result
    }()

    /// Chimney cells (row, column) of animated industrial lots; smoke frames draw only inside these cells.
    /// The first is the cell the engine animates. When a factory loses power the engine writes the
    /// second cell's tile into the first (IND3 over IND2 and so on), so those two tiles must be identical.
    static let industrialChimneys: [Int: [(Int, Int)]] = [
        621: [(0, 0)], 639: [(0, 2), (1, 2)], 648: [(0, 1), (0, 2)], 675: [(0, 1), (0, 2)], 684: [(0, 2), (1, 2)],
    ]

    /// Tiles the engine shows in another tile's place, as (shown tile, cell it must also fit).
    static var interchangeableChimneys: [(tile: Int, sameAs: Int)] {
        industrialChimneys.compactMap { lot, cells in
            guard cells.count == 2 else { return nil }
            return (lot + cells[1].0 * 3 + cells[1].1, lot + cells[0].0 * 3 + cells[0].1)
        }.sorted { $0.tile < $1.tile }
    }

    static func makeImage(style: ProceduralTileStyle, classic: CGImage) throws -> CGImage {
        let atlas = try Atlas(style: style, tileSize: tileSize)
        atlas.drawFallback(classic)
        try atlas.drawAll()
        guard let image = atlas.context.makeImage() else { throw TileAtlasError.failedToCreateContext }
        return image
    }

    final class Atlas {
        let style: ProceduralTileStyle
        let tileSize: Int
        let context: CGContext

        init(style: ProceduralTileStyle, tileSize: Int) throws {
            self.style = style
            self.tileSize = tileSize
            let edge = tileSize * 32
            guard let context = CGContext(data: nil, width: edge, height: edge, bitsPerComponent: 8,
                                          bytesPerRow: edge * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
                throw TileAtlasError.failedToCreateContext
            }
            self.context = context
        }

        /// Classic art stays underneath, so any ID without a drawing still shows something sensible.
        func drawFallback(_ classic: CGImage) {
            let edge = CGFloat(tileSize * 32)
            context.interpolationQuality = .none
            context.draw(classic, in: CGRect(x: 0, y: 0, width: edge, height: edge))
            // Top-left origin, so atlas coordinates match the engine's tile numbering.
            context.translateBy(x: 0, y: edge)
            context.scaleBy(x: 1, y: -1)
        }

        func drawAll() throws {
            let scenes = Scenes(style: style)
            for index in 0..<1024 where !Atlas.isLotTile(index) {
                try place(index, size: 1) { scenes.single(index, $0) }
            }
            for lot in Scenes.lots {
                try place(lot.base, size: lot.size) { scenes.lot(lot.base, $0, frame: nil) }
            }
            // The sibling chimney tile is a copy of the animated one, so it fits in either cell.
            for lot in Scenes.lots {
                guard let cells = ProceduralAtlasBuilder.industrialChimneys[lot.base], cells.count == 2 else { continue }
                let image = try render(size: lot.size, seed: lot.base) { scenes.lot(lot.base, $0, frame: nil) }
                try put(image, row: cells[0].0, column: cells[0].1, at: lot.base + cells[1].0 * lot.size + cells[1].1)
            }
            for animation in ProceduralAtlasBuilder.lotAnimations {
                for (frame, index) in animation.frames.enumerated() {
                    let image = try render(size: animation.size, seed: animation.lot) {
                        scenes.lot(animation.lot, $0, frame: frame)
                    }
                    try put(image, row: animation.row, column: animation.column, at: index)
                }
            }
        }

        static func isLotTile(_ index: Int) -> Bool {
            Scenes.lots.contains { index >= $0.base && index < $0.base + $0.size * $0.size }
        }

        private func render(size: Int, seed: Int, _ draw: (TilePainter) -> Void) throws -> CGImage {
            let pixels = size * tileSize
            guard let lot = CGContext(data: nil, width: pixels, height: pixels, bitsPerComponent: 8, bytesPerRow: 0,
                                      space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
                throw TileAtlasError.failedToCreateContext
            }
            lot.translateBy(x: 0, y: CGFloat(pixels))
            lot.scaleBy(x: CGFloat(tileSize), y: -CGFloat(tileSize))
            let painter = TilePainter(context: lot, style: style, size: size, seed: seed)
            draw(painter)
            guard let image = lot.makeImage() else { throw TileAtlasError.failedToCreateContext }
            return image
        }

        private func place(_ base: Int, size: Int, _ draw: (TilePainter) -> Void) throws {
            let image = try render(size: size, seed: base, draw)
            for row in 0..<size {
                for column in 0..<size {
                    try put(image, row: row, column: column, at: base + row * size + column)
                }
            }
        }

        private func put(_ lot: CGImage, row: Int, column: Int, at index: Int) throws {
            guard let fragment = lot.cropping(to: CGRect(x: column * tileSize, y: row * tileSize,
                                                         width: tileSize, height: tileSize)) else {
                throw TileAtlasError.failedToCrop
            }
            let rect = CGRect(x: (index % 32) * tileSize, y: (index / 32) * tileSize, width: tileSize, height: tileSize)
            context.saveGState()
            context.translateBy(x: rect.minX, y: rect.maxY)
            context.scaleBy(x: 1, y: -1)
            context.setBlendMode(.copy)
            context.draw(fragment, in: CGRect(origin: .zero, size: rect.size))
            context.restoreGState()
        }
    }
}

// MARK: - Scenes

private struct Scenes {
    let style: ProceduralTileStyle

    struct Lot { let base: Int; let size: Int }

    static let lots: [Lot] = {
        var result: [Lot] = [Lot(base: 240, size: 3), Lot(base: 423, size: 3), Lot(base: 612, size: 3)]
        result += stride(from: 261, through: 396, by: 9).map { Lot(base: $0, size: 3) }
        result += stride(from: 432, through: 603, by: 9).map { Lot(base: $0, size: 3) }
        result += stride(from: 621, through: 684, by: 9).map { Lot(base: $0, size: 3) }
        result += [Lot(base: 405, size: 3), Lot(base: 414, size: 3)]
        result += stride(from: 956, through: 1010, by: 9).map { Lot(base: $0, size: 3) }
        result += [Lot(base: 693, size: 4), Lot(base: 709, size: 6), Lot(base: 745, size: 4), Lot(base: 761, size: 3),
                   Lot(base: 770, size: 3), Lot(base: 779, size: 4), Lot(base: 795, size: 4), Lot(base: 811, size: 4)]
        return result
    }()

    private typealias B = ProceduralAtlasBuilder

    // MARK: Single tiles

    func single(_ tile: Int, _ p: TilePainter) {
        switch tile {
        case 0, 1, 1019...1023: p.ground(style.grass, specks: 6)
        case 2, 3, 4: water(p)
        case 5...20: shore(B.shoreLand(tile), p)
        case 21...43: forest(tile, p)
        case 44...47, 53...55: rubble(tile, p)
        case 48...51: flood(tile, p)
        case 52: radiation(p)
        case 56...63: fire(tile - 56, p)
        case 64...207: roadFamily(tile, p)
        case 208...223: powerFamily(tile, p)
        case 224...239: railFamily(tile, p)
        case 249...260: house(tile - 249, p)
        case 827: p.ground(style.grass, specks: 6); p.bolt(in: CGRect(x: 0.15, y: 0.1, width: 0.7, height: 0.8))
        case 828...831: drawbridge(horizontal: true, part: tile - 828, p)
        case 948...951: drawbridge(horizontal: false, part: tile - 948, p)
        case 840...843: fountain(tile - 840, p)
        case 844...851: telecom(tile - 844, p)
        case 860...883: explosion(tile - 860, p)
        default: p.ground(style.grass, specks: 6)
        }
    }

    // MARK: Terrain

    private func water(_ p: TilePainter) {
        p.ground(style.water)
        p.waterMarks(in: CGRect(x: 0, y: 0, width: 1, height: 1))
    }

    private func shore(_ land: Int, _ p: TilePainter) {
        p.ground(style.grass, specks: 6)
        let inset: CGFloat = 0.36
        let top = land & B.north != 0 ? inset : -0.5
        let right = land & B.east != 0 ? 1 - inset : 1.5
        let bottom = land & B.south != 0 ? 1 - inset : 1.5
        let left = land & B.west != 0 ? inset : -0.5
        let rect = CGRect(x: left, y: top, width: right - left, height: bottom - top)
        let radius: CGFloat = 0.32
        let sand = CGPath(roundedRect: rect.insetBy(dx: -0.08, dy: -0.08), cornerWidth: radius + 0.08,
                          cornerHeight: radius + 0.08, transform: nil)
        p.fill(sand, style.sand.cg)
        let water = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
        p.fill(water, style.water.cg)
        if style.outlined { p.stroke(water, style.waterMark, width: 0.03) }
        p.cg.saveGState()
        p.cg.addPath(water)
        p.cg.clip()
        p.waterMarks(in: rect.intersection(CGRect(x: 0, y: 0, width: 1, height: 1)))
        p.cg.restoreGState()
    }

    private func forest(_ tile: Int, _ p: TilePainter) {
        p.ground(style.extruded ? style.lawn : style.grass, specks: 4)
        let sides = B.forestSides(tile)
        let jitter: CGFloat = (21...28).contains(tile) ? 0.04 : 0
        var spots: [(CGFloat, CGFloat, CGFloat)] = []
        for (x, y) in [(0.22, 0.22), (0.72, 0.2), (0.25, 0.74), (0.78, 0.76)] {
            let needsWest = x < 0.5, needsNorth = y < 0.5
            let horizontal = needsWest ? sides & B.west != 0 : sides & B.east != 0
            let vertical = needsNorth ? sides & B.north != 0 : sides & B.south != 0
            if horizontal && vertical { spots.append((x + jitter, y - jitter, 0.27)) }
        }
        spots.append((0.5, 0.48, sides == 15 ? 0.3 : 0.26))
        if (40...43).contains(tile) || (37...39).contains(tile) {
            spots = spots.map { ($0.0 + CGFloat(tile % 3) * 0.02, $0.1 + CGFloat(tile % 2) * 0.03, $0.2) }
        }
        for (x, y, r) in spots.sorted(by: { $0.1 < $1.1 }) { p.tree(CGPoint(x: x, y: y), radius: r) }
    }

    private func rubble(_ tile: Int, _ p: TilePainter) {
        p.ground(style.dirt, specks: 10)
        let chunk = style.extruded ? RGB(0x8C8478) : RGB(0xB8B0A2)
        for _ in 0..<(5 + tile % 4) {
            let x = 0.1 + p.random.next() * 0.7, y = 0.1 + p.random.next() * 0.7
            let rect = CGRect(x: x, y: y, width: 0.1 + p.random.next() * 0.12, height: 0.08 + p.random.next() * 0.1)
            p.fill(rect, chunk.darker(p.random.next() * 0.25))
            p.inkOutline(rect)
        }
    }

    private func flood(_ tile: Int, _ p: TilePainter) {
        p.ground(style.grass.mix(style.dirt, 0.4))
        let grow = CGFloat(tile - 48) * 0.04
        let path = CGPath(ellipseIn: CGRect(x: 0.08 - grow, y: 0.12 - grow, width: 0.84 + 2 * grow, height: 0.76 + 2 * grow),
                          transform: nil)
        p.fill(path, style.water.cg)
        if style.outlined { p.stroke(path, style.waterMark, width: 0.03) }
        p.waterMarks(in: CGRect(x: 0.15, y: 0.2, width: 0.7, height: 0.6))
    }

    private func radiation(_ p: TilePainter) {
        p.ground(style.dirt.mix(RGB(0xC9D46A), 0.3), specks: 8)
        let center = CGPoint(x: 0.5, y: 0.5)
        p.fillEllipse(CGRect(x: 0.14, y: 0.14, width: 0.72, height: 0.72), RGB(0xFFD23F))
        for i in 0..<3 {
            let start = -CGFloat.pi / 2 + CGFloat(i) * 2 * .pi / 3 - .pi / 6
            let path = CGMutablePath()
            path.move(to: center)
            path.addArc(center: center, radius: 0.3, startAngle: start, endAngle: start + .pi / 3, clockwise: false)
            path.closeSubpath()
            p.fill(path, style.ink.cg)
        }
        p.fillEllipse(CGRect(x: 0.42, y: 0.42, width: 0.16, height: 0.16), RGB(0xFFD23F))
        p.fillEllipse(CGRect(x: 0.45, y: 0.45, width: 0.1, height: 0.1), style.ink)
    }

    private func fire(_ frame: Int, _ p: TilePainter) {
        p.ground(style.dirt.darker(0.25), specks: 6)
        for i in 0..<3 {
            let phase = CGFloat((frame + i * 3) % 8) / 8
            let x = 0.2 + CGFloat(i) * 0.3
            let h = 0.45 + 0.3 * sin(phase * 2 * .pi)
            for (color, scale) in [(RGB(0xE8483F), 1.0), (RGB(0xF29B4B), 0.7), (RGB(0xFFD23F), 0.4)] as [(RGB, CGFloat)] {
                let w = 0.26 * scale, height = h * scale
                let path = CGMutablePath()
                path.move(to: CGPoint(x: x - w / 2, y: 0.92))
                path.addQuadCurve(to: CGPoint(x: x, y: 0.92 - height), control: CGPoint(x: x - w / 2, y: 0.92 - height * 0.6))
                path.addQuadCurve(to: CGPoint(x: x + w / 2, y: 0.92), control: CGPoint(x: x + w / 2, y: 0.92 - height * 0.6))
                path.closeSubpath()
                p.fill(path, color.cg)
            }
        }
    }

    private func explosion(_ index: Int, _ p: TilePainter) {
        p.ground(style.dirt.darker(0.15), specks: 8)
        let t = CGFloat(index % 8) / 7
        let r = 0.18 + t * 0.3
        let center = CGPoint(x: 0.5, y: 0.5)
        if index < 8 {
            p.fillEllipse(CGRect(x: center.x - r, y: center.y - r, width: 2 * r, height: 2 * r), RGB(0xF29B4B))
            p.fillEllipse(CGRect(x: center.x - r * 0.6, y: center.y - r * 0.6, width: 1.2 * r, height: 1.2 * r), RGB(0xFFD23F))
        } else {
            for i in 0..<5 {
                let angle = CGFloat(i) * 1.3 + t
                let d = 0.1 + t * 0.25
                let s = 0.18 - t * 0.08
                p.fillEllipse(CGRect(x: center.x + cos(angle) * d - s, y: center.y + sin(angle) * d - s,
                                     width: 2 * s, height: 2 * s), RGB(0x8A8A86).lighter(t * 0.5))
            }
        }
    }

    // MARK: Networks

    private enum Network { case road, rail, power }

    private func cornerArc(_ mask: Int) -> (CGPoint, CGFloat)? {
        switch mask {
        case 3: return (CGPoint(x: 1, y: 0), .pi / 2)
        case 9: return (CGPoint(x: 0, y: 0), 0)
        case 6: return (CGPoint(x: 1, y: 1), .pi)
        case 12: return (CGPoint(x: 0, y: 1), .pi * 1.5)
        default: return nil
        }
    }

    private func arc(_ center: CGPoint, _ radius: CGFloat, _ start: CGFloat, reverse: Bool = false) -> [CGPoint] {
        let points = (0...14).map { i -> CGPoint in
            let a = start + CGFloat(i) / 14 * .pi / 2
            return CGPoint(x: center.x + cos(a) * radius, y: center.y + sin(a) * radius)
        }
        return reverse ? points.reversed() : points
    }

    /// The paved or ballast band of a network tile: straight arms, or a curved quarter for corners.
    private func band(_ mask: Int, half: CGFloat) -> CGPath {
        let path = CGMutablePath()
        if let (center, start) = cornerArc(mask) {
            path.addLines(between: arc(center, 0.5 + half, start) + arc(center, 0.5 - half, start, reverse: true))
            path.closeSubpath()
            return path
        }
        path.addRect(CGRect(x: 0.5 - half, y: 0.5 - half, width: 2 * half, height: 2 * half))
        if mask & B.north != 0 { path.addRect(CGRect(x: 0.5 - half, y: 0, width: 2 * half, height: 0.5)) }
        if mask & B.south != 0 { path.addRect(CGRect(x: 0.5 - half, y: 0.5, width: 2 * half, height: 0.5)) }
        if mask & B.west != 0 { path.addRect(CGRect(x: 0, y: 0.5 - half, width: 0.5, height: 2 * half)) }
        if mask & B.east != 0 { path.addRect(CGRect(x: 0.5, y: 0.5 - half, width: 0.5, height: 2 * half)) }
        return path
    }

    private let roadHalf: CGFloat = 0.29

    private func road(_ mask: Int, _ p: TilePainter) {
        let edge: CGFloat = style.outlined ? 0.035 : 0.06
        p.fill(band(mask, half: roadHalf + edge), style.roadEdge.cg)
        p.fill(band(mask, half: roadHalf), style.asphalt.cg)
        let dash: [CGFloat] = [0.14, 0.11]
        let width: CGFloat = style.outlined ? 0.025 : 0.035
        if let (center, start) = cornerArc(mask) {
            let path = CGMutablePath()
            path.addLines(between: arc(center, 0.5, start))
            p.stroke(path, style.laneMark, width: width, dash: dash)
            return
        }
        let straight = mask == 10 || mask == 5
        let stop = straight ? 0.5 : 0.5 - roadHalf
        let resume = straight ? 0.5 : 0.5 + roadHalf
        if mask & B.west != 0 { p.line(CGPoint(x: 0, y: 0.5), CGPoint(x: stop, y: 0.5), style.laneMark, width: width, dash: dash) }
        if mask & B.east != 0 {
            p.line(CGPoint(x: resume, y: 0.5), CGPoint(x: 1, y: 0.5), style.laneMark, width: width, dash: dash,
                   phase: resume.truncatingRemainder(dividingBy: 0.25))
        }
        if mask & B.north != 0 { p.line(CGPoint(x: 0.5, y: 0), CGPoint(x: 0.5, y: stop), style.laneMark, width: width, dash: dash) }
        if mask & B.south != 0 {
            p.line(CGPoint(x: 0.5, y: resume), CGPoint(x: 0.5, y: 1), style.laneMark, width: width, dash: dash,
                   phase: resume.truncatingRemainder(dividingBy: 0.25))
        }
        if !straight && style.outlined {
            p.stroke(CGPath(rect: CGRect(x: 0.5 - roadHalf + 0.05, y: 0.5 - roadHalf + 0.05,
                                         width: 2 * (roadHalf - 0.05), height: 2 * (roadHalf - 0.05)), transform: nil),
                     style.laneMark, width: 0.02, dash: [0.04, 0.04])
        }
    }

    /// Cars move a quarter tile per animation step; lanes keep to the right.
    private func traffic(_ mask: Int, heavy: Bool, step: Int, _ p: TilePainter) {
        guard cornerArc(mask) == nil else { return }
        let lane = roadHalf * 0.48
        let bases: [CGFloat] = heavy ? [0.08, 0.58] : [0.3]
        let shift = CGFloat(step) * 0.25
        func onRoad(_ along: CGFloat, low: Int, high: Int) -> Bool {
            if along < 0.5 - roadHalf { return mask & low != 0 }
            if along > 0.5 + roadHalf { return mask & high != 0 }
            return mask & (low | high) != 0
        }
        for (i, base) in bases.enumerated() {
            let color = style.cars[(i + step) % style.cars.count]
            let forward = (base + shift).truncatingRemainder(dividingBy: 1)
            let backward = (1 + base + 0.5 - shift).truncatingRemainder(dividingBy: 1)
            if mask & (B.east | B.west) != 0 {
                if onRoad(forward, low: B.west, high: B.east) {
                    p.car(CGPoint(x: forward, y: 0.5 + lane), horizontal: true, color: color)
                }
                if onRoad(backward, low: B.west, high: B.east) {
                    p.car(CGPoint(x: backward, y: 0.5 - lane), horizontal: true, color: style.cars[(i + 2) % style.cars.count])
                }
            }
            if mask & (B.north | B.south) != 0 {
                let down = (base + 0.2 + shift).truncatingRemainder(dividingBy: 1)
                let up = (1 + base + 0.7 - shift).truncatingRemainder(dividingBy: 1)
                if onRoad(down, low: B.north, high: B.south) && abs(down - 0.5) > roadHalf {
                    p.car(CGPoint(x: 0.5 - lane, y: down), horizontal: false, color: style.cars[(i + 1) % style.cars.count])
                }
                if onRoad(up, low: B.north, high: B.south) && abs(up - 0.5) > roadHalf {
                    p.car(CGPoint(x: 0.5 + lane, y: up), horizontal: false, color: style.cars[(i + 3) % style.cars.count])
                }
            }
        }
    }

    private func roadFamily(_ tile: Int, _ p: TilePainter) {
        let block = (tile - 64) / 16
        let local = (tile - 64) % 16
        // animate.cpp cycles 80→128→112→96 and 144→192→176→160.
        let heavy = block >= 5
        let step = block == 0 ? 0 : (4 - (block - (heavy ? 5 : 1))) % 4
        let mask: Int
        var overWater = false
        var wire: Int? = nil
        switch local {
        case 0: mask = 10; overWater = true
        case 1: mask = 5; overWater = true
        case 2...12: mask = B.networkMasks[local - 2]
        case 13: mask = 10; wire = 5
        case 14: mask = 5; wire = 10
        default:
            water(p)
            return
        }
        if overWater {
            water(p)
            bridgeDeck(mask, p)
        } else {
            p.ground(style.grass, specks: 6)
            road(mask, p)
        }
        if block > 0 { traffic(mask, heavy: heavy, step: step, p) }
        if let wire { power(wire, p, crossing: true) }
    }

    private func bridgeDeck(_ mask: Int, _ p: TilePainter) {
        let horizontal = mask == 10
        let deck = horizontal ? CGRect(x: 0, y: 0.5 - roadHalf - 0.06, width: 1, height: 2 * roadHalf + 0.12)
                              : CGRect(x: 0.5 - roadHalf - 0.06, y: 0, width: 2 * roadHalf + 0.12, height: 1)
        if style.extruded {
            p.fill(deck.offsetBy(dx: 0.06, dy: 0.08), RGB(0x000000).alpha(0.2))
        }
        p.fill(deck, style.roadEdge)
        road(mask, p)
        let rail = style.outlined ? style.ink : RGB(0xF4F4F0)
        if horizontal {
            p.line(CGPoint(x: 0, y: deck.minY + 0.02), CGPoint(x: 1, y: deck.minY + 0.02), rail, width: 0.03)
            p.line(CGPoint(x: 0, y: deck.maxY - 0.02), CGPoint(x: 1, y: deck.maxY - 0.02), rail, width: 0.03)
        } else {
            p.line(CGPoint(x: deck.minX + 0.02, y: 0), CGPoint(x: deck.minX + 0.02, y: 1), rail, width: 0.03)
            p.line(CGPoint(x: deck.maxX - 0.02, y: 0), CGPoint(x: deck.maxX - 0.02, y: 1), rail, width: 0.03)
        }
    }

    /// Drawbridge pieces from `doBridge`: parts 0 and 2 are the deck ends beside the opening,
    /// parts 1 and 3 the raised leaves beside them.
    private func drawbridge(horizontal: Bool, part: Int, _ p: TilePainter) {
        water(p)
        let lifted = part % 2 == 1
        let leadsIn = part < 2
        if !lifted {
            let deck = horizontal
                ? CGRect(x: leadsIn ? 0 : 0.25, y: 0.5 - roadHalf - 0.06, width: 0.75, height: 2 * roadHalf + 0.12)
                : CGRect(x: 0.5 - roadHalf - 0.06, y: leadsIn ? 0 : 0.25, width: 2 * roadHalf + 0.12, height: 0.75)
            p.fill(deck, style.roadEdge)
            p.fill(deck.insetBy(dx: horizontal ? 0 : 0.06, dy: horizontal ? 0.06 : 0), style.asphalt)
            p.inkOutline(deck)
        } else {
            let leaf = horizontal
                ? CGRect(x: leadsIn ? 0.45 : 0.25, y: 0.35, width: 0.3, height: 0.65)
                : CGRect(x: 0, y: leadsIn ? 0.45 : 0.25, width: 0.65, height: 0.3)
            p.fill(leaf.offsetBy(dx: 0.05, dy: 0.05), RGB(0x000000).alpha(0.2))
            p.fill(leaf, style.asphalt)
            p.inkOutline(leaf)
            let stripe = style.extruded ? style.laneMark : style.laneMark.darker(0.1)
            if horizontal {
                p.line(CGPoint(x: leaf.midX, y: leaf.minY), CGPoint(x: leaf.midX, y: leaf.maxY), stripe, width: 0.03, dash: [0.1, 0.08])
            } else {
                p.line(CGPoint(x: leaf.minX, y: leaf.midY), CGPoint(x: leaf.maxX, y: leaf.midY), stripe, width: 0.03, dash: [0.1, 0.08])
            }
        }
    }

    private func power(_ mask: Int, _ p: TilePainter, crossing: Bool = false) {
        let width: CGFloat = style.outlined ? 0.03 : 0.035
        var poles: [CGPoint] = []
        if crossing {
            if mask == 5 { poles = [CGPoint(x: 0.5, y: 0.08), CGPoint(x: 0.5, y: 0.92)] }
            else { poles = [CGPoint(x: 0.08, y: 0.5), CGPoint(x: 0.92, y: 0.5)] }
        } else {
            poles = [CGPoint(x: 0.5, y: 0.5)]
        }
        for offset in style.extruded ? [-0.05, 0.05] as [CGFloat] : [0] {
            if mask & B.north != 0 { p.line(CGPoint(x: 0.5 + offset, y: 0), CGPoint(x: 0.5 + offset, y: 0.5), style.wire, width: width) }
            if mask & B.south != 0 { p.line(CGPoint(x: 0.5 + offset, y: 0.5), CGPoint(x: 0.5 + offset, y: 1), style.wire, width: width) }
            if mask & B.west != 0 { p.line(CGPoint(x: 0, y: 0.5 + offset), CGPoint(x: 0.5, y: 0.5 + offset), style.wire, width: width) }
            if mask & B.east != 0 { p.line(CGPoint(x: 0.5, y: 0.5 + offset), CGPoint(x: 1, y: 0.5 + offset), style.wire, width: width) }
        }
        for pole in poles {
            if style.extruded {
                p.fillEllipse(CGRect(x: pole.x - 0.04, y: pole.y - 0.01, width: 0.14, height: 0.08), RGB(0x000000).mix(style.grass, 0.75))
                p.fillEllipse(CGRect(x: pole.x - 0.07, y: pole.y - 0.07, width: 0.14, height: 0.14), style.pole)
                p.fillEllipse(CGRect(x: pole.x - 0.035, y: pole.y - 0.05, width: 0.07, height: 0.07), style.pole.lighter(0.3))
            } else {
                let rect = CGRect(x: pole.x - 0.05, y: pole.y - 0.05, width: 0.1, height: 0.1)
                p.fill(rect, RGB(0xFFFFFF))
                p.inkOutline(rect)
            }
        }
    }

    private func powerFamily(_ tile: Int, _ p: TilePainter) {
        switch tile {
        case 208, 209:
            water(p)
            power(tile == 208 ? 10 : 5, p)
        case 210...220:
            p.ground(style.grass, specks: 6)
            power(B.networkMasks[tile - 210], p)
        case 221:
            p.ground(style.grass, specks: 6)
            rail(10, p)
            power(5, p, crossing: true)
        case 222:
            p.ground(style.grass, specks: 6)
            rail(5, p)
            power(10, p, crossing: true)
        default:
            p.ground(style.grass, specks: 6)
        }
    }

    private func rail(_ mask: Int, _ p: TilePainter, ties: Bool = true) {
        let gauge: CGFloat = 0.1
        p.fill(band(mask, half: 0.22), style.railBed.cg)
        if ties {
            if let (center, start) = cornerArc(mask) {
                for i in 0..<6 {
                    let a = start + (CGFloat(i) + 0.5) / 6 * .pi / 2
                    let path = CGMutablePath()
                    path.move(to: CGPoint(x: center.x + cos(a) * (0.5 - 0.17), y: center.y + sin(a) * (0.5 - 0.17)))
                    path.addLine(to: CGPoint(x: center.x + cos(a) * (0.5 + 0.17), y: center.y + sin(a) * (0.5 + 0.17)))
                    p.stroke(path, style.tie, width: 0.05)
                }
            } else {
                for i in 0..<8 {
                    let t = (CGFloat(i) + 0.5) / 8
                    if (mask & (B.east | B.west)) != 0 && ((t < 0.5 && mask & B.west != 0) || (t >= 0.5 && mask & B.east != 0)) {
                        p.fill(CGRect(x: t - 0.025, y: 0.33, width: 0.05, height: 0.34), style.tie)
                    }
                    if (mask & (B.north | B.south)) != 0 && ((t < 0.5 && mask & B.north != 0) || (t >= 0.5 && mask & B.south != 0)) {
                        p.fill(CGRect(x: 0.33, y: t - 0.025, width: 0.34, height: 0.05), style.tie)
                    }
                }
            }
        }
        let width: CGFloat = 0.03
        if let (center, start) = cornerArc(mask) {
            for radius in [0.5 - gauge, 0.5 + gauge] {
                let path = CGMutablePath()
                path.addLines(between: arc(center, radius, start))
                p.stroke(path, style.rail, width: width)
            }
            return
        }
        for offset in [-gauge, gauge] {
            if mask & B.west != 0 { p.line(CGPoint(x: 0, y: 0.5 + offset), CGPoint(x: 0.5 + gauge, y: 0.5 + offset), style.rail, width: width) }
            if mask & B.east != 0 { p.line(CGPoint(x: 0.5 - gauge, y: 0.5 + offset), CGPoint(x: 1, y: 0.5 + offset), style.rail, width: width) }
            if mask & B.north != 0 { p.line(CGPoint(x: 0.5 + offset, y: 0), CGPoint(x: 0.5 + offset, y: 0.5 + gauge), style.rail, width: width) }
            if mask & B.south != 0 { p.line(CGPoint(x: 0.5 + offset, y: 0.5 - gauge), CGPoint(x: 0.5 + offset, y: 1), style.rail, width: width) }
        }
    }

    private func railFamily(_ tile: Int, _ p: TilePainter) {
        switch tile {
        case 224, 225:
            water(p)
            let horizontal = tile == 224
            let deck = horizontal ? CGRect(x: 0, y: 0.26, width: 1, height: 0.48) : CGRect(x: 0.26, y: 0, width: 0.48, height: 1)
            if style.extruded { p.fill(deck.offsetBy(dx: 0.06, dy: 0.08), RGB(0x000000).alpha(0.2)) }
            p.fill(deck, style.roadEdge.darker(0.15))
            rail(horizontal ? 10 : 5, p)
        case 226...236:
            p.ground(style.grass, specks: 6)
            rail(B.networkMasks[tile - 226], p)
        case 237, 238:
            // HRAILROAD is a horizontal track over a vertical road; VRAILROAD the reverse.
            p.ground(style.grass, specks: 6)
            let railMask = tile == 237 ? 10 : 5
            road(railMask == 10 ? 5 : 10, p)
            let horizontal = railMask == 10
            let stripe = style.extruded ? RGB(0xFFFFFF) : style.ink
            for offset in [-0.2, 0.2] as [CGFloat] {
                if horizontal {
                    p.line(CGPoint(x: 0.5 - roadHalf, y: 0.5 + offset), CGPoint(x: 0.5 + roadHalf, y: 0.5 + offset), stripe, width: 0.03, dash: [0.05, 0.04])
                } else {
                    p.line(CGPoint(x: 0.5 + offset, y: 0.5 - roadHalf), CGPoint(x: 0.5 + offset, y: 0.5 + roadHalf), stripe, width: 0.03, dash: [0.05, 0.04])
                }
            }
            rail(railMask, p, ties: false)
        case 239:
            p.ground(style.grass, specks: 6)
            road(5, p)
            power(10, p, crossing: true)
        default:
            p.ground(style.grass, specks: 6)
        }
    }

    // MARK: Small animated things

    private func fountain(_ frame: Int, _ p: TilePainter) {
        // A small park fountain among shrubs, so parks still read as green space.
        p.ground(style.lawn, specks: 4)
        for (x, y) in [(0.2, 0.2), (0.8, 0.22), (0.18, 0.8), (0.82, 0.8)] as [(CGFloat, CGFloat)] {
            p.shrub(CGPoint(x: x, y: y))
        }
        let basin = CGRect(x: 0.32, y: 0.32, width: 0.36, height: 0.36)
        p.tank(CGPoint(x: 0.5, y: 0.5), radius: 0.18, height: 0.04, color: style.paving)
        p.fillEllipse(basin.insetBy(dx: 0.04, dy: 0.04), style.extruded ? RGB(0x5FC8EE) : style.water)
        let spray = 0.03 + CGFloat(frame % 2) * 0.025 + CGFloat(frame / 2) * 0.01
        p.fillEllipse(CGRect(x: 0.5 - spray, y: 0.48 - spray, width: 2 * spray, height: 2 * spray), RGB(0xFFFFFF))
        p.inkOutline(ellipse: basin)
    }

    private func telecom(_ frame: Int, _ p: TilePainter) {
        p.ground(style.grass, specks: 6)
        let base = CGRect(x: 0.3, y: 0.55, width: 0.4, height: 0.3)
        p.building(base, height: 0.12, roof: .flat, color: style.roof(.transport), windows: false)
        p.line(CGPoint(x: 0.5, y: style.extruded ? 0.43 : 0.55), CGPoint(x: 0.5, y: 0.1), style.ink, width: 0.04)
        p.line(CGPoint(x: 0.36, y: 0.22), CGPoint(x: 0.64, y: 0.22), style.ink, width: 0.03)
        if frame % 2 == 0 {
            p.fillEllipse(CGRect(x: 0.44, y: 0.04, width: 0.12, height: 0.12), style.accent)
        }
    }

    // MARK: Houses and zones

    private func house(_ index: Int, _ p: TilePainter) {
        let value = index / 3
        p.ground(value == 0 ? style.grass.mix(style.dirt, 0.3) : style.lawn, specks: 6)
        let w = 0.5 + CGFloat(value) * 0.05
        let rect = CGRect(x: 0.22 + CGFloat(index % 3) * 0.04, y: 0.36, width: w, height: 0.42)
        let color = style.roof(.residential).mix(RGB(0x9A9A9A), [0.4, 0.2, 0.05, 0][value])
        p.fill(CGRect(x: rect.midX - 0.06, y: rect.maxY, width: 0.12, height: 1 - rect.maxY), style.paving)
        p.building(rect, height: 0.16, roof: index % 2 == 0 ? .hip : .gableAcross, color: color)
        if value >= 2 { p.shrub(CGPoint(x: 0.85, y: 0.2)) }
        if value == 3 { p.pool(CGRect(x: 0.08, y: 0.08, width: 0.22, height: 0.14)) }
    }

    private func emptyZone(_ letter: Character, color: RGB, _ p: TilePainter) {
        p.ground(style.extruded ? style.grass.mix(color, 0.12) : style.grass.mix(color, 0.08), specks: 4)
        let rect = CGRect(x: 0.08, y: 0.08, width: 2.84, height: 2.84)
        p.stroke(CGPath(rect: rect, transform: nil), color, width: 0.06, dash: [0.18, 0.12])
        if style.extruded {
            p.fillEllipse(CGRect(x: 1.12, y: 1.12, width: 0.76, height: 0.76), color)
            p.letter(letter, in: CGRect(x: 1.33, y: 1.28, width: 0.34, height: 0.44), color: RGB(0xFFFFFF), width: 0.08)
        } else {
            p.letter(letter, in: CGRect(x: 1.3, y: 1.22, width: 0.4, height: 0.56), color: color, width: 0.08)
        }
    }

    // MARK: Lots

    func lot(_ base: Int, _ p: TilePainter, frame: Int?) {
        switch base {
        case 240: emptyZone("R", color: style.zoneR, p)
        case 423: emptyZone("C", color: style.zoneC, p)
        case 612: emptyZone("I", color: style.zoneI, p)
        case 261...404:
            let index = (base - 261) / 9
            residential(value: index / 4, density: index % 4, p)
        case 432...603:
            let index = (base - 432) / 9
            commercial(value: index / 5, density: index % 5, p)
        case 621...692:
            let index = (base - 621) / 9
            industrial(base: base, value: index / 4, density: index % 4, p, frame: frame)
        case 405: hospital(p)
        case 414: church(0, p)
        case 956...1018: church((base - 956) / 9 + 1, p)
        case 693: seaport(p)
        case 709: airport(p, frame: frame)
        case 745: coalPlant(p, frame: frame)
        case 761: fireStation(p)
        case 770: policeStation(p)
        case 779: stadium(full: false, p, frame: frame)
        case 795: stadium(full: true, p, frame: frame)
        case 811: nuclearPlant(p, frame: frame)
        default: p.ground(style.grass)
        }
    }

    private func tone(_ use: BuildingUse, value: Int) -> RGB {
        style.roof(use).mix(RGB(0x9A9A9A), [0.42, 0.2, 0.06, 0][min(value, 3)])
    }

    private func residential(value: Int, density: Int, _ p: TilePainter) {
        p.ground(value == 0 ? style.grass.mix(style.dirt, 0.35) : style.lawn, specks: 6)
        let color = tone(.residential, value: value)
        let alt = color.mix(style.extruded ? RGB(0xF2B640) : RGB(0xE3CB8B), 0.25)
        switch density {
        case 0:
            let spots: [(CGFloat, CGFloat)] = [(0.2, 0.45), (1.7, 0.4), (0.25, 1.85), (1.65, 1.8)]
            for (i, (x, y)) in spots.enumerated() {
                p.fill(CGRect(x: x + 0.4, y: y + 0.7, width: 0.14, height: 0.4), style.paving)
                p.building(CGRect(x: x, y: y, width: 0.95, height: 0.72), height: 0.18,
                           roof: i % 2 == 0 ? .hip : .gableAcross, color: i % 2 == 0 ? color : alt)
            }
        case 1:
            p.fill(CGRect(x: 0, y: 1.42, width: 3, height: 0.16), style.paving)
            p.building(CGRect(x: 0.2, y: 0.5, width: 2.6, height: 0.8), height: 0.26, roof: .gableAcross, color: color, lines: 4)
            p.building(CGRect(x: 0.2, y: 1.85, width: 2.6, height: 0.8), height: 0.26, roof: .gableAcross, color: alt, lines: 4)
        case 2:
            p.building(CGRect(x: 0.25, y: 0.7, width: 2.5, height: 0.8), height: 0.42, roof: .flat, color: color)
            p.building(CGRect(x: 0.25, y: 1.5, width: 0.85, height: 1.25), height: 0.42, roof: .flat, color: color)
            p.building(CGRect(x: 1.9, y: 1.5, width: 0.85, height: 1.25), height: 0.42, roof: .flat, color: alt)
        default:
            p.building(CGRect(x: 0.5, y: 0.95, width: 2.0, height: 1.75), height: 0.85, roof: .flat, color: color)
        }
        if value >= 2 {
            let trees: [(CGFloat, CGFloat)] = density == 0 ? [(1.45, 1.5), (2.8, 2.75)] : [(0.25, 2.8), (2.75, 2.8), (1.5, 2.85)]
            for (x, y) in trees { p.tree(CGPoint(x: x, y: y), radius: 0.17) }
        }
        if value == 3 && density >= 2 { p.pool(CGRect(x: 1.2, y: 1.85, width: 0.55, height: 0.35)) }
    }

    private func commercial(value: Int, density: Int, _ p: TilePainter) {
        p.ground(style.paving.mix(style.yard, value == 0 ? 0.6 : 0.1))
        let color = tone(.commercial, value: value)
        let alt = color.mix(style.roof(.civic), 0.3)
        switch density {
        case 0:
            p.parking(CGRect(x: 0.15, y: 2.05, width: 2.7, height: 0.8), stalls: 8, cars: 3)
            p.building(CGRect(x: 0.3, y: 0.55, width: 1.5, height: 1.1), height: 0.22, roof: .flat, color: color)
            p.building(CGRect(x: 2.0, y: 0.8, width: 0.75, height: 0.85), height: 0.2, roof: .flat, color: alt)
        case 1:
            p.parking(CGRect(x: 0.15, y: 2.1, width: 2.7, height: 0.75), stalls: 8, cars: 5)
            p.building(CGRect(x: 0.2, y: 0.5, width: 2.6, height: 1.3), height: 0.3, roof: .flat, color: color, lines: 2)
        case 2:
            p.parking(CGRect(x: 1.85, y: 1.4, width: 1.0, height: 1.45), stalls: 3, cars: 2)
            p.building(CGRect(x: 0.2, y: 0.65, width: 1.5, height: 2.15), height: 0.48, roof: .flat, color: color)
            p.building(CGRect(x: 1.85, y: 0.5, width: 1.0, height: 0.8), height: 0.3, roof: .flat, color: alt)
        case 3:
            p.building(CGRect(x: 0.4, y: 0.9, width: 2.2, height: 1.85), height: 0.7, roof: .flat, color: color)
        default:
            p.building(CGRect(x: 0.2, y: 1.0, width: 1.2, height: 1.8), height: 0.9, roof: .flat, color: color)
            p.building(CGRect(x: 1.6, y: 0.95, width: 1.2, height: 1.3), height: 0.75, roof: .flat, color: alt)
        }
        if value >= 2 {
            for x in stride(from: 0.3 as CGFloat, through: 2.7, by: 0.6) { p.shrub(CGPoint(x: x, y: 2.9)) }
        }
    }

    private func industrial(base: Int, value: Int, density: Int, _ p: TilePainter, frame: Int?) {
        p.ground(style.yard.mix(style.dirt, value == 0 ? 0.35 : 0.1), specks: 8)
        let color = tone(.industrial, value: value + 2)
        let metal = style.extruded ? RGB(0xC9CDD2) : RGB(0xD6D3CB)
        // Factories with two chimney cells keep those cells clear of buildings, tanks and their
        // shadows, because the engine swaps the two chimney tiles (see `industrialChimneys`).
        let chimneyRow = (B.industrialChimneys[base]?.count ?? 0) == 2 && B.industrialChimneys[base]![1].0 == 0
        let chimneyColumn = (B.industrialChimneys[base]?.count ?? 0) == 2 && !chimneyRow
        switch density {
        case 0:
            p.building(CGRect(x: 1.1, y: 0.7, width: 1.7, height: 1.4), height: 0.26, roof: .sawtooth, color: color)
            p.tank(CGPoint(x: 0.6, y: 2.3), radius: 0.32, height: 0.25, color: metal)
            p.fill(CGRect(x: 1.2, y: 2.35, width: 1.6, height: 0.45), style.paving)
        case 1:
            p.building(CGRect(x: 0.2, y: 0.55, width: 1.3, height: 1.2), height: 0.26, roof: .sawtooth, color: color)
            p.building(CGRect(x: 1.7, y: 0.55, width: 1.1, height: 2.2), height: 0.3, roof: .gableDown, color: color.darker(0.05))
            p.tank(CGPoint(x: 0.55, y: 2.35), radius: 0.3, height: 0.25, color: metal)
            p.tank(CGPoint(x: 1.2, y: 2.4), radius: 0.24, height: 0.2, color: metal)
        case 2 where chimneyColumn:
            p.building(CGRect(x: 0.2, y: 0.6, width: 1.55, height: 2.2), height: 0.34, roof: .sawtooth, color: color)
            p.tank(CGPoint(x: 2.5, y: 2.55), radius: 0.28, height: 0.24, color: metal)
        case 2 where chimneyRow:
            p.building(CGRect(x: 0.2, y: 1.4, width: 1.9, height: 1.4), height: 0.34, roof: .sawtooth, color: color)
            p.tank(CGPoint(x: 2.5, y: 2.45), radius: 0.3, height: 0.28, color: metal)
            p.tank(CGPoint(x: 0.45, y: 0.5), radius: 0.22, height: 0.2, color: metal)
        case 2:
            p.building(CGRect(x: 0.2, y: 1.0, width: 1.9, height: 1.8), height: 0.34, roof: .sawtooth, color: color)
            p.tank(CGPoint(x: 2.5, y: 2.4), radius: 0.32, height: 0.3, color: metal)
        case 3 where chimneyRow:
            p.building(CGRect(x: 0.2, y: 1.45, width: 1.2, height: 1.35), height: 0.4, roof: .flat, color: color)
            p.tank(CGPoint(x: 2.1, y: 1.85), radius: 0.34, height: 0.3, color: metal, ring: true)
            p.tank(CGPoint(x: 2.15, y: 2.62), radius: 0.28, height: 0.25, color: metal, ring: true)
            p.tank(CGPoint(x: 0.5, y: 0.55), radius: 0.25, height: 0.22, color: metal)
        case 3 where chimneyColumn:
            p.building(CGRect(x: 0.2, y: 1.1, width: 1.2, height: 1.7), height: 0.4, roof: .flat, color: color)
            p.tank(CGPoint(x: 1.5, y: 0.5), radius: 0.28, height: 0.25, color: metal, ring: true)
            p.tank(CGPoint(x: 2.5, y: 2.55), radius: 0.3, height: 0.22, color: metal, ring: true)
            p.tank(CGPoint(x: 0.5, y: 0.55), radius: 0.25, height: 0.22, color: metal)
        default:
            p.building(CGRect(x: 0.2, y: 1.1, width: 1.2, height: 1.7), height: 0.4, roof: .flat, color: color)
            p.tank(CGPoint(x: 2.0, y: 1.6), radius: 0.36, height: 0.35, color: metal, ring: true)
            p.tank(CGPoint(x: 2.1, y: 2.5), radius: 0.3, height: 0.3, color: metal, ring: true)
            p.tank(CGPoint(x: 0.5, y: 0.55), radius: 0.25, height: 0.22, color: metal)
        }
        let chimneys = B.industrialChimneys[base] ?? [(0, 2)]
        for (row, column) in chimneys {
            chimneyWithSmoke(row: row, column: column, p, frame: frame)
        }
    }

    private func chimneyWithSmoke(row: Int, column: Int, _ p: TilePainter, frame: Int?) {
        let height: CGFloat = 0.4
        let center = CGPoint(x: CGFloat(column) + 0.42, y: CGFloat(row) + (style.extruded ? 0.78 : 0.62))
        p.chimney(center, height: style.extruded ? height : 0.6)
        if let frame { p.smoke(above: center, chimneyHeight: style.extruded ? height : 0, frame: frame) }
    }

    private func hospital(_ p: TilePainter) {
        p.ground(style.lawn, specks: 4)
        let color = style.roof(.hospital)
        p.fill(CGRect(x: 1.3, y: 2.3, width: 0.4, height: 0.7), style.paving)
        p.building(CGRect(x: 0.35, y: 0.75, width: 2.3, height: 0.8), height: 0.4, roof: .flat, color: color)
        p.building(CGRect(x: 1.0, y: 0.75, width: 1.0, height: 1.7), height: 0.4, roof: .flat, color: color)
        let lift: CGFloat = style.extruded ? 0.4 : 0
        p.cross(CGPoint(x: 1.5, y: 1.15 - lift), size: 0.5, color: style.accent)
        for (x, y) in [(0.4, 2.2), (2.6, 2.2), (0.4, 2.75), (2.6, 2.75)] as [(CGFloat, CGFloat)] {
            p.tree(CGPoint(x: x, y: y), radius: 0.2)
        }
    }

    private func church(_ variant: Int, _ p: TilePainter) {
        p.ground(style.lawn, specks: 4)
        var random = TileRandom(seed: variant * 31 + 7)
        let colors: [RGB] = [style.roof(.church), style.roof(.civic), style.roof(.residential).mix(style.roof(.church), 0.5)]
        let color = colors[variant % colors.count]
        let across = variant % 2 == 0
        let nave = across ? CGRect(x: 0.5, y: 1.0, width: 2.0, height: 0.95) : CGRect(x: 1.0, y: 0.6, width: 0.95, height: 2.0)
        p.fill(across ? CGRect(x: 2.5, y: 1.35, width: 0.5, height: 0.25) : CGRect(x: 1.35, y: 2.6, width: 0.25, height: 0.4), style.paving)
        p.building(nave, height: 0.32, roof: across ? .gableAcross : .gableDown, color: color)
        let towerSize: CGFloat = 0.5 + random.next() * 0.1
        let tower = across ? CGRect(x: 2.15, y: 1.22, width: towerSize, height: towerSize)
                           : CGRect(x: 1.22, y: 2.15, width: towerSize, height: towerSize)
        p.building(tower, height: 0.7, roof: .hip, color: color.darker(0.08), windows: false)
        let lift: CGFloat = style.extruded ? 0.32 : 0
        p.cross(CGPoint(x: nave.midX - (across ? 0.45 : 0), y: nave.midY - lift - (across ? 0 : 0.45)), size: 0.24,
                color: style.outlined ? style.ink : RGB(0xFFFFFF))
        for i in 0..<3 {
            p.tree(CGPoint(x: 0.3 + CGFloat(i) * 0.4 + random.next() * 0.2, y: 2.6 + random.next() * 0.2), radius: 0.17)
        }
    }

    private func fireStation(_ p: TilePainter) {
        p.ground(style.paving)
        let color = style.roof(.fire)
        p.building(CGRect(x: 0.3, y: 0.5, width: 2.4, height: 1.2), height: 0.36, roof: .flat, color: color, windows: false)
        if style.extruded {
            for i in 0..<3 {
                p.fill(CGRect(x: 0.45 + CGFloat(i) * 0.8, y: 1.38, width: 0.5, height: 0.3), RGB(0xF4F4F0))
            }
        }
        for i in 0..<2 {
            let truck = CGRect(x: 0.55 + CGFloat(i) * 0.8, y: 2.0, width: 0.4, height: 0.75)
            p.fill(truck, style.accent)
            p.fill(CGRect(x: truck.minX + 0.05, y: truck.minY + 0.05, width: 0.3, height: 0.18), RGB(0xFFFFFF))
            p.inkOutline(truck)
        }
        p.tree(CGPoint(x: 2.6, y: 2.5), radius: 0.22)
    }

    private func policeStation(_ p: TilePainter) {
        p.ground(style.lawn, specks: 4)
        p.parking(CGRect(x: 0.15, y: 2.05, width: 2.7, height: 0.8), stalls: 6, cars: 0)
        for i in 0..<3 {
            p.car(CGPoint(x: 0.38 + CGFloat(i) * 0.45, y: 2.25), horizontal: false, color: RGB(0x2E479A))
        }
        let color = style.roof(.police)
        p.building(CGRect(x: 0.35, y: 0.55, width: 2.3, height: 1.2), height: 0.36, roof: .flat, color: color)
        let lift: CGFloat = style.extruded ? 0.36 : 0
        p.star(CGPoint(x: 1.5, y: 1.15 - lift), radius: 0.28, color: style.extruded ? RGB(0xFFD23F) : style.ink)
    }

    private func seaport(_ p: TilePainter) {
        p.ground(style.paving.mix(style.yard, 0.4))
        p.stroke(CGPath(rect: CGRect(x: 0.04, y: 0.04, width: 3.92, height: 3.92), transform: nil), style.ink, width: 0.05)
        p.building(CGRect(x: 0.3, y: 0.55, width: 1.6, height: 1.0), height: 0.34, roof: .gableAcross, color: style.roof(.transport))
        p.building(CGRect(x: 0.3, y: 1.95, width: 1.6, height: 1.0), height: 0.34, roof: .gableAcross, color: style.roof(.transport).darker(0.05))
        let containers: [RGB] = [style.accent, style.zoneC, style.zoneI, style.zoneR]
        for row in 0..<4 {
            for column in 0..<3 {
                let rect = CGRect(x: 2.25 + CGFloat(column) * 0.5, y: 0.5 + CGFloat(row) * 0.38, width: 0.42, height: 0.26)
                p.building(rect, height: 0.1, roof: .flat, color: containers[(row + column) % containers.count], windows: false)
            }
        }
        let crane = style.extruded ? RGB(0xF2B640) : style.ink
        p.line(CGPoint(x: 2.2, y: 3.1), CGPoint(x: 3.8, y: 3.1), crane, width: 0.08)
        p.line(CGPoint(x: 2.4, y: 2.7), CGPoint(x: 2.4, y: 3.5), crane, width: 0.06)
        p.line(CGPoint(x: 3.6, y: 2.7), CGPoint(x: 3.6, y: 3.5), crane, width: 0.06)
        for x in stride(from: 0.3 as CGFloat, through: 3.8, by: 0.5) {
            p.fillEllipse(CGRect(x: x, y: 3.75, width: 0.1, height: 0.1), style.ink)
        }
    }

    private func airport(_ p: TilePainter, frame: Int?) {
        p.ground(style.lawn, specks: 3)
        let runway = CGRect(x: 0.2, y: 3.7, width: 5.6, height: 0.9)
        p.fill(runway, style.asphalt)
        p.line(CGPoint(x: 0.5, y: runway.midY), CGPoint(x: 5.5, y: runway.midY), RGB(0xFFFFFF), width: 0.06, dash: [0.3, 0.2])
        for i in 0..<4 {
            let y = runway.minY + 0.12 + CGFloat(i) * 0.2
            p.line(CGPoint(x: 0.3, y: y), CGPoint(x: 0.6, y: y), RGB(0xFFFFFF), width: 0.06)
            p.line(CGPoint(x: 5.4, y: y), CGPoint(x: 5.7, y: y), RGB(0xFFFFFF), width: 0.06)
        }
        p.inkOutline(runway)
        p.fill(CGRect(x: 0.6, y: 2.6, width: 4.8, height: 0.35), style.asphalt)
        p.fill(CGRect(x: 2.7, y: 2.6, width: 0.35, height: 1.2), style.asphalt)
        p.fill(CGRect(x: 0.4, y: 1.3, width: 3.6, height: 1.3), style.paving)
        p.building(CGRect(x: 0.4, y: 1.1, width: 1.8, height: 0.9), height: 0.32, roof: .flat, color: style.roof(.transport))
        p.building(CGRect(x: 3.5, y: 0.7, width: 2.1, height: 1.6), height: 0.4, roof: .gableAcross, color: style.roof(.transport).darker(0.06))
        plane(CGPoint(x: 1.2, y: 2.35), p)
        plane(CGPoint(x: 4.6, y: 2.75), p)
        plane(CGPoint(x: 1.6, y: 4.15), p, horizontal: true)
        // Control tower with the radar in cell (0, 2).
        let center = CGPoint(x: 2.5, y: style.extruded ? 0.72 : 0.5)
        p.tank(center, radius: 0.2, height: style.extruded ? 0.45 : 0.5, color: style.roof(.transport).lighter(0.2))
        let top = CGPoint(x: center.x, y: center.y - (style.extruded ? 0.45 : 0))
        let angle = CGFloat(frame ?? 0) * .pi / 4
        let tip = CGPoint(x: top.x + cos(angle) * 0.24, y: top.y + sin(angle) * 0.24)
        p.line(CGPoint(x: top.x - (tip.x - top.x), y: top.y - (tip.y - top.y)), tip, style.ink, width: 0.06, cap: .round)
        if frame != nil { p.fillEllipse(CGRect(x: tip.x - 0.04, y: tip.y - 0.04, width: 0.08, height: 0.08), style.accent) }
    }

    private func plane(_ center: CGPoint, _ p: TilePainter, horizontal: Bool = false) {
        let body = horizontal ? CGRect(x: center.x - 0.4, y: center.y - 0.07, width: 0.8, height: 0.14)
                              : CGRect(x: center.x - 0.07, y: center.y - 0.4, width: 0.14, height: 0.8)
        let wing = horizontal ? CGRect(x: center.x - 0.08, y: center.y - 0.38, width: 0.18, height: 0.76)
                              : CGRect(x: center.x - 0.38, y: center.y - 0.08, width: 0.76, height: 0.18)
        let path = CGMutablePath()
        path.addRoundedRect(in: body, cornerWidth: 0.06, cornerHeight: 0.06)
        path.addRoundedRect(in: wing, cornerWidth: 0.04, cornerHeight: 0.04)
        var offset = CGAffineTransform(translationX: 0.08, y: 0.1)
        if style.extruded, let shadow = path.copy(using: &offset) { p.fill(shadow, RGB(0x000000).alpha(0.18)) }
        p.fill(path, RGB(0xFFFFFF).cg)
        if style.outlined { p.stroke(path, style.ink, width: 0.025) }
    }

    private func coalPlant(_ p: TilePainter, frame: Int?) {
        p.ground(style.yard.mix(style.dirt, 0.3), specks: 8)
        let color = style.roof(.power)
        p.building(CGRect(x: 0.25, y: 1.0, width: 1.6, height: 2.7), height: 0.5, roof: .flat, color: color)
        let coal = style.extruded ? RGB(0x3D3A38) : RGB(0x6B6560)
        let pile = CGPath(ellipseIn: CGRect(x: 2.15, y: 2.5, width: 1.6, height: 1.2), transform: nil)
        p.fill(pile, coal.cg)
        if style.outlined { p.stroke(pile, style.ink, width: 0.03) }
        // The four smokestacks occupy the animated cells (0,2), (0,3), (1,2) and (1,3).
        let cells = [(0, 2), (0, 3), (1, 2), (1, 3)]
        for (row, column) in cells {
            chimneyWithSmoke(row: row, column: column, p, frame: frame)
        }
    }

    private func stadium(full: Bool, _ p: TilePainter, frame: Int?) {
        p.ground(style.paving)
        let outer = CGRect(x: 0.2, y: 0.3, width: 3.6, height: 3.5)
        let color = style.roof(.stadium)
        if style.extruded {
            let lifted = outer.offsetBy(dx: 0, dy: -0.25)
            p.fill(CGPath(roundedRect: outer.offsetBy(dx: 0.15, dy: 0.05), cornerWidth: 0.9, cornerHeight: 0.9, transform: nil),
                   RGB(0x000000).alpha(0.16))
            p.fill(CGPath(roundedRect: outer, cornerWidth: 0.9, cornerHeight: 0.9, transform: nil), style.wall(color).cg)
            p.fill(CGPath(roundedRect: lifted, cornerWidth: 0.9, cornerHeight: 0.9, transform: nil), color.cg)
        } else {
            let path = CGPath(roundedRect: outer, cornerWidth: 0.9, cornerHeight: 0.9, transform: nil)
            p.fill(path, color.cg)
            p.stroke(path, style.ink, width: style.inkWidth)
        }
        let lift: CGFloat = style.extruded ? 0.25 : 0
        let stands = outer.insetBy(dx: 0.25, dy: 0.25).offsetBy(dx: 0, dy: -lift)
        let standColor = full ? style.roof(.commercial).mix(style.accent, 0.3) : color.darker(0.12)
        p.fill(CGPath(roundedRect: stands, cornerWidth: 0.7, cornerHeight: 0.7, transform: nil), standColor.cg)
        if full {
            var random = TileRandom(seed: 795)
            for _ in 0..<140 {
                let x = stands.minX + random.next() * stands.width, y = stands.minY + random.next() * stands.height
                p.fill(CGRect(x: x, y: y, width: 0.05, height: 0.05), style.cars[Int(random.next() * 4) % style.cars.count])
            }
        }
        let field = CGRect(x: 0.95, y: 1.05 - lift, width: 2.1, height: 2.0)
        p.fill(field, style.extruded ? RGB(0x5DB04A) : style.lawn)
        for i in 0..<5 where i % 2 == 0 {
            p.fill(CGRect(x: field.minX + CGFloat(i) * field.width / 5, y: field.minY, width: field.width / 5, height: field.height),
                   (style.extruded ? RGB(0x5DB04A) : style.lawn).darker(0.06))
        }
        let lineColor = RGB(0xFFFFFF)
        p.stroke(CGPath(rect: field.insetBy(dx: 0.1, dy: 0.1), transform: nil), lineColor, width: 0.03)
        p.line(CGPoint(x: field.midX, y: field.minY + 0.1), CGPoint(x: field.midX, y: field.maxY - 0.1), lineColor, width: 0.03)
        p.stroke(CGPath(ellipseIn: CGRect(x: field.midX - 0.25, y: field.midY - 0.25, width: 0.5, height: 0.5), transform: nil),
                 lineColor, width: 0.03)
        p.inkOutline(field)
        if full {
            // Players stay inside the two animated cells, (1, 2) and (2, 2), so no frame is cut off.
            let step = CGFloat(frame ?? 0)
            for i in 0..<10 {
                let team = i < 5
                let x = 2.2 + CGFloat((i * 37) % 17) / 17 * 0.5 + sin(step * 0.8 + CGFloat(i)) * 0.08
                let y = 1.2 + CGFloat((i * 53) % 13) / 13 * 1.5 + cos(step * 0.8 + CGFloat(i)) * 0.08
                p.fillEllipse(CGRect(x: x - 0.05, y: y - 0.05, width: 0.1, height: 0.1), team ? style.accent : style.zoneC)
            }
        }
    }

    private func nuclearPlant(_ p: TilePainter, frame: Int?) {
        p.ground(style.lawn.mix(style.paving, 0.5), specks: 3)
        let color = style.roof(.power).mix(RGB(0xFFFFFF), 0.4)
        p.building(CGRect(x: 0.3, y: 0.55, width: 1.5, height: 1.1), height: 0.36, roof: .flat, color: style.roof(.power))
        p.tank(CGPoint(x: 2.9, y: 1.1), radius: 0.62, height: 0.55, color: color, ring: true)
        p.tank(CGPoint(x: 2.9, y: 2.75), radius: 0.62, height: 0.55, color: color, ring: true)
        // The reactor dome fills animated cell (2, 1).
        let center = CGPoint(x: 1.5, y: 2.55)
        p.tank(center, radius: 0.42, height: 0.3, color: RGB(0xE9E6DD))
        let top = CGPoint(x: center.x, y: center.y - (style.extruded ? 0.3 : 0))
        let turn = CGFloat(frame ?? 0) * .pi / 2
        for i in 0..<3 {
            let a = turn + CGFloat(i) * 2 * .pi / 3
            let path = CGMutablePath()
            path.addArc(center: top, radius: 0.22, startAngle: a, endAngle: a + 1.2, clockwise: false)
            p.stroke(path, frame == nil ? RGB(0xB9BEC4) : RGB(0xFFD23F), width: 0.06, cap: .round)
        }
        p.fillEllipse(CGRect(x: top.x - 0.06, y: top.y - 0.06, width: 0.12, height: 0.12), style.ink)
    }
}
