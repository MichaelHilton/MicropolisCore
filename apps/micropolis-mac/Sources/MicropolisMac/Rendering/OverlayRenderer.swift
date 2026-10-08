import CoreGraphics
import Foundation
import MicropolisKit

/// The views of the DOS map window, in the order of its buttons. Population
/// and City Services each open a two-item menu in DOS, so they are split here.
enum MapOverlay: CaseIterable, Hashable {
    case cityForm, powerGrid, transportation
    case populationDensity, populationGrowth
    case traffic, pollution, crime, landValue
    case police, fire

    var title: String {
        switch self {
        case .cityForm: "City Form"
        case .powerGrid: "Power Grid"
        case .transportation: "Transportation"
        case .populationDensity: "Population Density"
        case .populationGrowth: "Population Growth"
        case .traffic: "Traffic Density"
        case .pollution: "Pollution"
        case .crime: "Crime"
        case .landValue: "Land Value"
        case .police: "Police Coverage"
        case .fire: "Fire Coverage"
        }
    }

    /// The engine data layer behind this view, if it is one.
    var dataLayer: OverlayKind? {
        switch self {
        case .populationDensity: .population
        case .populationGrowth: .growth
        case .traffic: .traffic
        case .pollution: .pollution
        case .crime: .crime
        case .landValue: .landValue
        case .police: .police
        case .fire: .fire
        case .powerGrid: .power
        case .cityForm, .transportation: nil
        }
    }

    /// Whether the map window shows the DOS Max/Min color key.
    var hasLegend: Bool { dataLayer != nil && self != .powerGrid }
}

/// Builds the 120x100 color layer drawn over the dimmed city in the map
/// window: one pixel per tile, clear where there is nothing to show.
enum OverlayRenderer {
    struct RGBA: Equatable {
        var r, g, b, a: UInt8
        static let clear = RGBA(r: 0, g: 0, b: 0, a: 0)
    }

    static let width = Engine.width
    static let height = Engine.height

    /// Pixels in row-major order (index `y * width + x`), ready for CGImage.
    static func pixels(for overlay: MapOverlay, cells: [UInt16], data: [Int16]?) -> [RGBA] {
        var out = [RGBA](repeating: .clear, count: width * height)
        switch overlay {
        case .cityForm:
            break
        case .powerGrid:
            // Conducting tiles (wires, plants, zones) the engine's power scan
            // reached are yellow; the rest are purple and need connecting.
            for x in 0..<width {
                for y in 0..<height {
                    let i = x * height + y
                    guard cells[i] & 0x4000 != 0 else { continue }   // CONDBIT
                    let powered = (data?[i] ?? Int16(cells[i] >> 15)) != 0
                    out[y * width + x] = powered
                        ? RGBA(r: 255, g: 255, b: 85, a: 255)
                        : RGBA(r: 170, g: 0, b: 170, a: 255)
                }
            }
        case .transportation:
            for x in 0..<width {
                for y in 0..<height {
                    let tile = Int(cells[x * height + y] & 0x3FF)
                    if (64...206).contains(tile) {                // roads and bridges
                        out[y * width + x] = RGBA(r: 255, g: 255, b: 255, a: 255)
                    } else if (224...238).contains(tile) {        // rail
                        out[y * width + x] = RGBA(r: 255, g: 85, b: 85, a: 255)
                    }
                }
            }
        case .populationGrowth:
            guard let data else { break }
            let peak = max(1, data.map { abs(Int($0)) }.max() ?? 1)
            for x in 0..<width {
                for y in 0..<height {
                    let value = Int(data[x * height + y])
                    guard value != 0 else { continue }
                    let strength = UInt8(min(255, 80 + 175 * abs(value) / peak))
                    out[y * width + x] = value > 0
                        ? RGBA(r: 0, g: strength, b: 0, a: 255)
                        : RGBA(r: strength, g: 0, b: 0, a: 255)
                }
            }
        default:
            guard let data else { break }
            let peak = max(1, Int(data.max() ?? 1))
            for x in 0..<width {
                for y in 0..<height {
                    let value = Int(data[x * height + y])
                    guard value > 0 else { continue }
                    out[y * width + x] = ramp(Double(value) / Double(peak))
                }
            }
        }
        return out
    }

    /// The DOS key runs from light cyan at Min through purple to red at Max.
    static func ramp(_ t: Double) -> RGBA {
        let t = max(0, min(1, t))
        let stops: [(Double, Double, Double)] = [(85, 255, 255), (170, 85, 255), (170, 0, 170), (255, 0, 0)]
        let scaled = t * Double(stops.count - 1)
        let i = min(Int(scaled), stops.count - 2)
        let f = scaled - Double(i)
        let (a, b) = (stops[i], stops[i + 1])
        return RGBA(r: UInt8(a.0 + (b.0 - a.0) * f), g: UInt8(a.1 + (b.1 - a.1) * f),
                    b: UInt8(a.2 + (b.2 - a.2) * f), a: 255)
    }

    static func image(from pixels: [RGBA]) -> CGImage? {
        var bytes = [UInt8]()
        bytes.reserveCapacity(pixels.count * 4)
        for p in pixels {
            // Premultiplied alpha: pixels are either opaque or fully clear.
            bytes += p.a == 0 ? [0, 0, 0, 0] : [p.r, p.g, p.b, p.a]
        }
        guard let provider = CGDataProvider(data: Data(bytes) as CFData) else { return nil }
        return CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32,
                       bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                       bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                       provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)
    }
}
