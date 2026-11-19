import CoreGraphics
import Foundation

/// Draws the moving pieces (train, helicopter, plane, ship, monster, tornado, explosion) for the
/// code-drawn graphics packages. Frame numbers follow `sprite.cpp`:
/// - plane, helicopter, ship: frames 1–8 head N, NE, E, SE, S, SW, W, NW; plane frames 9–11 take off eastward.
/// - train: 1 north–south, 2 east–west, 3 and 4 the two diagonals used on curves, 5 on a bridge.
/// - monster: 1–3 NE, 4–6 SE, 7–9 SW, 10–12 NW (left foot, both, right foot), 13 N, 14 E, 15 S, 16 W.
/// - tornado: 3 swirl frames; explosion: 6 frames from flash to smoke.
enum ProceduralSpriteBuilder {
    /// Pixels per map pixel. The map view zooms to 2× by default and up to 4×.
    static let scale = 3

    struct Kind {
        let type: Int
        let size: Int
        let frames: Int
    }

    static let kinds: [Kind] = [
        Kind(type: 1, size: 32, frames: 5),   // train
        Kind(type: 2, size: 32, frames: 8),   // helicopter
        Kind(type: 3, size: 48, frames: 11),  // plane
        Kind(type: 4, size: 48, frames: 8),   // ship
        Kind(type: 5, size: 48, frames: 16),  // monster
        Kind(type: 6, size: 48, frames: 3),   // tornado
        Kind(type: 7, size: 48, frames: 6),   // explosion
    ]

    static func makeSheets(style: ProceduralTileStyle) throws -> [Int: SpriteSheet] {
        var sheets: [Int: SpriteSheet] = [:]
        for kind in kinds {
            sheets[kind.type] = SpriteSheet(image: try makeImage(kind, style: style), frameSize: kind.size)
        }
        return sheets
    }

    static func makeImage(_ kind: Kind, style: ProceduralTileStyle) throws -> CGImage {
        let pixels = kind.size * scale
        guard let context = CGContext(data: nil, width: pixels * kind.frames, height: pixels, bitsPerComponent: 8,
                                      bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            throw TileAtlasError.failedToCreateContext
        }
        context.translateBy(x: 0, y: CGFloat(pixels))
        context.scaleBy(x: CGFloat(scale), y: -CGFloat(scale))
        for frame in 1...kind.frames {
            context.saveGState()
            context.clip(to: CGRect(x: (frame - 1) * kind.size, y: 0, width: kind.size, height: kind.size))
            context.translateBy(x: CGFloat((frame - 1) * kind.size) + CGFloat(kind.size) / 2,
                                y: CGFloat(kind.size) / 2)
            var pen = SpritePen(context: context, style: style, seed: kind.type * 100 + frame)
            switch kind.type {
            case 1: pen.train(frame: frame)
            case 2: pen.helicopter(frame: frame)
            case 3: pen.plane(frame: frame)
            case 4: pen.ship(frame: frame)
            case 5: pen.monster(frame: frame)
            case 6: pen.tornado(frame: frame)
            default: pen.explosion(frame: frame)
            }
            context.restoreGState()
        }
        guard let image = context.makeImage() else { throw TileAtlasError.failedToCreateContext }
        return image
    }

    /// Clockwise heading from north, in radians, for the 8-way frames.
    static func heading(_ frame: Int) -> CGFloat { CGFloat((frame - 1) % 8) * .pi / 4 }

    /// The monster's heading and step (-1 left foot forward, 0 both feet, 1 right foot).
    static func monsterPose(_ frame: Int) -> (heading: CGFloat, step: CGFloat) {
        if frame >= 13 {
            return (CGFloat(frame - 13) * .pi / 2, frame <= 14 ? -1 : 1)
        }
        let diagonal = (frame - 1) / 3
        let foot = (frame - 1) % 3
        let leftFirst = diagonal == 0 || diagonal == 3
        let step: CGFloat = foot == 1 ? 0 : ((foot == 0) == leftFirst ? -1 : 1)
        return (.pi / 4 + CGFloat(diagonal) * .pi / 2, step)
    }

