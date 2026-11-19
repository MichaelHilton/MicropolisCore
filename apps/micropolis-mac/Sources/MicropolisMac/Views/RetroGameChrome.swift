import SwiftUI
import MicropolisKit

/// The G concept: restrained navy/gold controls around dimensional pixel buildings.
enum Retro {
    static let navy = Color(red: 0.035, green: 0.09, blue: 0.16)
    static let panel = Color(red: 0.075, green: 0.15, blue: 0.23)
    static let gold = Color(red: 0.91, green: 0.74, blue: 0.38)
    static let cyan = Color(red: 0.24, green: 0.86, blue: 0.85)
    static let cream = Color(red: 0.95, green: 0.93, blue: 0.84)
    static func font(_ size: CGFloat = 12) -> Font {
        .system(size: size, weight: .semibold, design: .monospaced)
    }
}

struct GraphicsPackagePicker: View {
    @Environment(GameModel.self) private var model
    var body: some View {
        Picker("Appearance", selection: Binding(get: { model.graphicsPackage }, set: { package in
            model.setGraphicsPackage(package)
            if model.graphicsPackage == package {
                GraphicsPackage.preferences.set(package.rawValue, forKey: GraphicsPackage.preferenceKey)
            }
        })) {
            ForEach(GraphicsPackage.allCases) { package in Text(package.title).tag(package) }
        }
        .accessibilityIdentifier("options.appearance")
    }
}

struct RetroHUDView: View {
    @Environment(GameModel.self) private var model
    private let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Label("MICROPOLIS", systemImage: "building.2.fill")
                    .font(Retro.font(20)).foregroundStyle(Retro.gold)
                Rectangle().fill(Retro.gold.opacity(0.5)).frame(width: 1, height: 24)
                Text(model.cityName).lineLimit(1).accessibilityIdentifier(UIIdentifier.cityName)
                Spacer(minLength: 4)
                Text("$\(model.funds.formatted())").foregroundStyle(Retro.gold)
                    .accessibilityIdentifier(UIIdentifier.funds)
                Text("\(months[max(0, min(11, model.month - 1))]) \(String(model.year))")
                    .accessibilityIdentifier(UIIdentifier.date)
                Button {
                    if model.paused {
                        if model.speed == 0 { model.setSpeed(1) } else { model.resumeSimulation() }
                    } else {
                        model.pauseSimulation()
                    }
                } label: {
                    Image(systemName: model.paused ? "play.fill" : "pause.fill")
                        .frame(width: 28, height: 28)
                }
                .help(model.paused ? "Resume simulation" : "Pause simulation")
                .accessibilityLabel(model.paused ? "Resume simulation" : "Pause simulation")
                .buttonStyle(.plain).foregroundStyle(Retro.cyan)
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            HStack(spacing: 18) {
                chromeMenu("SYSTEM") { SystemMenuItems() }
                chromeMenu("OPTIONS") { OptionsMenuItems() }
                chromeMenu("DISASTERS") { DisastersMenuItems() }
                chromeMenu("WINDOWS") { WindowsMenuItems() }
                Spacer()
                Text("POP \(model.population.formatted())").foregroundStyle(Retro.cream.opacity(0.7))
                Menu { GraphicsPackagePicker() } label: {
                    Label("Retro Borough", systemImage: "paintpalette")
                }
                .menuStyle(.borderlessButton).fixedSize()
                .accessibilityLabel("Appearance")
                .accessibilityIdentifier("menu.appearance")
            }
            .font(Retro.font(10)).padding(.horizontal, 14).padding(.bottom, 8)
            Rectangle().fill(Retro.gold).frame(height: 1)
        }
        .font(Retro.font()).foregroundStyle(Retro.cream).background(Retro.navy)
        .environment(\.colorScheme, .dark)
        .tint(Retro.cream)
    }

    private func chromeMenu<C: View>(_ title: String, @ViewBuilder content: () -> C) -> some View {
        Menu(content: content) { Text(title) }
            .menuStyle(.borderlessButton).fixedSize()
            .accessibilityIdentifier(UIIdentifier.menu(title))
    }
}

struct RetroToolPalette: View {
    @Environment(GameModel.self) private var model
    private let columns = [GridItem(.flexible(), spacing: 5), GridItem(.flexible(), spacing: 5)]

