import CoreGraphics
import Foundation

/// An sRGB color that can be mixed before it becomes a `CGColor`.
struct RGB: Equatable {
    var r: CGFloat
    var g: CGFloat
    var b: CGFloat

    init(_ hex: UInt32) {
        r = CGFloat((hex >> 16) & 0xFF) / 255
        g = CGFloat((hex >> 8) & 0xFF) / 255
        b = CGFloat(hex & 0xFF) / 255
    }

    init(r: CGFloat, g: CGFloat, b: CGFloat) {
        self.r = r
        self.g = g
        self.b = b
    }

    var cg: CGColor { CGColor(srgbRed: r, green: g, blue: b, alpha: 1) }
    func alpha(_ a: CGFloat) -> CGColor { CGColor(srgbRed: r, green: g, blue: b, alpha: a) }
    func mix(_ other: RGB, _ t: CGFloat) -> RGB {
        RGB(r: r + (other.r - r) * t, g: g + (other.g - g) * t, b: b + (other.b - b) * t)
    }
    func darker(_ t: CGFloat) -> RGB { mix(RGB(0x000000), t) }
    func lighter(_ t: CGFloat) -> RGB { mix(RGB(0xFFFFFF), t) }
}

enum BuildingUse: CaseIterable {
    case residential, commercial, industrial, civic, police, fire, hospital, church, power, transport, stadium
}

/// Where a lot's border leaves a gap; see `TilePainter.zoneFrame`.
enum ZoneFrameOpening: Equatable {
    case none, topOfLastColumn, rightOfFirstRow
}

enum RoofShape {
    case hip, gableAcross, gableDown, flat, sawtooth
}

/// Colors and drawing rules for a code-drawn graphics package. Both styles share geometry;
/// Planner's Map draws inked roof plans, Toy Blocks draws bright extruded blocks.
struct ProceduralTileStyle {
    enum Kind { case plannersMap, toyBlocks }

    let kind: Kind
    let grass: RGB
    let lawn: RGB
    let dirt: RGB
    let water: RGB
    let waterMark: RGB
    let sand: RGB
    let paving: RGB
    let yard: RGB
    let lotLine: RGB
    let asphalt: RGB
    let roadEdge: RGB
    let laneMark: RGB
    let railBed: RGB
    let tie: RGB
    let rail: RGB
    let wire: RGB
    let pole: RGB
    let treeLight: RGB
    let treeDark: RGB
    let ink: RGB
    let zoneR: RGB
    let zoneC: RGB
    let zoneI: RGB
    let accent: RGB
    let roofs: [BuildingUse: RGB]
    let cars: [RGB]

    var extruded: Bool { kind == .toyBlocks }
    var outlined: Bool { kind == .plannersMap }
    var inkWidth: CGFloat { 0.035 }

    func roof(_ use: BuildingUse) -> RGB { roofs[use] ?? RGB(0xCCCCCC) }
    func wall(_ roof: RGB) -> RGB { roof.darker(extruded ? 0.32 : 0.15) }

    static let plannersMap = ProceduralTileStyle(
        kind: .plannersMap,
        grass: RGB(0xE7EBDD), lawn: RGB(0xD6E2C6), dirt: RGB(0xE3DCCB),
        water: RGB(0xA9C7DA), waterMark: RGB(0x8FB4CB), sand: RGB(0xF1E7D6),
        paving: RGB(0xDCDAD3), yard: RGB(0xD1CEC4), lotLine: RGB(0xB9B6AC),
        asphalt: RGB(0xBDBEBA), roadEdge: RGB(0x3A3F44), laneMark: RGB(0xFFFFFF),
        railBed: RGB(0xD9D2C6), tie: RGB(0x8E857A), rail: RGB(0x3A3F44),
        wire: RGB(0x3A3F44), pole: RGB(0x3A3F44),
        treeLight: RGB(0xA9C597), treeDark: RGB(0x86A775), ink: RGB(0x3A3F44),
        zoneR: RGB(0x5E9F5B), zoneC: RGB(0x4F7FB5), zoneI: RGB(0xB88F2E), accent: RGB(0xC8473D),
        roofs: [
            .residential: RGB(0xE6B4A3), .commercial: RGB(0xA9C2DD), .industrial: RGB(0xE3CB8B),
            .civic: RGB(0xC9B8DE), .police: RGB(0x9DB0DB), .fire: RGB(0xE59C93),
            .hospital: RGB(0xF6F3EE), .church: RGB(0xD8C9EA), .power: RGB(0xE2B48A),
            .transport: RGB(0xCDD0D5), .stadium: RGB(0xE9E6DD),
        ],
        cars: [RGB(0xFFFFFF), RGB(0xE6B4A3), RGB(0xA9C2DD), RGB(0xE3CB8B)]
    )

