import SwiftUI
import AppKit
import MicropolisKit

struct MapView: NSViewRepresentable {
    @State private var mapNSView: MapNSView?
    let gameModel: GameModel

    func makeNSView(context: Context) -> NSView {
        let view = MapNSView(gameModel: gameModel)
        self.mapNSView = view
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if let mapNSView = nsView as? MapNSView {
            mapNSView.updateMap()
            mapNSView.updateToolOutline()
            if let request = gameModel.scrollRequest {
                mapNSView.handle(request)
            }
        }
    }

    static func dismantleNSView(_ nsView: NSView, coordinator: ()) {
    }
}

class MapNSView: NSView {
    let gameModel: GameModel
    let renderer: MapRenderer
    let tileAtlas: TileAtlas

    var offset = CGPoint.zero
    var zoom: CGFloat = 1.0 {
        didSet { zoom = max(0.5, min(4, zoom)) }
    }

    private var mapLayer: CALayer?
    private var contentLayer: CALayer?
    private var spriteLayer: CALayer?
    let toolOutline = CALayer()
    /// Where the pointer is over the map, in view coordinates; nil when outside.
    private var hoverPoint: CGPoint?
    /// DOS hides the pointer over the map and shows only the tool outline.
    private static let blankCursor = NSCursor(image: NSImage(size: NSSize(width: 1, height: 1)), hotSpot: .zero)
    private var lastMapVersion = -1
    private var lastDragTile: (x: Int, y: Int)? = nil
    private var lastScrollRequestID = 0

    private let lineDrawTools: [Tool] = [.road, .railroad, .wire, .bulldozer, .park]

    init(gameModel: GameModel) {
        self.gameModel = gameModel
        self.renderer = gameModel.renderer
        self.tileAtlas = gameModel.tileAtlas
        super.init(frame: .zero)

        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor
        // The map layer is far larger than the view and is scrolled by moving
        // it. Views don't clip by default on macOS 14+, so without this the map
        // paints over the menu strip and HUD above it.
        clipsToBounds = true
        layer?.masksToBounds = true

        setupLayers()
        addTrackingArea(NSTrackingArea(
            rect: .zero,
            options: [.activeInKeyWindow, .inVisibleRect, .mouseMoved, .mouseEnteredAndExited, .cursorUpdate],
            owner: self, userInfo: nil))
    }

    override var isFlipped: Bool { true }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayers() {
        let mapLayer = CALayer()
        mapLayer.magnificationFilter = .nearest
        layer?.addSublayer(mapLayer)
        self.mapLayer = mapLayer

        let contentLayer = CALayer()
        mapLayer.addSublayer(contentLayer)
        self.contentLayer = contentLayer

        let spriteLayer = CALayer()
        layer?.addSublayer(spriteLayer)
        self.spriteLayer = spriteLayer

        // Like DOS: an unfilled box the size of what the tool builds.
        toolOutline.borderColor = NSColor(DOS.lightBlue).cgColor
        toolOutline.borderWidth = 2
        toolOutline.isHidden = true
        toolOutline.actions = ["position": NSNull(), "bounds": NSNull(), "hidden": NSNull()]
        layer?.addSublayer(toolOutline)
    }

    /// Moves the tool outline to the tiles a click at the pointer would cover.
    func updateToolOutline() {
        defer {
            if hoverPoint != nil { updatePointer() }
        }
        guard gameModel.editMode == .city, let point = hoverPoint, let tile = tile(at: point) else {
            toolOutline.isHidden = true
            return
        }
        let footprint = ToolSpec.footprint(for: gameModel.selectedTool, at: tile)
        let tilePixels = 16 * zoom
        toolOutline.frame = CGRect(x: CGFloat(footprint.x) * tilePixels - offset.x,
                                   y: CGFloat(footprint.y) * tilePixels - offset.y,
                                   width: CGFloat(footprint.size) * tilePixels,
                                   height: CGFloat(footprint.size) * tilePixels)
        toolOutline.isHidden = false
    }