    /// The train's angle: 0 north–south, π/2 east–west, then the two curve diagonals.
    static func trainAngle(_ frame: Int) -> CGFloat {
        switch frame {
        case 2: return .pi / 2
        case 3: return -.pi / 4
        case 4: return .pi / 4
        default: return 0
        }
    }
}

/// Draws one sprite frame centred on the origin, in map pixels with y pointing down.
private struct SpritePen {
    let cg: CGContext
    let style: ProceduralTileStyle
    var random: TileRandom

    init(context: CGContext, style: ProceduralTileStyle, seed: Int) {
        cg = context
        self.style = style
        random = TileRandom(seed: seed)
    }

    private var toy: Bool { style.extruded }
    private var ink: RGB { style.ink }
    private var inkWidth: CGFloat { 0.9 }

    // MARK: Helpers

    private func shape(_ path: CGPath, _ color: RGB, outline: Bool = true, shade: Bool = true) {
        cg.addPath(path)
        cg.setFillColor(color.cg)
        cg.fillPath()
        if toy && shade {
            // A light edge on the upper left and a darker one lower right give the toy a moulded look.
            cg.saveGState()
            cg.addPath(path)
            cg.clip()
            cg.setStrokeColor(color.darker(0.25).cg)
            cg.setLineWidth(2.2)
            cg.translateBy(x: -0.7, y: -0.7)
            cg.addPath(path)
            cg.strokePath()
            cg.restoreGState()
        }
        if !toy && outline {
            cg.addPath(path)
            cg.setStrokeColor(ink.cg)
            cg.setLineWidth(inkWidth)
            cg.setLineJoin(.round)
            cg.strokePath()
        }
    }

    private func shadow(_ path: CGPath, dx: CGFloat, dy: CGFloat, alpha: CGFloat = 0.22) {
        cg.saveGState()
        cg.translateBy(x: dx, y: dy)
        cg.addPath(path)
        cg.setFillColor(RGB(0x000000).alpha(toy ? alpha : alpha * 0.7))
        cg.fillPath()
        cg.restoreGState()
    }

    private func ellipse(_ cx: CGFloat, _ cy: CGFloat, _ rx: CGFloat, _ ry: CGFloat) -> CGPath {
        CGPath(ellipseIn: CGRect(x: cx - rx, y: cy - ry, width: 2 * rx, height: 2 * ry), transform: nil)
    }

    private func rounded(_ rect: CGRect, _ radius: CGFloat) -> CGPath {
        CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
    }

    private func polygon(_ points: [CGPoint]) -> CGPath {
        let path = CGMutablePath()
        path.addLines(between: points)
        path.closeSubpath()
        return path
    }

    private func line(_ a: CGPoint, _ b: CGPoint, _ color: CGColor, width: CGFloat) {
        cg.move(to: a)
        cg.addLine(to: b)
        cg.setStrokeColor(color)
        cg.setLineWidth(width)
        cg.setLineCap(.round)
        cg.strokePath()
    }

    private func rotated(_ angle: CGFloat, _ draw: () -> Void) {
        cg.saveGState()
        cg.rotate(by: angle)
        draw()
        cg.restoreGState()
    }

    // MARK: Train

    func train(frame: Int) {
        let onBridge = frame == 5
        rotated(ProceduralSpriteBuilder.trainAngle(frame)) {
            if onBridge { cg.setAlpha(0.75) }
            let engine = rounded(CGRect(x: -3.2, y: -13.5, width: 6.4, height: 12.5), 2.2)
            let wagon = rounded(CGRect(x: -3.2, y: 0.5, width: 6.4, height: 12.5), 1.2)
            shadow(engine, dx: 1.2, dy: 1.4)
            shadow(wagon, dx: 1.2, dy: 1.4)
            let body = toy ? style.accent : style.roof(.transport)
            let car = toy ? style.laneMark : style.roof(.industrial)
            shape(engine, body)
            shape(wagon, car)
            // Cab windows on the engine and a seam across the wagon roof.
            shape(rounded(CGRect(x: -2.2, y: -12.2, width: 4.4, height: 2.6), 0.8),
                  toy ? RGB(0x2F3437) : ink.lighter(0.55), outline: false, shade: false)
            line(CGPoint(x: -3.2, y: 6.75), CGPoint(x: 3.2, y: 6.75), (toy ? car.darker(0.3) : ink).cg, width: 0.6)
            shape(ellipse(0, -5, 1.2, 1.2), toy ? RGB(0x3D3A38) : ink.lighter(0.3), outline: false, shade: false)
        }
    }

