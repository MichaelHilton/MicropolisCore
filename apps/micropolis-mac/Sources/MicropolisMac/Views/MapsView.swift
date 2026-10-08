import SwiftUI
import MicropolisKit

/// The DOS map window ("City Form"): the whole city at a glance, a column of
/// view buttons, and a box showing what the edit window shows. Clicking or
/// dragging in the map scrolls the edit window there.
struct MapsView: View {
    @Environment(GameModel.self) var model

    @State private var cityImage: CGImage?
    @State private var overlayImage: CGImage?

    private let tileScale: CGFloat = 3
    private var mapSize: CGSize {
        CGSize(width: CGFloat(Engine.width) * tileScale, height: CGFloat(Engine.height) * tileScale)
    }

    var body: some View {
        VStack(spacing: 0) {
            DOSWindowTitle(model.mapOverlay.title)
            HStack(alignment: .top, spacing: 0) {
                buttonColumn
                mapArea
            }
        }
        .background(DOS.lightGray)
        .font(DOS.font())
        .fixedSize()
        .onAppear(perform: redraw)
        // The full city image is large, so redraw a few times a second at most.
        .onChange(of: model.mapVersion / 10) { redraw() }
        .onChange(of: model.mapOverlay) { redraw() }
    }

    private var buttonColumn: some View {
        VStack(spacing: 2) {
            overlayButton("FORM", .cityForm, help: "City Form")
            overlayButton("POWER", .powerGrid, help: "Power Grid")
            overlayButton("ROADS", .transportation, help: "Transportation")
            overlayMenu("POP", [.populationDensity, .populationGrowth], help: "Population")
            overlayButton("TRAFF", .traffic, help: "Traffic Density")
            overlayButton("POLL", .pollution, help: "Pollution")
            overlayButton("CRIME", .crime, help: "Crime")
            overlayButton("VALUE", .landValue, help: "Land Value")
            overlayMenu("SERV", [.police, .fire], help: "City Services")
            if model.mapOverlay.hasLegend {
                legend
            }
            Spacer(minLength: 0)
        }
        .padding(4)
        .frame(width: 70, height: mapSize.height + 8)
    }

    private var legend: some View {
        VStack(spacing: 2) {
            Text("Max").font(DOS.font(10))
            LinearGradient(colors: (0...6).reversed().map { color(OverlayRenderer.ramp(Double($0) / 6)) },
                           startPoint: .top, endPoint: .bottom)
                .frame(width: 20, height: 34)
                .overlay(Rectangle().stroke(DOS.black, lineWidth: 1))
            Text("Min").font(DOS.font(10))
        }
        .foregroundColor(DOS.black)
    }

    private var mapArea: some View {
        ZStack(alignment: .topLeading) {
            DOS.black
            if let cityImage {
                Image(decorative: cityImage, scale: 1)
                    .resizable()
                    .interpolation(.medium)
                    .opacity(model.mapOverlay == .cityForm ? 1 : 0.45)
            }
            if let overlayImage {
                Image(decorative: overlayImage, scale: 1)
                    .resizable()
                    .interpolation(.none)
            }
            viewportBox
        }
        .frame(width: mapSize.width, height: mapSize.height)
        .clipped()
        .overlay(Rectangle().stroke(DOS.white, lineWidth: 2))
        .padding(4)
        .contentShape(Rectangle())
        .gesture(DragGesture(minimumDistance: 0).onChanged { value in
            model.centerEditView(onTileX: Int((value.location.x - 4) / tileScale),
                                 y: Int((value.location.y - 4) / tileScale))
        })
    }

    private var viewportBox: some View {
        let r = model.visibleTiles
        // Black and white so the box shows over every view's colors.
        return Rectangle()
            .stroke(DOS.black, lineWidth: 4)
            .overlay(Rectangle().stroke(DOS.white, lineWidth: 2))
            .frame(width: max(4, r.width * tileScale), height: max(4, r.height * tileScale))
            .offset(x: r.minX * tileScale, y: r.minY * tileScale)
            .opacity(r.isEmpty ? 0 : 1)
            .allowsHitTesting(false)
    }

    private func overlayButton(_ label: String, _ overlay: MapOverlay, help: String) -> some View {
        Button { model.mapOverlay = overlay } label: {
            DOSButtonLabel(label, selected: model.mapOverlay == overlay)
        }
        .buttonStyle(.plain)
        .help(help)
    }

    /// DOS pops up a small menu for buttons that cover two views.
    private func overlayMenu(_ label: String, _ choices: [MapOverlay], help: String) -> some View {
        Menu {
            ForEach(choices, id: \.self) { choice in
                Toggle(choice.title, isOn: Binding(
                    get: { model.mapOverlay == choice },
                    set: { if $0 { model.mapOverlay = choice } }
                ))
            }
        } label: {
            DOSButtonLabel(label, selected: choices.contains(model.mapOverlay))
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
        .fixedSize()
        .help(help)
    }

    private func redraw() {
        let cells = model.engine.mapSnapshot()
        model.renderer.update(cells: cells)
        cityImage = model.renderer.makeImage()
        let overlay = model.mapOverlay
        let data = overlay.dataLayer.map { model.engine.overlay($0) }
        overlayImage = overlay == .cityForm
            ? nil
            : OverlayRenderer.image(from: OverlayRenderer.pixels(for: overlay, cells: cells, data: data))
    }

    private func color(_ p: OverlayRenderer.RGBA) -> Color {
        Color(red: Double(p.r) / 255, green: Double(p.g) / 255, blue: Double(p.b) / 255)
    }
}

/// The patterned title strip DOS puts across the top of every window, with
/// the title in a white box.
struct DOSWindowTitle: View {
    let title: String

    init(_ title: String) { self.title = title }

    var body: some View {
        Text(title)
            .foregroundColor(DOS.blue)
            .padding(.horizontal, 8)
            .padding(.vertical, 1)
            .background(DOS.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 3)
            .background(DOS.lightBlue.opacity(0.5))
    }
}

/// A raised grey DOS button face with a yellow ring when selected.
struct DOSButtonLabel: View {
    let text: String
    let selected: Bool

    init(_ text: String, selected: Bool = false) {
        self.text = text
        self.selected = selected
    }

    var body: some View {
        Text(text)
            .font(DOS.font(11))
            .foregroundColor(DOS.black)
            .frame(width: 58, height: 23)
            .background(DOS.lightGray)
            .overlay(Rectangle().strokeBorder(selected ? DOS.yellow : DOS.darkGray, lineWidth: selected ? 3 : 2))
    }
}
