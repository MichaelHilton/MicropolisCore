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

private extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}

/// Colors and type for the game screen around the map. Retro Borough, Planner's Map and Toy Blocks
/// share one layout and differ only here; Classic and Hand-inked Town keep the DOS screen.
struct ChromeTheme {
    /// Top bar: title, city, funds, date and the menus.
    let bar: Color
    let barText: Color
    let barAccent: Color
    let barHighlight: Color
    let barScheme: ColorScheme
    /// Build palette on the left.
    let palette: Color
    let button: Color
    let buttonText: Color
    let buttonBorder: Color
    let selectedFill: Color
    let selectedBorder: Color
    let heading: Color
    let symbol: Color
    /// Status line under the map.
    let status: Color
    let statusText: Color
    let statusMessage: Color
    let statusError: Color
    let gaugeTrack: Color
    let demand: (r: Color, c: Color, i: Color)
    /// Outline around the tool's footprint on the map.
    let outline: Color
    let rule: Color
    let corner: CGFloat
    /// Toy Blocks buttons sit on a darker lip, like a moulded brick.
    let raised: Bool
    let smoothIcons: Bool
    let design: Font.Design
    let weight: Font.Weight
    let uppercaseLabels: Bool
    /// Windows and sheets: Budget, Evaluation, Graphs, Maps and New City.
    let window: Color
    let windowScheme: ColorScheme
    /// Primary buttons and value chips.
    let accentFill: Color
    let onAccent: Color
    /// Draw the bar's drop-down menus in the theme instead of as system menus.
    let customMenus: Bool

    /// Inner boxes in windows share the build buttons' colors.
    var card: Color { button }
    var cardBorder: Color { buttonBorder }
    var ink: Color { buttonText }

    func font(_ size: CGFloat = 12) -> Font { .system(size: size, weight: weight, design: design) }
    func label(_ text: String) -> String { uppercaseLabels ? text.uppercased() : text }

    static let retro = ChromeTheme(
        bar: Retro.navy, barText: Retro.cream, barAccent: Retro.gold, barHighlight: Retro.cyan, barScheme: .dark,
        palette: Retro.navy, button: Retro.panel, buttonText: Retro.cream, buttonBorder: Retro.gold.opacity(0.4),
        selectedFill: Retro.cyan.opacity(0.18), selectedBorder: Retro.cyan, heading: Retro.gold, symbol: Retro.gold,
        status: Retro.navy, statusText: Retro.cream, statusMessage: Retro.gold, statusError: .orange,
        gaugeTrack: Retro.panel, demand: (Color.green, Color.cyan, Retro.gold), outline: Retro.cyan,
        rule: Retro.gold, corner: 0, raised: false, smoothIcons: false, design: .monospaced, weight: .semibold,
        uppercaseLabels: true, window: Retro.navy, windowScheme: .dark, accentFill: Retro.gold, onAccent: Retro.navy,
        customMenus: false
    )

    /// Drafting paper, graphite ink and a blueprint-blue accent, matching the inked roof plans.
    static let plannersMap = ChromeTheme(
        bar: Color(hex: 0xF4F1E8), barText: Color(hex: 0x3A3F44), barAccent: Color(hex: 0x2F5E8E),
        barHighlight: Color(hex: 0xC8473D), barScheme: .light,
        palette: Color(hex: 0xEDE9DD), button: Color(hex: 0xFAF8F2), buttonText: Color(hex: 0x3A3F44),
        buttonBorder: Color(hex: 0x3A3F44).opacity(0.35), selectedFill: Color(hex: 0xDCE6F0),
        selectedBorder: Color(hex: 0x2F5E8E), heading: Color(hex: 0x2F5E8E), symbol: Color(hex: 0x3A3F44),
        status: Color(hex: 0xF4F1E8), statusText: Color(hex: 0x3A3F44), statusMessage: Color(hex: 0x2F5E8E),
        statusError: Color(hex: 0xC8473D), gaugeTrack: Color(hex: 0xE3DFD3),
        demand: (Color(hex: 0x5E9F5B), Color(hex: 0x4F7FB5), Color(hex: 0xB88F2E)), outline: Color(hex: 0xC8473D),
        rule: Color(hex: 0x3A3F44).opacity(0.55), corner: 2, raised: false, smoothIcons: true, design: .default,
        weight: .medium, uppercaseLabels: false, window: Color(hex: 0xF4F1E8), windowScheme: .light,
        accentFill: Color(hex: 0x2F5E8E), onAccent: .white, customMenus: true
    )

