import Testing
import AppKit
import MicropolisKit
@testable import MicropolisMac

/// Keys, scroll requests and clicks on the edit window's map.
@MainActor
struct MapInteractionTests {
    /// A map view filling a 400x300 window, over a model with an all-dirt map
    /// and money to build with.
    private struct Rig {
        let model: GameModel
        let view: MapNSView
        let window: NSWindow
    }

    private func rig() -> Rig {
        let model = GameModel(city: nil, sound: RecordingSound(), seed: 1)
        for x in 0..<Engine.width { for y in 0..<Engine.height { model.engine.setTile(x: x, y: y, cell: 0) } }
        model.engine.setFunds(100_000)
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 300))
        let view = MapNSView(gameModel: model)
        view.frame = container.bounds
        container.addSubview(view)
        let window = NSWindow(contentRect: container.frame, styleMask: .borderless, backing: .buffered, defer: false)
        window.contentView = container
        container.layoutSubtreeIfNeeded()
        view.updateMap()
        return Rig(model: model, view: view, window: window)
    }

    private func key(_ characters: String, modifiers: NSEvent.ModifierFlags, in window: NSWindow) -> NSEvent {
        NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: modifiers, timestamp: 0,
                         windowNumber: window.windowNumber, context: nil, characters: characters,
                         charactersIgnoringModifiers: characters, isARepeat: false, keyCode: 0)!
    }

    /// A mouse event at the center of a tile, given the view's origin at the
    /// top-left of the window (the view is flipped, the window is not).
    private func mouse(_ type: NSEvent.EventType, tile: (x: Int, y: Int), modifiers: NSEvent.ModifierFlags = [],
                       in rig: Rig) -> NSEvent {
        let point = NSPoint(x: CGFloat(tile.x) * 16 + 8, y: 300 - (CGFloat(tile.y) * 16 + 8))
        return NSEvent.mouseEvent(with: type, location: point, modifierFlags: modifiers, timestamp: 0,
                                  windowNumber: rig.window.windowNumber, context: nil, eventNumber: 0,
                                  clickCount: 1, pressure: 1)!
    }

    private func tileNumber(_ rig: Rig, _ x: Int, _ y: Int) -> Int { Int(rig.model.engine.tile(x: x, y: y) & 0x3FF) }

    // MARK: Scrolling

    @Test
    func scrollRequestCentersTheTile() {
        let r = rig()
        r.view.handle(ScrollRequest(x: 60, y: 50, id: 1))
        // The tile's center sits at the middle of the 400x300 view.
        #expect(r.view.offset == CGPoint(x: 60.5 * 16 - 200, y: 50.5 * 16 - 150))
    }

    @Test
    func aRepeatedScrollRequestIdIsIgnored() {
        let r = rig()
        r.view.handle(ScrollRequest(x: 60, y: 50, id: 1))
        let first = r.view.offset
        r.view.handle(ScrollRequest(x: 20, y: 20, id: 1))
        #expect(r.view.offset == first)
        r.view.handle(ScrollRequest(x: 20, y: 20, id: 2))
        #expect(r.view.offset != first)
    }

    @Test
    func centeringNearTheCornerStopsAtTheMapEdge() {
        let r = rig()
        r.view.center(onTileX: 0, y: 0)
        #expect(r.view.offset == .zero)
        r.view.center(onTileX: Engine.width - 1, y: Engine.height - 1)
        #expect(r.view.offset == CGPoint(x: 1920 - 400, y: 1600 - 300))
    }

    @Test
    func scrollingPublishesTheVisibleTiles() {
        let r = rig()
        r.view.center(onTileX: 60, y: 50)
        let visible = r.model.visibleTiles
        #expect(visible.width == 25 && visible.height == 18.75)
        #expect(visible.origin == CGPoint(x: r.view.offset.x / 16, y: r.view.offset.y / 16))
    }

    // MARK: Zoom keys

    @Test
    func commandPlusAndMinusZoomByTenPercent() {
        let r = rig()
        r.view.keyDown(with: key("=", modifiers: .command, in: r.window))
        #expect(abs(r.view.zoom - 1.1) < 0.0001)
        r.view.keyDown(with: key("+", modifiers: .command, in: r.window))
        #expect(abs(r.view.zoom - 1.21) < 0.0001)
        r.view.keyDown(with: key("-", modifiers: .command, in: r.window))
        r.view.keyDown(with: key("-", modifiers: .command, in: r.window))
        #expect(abs(r.view.zoom - 1) < 0.0001)
    }

    @Test
    func zoomStaysBetweenHalfAndFour() {
        let r = rig()
        for _ in 0..<40 { r.view.keyDown(with: key("=", modifiers: .command, in: r.window)) }
        #expect(r.view.zoom == 4)
        for _ in 0..<80 { r.view.keyDown(with: key("-", modifiers: .command, in: r.window)) }
        #expect(r.view.zoom == 0.5)
    }

    @Test
    func zoomKeysNeedTheCommandKey() {
        let r = rig()
        r.view.keyDown(with: key("=", modifiers: [], in: r.window))
        #expect(r.view.zoom == 1)
    }

    // MARK: Clicks

    @Test
    func clickingWithRoadsBuildsARoad() {
        let r = rig()
        r.model.selectedTool = .road
        r.view.mouseDown(with: mouse(.leftMouseDown, tile: (5, 4), in: r))
        #expect(tileNumber(r, 5, 4) != 0)
        #expect(tileNumber(r, 6, 4) == 0)
    }

    @Test
    func clickingWithoutMoneyShowsAMessage() {
        let r = rig()
        r.model.engine.setFunds(0)
        r.model.selectedTool = .road
        r.view.mouseDown(with: mouse(.leftMouseDown, tile: (5, 4), in: r))
        #expect(tileNumber(r, 5, 4) == 0)
        #expect(r.model.toolMessage == "Not enough funds")
    }

    @Test
    func draggingARoadFillsTheGapsBetweenEvents() {
        let r = rig()
        r.model.selectedTool = .road
        r.view.mouseDown(with: mouse(.leftMouseDown, tile: (2, 2), in: r))
        r.view.mouseDragged(with: mouse(.leftMouseDragged, tile: (3, 2), in: r))
        r.view.mouseDragged(with: mouse(.leftMouseDragged, tile: (8, 2), in: r))
        for x in 2...8 { #expect(tileNumber(r, x, 2) != 0, "tile \(x)") }
        r.view.mouseUp(with: mouse(.leftMouseUp, tile: (8, 2), in: r))
        // After the button is released a new drag starts fresh.
        r.view.mouseDragged(with: mouse(.leftMouseDragged, tile: (8, 6), in: r))
        #expect(tileNumber(r, 8, 6) != 0)
        #expect(tileNumber(r, 8, 4) == 0, "no line back to the old stroke")
    }

    @Test
    func draggingABuildingToolBuildsNothingExtra() {
        let r = rig()
        r.model.selectedTool = .residential
        r.view.mouseDown(with: mouse(.leftMouseDown, tile: (10, 10), in: r))
        let built = r.model.engine.mapSnapshot().filter { $0 & 0x3FF != 0 }.count
        r.view.mouseDragged(with: mouse(.leftMouseDragged, tile: (20, 10), in: r))
        #expect(r.model.engine.mapSnapshot().filter { $0 & 0x3FF != 0 }.count == built)
    }

    @Test
    func optionDragScrollsInsteadOfBuilding() {
        let r = rig()
        r.model.selectedTool = .road
        r.view.mouseDragged(with: mouse(.leftMouseDragged, tile: (5, 5), modifiers: .option, in: r))
        #expect(r.model.engine.mapSnapshot().allSatisfy { $0 & 0x3FF == 0 })
    }

    @Test
    func clickOutsideTheMapDoesNothing() {
        let r = rig()
        r.model.selectedTool = .road
        r.view.zoom = 0.5
        r.view.offset = .zero
        // At half size the 400x300 view shows 50x37 tiles; use the far corner.
        let outside = NSEvent.mouseEvent(with: .leftMouseDown, location: NSPoint(x: 4000, y: 0), modifierFlags: [],
                                         timestamp: 0, windowNumber: r.window.windowNumber, context: nil,
                                         eventNumber: 0, clickCount: 1, pressure: 1)!
        r.view.mouseDown(with: outside)
        #expect(r.model.engine.mapSnapshot().allSatisfy { $0 & 0x3FF == 0 })
    }

    // MARK: Terrain mode

    @Test
    func clickingInTerrainModePaintsAndRemembersTheMapForUndo() {
        let r = rig()
        r.model.editMode = .terrain
        r.model.terrainTool = .water
        r.view.mouseDown(with: mouse(.leftMouseDown, tile: (5, 4), in: r))
        #expect(r.model.engine.tile(x: 5, y: 4) == TerrainTool.water.cell)
        #expect(r.model.terrainUndo != nil)
        #expect(r.model.toolMessage == nil, "no city tool was used")
    }

    @Test
    func terrainBrushPaintsAlongADrag() {
        let r = rig()
        r.model.editMode = .terrain
        r.model.terrainTool = .trees
        r.view.mouseDown(with: mouse(.leftMouseDown, tile: (2, 2), in: r))
        r.view.mouseDragged(with: mouse(.leftMouseDragged, tile: (9, 2), in: r))
        for x in 2...9 { #expect(r.model.engine.tile(x: x, y: 2) == TerrainTool.trees.cell, "tile \(x)") }
    }

    @Test
    func terrainFillActsOncePerClickNotPerDrag() {
        let r = rig()
        r.model.editMode = .terrain
        r.model.terrainTool = .water
        r.model.terrainFill = true
        r.view.mouseDown(with: mouse(.leftMouseDown, tile: (2, 2), in: r))
        // The fill covered the whole all-dirt map; put one tile back and drag
        // over it: a fill must not run again.
        r.model.engine.setTile(x: 9, y: 2, cell: 0)
        r.view.mouseDragged(with: mouse(.leftMouseDragged, tile: (9, 2), in: r))
        #expect(r.model.engine.tile(x: 9, y: 2) == 0)
    }
}
