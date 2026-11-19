import Foundation

/// Stable accessibility identifiers used by the end-user UI suite.
enum UIIdentifier {
    static let mapCanvas = "map.canvas"
    static let statusLine = "hud.statusLine"
    static let cityName = "hud.cityName"
    static let date = "hud.date"
    static let funds = "hud.funds"
    static let currentMessage = "hud.currentMessage"

    static func menu(_ name: String) -> String { "menu.\(name.lowercased())" }
    static func tool(_ shortcut: String) -> String { "tool.\(shortcut.lowercased())" }
    static func terrain(_ name: String) -> String { "terrain.\(name.lowercased())" }
    static func overlay(_ name: String) -> String { "overlay.\(name.lowercased())" }
    static func graph(_ name: String) -> String { "graph.\(name.lowercased())" }
    static func budget(_ name: String) -> String { "budget.\(name.lowercased())" }
}

/// Launch configuration reserved for an external XCUITest runner. The normal
/// app behavior remains unchanged unless the explicit environment flag is set.
enum UITestLaunchConfiguration {
    static let enabledKey = "MICROPOLIS_UI_TESTING"

    static func isEnabled(in environment: [String: String]) -> Bool {
        environment[enabledKey] == "1"
    }

    @MainActor
    static func makeModel(environment: [String: String] = ProcessInfo.processInfo.environment) -> GameModel {
        guard isEnabled(in: environment) else {
            let model = GameModel()
            let saved = UserDefaults.standard.string(forKey: GraphicsPackage.preferenceKey)
            model.setGraphicsPackage(saved.flatMap(GraphicsPackage.init(rawValue:)) ?? .retroSquare)
            return model
        }
        let inventory = environment["MICROPOLIS_INVENTORY_STATE"] != nil
        let sound: SoundPlaying = inventory ? InventorySoundSink() : SoundManager.shared
        let model = GameModel(city: Assets.city("haight"), sound: sound, seed: 1,
                              runsTimer: environment["MICROPOLIS_INVENTORY_TIMERS"] == "1")
        model.setSpeed(0)
        model.soundOn = false
        ButtonInventorySupport.configure(model, environment: environment)
        return model
    }
}
