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
    private var lastMapVersion = -1
    private var lastDragTile: (x: Int, y: Int)? = nil
    private var toolMessageTimer: Timer? = nil

    private let lineDrawTools: [Tool] = [.road, .railroad, .wire, .bulldozer, .park]

    init(gameModel: GameModel) {
        self.gameModel = gameModel
        self.renderer = gameModel.renderer
        self.tileAtlas = gameModel.tileAtlas
        super.init(frame: .zero)

        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor

        setupLayers()
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
        let location = event.locationInWindow
        guard let tile = tile(at: location) else { return }
        applyTool(at: tile)
    }

    override func mouseMoved(with event: NSEvent) {
        if NSEvent.modifierFlags.contains(.option) {
            // Option-drag handled in mouseDragged
        }
    }

    override func mouseDragged(with event: NSEvent) {
        if NSEvent.modifierFlags.contains(.option) {
            let delta = CGPoint(x: -event.deltaX, y: -event.deltaY)
            offset.x += delta.x * zoom
            offset.y += delta.y * zoom
            updateLayout()
        } else {
            let location = event.locationInWindow
            guard let tile = tile(at: location) else { return }

            if lineDrawTools.contains(gameModel.selectedTool) {
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
        let result = gameModel.engine.apply(gameModel.selectedTool, x: tile.x, y: tile.y)

        let message: String?
        switch result {
        case .noMoney:
            message = "Not enough funds"
        case .needBulldoze:
            message = "Bulldoze first"
        case .failed:
            message = "Can't build there"
        case .ok:
            message = nil
        default:
            message = nil
        }

        if let message = message {
            gameModel.toolMessage = message
            toolMessageTimer?.invalidate()
            toolMessageTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
                Task { @MainActor in
                    self?.gameModel.toolMessage = nil
                }
            }
        } else {
            gameModel.toolMessage = nil
        }
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
        let modifiers = NSEvent.modifierFlags
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