    static let toyBlocks = ProceduralTileStyle(
        kind: .toyBlocks,
        grass: RGB(0x9CCB7A), lawn: RGB(0x8BC26A), dirt: RGB(0xC9B48A),
        water: RGB(0x4FA3D9), waterMark: RGB(0x86C4EC), sand: RGB(0xF3DFA8),
        paving: RGB(0xD4D4CC), yard: RGB(0xB8B9B2), lotLine: RGB(0x9A9C96),
        asphalt: RGB(0x6E7378), roadEdge: RGB(0xD6D6CF), laneMark: RGB(0xF4D35E),
        railBed: RGB(0xB9AE9C), tie: RGB(0x7E5E44), rail: RGB(0x3D3A38),
        wire: RGB(0x2E2E2E), pole: RGB(0x7A5536),
        treeLight: RGB(0x6DB34F), treeDark: RGB(0x3F7F32), ink: RGB(0x2F3437),
        zoneR: RGB(0x3FA34D), zoneC: RGB(0x2F7FD0), zoneI: RGB(0xE0A21C), accent: RGB(0xE8483F),
        roofs: [
            .residential: RGB(0xF07C6C), .commercial: RGB(0x5AA6E8), .industrial: RGB(0xF2B640),
            .civic: RGB(0xB48CE0), .police: RGB(0x4C6EDB), .fire: RGB(0xE8483F),
            .hospital: RGB(0xFFFFFF), .church: RGB(0xF2E2C4), .power: RGB(0xF29B4B),
            .transport: RGB(0xD7DBE0), .stadium: RGB(0xF4F4F0),
        ],
        cars: [RGB(0xE8483F), RGB(0xFFFFFF), RGB(0x2F7FD0), RGB(0xF4D35E), RGB(0x3FA34D)]
    )
}

/// Deterministic noise so a regenerated atlas is byte-identical.
struct TileRandom {
    private var state: UInt64

    init(seed: Int) { state = UInt64(truncatingIfNeeded: seed &* 2_654_435_761 &+ 0x9E37_79B9) | 1 }

    mutating func next() -> CGFloat {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return CGFloat(state % 10_000) / 10_000
    }
}

/// Draws in tile units: (0, 0) is the top-left of the lot and 1 is one map cell.
final class TilePainter {
    let cg: CGContext
    let style: ProceduralTileStyle
    let size: CGFloat
    var random: TileRandom
    /// Drawn once, straight after the next `ground` fill, so a lot's border sits under its buildings.
    var afterGround: ((TilePainter) -> Void)?

    init(context: CGContext, style: ProceduralTileStyle, size: Int, seed: Int) {
        cg = context
        self.style = style
        self.size = CGFloat(size)
        random = TileRandom(seed: seed)
    }

    // MARK: Primitives

    func fill(_ rect: CGRect, _ color: RGB) { cg.setFillColor(color.cg); cg.fill(rect) }
    func fill(_ rect: CGRect, _ color: CGColor) { cg.setFillColor(color); cg.fill(rect) }

    func fill(_ path: CGPath, _ color: CGColor) {
        cg.addPath(path)
        cg.setFillColor(color)
        cg.fillPath(using: .winding)
    }

    func fillEllipse(_ rect: CGRect, _ color: RGB) { cg.setFillColor(color.cg); cg.fillEllipse(in: rect) }