    // MARK: Helicopter

    func helicopter(frame: Int) {
        let height: CGFloat = 4
        rotated(ProceduralSpriteBuilder.heading(frame)) {
            let body = ellipse(0, -1.5, 4.2, 6.2)
            let boom = rounded(CGRect(x: -1, y: 3, width: 2, height: 9), 1)
            let fin = rounded(CGRect(x: -3.5, y: 10.5, width: 7, height: 1.8), 0.8)
            for part in [body, boom, fin] { shadow(part, dx: height, dy: height + 1.5, alpha: 0.18) }
            let paint = toy ? style.roof(.police) : style.roof(.police).lighter(0.2)
            shape(boom, paint)
            shape(fin, paint)
            shape(body, paint)
            shape(ellipse(0, -4.2, 3, 2.6), toy ? RGB(0xBFE6F7) : RGB(0xFFFFFF), outline: !toy, shade: false)
            // Rotor: a faint disc with two blades that turn a little with every heading.
            cg.addPath(ellipse(0, -1.5, 11.5, 11.5))
            cg.setFillColor((toy ? RGB(0xFFFFFF) : ink).alpha(toy ? 0.22 : 0.08))
            cg.fillPath()
            let spin = CGFloat(frame) * 0.7
            for blade in 0..<2 {
                let a = spin + CGFloat(blade) * .pi / 2
                line(CGPoint(x: cos(a) * 11, y: -1.5 + sin(a) * 11), CGPoint(x: -cos(a) * 11, y: -1.5 - sin(a) * 11),
                     (toy ? RGB(0x2F3437) : ink).alpha(0.85), width: 1.1)
            }
            shape(ellipse(0, -1.5, 1.3, 1.3), toy ? RGB(0x2F3437) : ink, outline: false, shade: false)
        }
    }

    // MARK: Plane

    func plane(frame: Int) {
        let angle: CGFloat
        let lift: CGFloat
        let size: CGFloat
        if frame > 8 {
            // Frames 11, 10, 9 roll down the runway and climb eastward.
            let progress = CGFloat(11 - frame) / 3
            angle = .pi / 2
            lift = 1 + progress * 3
            size = 0.82 + progress * 0.12
        } else {
            angle = ProceduralSpriteBuilder.heading(frame)
            lift = 4.5
            size = 1
        }
        rotated(angle) {
            cg.scaleBy(x: size, y: size)
            let fuselage = rounded(CGRect(x: -2.4, y: -16, width: 4.8, height: 31), 2.4)
            let wings = polygon([CGPoint(x: -1.5, y: -5), CGPoint(x: -15, y: 3), CGPoint(x: -15, y: 5.5),
                                 CGPoint(x: -1.5, y: 1.5), CGPoint(x: 1.5, y: 1.5), CGPoint(x: 15, y: 5.5),
                                 CGPoint(x: 15, y: 3), CGPoint(x: 1.5, y: -5)])
            let tail = polygon([CGPoint(x: -1, y: 9), CGPoint(x: -6.5, y: 13.5), CGPoint(x: -6.5, y: 15),
                                CGPoint(x: 6.5, y: 15), CGPoint(x: 6.5, y: 13.5), CGPoint(x: 1, y: 9)])
            // Rotate the shadow offset back so it always falls down and to the right.
            let dx = (cos(-angle) * lift - sin(-angle) * lift) / size
            let dy = (sin(-angle) * lift + cos(-angle) * lift) / size
            for part in [wings, tail, fuselage] { shadow(part, dx: dx, dy: dy, alpha: 0.2) }
            let paint = toy ? RGB(0xF7F7F4) : RGB(0xFFFFFF)
            shape(wings, toy ? RGB(0xDADDE2) : paint)
            shape(tail, toy ? RGB(0xDADDE2) : paint)
            shape(fuselage, paint)
            // A coloured stripe and a cockpit window.
            line(CGPoint(x: 0, y: -11), CGPoint(x: 0, y: 13), (toy ? style.accent : style.zoneC).alpha(0.9), width: 1.4)
            shape(rounded(CGRect(x: -1.5, y: -14.5, width: 3, height: 2.6), 1), toy ? RGB(0x2F3437) : ink,
                  outline: false, shade: false)
            if toy {
                shape(ellipse(-7, 2.5, 1.4, 2.2), RGB(0x9AA0A6), outline: false, shade: false)
                shape(ellipse(7, 2.5, 1.4, 2.2), RGB(0x9AA0A6), outline: false, shade: false)
            }
        }
    }