    /// Records where the pointer is over the map, in view coordinates.
    func hover(at point: CGPoint?) {
        hoverPoint = point
        updateToolOutline()
    }

    private func trackPointer(_ event: NSEvent?) {
        hover(at: event.map { convert($0.locationInWindow, from: nil) })
    }

    override func mouseEntered(with event: NSEvent) { trackPointer(event) }
    override func mouseExited(with event: NSEvent) {
        trackPointer(nil)
        NSCursor.arrow.set()
    }

    override func cursorUpdate(with event: NSEvent) {
        updatePointer()
    }

    /// The outline stands in for the pointer; show the arrow where there is none.
    private func updatePointer() {
        (toolOutline.isHidden ? NSCursor.arrow : Self.blankCursor).set()
    }

    func updateMap() {
        guard gameModel.mapVersion != lastMapVersion else { return }
        lastMapVersion = gameModel.mapVersion

        let cells = gameModel.engine.mapSnapshot()
        renderer.update(cells: cells)

        if let image = renderer.makeImage() {
            mapLayer?.contents = image
        }

        let sprites = gameModel.engine.sprites()
        if let spriteLayer = spriteLayer {
            gameModel.spriteRenderer.updateSprites(sprites, in: spriteLayer)
        }

        updateLayout()
    }

    private func updateLayout() {
        guard let bounds = mapLayer?.superlayer?.bounds else { return }

        let mapWidth: CGFloat = 1920 * zoom
        let mapHeight: CGFloat = 1600 * zoom
        let viewWidth = bounds.width
        let viewHeight = bounds.height

        let maxOffsetX = max(0, mapWidth - viewWidth)
        let maxOffsetY = max(0, mapHeight - viewHeight)

        offset.x = max(0, min(offset.x, maxOffsetX))
        offset.y = max(0, min(offset.y, maxOffsetY))

        mapLayer?.frame = bounds
        contentLayer?.frame = CGRect(x: -offset.x, y: -offset.y, width: mapWidth, height: mapHeight)
        contentLayer?.contents = mapLayer?.contents
        updateToolOutline()
        publishVisibleTiles()
    }

    /// Tells the map window which tiles this view shows, so it can draw the box.
    private func publishVisibleTiles() {
        let tilePixels = 16 * zoom
        let visible = CGRect(x: offset.x / tilePixels, y: offset.y / tilePixels,
                             width: min(CGFloat(Engine.width), bounds.width / tilePixels),
                             height: min(CGFloat(Engine.height), bounds.height / tilePixels))
        if gameModel.visibleTiles != visible {
            gameModel.visibleTiles = visible
        }
    }

    /// Scrolls so a tile is centered, for the map window and Auto-Goto.
    func handle(_ request: ScrollRequest) {
        guard request.id != lastScrollRequestID else { return }
        lastScrollRequestID = request.id
        center(onTileX: request.x, y: request.y)
    }

    func center(onTileX x: Int, y: Int) {
        let tilePixels = 16 * zoom
        offset = CGPoint(x: (CGFloat(x) + 0.5) * tilePixels - bounds.width / 2,
                         y: (CGFloat(y) + 0.5) * tilePixels - bounds.height / 2)
        updateLayout()
    }

    override func scrollWheel(with event: NSEvent) {
        let delta = CGPoint(x: -event.deltaX * 4, y: -event.deltaY * 4)
        offset.x += delta.x
        offset.y += delta.y
        updateLayout()
    }