    func stroke(_ path: CGPath, _ color: RGB, width: CGFloat, dash: [CGFloat] = [], phase: CGFloat = 0,
                cap: CGLineCap = .butt) {
        cg.saveGState()
        cg.addPath(path)
        cg.setStrokeColor(color.cg)
        cg.setLineWidth(width)
        cg.setLineCap(cap)
        cg.setLineJoin(.round)
        if !dash.isEmpty { cg.setLineDash(phase: phase, lengths: dash) }
        cg.strokePath()
        cg.restoreGState()
    }

    func line(_ a: CGPoint, _ b: CGPoint, _ color: RGB, width: CGFloat, dash: [CGFloat] = [],
              phase: CGFloat = 0, cap: CGLineCap = .butt) {
        let path = CGMutablePath()
        path.move(to: a)
        path.addLine(to: b)
        stroke(path, color, width: width, dash: dash, phase: phase, cap: cap)
    }

    func inkOutline(_ rect: CGRect) {
        guard style.outlined else { return }
        stroke(CGPath(rect: rect, transform: nil), style.ink, width: style.inkWidth)
    }

    func inkOutline(ellipse rect: CGRect) {
        guard style.outlined else { return }
        stroke(CGPath(ellipseIn: rect, transform: nil), style.ink, width: style.inkWidth)
    }

    // MARK: Ground

    func ground(_ color: RGB, specks: Int = 0) {
        fill(CGRect(x: 0, y: 0, width: size, height: size), color)
        if style.extruded, specks > 0 {
            let speck = color.darker(0.07)
            for _ in 0..<(specks * Int(size * size)) {
                let x = random.next() * size, y = random.next() * size
                fill(CGRect(x: x, y: y, width: 0.06, height: 0.04), speck)
            }
        }
        if let after = afterGround {
            afterGround = nil
            after(self)
        }
    }

    /// The colored border that marks a lot's type, like the frames in the classic tiles.
    /// Planner's Map draws a thin property line; Toy Blocks a raised, rounded kerb.
    /// `opening` leaves the top-right corner open where a factory's two chimney tiles are swapped.
    func zoneFrame(_ color: RGB, opening: ZoneFrameOpening) {
        let inset: CGFloat = style.extruded ? 0.075 : 0.05
        let width: CGFloat = style.extruded ? 0.11 : 0.06
        let radius: CGFloat = style.extruded ? 0.16 : 0
        let lo = inset, hi = size - inset
        let path = CGMutablePath()
        func corner(_ a: CGPoint, _ b: CGPoint) {
            if radius > 0 { path.addArc(tangent1End: a, tangent2End: b, radius: radius) } else { path.addLine(to: a) }
        }
        switch opening {
        case .none:
            path.addRoundedRect(in: CGRect(x: lo, y: lo, width: hi - lo, height: hi - lo),
                                cornerWidth: radius, cornerHeight: radius)
        case .topOfLastColumn:
            // The top line stops short of the last column; the right line runs to the top edge.
            path.move(to: CGPoint(x: size - 1, y: lo))
            corner(CGPoint(x: lo, y: lo), CGPoint(x: lo, y: hi))
            corner(CGPoint(x: lo, y: hi), CGPoint(x: hi, y: hi))
            corner(CGPoint(x: hi, y: hi), CGPoint(x: hi, y: 0))
            path.addLine(to: CGPoint(x: hi, y: 0))
        case .rightOfFirstRow:
            // The top line runs to the right edge; the right line starts below the first row.
            path.move(to: CGPoint(x: size, y: lo))
            corner(CGPoint(x: lo, y: lo), CGPoint(x: lo, y: hi))
            corner(CGPoint(x: lo, y: hi), CGPoint(x: hi, y: hi))
            corner(CGPoint(x: hi, y: hi), CGPoint(x: hi, y: 1))
            path.addLine(to: CGPoint(x: hi, y: 1))
        }
        if style.extruded {
            stroke(path, color.darker(0.18), width: width, cap: .butt)
            cg.saveGState()
            cg.translateBy(x: -0.015, y: -0.02)
            stroke(path, color, width: width * 0.72, cap: .butt)
            cg.restoreGState()
            stroke(path, RGB(0xFFFFFF).mix(color, 0.45), width: 0.022, cap: .butt)
        } else {
            stroke(path, color, width: width, cap: .butt)
        }
    }

