import AppKit
import SwiftUI
import ImageIO
import Testing
@testable import MicropolisMac

@MainActor
struct RetroPreviewCaptureTests {
    @Test(.enabled(if: ProcessInfo.processInfo.environment["MICROPOLIS_CAPTURE_RETRO"] == "1"))
    func capturePreview() throws {
        let model = GameModel(city: Assets.city("haight"), sound: RecordingSound(), seed: 1, runsTimer: false)
        model.setGraphicsPackage(.retroSquare)
        model.selectedTool = .residential
        model.renderer.update(cells: model.engine.mapSnapshot())
        let rendered = try #require(model.renderer.makeImage())
        let mapDestination = try #require(CGImageDestinationCreateWithURL(URL(fileURLWithPath: "/tmp/micropolis-retro-map.png") as CFURL, "public.png" as CFString, 1, nil))
        CGImageDestinationAddImage(mapDestination, rendered, nil)
        #expect(CGImageDestinationFinalize(mapDestination))
        let host = NSHostingView(rootView: ContentView().environment(model))
        host.frame = NSRect(x: 0, y: 0, width: 1100, height: 800)
        let window = NSWindow(contentRect: host.frame, styleMask: .borderless, backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = host
        host.layoutSubtreeIfNeeded()
        func findMap(_ view: NSView) -> MapNSView? {
            if let map = view as? MapNSView { return map }
            return view.subviews.compactMap(findMap).first
        }
        window.display()
        let map = try #require(findMap(host))
        map.updateMap()
        map.center(onTileX: 65, y: 55)
        host.layoutSubtreeIfNeeded()
        window.display()
        let image = try #require(model.renderer.makeImage())
        let dest = try #require(CGImageDestinationCreateWithURL(URL(fileURLWithPath: "/tmp/micropolis-retro-map.png") as CFURL, "public.png" as CFString, 1, nil))
        CGImageDestinationAddImage(dest, image, nil)
        #expect(CGImageDestinationFinalize(dest))
        let bitmap = try #require(host.bitmapImageRepForCachingDisplay(in: host.bounds))
        host.cacheDisplay(in: host.bounds, to: bitmap)
        try #require(bitmap.representation(using: .png, properties: [:])).write(to: URL(fileURLWithPath: "/tmp/micropolis-retro-window.png"))
        window.close()
    }
}
