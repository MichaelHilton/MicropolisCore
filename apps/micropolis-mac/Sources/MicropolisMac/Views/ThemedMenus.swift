import SwiftUI
import MicropolisKit

/// The bar's drop-down menus drawn in the look's own colors and type, for looks whose
/// `ChromeTheme.customMenus` is set. They offer the same commands, with the same identifiers,
/// as `SystemMenuItems` and its siblings, which still fill the macOS menu bar and its shortcuts.
enum ThemedMenu: String, CaseIterable {
    case system = "SYSTEM", options = "OPTIONS", disasters = "DISASTERS", windows = "WINDOWS", appearance = "APPEARANCE"
}

/// A menu title in the bar that opens its themed panel below it.
struct ThemedMenuButton<Label: View>: View {
    let menu: ThemedMenu
    let theme: ChromeTheme
    @Binding var open: ThemedMenu?
    @ViewBuilder let label: () -> Label
    @Environment(GameModel.self) private var model

    var body: some View {
        Button { open = open == menu ? nil : menu } label: {
            HStack(spacing: 3) {
                label()
                Image(systemName: "chevron.down").font(.system(size: 8, weight: .bold)).opacity(0.7)
            }
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(theme.cornerShape.fill(open == menu ? theme.barText.opacity(0.16) : .clear))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .popover(isPresented: Binding(get: { open == menu }, set: { if !$0, open == menu { open = nil } }),
                 arrowEdge: .bottom) {
            ThemedMenuPanel(menu: menu, theme: theme) { open = nil }
                .environment(model)
                .presentationBackground(theme.window)
        }
    }
}

struct ThemedMenuPanel: View {
    let menu: ThemedMenu
    let theme: ChromeTheme
    let close: () -> Void
    /// Off only for offscreen captures, which cannot draw a scroll view.
    var scrolls = true
    @Environment(GameModel.self) private var model
    @Environment(\.openWindow) private var openWindow
    @State private var expanded: String?

    var body: some View {
        Group {
            if scrolls {
                ScrollView { list }
            } else {
                list
            }
        }
        .frame(width: 260)
        .frame(maxHeight: 520)
        .fixedSize(horizontal: false, vertical: true)
        .font(theme.font(13)).foregroundStyle(theme.ink)
        .background(theme.window)
        .environment(\.colorScheme, theme.windowScheme)
    }

    private var list: some View {
        VStack(alignment: .leading, spacing: 1) { rows }
            .padding(6)
    }

    @ViewBuilder
    private var rows: some View {
        switch menu {
        case .system: systemRows
        case .options: optionsRows
        case .disasters: disasterRows
        case .windows: windowRows
        case .appearance: appearanceRows
        }
    }

    // MARK: Menus

    @ViewBuilder
    private var systemRows: some View {
        item("About Micropolis", id: "system.about") { model.showAbout() }
        divider
        item("Print…", shortcut: "⇧⌘P", id: "system.print") { model.printMap() }
        divider
        submenu("Load Scenario") {
            ForEach(Scenario.allCases, id: \.self) { scenario in
                item(ScenarioText.name(scenario), id: "system.scenario.\(scenario.rawValue)", indent: true) {
                    model.loadScenario(scenario)
                }
            }
        }
        item("Start New City…", shortcut: "⌘N", id: "system.newCity") { model.showNewCitySheet = true }
        divider
        item("Load City…", shortcut: "⌘O", id: "system.loadCity") { model.showOpenPanel() }
        submenu("Load Sample City") {
            ForEach(Assets.allCities.filter { !$0.lastPathComponent.hasPrefix("scenario_") }, id: \.self) { url in
                let name = url.deletingPathExtension().lastPathComponent
                item(name, id: "system.sample.\(name)", indent: true) { model.loadCity(from: url) }
            }
        }
        item("Save City as…", shortcut: "⇧⌘S", id: "system.saveAs") { model.showSavePanel() }
        item("Save City", shortcut: "⌘S", id: "system.save") { model.save() }
        divider
        item("Exit", id: "system.exit") { NSApp.terminate(nil) }
    }

    @ViewBuilder
    private var optionsRows: some View {
        @Bindable var model = model
        appearanceRows
        divider
        toggle("Auto-Bulldoze", $model.autoBulldoze, id: "options.autoBulldoze")
        toggle("Auto-Budget", $model.autoBudget, id: "options.autoBudget")
        toggle("Auto-Goto", $model.autoGoto, id: "options.autoGoto")
        toggle("Sound On", $model.soundOn, id: "options.sound")
        divider
        heading("Speed")
        ForEach(Array(["Pause", "Slow", "Medium", "Fast"].enumerated()), id: \.offset) { speed, name in
            choice(name, selected: model.speed == speed, id: "options.speed.\(speed)") { model.setSpeed(speed) }
        }
        divider
        toggle("Animate All", $model.animateAll, id: "options.animateAll")
        toggle("Frequent Animation", $model.frequentAnimation, id: "options.frequentAnimation")
    }

