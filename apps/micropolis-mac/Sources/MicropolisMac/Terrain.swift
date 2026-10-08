/// The four painting tools of the DOS terrain editor.
enum TerrainTool: CaseIterable {
    case dirt, trees, water, channel

    var name: String {
        switch self {
        case .dirt: "Dirt"
        case .trees: "Trees"
        case .water: "Water"
        case .channel: "Channel"
        }
    }

    /// The raw cell each brush and Fill writes. The engine's own land, water
    /// and forest tools run the bulldozer first, which costs money and fails
    /// on bare dirt, while the DOS terrain editor is free and paints anywhere;
    /// Smooth tidies the edges afterwards. Tile numbers are from the engine's
    /// Tiles enum (micropolis.h).
    var cell: UInt16 {
        switch self {
        case .dirt: 0                       // DIRT
        case .trees: 37 | 0x3000            // WOODS | BLBNBIT
        case .water: 2                      // RIVER
        case .channel: 4                    // CHANNEL
        }
    }

    var kind: TerrainKind {
        switch self {
        case .dirt: .dirt
        case .trees: .trees
        case .water, .channel: .water
        }
    }
}

/// What Fill treats as one patch of land. Anything else (roads, zones,
/// rubble) is not terrain and stops a fill.
enum TerrainKind {
    case dirt, water, trees

    init?(cell: UInt16) {
        switch Int(cell & 0x3FF) {
        case 0: self = .dirt
        case 2...20: self = .water      // RIVER, REDGE, CHANNEL and river edges
        case 21...43: self = .trees     // TREEBASE ... WOODS5
        default: return nil
        }
    }
}
