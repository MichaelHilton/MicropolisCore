import Foundation

enum Messages {
    static let engineMessages: [Int: String] = [
        1: "More residential zones needed.",
        2: "More commercial zones needed.",
        3: "More industrial zones needed.",
        4: "More roads required.",
        5: "Inadequate rail system.",
        6: "Build a power plant.",
        10: "Pollution very high.",
        11: "Crime very high.",
        12: "Frequent traffic jams reported.",
        20: "Fire reported!",
        21: "A monster has been sighted!",
        22: "Tornado reported!",
        23: "Major earthquake reported!",
        24: "A plane has crashed!",
        25: "Shipwreck reported!",
        26: "A train crashed!",
        27: "A helicopter crashed!",
        29: "Your city has gone broke!"
    ]

    static func text(for index: Int) -> String {
        if index < 0 { return "" }
        return engineMessages[index] ?? "City message #\(index)"
    }
}
