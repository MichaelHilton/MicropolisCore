import AppKit
import ImageIO
import SwiftUI
import Testing
@testable import MicropolisKit
@testable import MicropolisMac

@MainActor
struct ChromeThemeTests {
    @Test
    func eachLookPicksItsScreen() {
        #expect(GraphicsPackage.classic.chrome == nil)
        #expect(GraphicsPackage.handInked.chrome == nil)
        #expect(GraphicsPackage.retroSquare.chrome?.design == .monospaced)
        #expect(GraphicsPackage.plannersMap.chrome?.barScheme == .light)
        #expect(GraphicsPackage.toyBlocks.chrome?.raised == true)
        #expect(GraphicsPackage.toyBlocks.shortTitle == "Toy Blocks")
        #expect(GraphicsPackage.retroSquare.shortTitle == "Retro Borough")
    }

    @Test
    func retroLabelsStayUppercaseAndTheOthersDoNot() {
        #expect(ChromeTheme.retro.label("Build") == "BUILD")
        #expect(ChromeTheme.plannersMap.label("Build") == "Build")
        #expect(ChromeTheme.toyBlocks.label("Build") == "Build")
    }

    @Test
    func themedLooksDrawTheirOwnMenusButRetroKeepsSystemMenus() {
        #expect(ChromeTheme.retro.customMenus == false)
        #expect(ChromeTheme.plannersMap.customMenus)
        #expect(ChromeTheme.toyBlocks.customMenus)
        #expect(Set(ThemedMenu.allCases.map(\.rawValue)) == ["SYSTEM", "OPTIONS", "DISASTERS", "WINDOWS", "APPEARANCE"])
    }

    /// Renders every window and menu panel in each themed look for review.
    @Test(.enabled(if: ProcessInfo.processInfo.environment["MICROPOLIS_CAPTURE_PROCEDURAL"] != nil))
    func captureWindows() throws {
        let directory = URL(fileURLWithPath: ProcessInfo.processInfo.environment["MICROPOLIS_CAPTURE_PROCEDURAL"]!)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        for package in [GraphicsPackage.classic, .retroSquare, .plannersMap, .toyBlocks] {
            let model = GameModel(city: Assets.city("haight"), sound: RecordingSound(), seed: 1, runsTimer: false)
            model.setGraphicsPackage(package)
            for _ in 0..<200 { model.engine.tick() }
            model.evaluation = model.engine.evaluation()
            let theme = package.chrome ?? .retro
            let menus = HStack(alignment: .top, spacing: 12) {
                ForEach([ThemedMenu.system, .options, .disasters, .windows], id: \.self) { menu in
                    ThemedMenuPanel(menu: menu, theme: theme, close: {}, scrolls: false)
                }
            }
            let screen = VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 16) {
                    BudgetView()
                    VStack(alignment: .leading, spacing: 16) { NewCityView(); GraphsView() }
                }
                HStack(alignment: .top, spacing: 16) { EvaluationView(); TerrainPalette().frame(height: 330) }
                MapsView()
                if package.chrome?.customMenus == true { menus }
            }
            .padding(16)
            .background(Color.gray.opacity(0.4))
            .environment(model)
            let renderer = ImageRenderer(content: screen)
            renderer.scale = 1
            let image = try #require(renderer.cgImage)
            let url = directory.appendingPathComponent("windows-\(package.rawValue).png")
            let destination = try #require(CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil))
            CGImageDestinationAddImage(destination, image, nil)
            #expect(CGImageDestinationFinalize(destination))
        }
    }

    /// Renders the bar, palette and status line of each themed look for review:
    /// MICROPOLIS_CAPTURE_PROCEDURAL=/some/dir swift test --filter ChromeThemeTests
    @Test(.enabled(if: ProcessInfo.processInfo.environment["MICROPOLIS_CAPTURE_PROCEDURAL"] != nil))
    func captureChrome() throws {
        let directory = URL(fileURLWithPath: ProcessInfo.processInfo.environment["MICROPOLIS_CAPTURE_PROCEDURAL"]!)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        for package in [GraphicsPackage.retroSquare, .plannersMap, .toyBlocks] {
            let model = GameModel(city: Assets.city("haight"), sound: RecordingSound(), seed: 1, runsTimer: false)
            model.setGraphicsPackage(package)
            model.selectedTool = .residential
            model.renderer.update(cells: model.engine.mapSnapshot())
            let map = try #require(model.renderer.makeImage()?.cropping(to: CGRect(x: 1400, y: 1300, width: 1400, height: 900)))
            let screen = VStack(spacing: 0) {
                RetroHUDView()
                HStack(spacing: 0) {
                    RetroToolPalette()
                    VStack(spacing: 0) {
                        Image(decorative: map, scale: 2).resizable().frame(width: 700, height: 450)
                        RetroStatusLine()
                    }
                }
            }
            .frame(width: 826)
            .environment(model)
            let renderer = ImageRenderer(content: screen)
            renderer.scale = 2
            let image = try #require(renderer.cgImage)
            let url = directory.appendingPathComponent("chrome-\(package.rawValue).png")
            let destination = try #require(CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil))
            CGImageDestinationAddImage(destination, image, nil)
            #expect(CGImageDestinationFinalize(destination))
        }
    }
}