    // MARK: Ship

    func ship(frame: Int) {
        rotated(ProceduralSpriteBuilder.heading(frame)) {
            // Wake first, spreading behind the stern.
            let wake = (toy ? RGB(0xFFFFFF) : style.waterMark.darker(0.1)).alpha(toy ? 0.7 : 0.9)
            line(CGPoint(x: -3, y: 15), CGPoint(x: -8, y: 23), wake, width: 1.2)
            line(CGPoint(x: 3, y: 15), CGPoint(x: 8, y: 23), wake, width: 1.2)
            line(CGPoint(x: 0, y: 16), CGPoint(x: 0, y: 22), wake, width: 0.9)
            let hull = CGMutablePath()
            hull.move(to: CGPoint(x: 0, y: -18))
            hull.addQuadCurve(to: CGPoint(x: 5.5, y: -6), control: CGPoint(x: 5.5, y: -14))
            hull.addLine(to: CGPoint(x: 5.5, y: 13))
            hull.addQuadCurve(to: CGPoint(x: -5.5, y: 13), control: CGPoint(x: 0, y: 16))
            hull.addLine(to: CGPoint(x: -5.5, y: -6))
            hull.addQuadCurve(to: CGPoint(x: 0, y: -18), control: CGPoint(x: -5.5, y: -14))
            hull.closeSubpath()
            shadow(hull, dx: 1.2, dy: 1.5, alpha: 0.25)
            shape(hull, toy ? style.accent.darker(0.15) : RGB(0xFFFFFF))
            shape(rounded(CGRect(x: -4.3, y: -9, width: 8.6, height: 20), 1), toy ? RGB(0x8C8F94) : style.paving,
                  outline: false, shade: false)
            // Rows of containers, then the bridge at the stern.
            let colours = toy ? [style.zoneC, style.laneMark, style.zoneR, style.roof(.residential)]
                              : [style.roof(.commercial), style.roof(.industrial), style.roof(.residential)]
            for row in 0..<4 {
                for column in 0..<2 {
                    let box = CGRect(x: -3.8 + CGFloat(column) * 3.9, y: -8 + CGFloat(row) * 3.8, width: 3.5, height: 3.3)
                    shape(CGPath(rect: box, transform: nil), colours[(row * 2 + column + row) % colours.count],
                          outline: !toy, shade: false)
                }
            }
            let bridge = rounded(CGRect(x: -4, y: 7.8, width: 8, height: 4.2), 0.8)
            shape(bridge, RGB(0xFFFFFF))
            line(CGPoint(x: -3, y: 8.8), CGPoint(x: 3, y: 8.8), (toy ? RGB(0x2F3437) : ink).cg, width: 0.8)
        }
    }

    // MARK: Monster

