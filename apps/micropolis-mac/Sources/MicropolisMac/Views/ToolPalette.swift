import SwiftUI
import MicropolisKit

struct ToolPalette: View {
    @Environment(GameModel.self) var model

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 4) {
                    ToolButtonRow("Query", .query, 0, "Q")
                    ToolButtonRow("Bulldoze", .bulldozer, 1, "B")
                    ToolButtonRow("Road", .road, 10, "R")
                    ToolButtonRow("Rail", .railroad, 20, "L")
                    ToolButtonRow("Wire", .wire, 5, "W")
                    ToolButtonRow("Park", .park, 10, "P")
                    ToolButtonRow("Residential", .residential, 100, "U")
                    ToolButtonRow("Commercial", .commercial, 100, "E")
                    ToolButtonRow("Industrial", .industrial, 100, "T")
                    ToolButtonRow("Police", .policeStation, 500, "K")
                    ToolButtonRow("Fire", .fireStation, 500, "F")
                    ToolButtonRow("Stadium", .stadium, 5000, "S")
                    ToolButtonRow("Seaport", .seaport, 3000, "H")
                    ToolButtonRow("Coal Power", .coalPower, 3000, "Y")
                    ToolButtonRow("Nuclear", .nuclearPower, 5000, "N")
                    ToolButtonRow("Airport", .airport, 10000, "A")
                }
                .padding(4)
            }
        }
        .frame(width: 100)
        .background(Color(nsColor: .controlBackgroundColor))
        .border(Color(nsColor: .separatorColor), width: 1)
    }

    @ViewBuilder
    func ToolButtonRow(_ label: String, _ tool: Tool, _ cost: Int, _ shortcut: String) -> some View {
        ToolButton(
            label: label,
            cost: cost,
            shortcut: shortcut,
            isSelected: model.selectedTool == tool,
            action: { model.selectedTool = tool }
        )
    }
}

struct ToolButton: View {
    let label: String
    let cost: Int
    let shortcut: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .center, spacing: 2) {
                Text(label)
                    .font(.system(.caption, design: .default))
                    .lineLimit(1)
                if cost > 0 {
                    Text("$\(cost)")
                        .font(.system(.caption2, design: .monospaced))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(4)
            .background(isSelected ? Color.blue : Color.clear)
            .foregroundColor(isSelected ? .white : .primary)
            .border(Color.gray, width: 1)
        }
        .buttonStyle(.plain)
        .help("Shortcut: \(shortcut)")
    }
}
