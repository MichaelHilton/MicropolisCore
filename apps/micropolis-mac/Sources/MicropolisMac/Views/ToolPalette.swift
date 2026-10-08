import SwiftUI
import MicropolisKit

/// How a tool is drawn in the palette: a building cut from the tile atlas,
/// or a glyph for tools that have no tile of their own.
enum ToolIcon {
    case tiles(base: Int, size: Int)
    case glyph(String)
}

struct ToolSpec: Identifiable {
    let tool: Tool
    let name: String
    let cost: Int
    let shortcut: String
    let icon: ToolIcon

    var id: Tool { tool }

    var statusText: String {
        cost > 0 ? "\(name): $\(cost)" : name
    }

    /// Width in tiles of what the tool builds.
    var size: Int {
        if case .tiles(_, let size) = icon { return size }
        return 1
    }

    /// The tiles a click on `tile` covers. The engine centers buildings of
    /// size 3 and up on the clicked tile, one tile in from the top-left.
    static func footprint(for tool: Tool, at tile: (x: Int, y: Int)) -> (x: Int, y: Int, size: Int) {
        let size = spec(for: tool)?.size ?? 1
        let inset = size > 1 ? 1 : 0
        return (tile.x - inset, tile.y - inset, size)
    }

    /// Two columns, in the order of the DOS palette. Tile numbers come from
    /// the engine's Tiles enum (micropolis.h).
    static let all: [ToolSpec] = [
        ToolSpec(tool: .query, name: "Query", cost: 0, shortcut: "Q", icon: .glyph("?")),
        ToolSpec(tool: .bulldozer, name: "Bulldozer", cost: 1, shortcut: "B", icon: .tiles(base: 44, size: 1)),
        ToolSpec(tool: .road, name: "Roads", cost: 10, shortcut: "R", icon: .tiles(base: 66, size: 1)),
        ToolSpec(tool: .wire, name: "Power Lines", cost: 5, shortcut: "W", icon: .tiles(base: 210, size: 1)),
        ToolSpec(tool: .railroad, name: "Transit Lines", cost: 20, shortcut: "L", icon: .tiles(base: 226, size: 1)),
        ToolSpec(tool: .park, name: "Park", cost: 10, shortcut: "P", icon: .tiles(base: 840, size: 1)),
        ToolSpec(tool: .residential, name: "Residential", cost: 100, shortcut: "U", icon: .tiles(base: 240, size: 3)),
        ToolSpec(tool: .commercial, name: "Commercial", cost: 100, shortcut: "E", icon: .tiles(base: 423, size: 3)),
        ToolSpec(tool: .industrial, name: "Industrial", cost: 100, shortcut: "T", icon: .tiles(base: 612, size: 3)),
        ToolSpec(tool: .policeStation, name: "Police Dept", cost: 500, shortcut: "K", icon: .tiles(base: 770, size: 3)),
        ToolSpec(tool: .fireStation, name: "Fire Dept", cost: 500, shortcut: "F", icon: .tiles(base: 761, size: 3)),
        ToolSpec(tool: .stadium, name: "Stadium", cost: 5000, shortcut: "S", icon: .tiles(base: 779, size: 4)),
        ToolSpec(tool: .coalPower, name: "Coal Power", cost: 3000, shortcut: "Y", icon: .tiles(base: 745, size: 4)),
        ToolSpec(tool: .nuclearPower, name: "Nuclear Power", cost: 5000, shortcut: "N", icon: .tiles(base: 811, size: 4)),
        ToolSpec(tool: .seaport, name: "Seaport", cost: 3000, shortcut: "H", icon: .tiles(base: 693, size: 4)),
        ToolSpec(tool: .airport, name: "Airport", cost: 10000, shortcut: "A", icon: .tiles(base: 709, size: 6)),
    ]

    static func spec(for tool: Tool) -> ToolSpec? {
        all.first { $0.tool == tool }
    }
}

struct ToolPalette: View {
    @Environment(GameModel.self) var model

    private let columns = [GridItem(.fixed(40), spacing: 4), GridItem(.fixed(40), spacing: 4)]

    var body: some View {
        VStack(spacing: 8) {
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(ToolSpec.all) { spec in
                    ToolButton(
                        spec: spec,
                        image: image(for: spec.icon),
                        isSelected: model.selectedTool == spec.tool,
                        action: { model.selectedTool = spec.tool }
                    )
                }
            }

            DemandGauge(
                residential: model.demandResidential,
                commercial: model.demandCommercial,
                industrial: model.demandIndustrial
            )

            Spacer(minLength: 0)
        }
        .padding(6)
        .frame(width: 96)
        .background(DOS.lightGray)
    }

    private func image(for icon: ToolIcon) -> CGImage? {
        guard case let .tiles(base, size) = icon else { return nil }
        return model.tileAtlas.buildingImage(base: base, size: size)
    }
}

struct ToolButton: View {
    let spec: ToolSpec
    let image: CGImage?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                DOS.black
                if let image {
                    Image(decorative: image, scale: 1)
                        .resizable()
                        .interpolation(.none)
                        .padding(2)
                } else if case let .glyph(text) = spec.icon {
                    Text(text)
                        .font(DOS.font(22))
                        .foregroundColor(DOS.white)
                }
            }
            .frame(width: 40, height: 40)
            .overlay(
                Rectangle().stroke(isSelected ? DOS.yellow : DOS.darkGray, lineWidth: isSelected ? 3 : 2)
            )
        }
        .buttonStyle(.plain)
        .help("\(spec.statusText)  (\(spec.shortcut))")
    }
}

/// The white box under the DOS tool palette: R, C and I bars rise above the
/// midline for positive demand and drop below it for negative demand.
struct DemandGauge: View {
    let residential: Float
    let commercial: Float
    let industrial: Float

    private let halfHeight: CGFloat = 22

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 6) {
                bar(residential, DOS.green)
                bar(commercial, DOS.lightBlue)
                bar(industrial, DOS.yellow)
            }
            .frame(height: halfHeight * 2)
            .overlay(Rectangle().fill(DOS.black).frame(height: 1))

            HStack(spacing: 6) {
                ForEach(["R", "C", "I"], id: \.self) { label in
                    Text(label).frame(width: 14)
                }
            }
            .font(DOS.font(10))
            .foregroundColor(DOS.black)
        }
        .padding(4)
        .frame(maxWidth: .infinity)
        .background(DOS.white)
        .overlay(Rectangle().stroke(DOS.darkGray, lineWidth: 2))
    }

    private func bar(_ value: Float, _ color: Color) -> some View {
        let clamped = CGFloat(max(-1, min(1, value)))
        let height = abs(clamped) * halfHeight
        return VStack(spacing: 0) {
            Spacer(minLength: 0)
                .frame(height: clamped > 0 ? halfHeight - height : halfHeight)
            Rectangle().fill(color).frame(width: 14, height: height)
            Spacer(minLength: 0)
        }
        .frame(width: 14, height: halfHeight * 2)
    }
}
