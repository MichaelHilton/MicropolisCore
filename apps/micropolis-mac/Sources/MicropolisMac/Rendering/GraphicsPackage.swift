import Foundation

enum GraphicsPackage: String, CaseIterable, Identifiable {
    case classic
    case retroSquare
    case handInked
    case plannersMap
    case toyBlocks

    var id: String { rawValue }
    var title: String {
        switch self {
        case .classic: "Classic"
        case .retroSquare: "Retro Borough (Preview)"
        case .handInked: "Hand-inked Town (Preview)"
        case .plannersMap: "Planner's Map (Preview)"
        case .toyBlocks: "Toy Blocks (Preview)"
        }
    }

    /// Code-drawn packages built from the classic atlas's tile layout.
    var proceduralStyle: ProceduralTileStyle? {
        switch self {
        case .plannersMap: .plannersMap
        case .toyBlocks: .toyBlocks
        default: nil
        }
    }

    /// Painted and vector-style art scales smoothly; pixel art keeps hard edges.
    var smoothScaling: Bool {
        self == .handInked || proceduralStyle != nil
    }

    static let preferenceKey = "graphicsPackage"

    /// The optional inventory runner gets a separate preference domain so
    /// appearance tests cannot change the user's saved appearance.
    static var preferences: UserDefaults {
        let environment = ProcessInfo.processInfo.environment
        if environment["MICROPOLIS_UI_TESTING"] == "1",
           let suite = environment["MICROPOLIS_INVENTORY_PREFERENCES"],
           suite.hasPrefix("org.micropolis.inventory.") {
            return UserDefaults(suiteName: suite)!
        }
        return .standard
    }
}
