import Testing
import CoreFoundation
import Foundation
@testable import MicropolisMac
@testable import MicropolisKit

struct MapRendererTests {
    @Test
    func tilesRenderCorrectly() throws {
        let atlasURL = Assets.tileAtlas
        let tileAtlas = try TileAtlas(atlasURL: atlasURL)
        let renderer = MapRenderer(tileAtlas: tileAtlas)

        let engine = Engine(seed: 1)
        let cityPath = Assets.city("haight")
        _ = engine.loadCity(at: cityPath)

        let cells = engine.mapSnapshot()
        renderer.update(cells: cells)

        let atlasBytes = tileAtlas.bytes

        for x in 0..<120 { for y in 0..<100 {
            let cellIndex = x * 100 + y
            let tileIndex = Int(cells[cellIndex] & 0x3FF)

            let pixelX = x * 16 + 3
            let pixelY = y * 16 + 3
            let bufferOffset = (pixelY * 1920 + pixelX) * 4

            let tilePixelX = (tileIndex % 32) * 16 + 3
            let tilePixelY = (tileIndex / 32) * 16 + 3
            let atlasOffset = (tilePixelY * 512 + tilePixelX) * 4

            guard bufferOffset + 4 <= renderer.pixelBuffer.count else { continue }
            guard atlasOffset + 4 <= atlasBytes.count else { continue }

            for i in 0..<4 {
                #expect(renderer.pixelBuffer[bufferOffset + i] == atlasBytes[atlasOffset + i])
            }
        } }
    }

    @Test
    func secondUpdateNoRedraw() throws {
        let atlasURL = Assets.tileAtlas
        let tileAtlas = try TileAtlas(atlasURL: atlasURL)
        let renderer = MapRenderer(tileAtlas: tileAtlas)

        let engine = Engine(seed: 1)
        let cityPath = Assets.city("haight")
        _ = engine.loadCity(at: cityPath)

        let cells = engine.mapSnapshot()
        renderer.update(cells: cells)

        _ = renderer.makeImage()

        renderer.update(cells: cells)
        #expect(renderer.lastRedrawCount == 0)
    }

    @Test
    func animationRedraws() throws {
        let atlasURL = Assets.tileAtlas
        let tileAtlas = try TileAtlas(atlasURL: atlasURL)
        let renderer = MapRenderer(tileAtlas: tileAtlas)

        let engine = Engine(seed: 1)
        let cityPath = Assets.city("haight")
        _ = engine.loadCity(at: cityPath)

        var cells = engine.mapSnapshot()
        renderer.update(cells: cells)

        for _ in 0..<200 {
            engine.tick()
        }

        cells = engine.mapSnapshot()
        renderer.update(cells: cells)
        #expect(renderer.lastRedrawCount > 0)
    }

    @Test(.enabled(
        if: ProcessInfo.processInfo.environment["MICROPOLIS_RUN_BENCHMARKS"] == "1",
        "Set MICROPOLIS_RUN_BENCHMARKS=1 to run benchmarks."
    ))
    func benchmarkFirstUpdate() throws {
        let engine = Engine(seed: 1)
        _ = engine.loadCity(at: Assets.city("haight"))
        let cells = engine.mapSnapshot()

        let measurements = try (0..<7).map { _ -> Double in
            let tileAtlas = try TileAtlas(atlasURL: Assets.tileAtlas)
            let renderer = MapRenderer(tileAtlas: tileAtlas)
            let startTime = Date()
            renderer.update(cells: cells)
            #expect(renderer.lastRedrawCount == Engine.width * Engine.height)
            return Date().timeIntervalSince(startTime) * 1_000
        }.sorted()

        print("METRIC map_renderer.first_update_ms.median \(measurements[measurements.count / 2])")
    }
}

extension MapRenderer {
    var pixelBuffer: [UInt8] {
        get { _pixelBuffer }
    }

    private var _pixelBuffer: [UInt8] {
        let mirror = Mirror(reflecting: self)
        for child in mirror.children {
            if child.label == "pixelBuffer" {
                return child.value as! [UInt8]
            }
        }
        return []
    }
}
