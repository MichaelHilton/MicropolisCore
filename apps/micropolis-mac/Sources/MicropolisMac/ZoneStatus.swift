import Foundation

struct ZoneStatusInfo {
    // Raw engine text IDs, not indexes into the presentation arrays below.
    let category: Int
    let density: Int
    let landValue: Int
    let crime: Int
    let pollution: Int
    let growth: Int
    let x: Int
    let y: Int
}

enum ZoneStatus {
    // Category order is defined by idArray in tool.cpp. Detail text IDs are
    // STR202_* in text.h, plus one as emitted by doZoneStatus.
    static let zones = ["Clear", "Water", "Trees", "Rubble", "Flood", "Radioactive Waste",
                        "Fire", "Road", "Power", "Rail", "Residential", "Commercial",
                        "Industrial", "Port", "Airport", "Coal Power", "Fire Department",
                        "Police Department", "Stadium", "Nuclear Power", "Draw Bridge",
                        "Radar Dish", "Fountain", "Industrial", "Football Game", "Draw Bridge",
                        "Ur 238", "Unknown"]
    static let densities = ["Low", "Medium", "High", "Very High"]
    static let values = ["Slum", "Lower Class", "Middle Class", "High"]
    static let crimeLevels = ["Safe", "Light", "Moderate", "Dangerous"]
    static let pollutionLevels = ["None", "Moderate", "Heavy", "Very Heavy"]
    static let growth = ["Declining", "Stable", "Slow Growth", "Fast Growth"]

    static func categoryName(_ id: Int) -> String {
        name(id, first: 1, in: zones)
    }

    static func densityName(_ id: Int) -> String {
        name(id, first: 1, in: densities)
    }

    static func valueName(_ id: Int) -> String {
        name(id, first: 5, in: values)
    }

    static func crimeName(_ id: Int) -> String {
        name(id, first: 9, in: crimeLevels)
    }

    static func pollutionName(_ id: Int) -> String {
        name(id, first: 13, in: pollutionLevels)
    }

    static func growthName(_ id: Int) -> String {
        name(id, first: 17, in: growth)
    }

    private static func name(_ id: Int, first: Int, in table: [String]) -> String {
        guard id >= first, id - first < table.count else { return "Unknown" }
        return table[id - first]
    }
}
