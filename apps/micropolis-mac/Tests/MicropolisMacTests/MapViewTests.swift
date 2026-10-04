import Testing
import AppKit
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
}
