import XCTest
@testable import MicropolisKit

/// The moving things (sprite.cpp): trains, aircraft, ships, monsters,
/// tornadoes and explosions, read through Engine.sprites().
final class SpriteTests: XCTestCase {
    private enum Kind {
        static let train = 1, helicopter = 2, airplane = 3, ship = 4, monster = 5, tornado = 6, explosion = 7
    }

    private func city(_ name: String) -> Engine {
        let engine = Engine()
        XCTAssertTrue(engine.loadCity(at: Repo.city(name)), name)
        return engine
    }

    /// Ticks until a sprite of `type` exists, for at most `limit` ticks.
    private func sprite(_ type: Int, in engine: Engine, within limit: Int = 3000,
                        file: StaticString = #filePath, line: UInt = #line) -> Sprite? {
        for tick in 0...limit {
            if let found = engine.sprites().first(where: { $0.type == type }) { return found }
            if tick < limit { engine.tick() }
        }
        XCTFail("no sprite of type \(type) in \(limit) ticks", file: file, line: line)
        return nil
    }

    private func count(_ engine: Engine, where matches: (UInt16) -> Bool) -> Int {
        engine.mapSnapshot().filter(matches).count
    }

    private func isRubbleOrFire(_ cell: UInt16) -> Bool {
        let tile = Int(cell & 0x3FF)
        return (44...47).contains(tile) || (56...63).contains(tile)
    }

    func testTrainsRunOnARailCity() {
        _ = sprite(Kind.train, in: city("bruce"))
    }

    func testShipsSailFromASeaport() {
        _ = sprite(Kind.ship, in: city("ndulls"))
    }

    func testPlanesTakeOffFromAnAirport() {
        _ = sprite(Kind.airplane, in: city("deadwood"))
    }

    func testHelicoptersFlyOverABigCity() {
        let engine = Engine()
        XCTAssertTrue(engine.loadScenario(.boston, resourceDirectory: Repo.content))
        _ = sprite(Kind.helicopter, in: engine)
    }

    func testSpritesMoveWhileTheyLive() throws {
        let engine = city("deadwood")
        let plane = try XCTUnwrap(sprite(Kind.airplane, in: engine))
        for _ in 0..<20 { engine.tick() }
        let later = engine.sprites().filter { $0.type == Kind.airplane }
        XCTAssertTrue(later.isEmpty || later.contains { $0.x != plane.x || $0.y != plane.y },
                      "a plane that is still flying has moved")
    }

    func testMonsterAppearsWalksAndWrecksThings() throws {
        let engine = city("haight")
        let damagedBefore = count(engine, where: isRubbleOrFire)
        engine.makeDisaster(.monster)
        let start = try XCTUnwrap(sprite(Kind.monster, in: engine, within: 5))
        var moved = false
        for _ in 0..<50 {
            engine.tick()
            if let now = engine.sprites().first(where: { $0.type == Kind.monster }), now.x != start.x || now.y != start.y {
                moved = true
            }
        }
        XCTAssertTrue(moved, "the monster should walk")
        for _ in 0..<400 { engine.tick() }
        XCTAssertGreaterThan(count(engine, where: isRubbleOrFire), damagedBefore, "the monster leaves damage behind")
    }

    func testTornadoAppearsAndMoves() throws {
        let engine = city("haight")
        engine.makeDisaster(.tornado)
        let start = try XCTUnwrap(sprite(Kind.tornado, in: engine, within: 5))
        var moved = false
        for _ in 0..<50 {
            engine.tick()
            if let now = engine.sprites().first(where: { $0.type == Kind.tornado }), now.x != start.x || now.y != start.y {
                moved = true
            }
        }
        XCTAssertTrue(moved, "the tornado should move")
    }

    func testAirCrashBlowsUpThePlane() throws {
        let engine = city("deadwood")
        // Wait for a plane at a moment with no explosion already on screen.
        var ticks = 0
        while !(engine.sprites().contains { $0.type == Kind.airplane } && !engine.sprites().contains { $0.type == Kind.explosion }) {
            engine.tick()
            ticks += 1
            if ticks > 3000 { return XCTFail("never saw a plane without an explosion") }
        }
        engine.makeDisaster(.airCrash)
        XCTAssertTrue(engine.sprites().contains { $0.type == Kind.explosion }, "the crash makes an explosion")
    }
}
