import SwiftUI

@main
struct MicropolisApp: App {
    @State private var model = GameModel()

    init() {
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    var body: some Scene {
        WindowGroup(model.cityName) {
            ContentView()
                .environment(model)
                .sheet(isPresented: $model.showBudgetSheet) {
                    BudgetView()
                }
        }
        .defaultSize(width: 960, height: 700)

        Window("Graphs", id: "graphs") {
            Text("Residential: \(model.engine.history(.residential))")
                .padding()
        }
        .keyboardShortcut("g", modifiers: .command)

        Window("Evaluation", id: "evaluation") {
            VStack(spacing: 12) {
                Text("City Class: \(model.cityClass)")
                Text("Population: \(model.population)")
                Spacer()
            }
            .padding()
        }
        .keyboardShortcut("e", modifiers: .command)
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button("About Micropolis") {
                    // About dialog
                }

                Divider()

                Button("Preferences") {
                    // Will be implemented with AppStorage options
                }
                .keyboardShortcut(",", modifiers: .command)
            }

            CommandGroup(replacing: .newItem) {
                Menu("File") {
                    Button("New City") {
                        let seed = Int.random(in: 1...9999)
                        model.newCity(seed: seed)
                    }
                    .keyboardShortcut("n", modifiers: .command)

                    Divider()

                    Button("Open…") {
                        openCity()
                    }
                    .keyboardShortcut("o", modifiers: .command)

                    Menu("Open Scenario") {
                        ForEach(Assets.allCities, id: \.self) { url in
                            Button(url.deletingPathExtension().lastPathComponent) {
                                model.loadCity(from: url)
                            }
                        }
                    }

                    Divider()

                    Button("Save") {
                        if let url = model.currentFileURL {
                            model.saveCity(to: url)
                        } else {
                            saveAsCity()
                        }
                    }
                    .keyboardShortcut("s", modifiers: .command)

                    Button("Save As…") {
                        saveAsCity()
                    }
                    .keyboardShortcut("s", modifiers: [.command, .shift])
                }
            }

            CommandMenu("Options") {
                Toggle("Auto-Budget", isOn: .constant(true))
                Toggle("Auto-Bulldoze", isOn: .constant(true))
                Toggle("Auto-Goto", isOn: $model.autoGoto)
                Toggle("Disasters Enabled", isOn: .constant(true))
                Toggle("Sound", isOn: .constant(true))
            }

            CommandMenu("Simulation") {
                Button("Budget") {
                    model.showBudgetSheet = true
                }
                .keyboardShortcut("b", modifiers: .command)

                Divider()

                Button(model.paused ? "Resume" : "Pause") {
                    if model.paused {
                        model.resumeSimulation()
                    } else {
                        model.pauseSimulation()
                    }
                }
                .keyboardShortcut("p", modifiers: .command)

                Divider()

                Button("Slow") {
                    model.setSpeed(1)
                }

                Button("Medium") {
                    model.setSpeed(2)
                }

                Button("Fast") {
                    model.setSpeed(3)
                }
            }

            CommandMenu("Disasters") {
                Button("Fire") { model.engine.makeDisaster(0) }
                Button("Flood") { model.engine.makeDisaster(1) }
                Button("Earthquake") { model.engine.makeDisaster(2) }
                Button("Monster") { model.engine.makeDisaster(3) }
                Button("Tornado") { model.engine.makeDisaster(4) }
                Button("Meltdown") { model.engine.makeDisaster(5) }
            }
        }
    }

    private func openCity() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.init(filenameExtension: "cty")!]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false

        panel.begin { response in
            if response == .OK, let url = panel.url {
                model.loadCity(from: url)
            }
        }
    }

    private func saveAsCity() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.init(filenameExtension: "cty")!]
        panel.nameFieldStringValue = model.cityName + ".cty"

        panel.begin { response in
            if response == .OK, let url = panel.url {
                model.saveCity(to: url)
            }
        }
    }
}

struct ContentView: View {
    @Environment(GameModel.self) var model

    var body: some View {
        VStack(spacing: 0) {
            HUDView()
            MessageBar()
            HStack(spacing: 0) {
                ToolPalette()
                MapView(gameModel: model)
            }
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}