    func waterMarks(in rect: CGRect) {
        let count = style.extruded ? 3 : 2
        for _ in 0..<count {
            let x = rect.minX + 0.1 + random.next() * max(rect.width - 0.4, 0.01)
            let y = rect.minY + 0.15 + random.next() * max(rect.height - 0.3, 0.01)
            if style.extruded {
                let path = CGMutablePath()
                path.move(to: CGPoint(x: x, y: y))
                path.addQuadCurve(to: CGPoint(x: x + 0.2, y: y), control: CGPoint(x: x + 0.1, y: y - 0.07))
                stroke(path, style.waterMark, width: 0.04, cap: .round)
            } else {
                line(CGPoint(x: x, y: y), CGPoint(x: x + 0.2, y: y), style.waterMark, width: 0.025)
            }
        }
    }

    // MARK: Things on the ground

    func tree(_ center: CGPoint, radius r: CGFloat) {
        if style.extruded {
            fillEllipse(CGRect(x: center.x - r + 0.05, y: center.y - r + 0.07, width: 2 * r, height: 2 * r),
                        RGB(0x000000).mix(style.grass, 0.75))
            fillEllipse(CGRect(x: center.x - r, y: center.y - r, width: 2 * r, height: 2 * r), style.treeDark)
            fillEllipse(CGRect(x: center.x - r * 0.95, y: center.y - r * 1.05, width: 1.7 * r, height: 1.7 * r),
                        style.treeLight)
            fillEllipse(CGRect(x: center.x - r * 0.5, y: center.y - r * 0.7, width: 0.55 * r, height: 0.45 * r),
                        style.treeLight.lighter(0.25))
        } else {
            let rect = CGRect(x: center.x - r, y: center.y - r, width: 2 * r, height: 2 * r)
            fillEllipse(rect, style.treeLight)
            inkOutline(ellipse: rect)
        }
    }

    func shrub(_ center: CGPoint) { tree(center, radius: 0.11) }

    func car(_ center: CGPoint, horizontal: Bool, color: RGB) {
        let w: CGFloat = horizontal ? 0.2 : 0.11
        let h: CGFloat = horizontal ? 0.11 : 0.2
        let rect = CGRect(x: center.x - w / 2, y: center.y - h / 2, width: w, height: h)
        let path = CGPath(roundedRect: rect, cornerWidth: 0.03, cornerHeight: 0.03, transform: nil)
        fill(path, color.cg)
        if style.outlined {
            stroke(path, style.ink, width: 0.022)
        } else {
            let roof = horizontal ? rect.insetBy(dx: 0.055, dy: 0.02) : rect.insetBy(dx: 0.02, dy: 0.055)
            fill(roof, color.darker(0.25))
        }
    }

    func parking(_ rect: CGRect, stalls: Int, cars: Int) {
        fill(rect, style.extruded ? style.asphalt.lighter(0.12) : style.yard)
        let stall = rect.width / CGFloat(max(stalls, 1))
        let mark = style.extruded ? RGB(0xFFFFFF) : style.ink
        for i in 0...stalls {
            let x = rect.minX + CGFloat(i) * stall
            line(CGPoint(x: x, y: rect.minY), CGPoint(x: x, y: rect.minY + rect.height * 0.42), mark,
                 width: 0.018)
        }
        for i in 0..<min(cars, stalls) {
            let slot = Int(random.next() * CGFloat(stalls))
            let x = rect.minX + (CGFloat(slot) + 0.5) * stall
            car(CGPoint(x: x, y: rect.minY + rect.height * 0.22), horizontal: false,
                color: style.cars[(i + slot) % style.cars.count])
        }
    }

    func pool(_ rect: CGRect) {
        fill(rect.insetBy(dx: -0.04, dy: -0.04), style.paving)
        fill(rect, style.extruded ? RGB(0x5FC8EE) : style.water)
        inkOutline(rect)
    }

    // MARK: Buildings

