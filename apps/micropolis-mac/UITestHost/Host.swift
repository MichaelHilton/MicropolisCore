import AppKit

/// Replaced during the Xcode build by the SwiftPM Micropolis executable.
/// Keeping a tiny real app target gives XCUITest an application bundle to launch.
@main
struct UITestHost {
    static func main() {
        NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
    }
}
