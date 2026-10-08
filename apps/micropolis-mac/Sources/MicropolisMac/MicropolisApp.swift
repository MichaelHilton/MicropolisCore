import SwiftUI

@main
struct MicropolisApp: App {
    @State private var model = GameModel()

    init() {
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    var body: some Scene {
        // One edit window, like DOS, so Windows › Edit can bring it back.
        Window(model.cityName, id: "main") {
            ContentView()
                .sheet(isPresented: $model.showBudgetSheet) {
                    BudgetView()
                        .environment(model)
                }
                .sheet(isPresented: $model.showNewCitySheet) {
                    NewCityView()
                        .environment(model)
                }
                .environment(model)
        }
        .defaultSize(width: 960, height: 700)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Micropolis") { model.showAbout() }
            }
            CommandGroup(replacing: .newItem) {}
            CommandMenu("System") { SystemMenuItems().environment(model) }
            CommandMenu("Options") { OptionsMenuItems().environment(model) }
            CommandMenu("Disasters") { DisastersMenuItems().environment(model) }
            CommandGroup(before: .windowList) {
                WindowsMenuItems().environment(model)
                Divider()
            }
        }

        Window("Maps", id: "maps") {
            MapsView().environment(model)
        }
        .windowResizability(.contentSize)

        Window("Graphs", id: "graphs") {
            GraphsView().environment(model)
        }
        .windowResizability(.contentSize)

        Window("Evaluation", id: "evaluation") {
            EvaluationView().environment(model)
        }
        .windowResizability(.contentSize)
    }
}

struct ContentView: View {
    @Environment(GameModel.self) var model

    var body: some View {
        VStack(spacing: 0) {
            HUDView()
            HStack(spacing: 0) {
                if model.editMode == .terrain {
                    TerrainPalette()
                } else {
                    ToolPalette()
                }
                VStack(spacing: 0) {
                    MapView(gameModel: model)
                    StatusLine()
                }
            }
        }
        .background(DOS.lightGray)
        .frame(minWidth: 800, minHeight: 600)
        .alert(outcomeTitle, isPresented: Binding(
            get: { model.outcome != nil },
            set: { if !$0 { model.outcome = nil } }
        )) {
            Button("OK") { model.outcome = nil }
        } message: {
            Text(model.outcome == .won
                 ? "You have met the scenario's goal. The citizens are proud of you."
                 : "You failed to meet the scenario's goal. The citizens have run you out of office.")
        }
    }

    private var outcomeTitle: String {
        model.outcome == .won ? "You Win!" : "Game Over"
    }
}
