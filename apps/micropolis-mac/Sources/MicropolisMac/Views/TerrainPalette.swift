import SwiftUI

/// The DOS terrain editor palette that replaces the city tools in the edit
/// window: four terrain brushes, then Fill (a toggle), Undo and Smooth.
struct TerrainPalette: View {
    @Environment(GameModel.self) var model

    var body: some View {
        VStack(spacing: 4) {
            ForEach(TerrainTool.allCases, id: \.self) { tool in
                Button { model.terrainTool = tool } label: {
                    face(tool.name.uppercased(), selected: model.terrainTool == tool)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(UIIdentifier.terrain(tool.name))
            }
            Button { model.terrainFill.toggle() } label: {
                face("FILL", selected: model.terrainFill)
            }
            .buttonStyle(.plain)
            .help("Click a patch of land, water or trees to fill it with the selected terrain")
            .accessibilityIdentifier(UIIdentifier.terrain("fill"))

            Button { model.undoTerrain() } label: {
                face("UNDO", selected: false)
            }
            .buttonStyle(.plain)
            .disabled(model.terrainUndo == nil)
            .opacity(model.terrainUndo == nil ? 0.45 : 1)
            .accessibilityIdentifier(UIIdentifier.terrain("undo"))

            Button { model.smoothTerrain() } label: {
                face("SMOOTH", selected: false)
            }
            .buttonStyle(.plain)
            .help("Tidy the edges of water and trees")
            .accessibilityIdentifier(UIIdentifier.terrain("smooth"))

            Spacer(minLength: 0)
        }
        .padding(6)
        .frame(width: model.graphicsPackage.chrome == nil ? 96 : 126)
        .background(model.graphicsPackage.chrome?.palette ?? DOS.lightGray)
    }

    @ViewBuilder
    private func face(_ text: String, selected: Bool) -> some View {
        if let theme = model.graphicsPackage.chrome {
            Text(theme.label(text.capitalized)).font(theme.font(13))
                .foregroundStyle(theme.buttonText)
                .frame(width: 108, height: 34)
                .background(theme.cornerShape.fill(selected ? theme.selectedFill : theme.button))
                .overlay(theme.cornerShape.stroke(selected ? theme.selectedBorder : theme.buttonBorder,
                                                  lineWidth: selected ? 2 : 1))
        } else {
            dosFace(text, selected: selected)
        }
    }

    private func dosFace(_ text: String, selected: Bool) -> some View {
        Text(text)
            .font(DOS.font(14))
            .foregroundColor(DOS.white)
            .frame(width: 80, height: 34)
            .background(DOS.darkGray)
            .overlay(Rectangle().strokeBorder(selected ? DOS.yellow : DOS.black, lineWidth: selected ? 3 : 2))
    }
}