    /// `height` is in tiles. Toy Blocks lifts the roof by it; Planner's Map casts a shadow.
    func building(_ footprint: CGRect, height: CGFloat, roof shape: RoofShape, color: RGB,
                  windows: Bool = true, lines: Int = 0) {
        let roofRect: CGRect
        if style.extruded {
            roofRect = footprint.offsetBy(dx: 0, dy: -height)
            let shadow = CGMutablePath()
            shadow.addRect(footprint.offsetBy(dx: height * 0.45 + 0.04, dy: 0.03))
            shadow.addRect(roofRect.offsetBy(dx: height * 0.45 + 0.04, dy: 0.03))
            fill(shadow, RGB(0x000000).alpha(0.16))
            let wall = CGRect(x: footprint.minX, y: footprint.maxY - height, width: footprint.width, height: height)
            fill(wall, style.wall(color))
            if windows && height >= 0.14 {
                let rows = max(1, Int(height / 0.14))
                let pitch = height / CGFloat(rows)
                let columns = max(1, Int(footprint.width / 0.15))
                let step = footprint.width / CGFloat(columns)
                let pane = style.wall(color).lighter(0.55)
                for row in 0..<rows {
                    for column in 0..<columns {
                        fill(CGRect(x: footprint.minX + CGFloat(column) * step + step * 0.3,
                                    y: wall.minY + CGFloat(row) * pitch + pitch * 0.3,
                                    width: step * 0.4, height: pitch * 0.4), pane)
                    }
                }
            }
        } else {
            roofRect = footprint
            let reach = 0.06 + height * 0.3
            fill(footprint.offsetBy(dx: reach, dy: reach), style.ink.alpha(0.13))
        }
        fill(roofRect, color)
        roofDetail(roofRect, shape: shape, color: color)
        if lines > 0 {
            let lineColor = style.outlined ? style.ink : color.darker(0.2)
            for i in 1..<(lines + 1) {
                let x = roofRect.minX + roofRect.width * CGFloat(i) / CGFloat(lines + 1)
                line(CGPoint(x: x, y: roofRect.minY), CGPoint(x: x, y: roofRect.maxY), lineColor, width: 0.02)
            }
        }
        if style.outlined {
            inkOutline(roofRect)
        } else {
            stroke(CGPath(rect: roofRect.insetBy(dx: 0.01, dy: 0.01), transform: nil), color.darker(0.12),
                   width: 0.02)
        }
    }