    @ViewBuilder
    private var appearanceRows: some View {
        heading("Appearance")
        ForEach(GraphicsPackage.allCases) { package in
            choice(package.title, selected: model.graphicsPackage == package, id: "options.appearance.\(package.rawValue)") {
                model.setGraphicsPackage(package)
                if model.graphicsPackage == package {
                    GraphicsPackage.preferences.set(package.rawValue, forKey: GraphicsPackage.preferenceKey)
                }
            }
        }
    }

    @ViewBuilder
    private var disasterRows: some View {
        let disasters: [(String, Disaster, String)] = [
            ("Fire", .fire, "fire"), ("Flood", .flood, "flood"), ("Air Crash", .airCrash, "airCrash"),
            ("Tornado", .tornado, "tornado"), ("Earthquake", .earthquake, "earthquake"),
            ("Monster", .monster, "monster"), ("Nuclear Meltdown", .meltdown, "meltdown"),
        ]
        ForEach(disasters, id: \.2) { title, disaster, id in
            item(title, id: "disaster.\(id)", enabled: model.disastersEnabled) { model.engine.makeDisaster(disaster) }
        }
        divider
        toggle("Disable", Binding(get: { !model.disastersEnabled }, set: { model.disastersEnabled = !$0 }),
               id: "disaster.disable")
    }

    @ViewBuilder
    private var windowRows: some View {
        item("Maps", shortcut: "⇧⌘M", id: "window.maps") { openWindow(id: "maps") }
        item("Graphs", shortcut: "⌘G", id: "window.graphs") { openWindow(id: "graphs") }
        item("Budget", shortcut: "⌘B", id: "window.budget") { model.showBudgetSheet = true }
        item("Edit", shortcut: "⇧⌘E", id: "window.edit") {
            model.editMode = .city
            openWindow(id: "main")
        }
        item("Evaluation", shortcut: "⌘E", id: "window.evaluation") { openWindow(id: "evaluation") }
        item("Terrain Edit", shortcut: "⇧⌘T", id: "window.terrainEdit") {
            model.editMode = .terrain
            openWindow(id: "main")
        }
        divider
        item("Close", id: "window.close") { NSApp.keyWindow?.performClose(nil) }
        item("Hide", id: "window.hide") { NSApp.hide(nil) }
    }

    // MARK: Rows

    private var divider: some View {
        Rectangle().fill(theme.cardBorder).frame(height: 1).padding(.vertical, 4).padding(.horizontal, 4)
    }

    private func heading(_ text: String) -> some View {
        Text(theme.label(text)).font(theme.font(11)).foregroundStyle(theme.heading)
            .padding(.horizontal, 8).padding(.top, 2).padding(.bottom, 1)
    }

    private func item(_ title: String, shortcut: String? = nil, id: String, enabled: Bool = true,
                      indent: Bool = false, _ action: @escaping () -> Void) -> some View {
        MenuRow(theme: theme, enabled: enabled) {
            close()
            action()
        } content: {
            Text(title).padding(.leading, indent ? 14 : 0)
            Spacer(minLength: 12)
            if let shortcut { Text(shortcut).opacity(0.55) }
        }
        .accessibilityIdentifier(id)
    }

    private func toggle(_ title: String, _ isOn: Binding<Bool>, id: String) -> some View {
        MenuRow(theme: theme) {
            isOn.wrappedValue.toggle()
        } content: {
            Image(systemName: "checkmark").font(.system(size: 10, weight: .bold))
                .opacity(isOn.wrappedValue ? 1 : 0).frame(width: 14)
            Text(title)
            Spacer()
        }
        .accessibilityIdentifier(id)
        .accessibilityValue(isOn.wrappedValue ? "1" : "0")
    }

    private func choice(_ title: String, selected: Bool, id: String, _ action: @escaping () -> Void) -> some View {
        MenuRow(theme: theme) {
            close()
            action()
        } content: {
            Circle().fill(selected ? theme.accentFill : .clear)
                .overlay(Circle().stroke(selected ? theme.accentFill : theme.cardBorder, lineWidth: 1))
                .frame(width: 9, height: 9).frame(width: 14)
            Text(title)
            Spacer()
        }
        .accessibilityIdentifier(id)
        .accessibilityValue(selected ? "1" : "0")
    }

    @ViewBuilder
    private func submenu<C: View>(_ title: String, @ViewBuilder _ content: () -> C) -> some View {
        let isOpen = expanded == title
        MenuRow(theme: theme) {
            withAnimation(.easeOut(duration: 0.12)) { expanded = isOpen ? nil : title }
        } content: {
            Text(title)
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 9, weight: .bold))
                .rotationEffect(.degrees(isOpen ? 90 : 0)).opacity(0.6)
        }
        if isOpen { content() }
    }
}

/// One clickable line in a themed menu, highlighted under the pointer like a system menu.
private struct MenuRow<Content: View>: View {
    let theme: ChromeTheme
    var enabled = true
    let action: () -> Void
    @ViewBuilder let content: () -> Content
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6, content: content)
                .padding(.horizontal, 8).padding(.vertical, 4)
                .foregroundStyle(hovering && enabled ? theme.onAccent : theme.ink)
                .background(theme.cornerShape.fill(hovering && enabled ? theme.accentFill : .clear))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.4)
        .onHover { hovering = $0 }
    }
}
