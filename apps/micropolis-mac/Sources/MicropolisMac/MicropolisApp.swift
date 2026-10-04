import SwiftUI

@main
struct MicropolisApp: App {
    @State private var model = GameModel()

    init() {
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(model)
        }
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button("Preferences") {
                    // Preferences will go here in a later step
                }
                .keyboardShortcut(",", modifiers: .command)
            }

            CommandMenu("Simulation") {
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
}

struct ContentView: View {
    @Environment(GameModel.self) var model

    var body: some View {
        VStack(spacing: 0) {
            HUDView()
            HStack(spacing: 0) {
                ToolPalette()
                MapView(gameModel: model)
            }
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}