    private func roofDetail(_ rect: CGRect, shape: RoofShape, color: RGB) {
        let lineColor = style.outlined ? style.ink : color.darker(0.18)
        let shade = color.darker(0.1)
        let lineWidth: CGFloat = style.outlined ? 0.022 : 0.02
        switch shape {
        case .hip:
            // A slightly shallow hip keeps a visible ridge on near-square houses.
            let inset = min(min(rect.width, rect.height) / 2, max(rect.width, rect.height) * 0.3)
            let a: CGPoint, b: CGPoint
            if rect.width >= rect.height {
                a = CGPoint(x: rect.minX + inset, y: rect.midY)
                b = CGPoint(x: rect.maxX - inset, y: rect.midY)
            } else {
                a = CGPoint(x: rect.midX, y: rect.minY + inset)
                b = CGPoint(x: rect.midX, y: rect.maxY - inset)
            }
            if style.extruded {
                let facet = CGMutablePath()
                facet.addLines(between: [CGPoint(x: rect.minX, y: rect.maxY), CGPoint(x: rect.maxX, y: rect.maxY),
                                         CGPoint(x: rect.maxX, y: rect.minY), b, a])
                facet.closeSubpath()
                fill(facet, shade.cg)
            }
            let path = CGMutablePath()
            path.move(to: CGPoint(x: rect.minX, y: rect.minY)); path.addLine(to: a)
            path.move(to: CGPoint(x: rect.minX, y: rect.maxY)); path.addLine(to: a)
            path.move(to: CGPoint(x: rect.maxX, y: rect.minY)); path.addLine(to: b)
            path.move(to: CGPoint(x: rect.maxX, y: rect.maxY)); path.addLine(to: b)
            path.move(to: a); path.addLine(to: b)
            stroke(path, lineColor, width: lineWidth)
        case .gableAcross:
            if style.extruded {
                fill(CGRect(x: rect.minX, y: rect.midY, width: rect.width, height: rect.height / 2), shade)
            }
            line(CGPoint(x: rect.minX, y: rect.midY), CGPoint(x: rect.maxX, y: rect.midY), lineColor, width: lineWidth)
        case .gableDown:
            if style.extruded {
                fill(CGRect(x: rect.midX, y: rect.minY, width: rect.width / 2, height: rect.height), shade)
            }
            line(CGPoint(x: rect.midX, y: rect.minY), CGPoint(x: rect.midX, y: rect.maxY), lineColor, width: lineWidth)
        case .flat:
            let inner = rect.insetBy(dx: min(0.07, rect.width / 6), dy: min(0.07, rect.height / 6))
            if style.extruded {
                fill(inner, color.lighter(0.12))
            } else {
                stroke(CGPath(rect: inner, transform: nil), lineColor, width: 0.015)
            }
            if rect.width > 0.6 && rect.height > 0.5 {
                let unit = CGRect(x: inner.minX + inner.width * 0.62, y: inner.minY + inner.height * 0.2,
                                  width: min(0.22, inner.width * 0.25), height: min(0.16, inner.height * 0.25))
                fill(unit, style.extruded ? color.darker(0.22) : style.paving)
                inkOutline(unit)
            }
        case .sawtooth:
            let teeth = max(2, Int(rect.width / 0.28))
            let step = rect.width / CGFloat(teeth)
            for i in 0..<teeth {
                let band = CGRect(x: rect.minX + CGFloat(i) * step, y: rect.minY, width: step * 0.42,
                                  height: rect.height)
                fill(band, style.extruded ? color.lighter(0.3) : color.darker(0.08))
                line(CGPoint(x: band.minX, y: rect.minY), CGPoint(x: band.minX, y: rect.maxY), lineColor,
                     width: lineWidth * 0.8)
            }
        }
    }

    /// A round structure: tanks, silos, cooling towers and domes.
    func tank(_ center: CGPoint, radius r: CGFloat, height: CGFloat, color: RGB, ring: Bool = false) {
        let base = CGRect(x: center.x - r, y: center.y - r, width: 2 * r, height: 2 * r)
        if style.extruded {
            let top = base.offsetBy(dx: 0, dy: -height)
            fillEllipse(base.offsetBy(dx: height * 0.45 + 0.04, dy: 0.03), RGB(0x000000).mix(style.grass, 0.78))
            fill(CGRect(x: base.minX, y: top.midY, width: base.width, height: height), style.wall(color))
            fillEllipse(base, style.wall(color))
            fillEllipse(top, color)
            if ring { fillEllipse(top.insetBy(dx: r * 0.35, dy: r * 0.35), color.darker(0.35)) }
        } else {
            let reach = 0.05 + height * 0.3
            fillEllipse(base.offsetBy(dx: reach, dy: reach), RGB(0x3A3F44).mix(style.grass, 0.85))
            fillEllipse(base, color)
            inkOutline(ellipse: base)
            if ring {
                let inner = base.insetBy(dx: r * 0.35, dy: r * 0.35)
                fillEllipse(inner, color.darker(0.18))
                inkOutline(ellipse: inner)
            }
        }
    }

    func chimney(_ center: CGPoint, height: CGFloat) {
        tank(center, radius: 0.09, height: height, color: style.extruded ? RGB(0xB04A3A) : RGB(0xB8B2A8), ring: true)
    }