    var body: some View {
        VStack(spacing: 8) {
            Text("BUILD").font(Retro.font(10)).foregroundStyle(Retro.gold)
                .frame(maxWidth: .infinity, alignment: .leading)
            LazyVGrid(columns: columns, spacing: 5) {
                ForEach(ToolSpec.all) { spec in
                    Button { model.selectedTool = spec.tool } label: {
                        VStack(spacing: 2) {
                            icon(spec).frame(width: 42, height: 36)
                            Text(shortName(spec.tool)).font(Retro.font(8)).lineLimit(1)
                        }
                        .foregroundStyle(Retro.cream)
                        .frame(maxWidth: .infinity).frame(height: 55)
                        .background(model.selectedTool == spec.tool ? Retro.cyan.opacity(0.18) : Retro.panel)
                        .overlay(Rectangle().stroke(model.selectedTool == spec.tool ? Retro.cyan : Retro.gold.opacity(0.4),
                                                    lineWidth: model.selectedTool == spec.tool ? 2 : 1))
                    }
                    .buttonStyle(.plain).help("\(spec.statusText) (\(spec.shortcut))")
                    .accessibilityLabel(spec.name).accessibilityIdentifier(UIIdentifier.tool(spec.shortcut))
                }
            }
            Spacer(minLength: 4)
            Text("\(ToolSpec.spec(for: model.selectedTool)?.name ?? "Query")")
                .font(Retro.font(10)).foregroundStyle(Retro.gold)
            if let spec = ToolSpec.spec(for: model.selectedTool), spec.cost > 0 {
                Text("$\(spec.cost.formatted())").font(Retro.font(11)).foregroundStyle(Retro.cream)
            }
        }
        .padding(8).frame(width: 126).background(Retro.navy)
        .overlay(alignment: .trailing) { Rectangle().fill(Retro.gold.opacity(0.5)).frame(width: 1) }
    }

    @ViewBuilder
    private func icon(_ spec: ToolSpec) -> some View {
        // Zoning buttons preview the new developed artwork; placement still creates empty lots.
        let base: Int? = switch spec.tool {
        case .residential: 261
        case .commercial: 432
        case .industrial: 621
        default: nil
        }
        if let symbol = utilitySymbol(spec.tool) {
            Image(systemName: symbol).font(.system(size: 23, weight: .semibold)).foregroundStyle(Retro.gold)
        } else if let base, let image = model.tileAtlas.buildingImage(base: base, size: 3) {
            Image(decorative: image, scale: 1).resizable().interpolation(.none).scaledToFit()
        } else if case let .tiles(base, size) = spec.icon,
                  let image = model.tileAtlas.buildingImage(base: base, size: size) {
            Image(decorative: image, scale: 1).resizable().interpolation(.none).scaledToFit()
        } else {
            Image(systemName: "magnifyingglass").font(.system(size: 22)).foregroundStyle(Retro.gold)
        }
    }

    private func utilitySymbol(_ tool: Tool) -> String? {
        switch tool {
        case .query: "magnifyingglass"
        case .bulldozer: "hammer.fill"
        case .road: "road.lanes"
        case .wire: "bolt.fill"
        case .railroad: "tram.fill"
        case .park: "tree.fill"
        default: nil
        }
    }

    private func shortName(_ tool: Tool) -> String {
        switch tool {
        case .query: "Inspect"
        case .bulldozer: "Clear"
        case .road: "Road"
        case .wire: "Power"
        case .railroad: "Rail"
        case .park: "Park"
        case .residential: "Homes"
        case .commercial: "Shops"
        case .industrial: "Industry"
        case .policeStation: "Police"
        case .fireStation: "Fire"
        case .stadium: "Stadium"
        case .coalPower: "Coal"
        case .nuclearPower: "Nuclear"
        case .seaport: "Port"
        case .airport: "Airport"
        default: "Build"
        }
    }
}

struct RetroStatusLine: View {
    @Environment(GameModel.self) private var model
    var body: some View {
        HStack(spacing: 16) {
            Text(status).lineLimit(1).foregroundStyle(model.toolMessage == nil ? Retro.cream : .orange)
                .accessibilityIdentifier(UIIdentifier.statusLine)
            Spacer(minLength: 0)
            if let message = model.currentMessage {
                Text(message).lineLimit(1).foregroundStyle(Retro.gold)
                    .accessibilityIdentifier(UIIdentifier.currentMessage)
            }
            HStack(spacing: 8) {
                demand("R", model.demandResidential, Color.green)
                demand("C", model.demandCommercial, Color.cyan)
                demand("I", model.demandIndustrial, Retro.gold)
            }.accessibilityElement(children: .combine)
        }
        .font(Retro.font(11)).padding(.horizontal, 12).padding(.vertical, 8)
        .background(Retro.navy)
        .overlay(alignment: .top) { Rectangle().fill(Retro.gold).frame(height: 1) }
    }

    private var status: String {
        if let message = model.toolMessage { return message }
        if model.editMode == .terrain { return model.terrainTool.name }
        return ToolSpec.spec(for: model.selectedTool)?.statusText ?? "Inspect"
    }

    private func demand(_ label: String, _ value: Float, _ color: Color) -> some View {
        HStack(spacing: 3) {
            Text(label).foregroundStyle(color)
            // Midpoint marks zero, and negative demand extends to the left.
            ZStack(alignment: .leading) {
                Rectangle().fill(Retro.panel)
                let clamped = CGFloat(max(-1, min(1, value)))
                Rectangle().fill(color).frame(width: abs(clamped) * 20)
                    .offset(x: clamped >= 0 ? 20 : 20 + clamped * 20)
                Rectangle().fill(Retro.cream.opacity(0.6)).frame(width: 1).offset(x: 20)
            }.frame(width: 40, height: 7)
        }.accessibilityLabel("\(label) demand \(Int(value * 100)) percent")
    }
}