    override func rightMouseDown(with event: NSEvent) {
        let startOffset = offset
        let startPoint = event.locationInWindow

        let trackingArea = NSTrackingArea(rect: bounds, options: [.activeInKeyWindow, .mouseMoved, .inVisibleRect], owner: self, userInfo: nil)
        addTrackingArea(trackingArea)

        var isTracking = true
        while isTracking {
            guard let nextEvent = window?.nextEvent(matching: [.leftMouseDragged, .rightMouseUp, .rightMouseDragged]) else { break }

            switch nextEvent.type {
            case .rightMouseDragged:
                let currentPoint = nextEvent.locationInWindow
                let deltaX = startPoint.x - currentPoint.x
                let deltaY = startPoint.y - currentPoint.y
                offset.x = startOffset.x + deltaX * zoom
                offset.y = startOffset.y + deltaY * zoom
                updateLayout()
            case .rightMouseUp:
                isTracking = false
            default:
                break
            }
        }

        removeTrackingArea(trackingArea)
    }

    override func mouseDown(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        guard let tile = tile(at: location) else { return }
        if gameModel.editMode == .terrain {
            gameModel.beginTerrainStroke()
            gameModel.applyTerrain(atX: tile.x, y: tile.y)
            lastDragTile = tile
            return
        }
        applyTool(at: tile)
    }

    override func mouseMoved(with event: NSEvent) {
        trackPointer(event)
    }

    override func mouseDragged(with event: NSEvent) {
        trackPointer(event)
        if event.modifierFlags.contains(.option) {
            let delta = CGPoint(x: -event.deltaX, y: -event.deltaY)
            offset.x += delta.x * zoom
            offset.y += delta.y * zoom
            updateLayout()
        } else {
            let location = convert(event.locationInWindow, from: nil)
            guard let tile = tile(at: location) else { return }

            if gameModel.editMode == .terrain {
                // Fill acts once per click; brushes paint along the drag.
                guard !gameModel.terrainFill else { return }
                let path = lastDragTile.map { Bresenham.line(from: $0, to: tile) } ?? [tile]
                for point in path {
                    gameModel.applyTerrain(atX: point.x, y: point.y)
                }
                lastDragTile = tile
            } else if lineDrawTools.contains(gameModel.selectedTool) {
                if let lastTile = lastDragTile {
                    let path = Bresenham.line(from: lastTile, to: tile)
                    for point in path {
                        applyTool(at: point)
                    }
                } else {
                    applyTool(at: tile)
                }
                lastDragTile = tile
            }
        }
    }

    override func mouseUp(with event: NSEvent) {
        lastDragTile = nil
    }

    private func applyTool(at tile: (x: Int, y: Int)) {
        gameModel.applyTool(atX: tile.x, y: tile.y)
    }

    override func magnify(with event: NSEvent) {
        let oldZoom = zoom
        zoom *= (1 + event.magnification)

        let mouseLocation = event.locationInWindow
        let viewCenter = CGPoint(x: bounds.midX, y: bounds.midY)
        let delta = CGPoint(x: mouseLocation.x - viewCenter.x, y: mouseLocation.y - viewCenter.y)

        offset.x += delta.x * (oldZoom - zoom) / oldZoom
        offset.y += delta.y * (oldZoom - zoom) / oldZoom

        updateLayout()
    }

    override func keyDown(with event: NSEvent) {
        let modifiers = event.modifierFlags
        if modifiers.contains(.command) {
            if event.characters == "+" || event.characters == "=" {
                zoom *= 1.1
                updateLayout()
            } else if event.characters == "-" {
                zoom /= 1.1
                updateLayout()
            } else {
                super.keyDown(with: event)
            }
        } else {
            super.keyDown(with: event)
        }
    }

    func tile(at point: NSPoint) -> (x: Int, y: Int)? {
        guard mapLayer?.superlayer != nil else { return nil }

        let mapX = (point.x + offset.x) / zoom
        let mapY = (point.y + offset.y) / zoom

        let tileX = Int(mapX / 16)
        let tileY = Int(mapY / 16)

        guard tileX >= 0 && tileX < Engine.width && tileY >= 0 && tileY < Engine.height else {
            return nil
        }

        return (tileX, tileY)
    }
}