    /// A toy-box blue bar over a cream tray of chunky, rounded building bricks.
    static let toyBlocks = ChromeTheme(
        bar: Color(hex: 0x2F7FD0), barText: .white, barAccent: Color(hex: 0xF4D35E), barHighlight: .white,
        barScheme: .dark,
        palette: Color(hex: 0xFFF6E3), button: .white, buttonText: Color(hex: 0x2F3437),
        buttonBorder: Color(hex: 0xD9CDB4), selectedFill: Color(hex: 0xFFF1B8), selectedBorder: Color(hex: 0xE8483F),
        heading: Color(hex: 0xE8483F), symbol: Color(hex: 0x2F7FD0),
        status: Color(hex: 0x2F7FD0), statusText: .white, statusMessage: Color(hex: 0xF4D35E),
        statusError: Color(hex: 0xFFC2B8), gaugeTrack: Color.white.opacity(0.25),
        demand: (Color(hex: 0x7BDB6A), Color(hex: 0xBFE6F7), Color(hex: 0xF4D35E)), outline: Color(hex: 0xF4D35E),
        rule: Color(hex: 0x1E5FA3), corner: 9, raised: true, smoothIcons: true, design: .rounded, weight: .bold,
        uppercaseLabels: false, window: Color(hex: 0xFFF6E3), windowScheme: .light,
        accentFill: Color(hex: 0x2F7FD0), onAccent: .white, customMenus: true
    )
}

extension GraphicsPackage {
    /// The themed game screen for this look, or nil for the DOS screen.
    var chrome: ChromeTheme? {
        switch self {
        case .retroSquare: .retro
        case .plannersMap: .plannersMap
        case .toyBlocks: .toyBlocks
        default: nil
        }
    }

    /// The title without the "(Preview)" note, for the appearance button.
    var shortTitle: String { title.replacingOccurrences(of: " (Preview)", with: "") }
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
    @State private var openMenu: ThemedMenu?
    private var theme: ChromeTheme { model.graphicsPackage.chrome ?? .retro }
    private let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Label(theme.label("Micropolis"), systemImage: "building.2.fill")
                    .font(theme.font(20)).foregroundStyle(theme.barAccent)
                Rectangle().fill(theme.barAccent.opacity(0.5)).frame(width: 1, height: 24)
                Text(model.cityName).lineLimit(1).accessibilityIdentifier(UIIdentifier.cityName)
                Spacer(minLength: 4)
                Text("$\(model.funds.formatted())").foregroundStyle(theme.barAccent)
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
                .buttonStyle(.plain).foregroundStyle(theme.barHighlight)
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            HStack(spacing: 18) {
                chromeMenu("SYSTEM") { SystemMenuItems() }
                chromeMenu("OPTIONS") { OptionsMenuItems() }
                chromeMenu("DISASTERS") { DisastersMenuItems() }
                chromeMenu("WINDOWS") { WindowsMenuItems() }
                Spacer()
                Text("\(theme.label("Pop")) \(model.population.formatted())").foregroundStyle(theme.barText.opacity(0.7))
                appearanceMenu
            }
            .font(theme.font(theme.uppercaseLabels ? 10 : 12)).padding(.horizontal, 14).padding(.bottom, 8)
            Rectangle().fill(theme.rule).frame(height: theme.raised ? 3 : 1)
        }
        .font(theme.font()).foregroundStyle(theme.barText).background(theme.bar)
        .environment(\.colorScheme, theme.barScheme)
        .tint(theme.barText)
    }

    @ViewBuilder
    private func chromeMenu<C: View>(_ title: String, @ViewBuilder content: () -> C) -> some View {
        if theme.customMenus, let menu = ThemedMenu(rawValue: title) {
            ThemedMenuButton(menu: menu, theme: theme, open: $openMenu) { Text(theme.label(title.capitalized)) }
                .fixedSize()
                .accessibilityIdentifier(UIIdentifier.menu(title))
        } else {
            Menu(content: content) { Text(theme.label(title.capitalized)) }
                .menuStyle(.borderlessButton).fixedSize()
                .accessibilityIdentifier(UIIdentifier.menu(title))
        }
    }

    @ViewBuilder
    private var appearanceMenu: some View {
        if theme.customMenus {
            ThemedMenuButton(menu: .appearance, theme: theme, open: $openMenu) {
                Label(model.graphicsPackage.shortTitle, systemImage: "paintpalette")
            }
            .fixedSize()
            .accessibilityLabel("Appearance")
            .accessibilityIdentifier("menu.appearance")
        } else {
            Menu { GraphicsPackagePicker() } label: {
                Label(model.graphicsPackage.shortTitle, systemImage: "paintpalette")
            }
            .menuStyle(.borderlessButton).fixedSize()
            .accessibilityLabel("Appearance")
            .accessibilityIdentifier("menu.appearance")
        }
    }
}