    /// An original creature: a squat, horned beast with a spiked tail, seen from above.
    func monster(frame: Int) {
        let pose = ProceduralSpriteBuilder.monsterPose(frame)
        rotated(pose.heading) {
            let skin = toy ? RGB(0x8E5BD0) : RGB(0xB9A3CF)
            let belly = toy ? RGB(0xB892E8) : RGB(0xD9CCE6)
            let spikes = toy ? RGB(0xF29B4B) : RGB(0xE3CB8B)
            let reach = 4.5 * pose.step
            // Legs: the stepping pair reaches forward while the other pushes back.
            let legs = [(-8.5, -5 + reach), (8.5, -5 - reach), (-8.5, 7 - reach), (8.5, 7 + reach)]
            let tail = CGMutablePath()
            tail.move(to: CGPoint(x: -4.5, y: 8))
            tail.addQuadCurve(to: CGPoint(x: 1.5 * pose.step, y: 23), control: CGPoint(x: -3 - 2 * pose.step, y: 17))
            tail.addQuadCurve(to: CGPoint(x: 4.5, y: 8), control: CGPoint(x: 3 - 2 * pose.step, y: 17))
            tail.closeSubpath()
            let body = ellipse(0, 1, 8.5, 11.5)
            let head = ellipse(0, -13, 6, 5.5)
            for part in [tail, body, head] { shadow(part, dx: 2, dy: 2.5, alpha: 0.25) }
            for (x, y) in legs {
                let leg = ellipse(x, y, 3.2, 4.2)
                shadow(leg, dx: 2, dy: 2.5, alpha: 0.25)
                shape(leg, skin.darker(0.12))
                for toe in [-1.6, 0, 1.6] {
                    cg.addPath(ellipse(x + toe, y - 3.6, 0.7, 0.7))
                    cg.setFillColor((toy ? RGB(0xFFFFFF) : ink).cg)
                    cg.fillPath()
                }
            }
            shape(tail, skin)
            shape(body, skin)
            shape(ellipse(0, 2, 4.5, 7.5), belly, outline: false, shade: false)
            // A ridge of spikes down the spine and out along the tail.
            for i in 0..<6 {
                let y = -7 + CGFloat(i) * 4.6
                let x = i >= 4 ? CGFloat(i - 3) * 0.6 * pose.step : 0
                shape(polygon([CGPoint(x: x - 1.8, y: y + 1.6), CGPoint(x: x, y: y - 2.2),
                               CGPoint(x: x + 1.8, y: y + 1.6)]), spikes, shade: false)
            }
            shape(head, skin)
            // Horns and eyes.
            shape(polygon([CGPoint(x: -4.5, y: -15.5), CGPoint(x: -7.5, y: -20), CGPoint(x: -2.8, y: -17)]), spikes,
                  shade: false)
            shape(polygon([CGPoint(x: 4.5, y: -15.5), CGPoint(x: 7.5, y: -20), CGPoint(x: 2.8, y: -17)]), spikes,
                  shade: false)
            for side in [-1.0, 1.0] {
                shape(ellipse(side * 2.6, -14.2, 1.6, 1.6), RGB(0xFFF6C8), outline: !toy, shade: false)
                cg.addPath(ellipse(side * 2.6, -14.7, 0.7, 0.7))
                cg.setFillColor(RGB(0x1E1E24).cg)
                cg.fillPath()
            }
        }
    }

    // MARK: Tornado

