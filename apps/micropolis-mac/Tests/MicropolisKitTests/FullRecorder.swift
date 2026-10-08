import Foundation
@testable import MicropolisKit

/// Records every delegate callback the wrapper forwards. Keep a strong
/// reference to it: Engine.delegate is weak.
final class FullRecorder: EngineDelegate {
    var sounds: [String] = []
    var messages: [(index: Int, x: Int, y: Int, important: Bool)] = []
    var autoGotos: [(x: Int, y: Int)] = []
    var zoneStatuses: [(category: Int, x: Int, y: Int)] = []
    var budgetRequests = 0
    var earthquakes: [Int] = []
    var taxRates: [Int] = []
    var pausedUpdates: [Bool] = []
    var speedUpdates: [Int] = []
    var won = 0
    var lost = 0

    func engineMakeSound(channel: String, sound: String, x: Int, y: Int) { sounds.append(sound) }
    func engineSendMessage(index: Int, x: Int, y: Int, picture: Bool, important: Bool) {
        messages.append((index, x, y, important))
    }
    func engineAutoGoto(x: Int, y: Int, message: String) { autoGotos.append((x, y)) }
    func engineShowBudgetAndWait() { budgetRequests += 1 }
    func engineShowZoneStatus(category: Int, density: Int, landValue: Int, crime: Int, pollution: Int, growth: Int, x: Int, y: Int) {
        zoneStatuses.append((category, x, y))
    }
    func engineStartEarthquake(strength: Int) { earthquakes.append(strength) }
    func engineUpdateTaxRate(tax: Int) { taxRates.append(tax) }
    func engineUpdatePaused(paused: Bool) { pausedUpdates.append(paused) }
    func engineUpdateSpeed(speed: Int) { speedUpdates.append(speed) }
    func engineDidWinGame() { won += 1 }
    func engineDidLoseGame() { lost += 1 }
}

/// Implements nothing, so every callback runs the protocol's default.
final class MinimalDelegate: EngineDelegate {}

enum Repo {
    static var root: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent()
    }
    static var cities: URL { root.appendingPathComponent("content/micropolis/cities") }
    static var content: URL { root.appendingPathComponent("content/micropolis") }
    static func city(_ name: String) -> URL { cities.appendingPathComponent("\(name).cty") }
}