    /// Smoke drawn above a chimney; it stays within the chimney's own map cell.
    func smoke(above center: CGPoint, chimneyHeight: CGFloat, frame: Int) {
        let top = style.extruded ? center.y - chimneyHeight : center.y
        let cell = CGPoint(x: floor(center.x), y: floor(center.y))
        let color = style.extruded ? RGB(0xF2F2EE) : RGB(0xFFFFFF)
        for i in 0..<3 {
            let t = CGFloat((frame + i * 2) % 6) / 6
            let r = 0.06 + t * 0.07
            var x = center.x + 0.12 + t * 0.2
            var y = top - 0.08 - t * 0.28
            x = min(max(x, cell.x + r), cell.x + 1 - r)
            y = min(max(y, cell.y + r), cell.y + 1 - r)
            let rect = CGRect(x: x - r, y: y - r, width: 2 * r, height: 2 * r)
            cg.setFillColor(color.alpha(0.9 - t * 0.5))
            cg.fillEllipse(in: rect)
            if style.outlined {
                cg.setStrokeColor(style.ink.alpha(0.5 - t * 0.3))
                cg.setLineWidth(0.015)
                cg.strokeEllipse(in: rect)
            }
        }
    }

    // MARK: Symbols

    /// Large zone letters, drawn as strokes so no font is needed.
    func letter(_ character: Character, in rect: CGRect, color: RGB, width: CGFloat) {
        let x0 = rect.minX, x1 = rect.maxX, y0 = rect.minY, y1 = rect.maxY
        let midY = rect.midY, w = rect.width
        let path = CGMutablePath()
        switch character {
        case "R":
            path.move(to: CGPoint(x: x0, y: y1)); path.addLine(to: CGPoint(x: x0, y: y0))
            path.addLine(to: CGPoint(x: x0 + w * 0.55, y: y0))
            path.addArc(center: CGPoint(x: x0 + w * 0.55, y: (y0 + midY) / 2), radius: (midY - y0) / 2,
                        startAngle: -.pi / 2, endAngle: .pi / 2, clockwise: false)
            path.addLine(to: CGPoint(x: x0, y: midY))
            path.move(to: CGPoint(x: x0 + w * 0.45, y: midY)); path.addLine(to: CGPoint(x: x1, y: y1))
        case "C":
            path.addArc(center: CGPoint(x: rect.midX, y: midY), radius: min(w, rect.height) / 2,
                        startAngle: .pi * 0.25, endAngle: .pi * 1.75, clockwise: false)
        case "I":
            path.move(to: CGPoint(x: x0, y: y0)); path.addLine(to: CGPoint(x: x1, y: y0))
            path.move(to: CGPoint(x: rect.midX, y: y0)); path.addLine(to: CGPoint(x: rect.midX, y: y1))
            path.move(to: CGPoint(x: x0, y: y1)); path.addLine(to: CGPoint(x: x1, y: y1))
        case "H":
            path.move(to: CGPoint(x: x0, y: y0)); path.addLine(to: CGPoint(x: x0, y: y1))
            path.move(to: CGPoint(x: x1, y: y0)); path.addLine(to: CGPoint(x: x1, y: y1))
            path.move(to: CGPoint(x: x0, y: midY)); path.addLine(to: CGPoint(x: x1, y: midY))
        default:
            break
        }
        stroke(path, color, width: width, cap: .round)
    }

    func cross(_ center: CGPoint, size s: CGFloat, color: RGB) {
        let path = CGMutablePath()
        path.addRect(CGRect(x: center.x - s / 2, y: center.y - s / 6, width: s, height: s / 3))
        path.addRect(CGRect(x: center.x - s / 6, y: center.y - s / 2, width: s / 3, height: s))
        fill(path, color.cg)
    }

    func star(_ center: CGPoint, radius r: CGFloat, color: RGB) {
        let path = CGMutablePath()
        for i in 0..<10 {
            let angle = -CGFloat.pi / 2 + CGFloat(i) * .pi / 5
            let radius = i % 2 == 0 ? r : r * 0.45
            let point = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        fill(path, color.cg)
    }

    func bolt(in rect: CGRect) {
        let points: [(CGFloat, CGFloat)] = [(0.58, 0.05), (0.22, 0.55), (0.47, 0.55), (0.38, 0.95),
                                            (0.78, 0.4), (0.53, 0.4), (0.66, 0.05)]
        let path = CGMutablePath()
        path.addLines(between: points.map { CGPoint(x: rect.minX + $0.0 * rect.width, y: rect.minY + $0.1 * rect.height) })
        path.closeSubpath()
        fill(path, RGB(0xFFD23F).cg)
        stroke(path, RGB(0x2F3437), width: 0.035)
    }
}