struct RetroToolPalette: View {
    @Environment(GameModel.self) private var model
    private var theme: ChromeTheme { model.graphicsPackage.chrome ?? .retro }
    private let columns = [GridItem(.flexible(), spacing: 5), GridItem(.flexible(), spacing: 5)]

    var body: some View {
        VStack(spacing: 8) {
            Text(theme.label("Build")).font(theme.font(theme.uppercaseLabels ? 10 : 12)).foregroundStyle(theme.heading)
                .frame(maxWidth: .infinity, alignment: .leading)
            LazyVGrid(columns: columns, spacing: 5) {
                ForEach(ToolSpec.all) { spec in
                    let selected = model.selectedTool == spec.tool
                    let shape = RoundedRectangle(cornerRadius: theme.corner, style: .continuous)
                    Button { model.selectedTool = spec.tool } label: {
                        VStack(spacing: 2) {
                            icon(spec).frame(width: 42, height: 36)
                            Text(shortName(spec.tool)).font(theme.font(theme.uppercaseLabels ? 8 : 9)).lineLimit(1)
                        }
                        .foregroundStyle(theme.buttonText)
                        .frame(maxWidth: .infinity).frame(height: 55)
                        .background(shape.fill(selected ? theme.selectedFill : theme.button))
                        .overlay(shape.stroke(selected ? theme.selectedBorder : theme.buttonBorder,
                                              lineWidth: selected ? 2 : 1))
                        .background(
                            // The brick's lip: a darker edge showing below the face.
                            shape.fill(theme.raised ? theme.buttonBorder : .clear).offset(y: selected ? 1 : 3)
                        )
                        .offset(y: theme.raised && selected ? 2 : 0)
                        .contentShape(shape)
                    }
                    .buttonStyle(.plain).help("\(spec.statusText) (\(spec.shortcut))")
                    .accessibilityLabel(spec.name).accessibilityIdentifier(UIIdentifier.tool(spec.shortcut))
                }
            }
            Spacer(minLength: 4)
            Text("\(ToolSpec.spec(for: model.selectedTool)?.name ?? "Query")")
                .font(theme.font(theme.uppercaseLabels ? 10 : 12)).foregroundStyle(theme.heading)
            if let spec = ToolSpec.spec(for: model.selectedTool), spec.cost > 0 {
                Text("$\(spec.cost.formatted())").font(theme.font(11)).foregroundStyle(theme.buttonText)
            }
        }
        .padding(8).frame(width: 126).background(theme.palette)
        .overlay(alignment: .trailing) { Rectangle().fill(theme.rule.opacity(theme.raised ? 0.25 : 0.5)).frame(width: 1) }
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
            Image(systemName: symbol).font(.system(size: 23, weight: .semibold)).foregroundStyle(theme.symbol)
        } else if let base, let image = model.tileAtlas.buildingImage(base: base, size: 3) {
            Image(decorative: image, scale: 1).resizable().interpolation(theme.smoothIcons ? .high : .none).scaledToFit()
        } else if case let .tiles(base, size) = spec.icon,
                  let image = model.tileAtlas.buildingImage(base: base, size: size) {
            Image(decorative: image, scale: 1).resizable().interpolation(theme.smoothIcons ? .high : .none).scaledToFit()
        } else {
            Image(systemName: "magnifyingglass").font(.system(size: 22)).foregroundStyle(theme.symbol)
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
    private var theme: ChromeTheme { model.graphicsPackage.chrome ?? .retro }
    var body: some View {
        HStack(spacing: 16) {
            Text(status).lineLimit(1).foregroundStyle(model.toolMessage == nil ? theme.statusText : theme.statusError)
                .accessibilityIdentifier(UIIdentifier.statusLine)
            Spacer(minLength: 0)
            if let message = model.currentMessage {
                Text(message).lineLimit(1).foregroundStyle(theme.statusMessage)
                    .accessibilityIdentifier(UIIdentifier.currentMessage)
            }
            HStack(spacing: 8) {
                demand("R", model.demandResidential, theme.demand.r)
                demand("C", model.demandCommercial, theme.demand.c)
                demand("I", model.demandIndustrial, theme.demand.i)
            }.accessibilityElement(children: .combine)
        }
        .font(theme.font(11)).padding(.horizontal, 12).padding(.vertical, 8)
        .background(theme.status)
        .overlay(alignment: .top) { Rectangle().fill(theme.rule).frame(height: theme.raised ? 3 : 1) }
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
                Rectangle().fill(theme.gaugeTrack)
                let clamped = CGFloat(max(-1, min(1, value)))
                Rectangle().fill(color).frame(width: abs(clamped) * 20)
                    .offset(x: clamped >= 0 ? 20 : 20 + clamped * 20)
                Rectangle().fill(theme.statusText.opacity(0.6)).frame(width: 1).offset(x: 20)
            }.frame(width: 40, height: 7)
        }.accessibilityLabel("\(label) demand \(Int(value * 100)) percent")
    }
}

