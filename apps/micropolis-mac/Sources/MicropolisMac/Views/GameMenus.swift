import SwiftUI
import MicropolisKit

/// Menu contents shared by the DOS menu strip in the window and the macOS
/// menu bar, so the two always offer the same commands. Items follow the
/// order of the DOS menus.

struct SystemMenuItems: View {
    @Environment(GameModel.self) var model

    var body: some View {
        Button("About Micropolis") { model.showAbout() }
        Divider()
        Button("Print…") { model.printMap() }
            .keyboardShortcut("p", modifiers: [.command, .shift])
        Divider()
        Menu("Load Scenario") {
            ForEach(Scenario.allCases, id: \.self) { scenario in
                Button(ScenarioText.name(scenario)) { model.loadScenario(scenario) }
            }
        }
        Button("Start New City…") { model.showNewCitySheet = true }
            .keyboardShortcut("n", modifiers: .command)
        Divider()
        Button("Load City…") { model.showOpenPanel() }
            .keyboardShortcut("o", modifiers: .command)
        Menu("Load Sample City") {
            ForEach(Assets.allCities.filter { !$0.lastPathComponent.hasPrefix("scenario_") }, id: \.self) { url in
                Button(url.deletingPathExtension().lastPathComponent) { model.loadCity(from: url) }
            }
        }
        Button("Save City as…") { model.showSavePanel() }
            .keyboardShortcut("s", modifiers: [.command, .shift])
        Button("Save City") { model.save() }
            .keyboardShortcut("s", modifiers: .command)
        Divider()
        Button("Exit") { NSApp.terminate(nil) }
    }
}

struct OptionsMenuItems: View {
    @Environment(GameModel.self) var model

    var body: some View {
        @Bindable var model = model
        Toggle("Auto-Bulldoze", isOn: $model.autoBulldoze)
        Toggle("Auto-Budget", isOn: $model.autoBudget)
        Toggle("Auto-Goto", isOn: $model.autoGoto)
        Toggle("Sound On", isOn: $model.soundOn)
        Picker("Speed", selection: Binding(get: { model.speed }, set: { model.setSpeed($0) })) {
            Text("Pause").tag(0)
            Text("Slow").tag(1)
            Text("Medium").tag(2)
            Text("Fast").tag(3)
        }
        Toggle("Animate All", isOn: $model.animateAll)
        Toggle("Frequent Animation", isOn: $model.frequentAnimation)
    }
}

struct DisastersMenuItems: View {
    @Environment(GameModel.self) var model

    var body: some View {
        @Bindable var model = model
        Group {
            Button("Fire") { model.engine.makeDisaster(.fire) }
            Button("Flood") { model.engine.makeDisaster(.flood) }
            Button("Air Crash") { model.engine.makeDisaster(.airCrash) }
            Button("Tornado") { model.engine.makeDisaster(.tornado) }
            Button("Earthquake") { model.engine.makeDisaster(.earthquake) }
            Button("Monster") { model.engine.makeDisaster(.monster) }
            Button("Nuclear Meltdown") { model.engine.makeDisaster(.meltdown) }
        }
        .disabled(!model.disastersEnabled)
        Divider()
        // DOS "Disable" stops the random disasters the simulation causes, and
        // greys out the menu items above.
        Toggle("Disable", isOn: Binding(get: { !model.disastersEnabled }, set: { model.disastersEnabled = !$0 }))
    }
}

struct WindowsMenuItems: View {
    @Environment(GameModel.self) var model
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("Maps") { openWindow(id: "maps") }
            .keyboardShortcut("m", modifiers: [.command, .shift])
        Button("Graphs") { openWindow(id: "graphs") }
            .keyboardShortcut("g", modifiers: .command)
        Button("Budget") { model.showBudgetSheet = true }
            .keyboardShortcut("b", modifiers: .command)
        Button("Edit") {
            model.editMode = .city
            openWindow(id: "main")
        }
        .keyboardShortcut("e", modifiers: [.command, .shift])
        Button("Evaluation") { openWindow(id: "evaluation") }
            .keyboardShortcut("e", modifiers: .command)
        Button("Terrain Edit") {
            model.editMode = .terrain
            openWindow(id: "main")
        }
        .keyboardShortcut("t", modifiers: [.command, .shift])
        Divider()
        Button("Close") { NSApp.keyWindow?.performClose(nil) }
        Button("Hide") { NSApp.hide(nil) }
    }
}

enum ScenarioText {
    static func name(_ scenario: Scenario) -> String {
        switch scenario {
        case .dullsville: "Dullsville 1900"
        case .sanFrancisco: "San Francisco 1906"
        case .hamburg: "Hamburg 1944"
        case .bern: "Bern 1965"
        case .tokyo: "Tokyo 1957"
        case .detroit: "Detroit 1972"
        case .boston: "Boston 2010"
        case .rio: "Rio de Janeiro 2047"
        }
    }
}
