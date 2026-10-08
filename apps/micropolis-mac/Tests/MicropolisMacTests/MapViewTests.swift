import Testing
import AppKit
import MicropolisKit
@testable import MicropolisMac

@MainActor
struct MapViewTests {
    @Test
    func tileAtWithZoomAndOffset() {
        let model = GameModel()
        let view = MapNSView(gameModel: model)

        view.zoom = 2.0
        view.offset = CGPoint(x: 32, y: 32)

        // With zoom=2 and offset=32:
        // point (x,y) -> mapX = (x+offset) / zoom -> tileX = mapX / 16
        let testCases: [(point: NSPoint, expected: (x: Int, y: Int))] = [
            (NSPoint(x: 0, y: 0), (1, 1)),      // (0+32)/2 = 16, 16/16 = 1
            (NSPoint(x: 32, y: 32), (2, 2)),    // (32+32)/2 = 32, 32/16 = 2
            (NSPoint(x: 96, y: 96), (4, 4)),    // (96+32)/2 = 64, 64/16 = 4
        ]

        for (point, expected) in testCases {
            let result = view.tile(at: point)
            #expect(result?.x == expected.x)
            #expect(result?.y == expected.y)
        }
    }

    @Test
    func tileAtOffMap() {
        let model = GameModel()
        let view = MapNSView(gameModel: model)

        let result = view.tile(at: NSPoint(x: 2000, y: 2000))
        #expect(result == nil)
    }

    @Test
    func tileAtNegativeCoordinates() {
        let model = GameModel()
        let view = MapNSView(gameModel: model)

        let result = view.tile(at: NSPoint(x: -100, y: -100))
        #expect(result == nil)
    }

    /// The map scrolls by moving a layer much larger than the view. After a
    /// scroll it must not draw outside the view, or it covers the menu strip
    /// and HUD above it in the edit window.
    @Test
    func scrolledMapStaysInsideItsBounds() throws {
        let model = GameModel()
        model.newCity(name: "Clip", level: .easy, seed: 3)

        // A magenta container with the map in a band across the middle,
        // standing in for the HUD above and the status line below.
        let size = 400
        let container = NSView(frame: NSRect(x: 0, y: 0, width: size, height: size))
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor.magenta.cgColor
        let view = MapNSView(gameModel: model)
        view.frame = NSRect(x: 0, y: 150, width: size, height: 100)
        container.addSubview(view)
        // AppKit only joins the view's layer to the container's inside a window.
        let window = NSWindow(contentRect: container.frame, styleMask: .borderless,
                              backing: .buffered, defer: false)
        window.contentView = container
        container.layoutSubtreeIfNeeded()
        window.display()

        view.updateMap()
        view.center(onTileX: Engine.width / 2, y: Engine.height / 2)
        #expect(view.offset.y > 0)

        let layer = try #require(container.layer)
        layer.layoutIfNeeded()
        let context = try #require(CGContext(
            data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: size * 4,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        layer.render(in: context)
        let pixels = try #require(context.data).bindMemory(to: UInt8.self, capacity: size * size * 4)

        // Rows well clear of the map band, above and below, must be untouched.
        var mapPixelsOutside = 0
        for row in Array(0..<140) + Array(260..<size) {
            for col in 0..<size {
                let i = (row * size + col) * 4
                let isMagenta = pixels[i] > 200 && pixels[i + 1] < 50 && pixels[i + 2] > 200
                if !isMagenta { mapPixelsOutside += 1 }
            }
        }
        #expect(mapPixelsOutside == 0)

        // And the map really is drawn inside the band, so the check above can fail.
        let inside = (200 * size + size / 2) * 4
        #expect(!(pixels[inside] > 200 && pixels[inside + 1] < 50 && pixels[inside + 2] > 200))
    }
}