private struct ChromeThemeKey: EnvironmentKey {
    static let defaultValue: ChromeTheme? = nil
}

extension EnvironmentValues {
    /// The themed look for windows and controls, or nil for the DOS look.
    var chromeTheme: ChromeTheme? {
        get { self[ChromeThemeKey.self] }
        set { self[ChromeThemeKey.self] = newValue }
    }
}

extension ChromeTheme {
    var cornerShape: RoundedRectangle { RoundedRectangle(cornerRadius: corner, style: .continuous) }
}

extension View {
    /// A box inside a themed window.
    func themedCard(_ theme: ChromeTheme, padding: CGFloat = 8) -> some View {
        self.padding(padding)
            .background(theme.cornerShape.fill(theme.card))
            .overlay(theme.cornerShape.stroke(theme.cardBorder, lineWidth: 1))
    }

    /// The face of a primary button in a themed window.
    func themedPrimary(_ theme: ChromeTheme) -> some View {
        self.font(theme.font(13)).foregroundStyle(theme.onAccent)
            .padding(.horizontal, 14).padding(.vertical, 6)
            .background(theme.cornerShape.fill(theme.accentFill))
            .background(theme.cornerShape.fill(theme.accentFill.opacity(0.55)).offset(y: theme.raised ? 3 : 0))
    }

    /// A whole themed window: its font, text color, background and light or dark controls.
    func themedWindow(_ theme: ChromeTheme) -> some View {
        self.font(theme.font(13)).foregroundStyle(theme.ink).tint(theme.accentFill)
            .background(theme.window)
            .environment(\.colorScheme, theme.windowScheme)
            .environment(\.chromeTheme, theme)
    }
}

extension View {
    /// Themed window, or the grey DOS window with its monospaced font.
    @ViewBuilder
    func themedOrDOSWindow(_ theme: ChromeTheme?) -> some View {
        if let theme {
            self.themedWindow(theme)
        } else {
            self.background(DOS.lightGray).font(DOS.font())
        }
    }
}
