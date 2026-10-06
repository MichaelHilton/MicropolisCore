import SwiftUI

/// The 16-color EGA palette and type used to echo the 1989 DOS SimCity screen.
/// These are fixed colors on purpose: the retro look doesn't follow dark mode.
enum DOS {
    static let black = Color(red: 0, green: 0, blue: 0)
    static let blue = Color(red: 0, green: 0, blue: 0xAA / 255)
    static let green = Color(red: 0, green: 0xAA / 255, blue: 0)
    static let red = Color(red: 0xAA / 255, green: 0, blue: 0)
    static let lightGray = Color(red: 0xAA / 255, green: 0xAA / 255, blue: 0xAA / 255)
    static let darkGray = Color(red: 0x55 / 255, green: 0x55 / 255, blue: 0x55 / 255)
    static let lightBlue = Color(red: 0x55 / 255, green: 0x55 / 255, blue: 1)
    static let yellow = Color(red: 1, green: 1, blue: 0x55 / 255)
    static let white = Color(red: 1, green: 1, blue: 1)

    static func font(_ size: CGFloat = 13) -> Font {
        .system(size: size, weight: .bold, design: .monospaced)
    }
}