    mutating func tornado(frame: Int) {
        let turn = CGFloat(frame - 1) * 2 * .pi / 3
        // Dust and debris kicked up around the base.
        cg.addPath(ellipse(0, 4, 19, 15))
        cg.setFillColor((toy ? RGB(0xC9B48A) : style.dirt.darker(0.15)).alpha(toy ? 0.45 : 0.55))
        cg.fillPath()
        for _ in 0..<14 {
            let a = random.next() * 2 * .pi + turn
            let r = 9 + random.next() * 10
            let piece = CGRect(x: cos(a) * r - 0.8, y: 4 + sin(a) * r * 0.8 - 0.8, width: 1.6, height: 1.6)
            cg.setFillColor((toy ? RGB(0x6B4F3A) : ink).alpha(0.7))
            cg.fill(piece)
        }
        // Layered funnel, narrowing toward the ground and offset as it leans.
        let greys: [RGB] = toy ? [RGB(0x9EA4AA), RGB(0x878D94), RGB(0x6F757C), RGB(0x5A5F66)]
                               : [RGB(0xE3E4E2), RGB(0xD2D4D2), RGB(0xBFC2C1), RGB(0xA9ADAD)]
        for (i, grey) in greys.enumerated() {
            let r = 15 - CGFloat(i) * 3.4
            let lean = CGFloat(i) * 1.6
            shape(ellipse(lean * 0.6, -4 + lean, r, r * 0.9), grey, outline: !toy, shade: false)
        }
        // Spiral bands that turn from frame to frame.
        let spiral = (toy ? RGB(0xFFFFFF) : ink).alpha(toy ? 0.55 : 0.75)
        for arm in 0..<3 {
            let path = CGMutablePath()
            for step in 0...20 {
                let t = CGFloat(step) / 20
                let a = turn + CGFloat(arm) * 2 * .pi / 3 + t * 4.2
                let r = 2 + t * 12.5
                let point = CGPoint(x: cos(a) * r + (1 - t) * 6 * 0.6, y: -4 + sin(a) * r * 0.9 + (1 - t) * 6)
                if step == 0 { path.move(to: point) } else { path.addLine(to: point) }
            }
            cg.addPath(path)
            cg.setStrokeColor(spiral)
            cg.setLineWidth(1)
            cg.setLineCap(.round)
            cg.strokePath()
        }
    }

    // MARK: Explosion

    mutating func explosion(frame: Int) {
        let radius: [CGFloat] = [6, 11, 16, 19, 20, 21]
        let r = radius[frame - 1]
        let smoke = toy ? RGB(0x55585C) : RGB(0x8E8F8C)
        if frame >= 3 {
            // Smoke clouds billowing outwards, fading in the last frames.
            let fade: CGFloat = frame == 6 ? 0.45 : (frame == 5 ? 0.75 : 1)
            cg.setAlpha(fade)
            for i in 0..<9 {
                let a = CGFloat(i) * 2 * .pi / 9 + CGFloat(frame) * 0.3
                let d = r * 0.62
                let puff = ellipse(cos(a) * d, sin(a) * d, r * 0.42, r * 0.42)
                shape(puff, smoke.lighter(CGFloat(i % 3) * 0.12), outline: !toy, shade: false)
            }
            cg.setAlpha(1)
        }
        if frame <= 4 {
            // Fireball: a jagged burst with a hot core.
            let points = 12
            var burst: [CGPoint] = []
            for i in 0..<(points * 2) {
                let a = CGFloat(i) * .pi / CGFloat(points) + CGFloat(frame) * 0.4
                let reach = (i % 2 == 0 ? 1 : 0.62) * r * (frame == 4 ? 0.75 : 1) * (0.9 + random.next() * 0.2)
                burst.append(CGPoint(x: cos(a) * reach, y: sin(a) * reach))
            }
            let outer = toy ? RGB(0xF2762E) : RGB(0xE59C93)
            shape(polygon(burst), outer, shade: false)
            let inner = burst.map { CGPoint(x: $0.x * 0.62, y: $0.y * 0.62) }
            shape(polygon(inner), toy ? RGB(0xF4D35E) : RGB(0xF1DFA4), outline: false, shade: false)
            shape(ellipse(0, 0, r * 0.25, r * 0.25), RGB(0xFFFBEA), outline: false, shade: false)
        }
        if frame >= 4 {
            // Embers thrown clear of the cloud.
            for _ in 0..<10 {
                let a = random.next() * 2 * .pi
                let d = r * (0.7 + random.next() * 0.4)
                cg.setFillColor((toy ? RGB(0xF4D35E) : style.accent).alpha(frame == 6 ? 0.5 : 0.9))
                cg.fillEllipse(in: CGRect(x: cos(a) * d - 0.8, y: sin(a) * d - 0.8, width: 1.6, height: 1.6))
            }
        }
    }
}
