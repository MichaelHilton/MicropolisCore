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

/// The outline shown under the pointer, which previews where a click builds.
@MainActor
struct ToolOutlineTests {
    @Test
    func footprintMatchesWhereTheEngineBuilds() {
        #expect(ToolSpec.footprint(for: .road, at: (10, 20)) == (10, 20, 1))
        #expect(ToolSpec.footprint(for: .query, at: (10, 20)) == (10, 20, 1))
        #expect(ToolSpec.footprint(for: .residential, at: (10, 20)) == (9, 19, 3))
        #expect(ToolSpec.footprint(for: .coalPower, at: (10, 20)) == (9, 19, 4))
        #expect(ToolSpec.footprint(for: .airport, at: (10, 20)) == (9, 19, 6))
    }

    @Test
    func footprintCoversTheTilesTheEngineChanges() {
        let model = GameModel()
        model.newCity(name: "Outline", level: .easy, seed: 1)
        for x in 0..<Engine.width {
            for y in 0..<Engine.height { model.engine.setTile(x: x, y: y, cell: 0) }
        }
        let before = model.engine.mapSnapshot()
        #expect(model.engine.apply(.coalPower, x: 30, y: 40) == .ok)
        let after = model.engine.mapSnapshot()

        let footprint = ToolSpec.footprint(for: .coalPower, at: (30, 40))
        var changed: [(Int, Int)] = []
        for x in 0..<Engine.width {
            for y in 0..<Engine.height where before[x * Engine.height + y] != after[x * Engine.height + y] {
                changed.append((x, y))
            }
        }
        #expect(changed.count == footprint.size * footprint.size)
        #expect(changed.allSatisfy { $0.0 >= footprint.x && $0.0 < footprint.x + footprint.size
                                     && $0.1 >= footprint.y && $0.1 < footprint.y + footprint.size })
    }

    @Test
    func outlineFollowsPointerToolZoomAndScroll() {
        let model = GameModel()
        let view = MapNSView(gameModel: model)
        view.frame = NSRect(x: 0, y: 0, width: 400, height: 300)
        #expect(view.toolOutline.isHidden)

        model.selectedTool = .residential
        view.hover(at: CGPoint(x: 100, y: 50))      // tile (6, 3)
        #expect(!view.toolOutline.isHidden)
        #expect(view.toolOutline.frame == CGRect(x: 80, y: 32, width: 48, height: 48))

        model.selectedTool = .road
        view.updateToolOutline()
        #expect(view.toolOutline.frame == CGRect(x: 96, y: 48, width: 16, height: 16))

        // Zoomed in and scrolled, the box still sits on the tile under the pointer.
        view.zoom = 2
        view.offset = CGPoint(x: 64, y: 32)
        view.hover(at: CGPoint(x: 100, y: 50))      // map (164, 82)/2 -> tile (5, 2)
        #expect(view.toolOutline.frame == CGRect(x: 5 * 32 - 64, y: 2 * 32 - 32, width: 32, height: 32))

        view.hover(at: nil)
        #expect(view.toolOutline.isHidden)
    }

    @Test
    func noOutlineInTerrainEditor() {
        let model = GameModel()
        let view = MapNSView(gameModel: model)
        view.frame = NSRect(x: 0, y: 0, width: 400, height: 300)
        model.editMode = .terrain
        view.hover(at: CGPoint(x: 100, y: 50))
        #expect(view.toolOutline.isHidden)
    }
}
