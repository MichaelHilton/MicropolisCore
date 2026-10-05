import Foundation

struct ZoneStatusInfo {
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
    static let zones = ["Residential", "Commercial", "Industrial", "Port", "Airport"]
    static let densities = ["Light", "Medium", "Dense"]
    static let values = ["Very Low", "Low", "Medium", "High", "Very High"]
    static let levels = ["None", "Low", "Medium", "High", "Very High"]
    static let growth = ["Declining", "Stable", "Slow", "Fast"]

    static func categoryName(_ index: Int) -> String {
        guard index >= 0 && index < zones.count else { return "Unknown" }
        return zones[index]
    }

    static func densityName(_ index: Int) -> String {
        guard index >= 0 && index < densities.count else { return "Unknown" }
        return densities[index]
    }

    static func valueName(_ index: Int) -> String {
        guard index >= 0 && index < values.count else { return "Unknown" }
        return values[index]
    }

    static func levelName(_ index: Int) -> String {
        guard index >= 0 && index < levels.count else { return "Unknown" }
        return levels[index]
    }

    static func growthName(_ index: Int) -> String {
        guard index >= 0 && index < growth.count else { return "Unknown" }
        return growth[index]
    }
}
