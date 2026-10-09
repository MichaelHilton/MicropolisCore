import XCTest
@testable import MicropolisKit

/// Sprites in cities built by hand (sprite.cpp): each test lays out the
/// ground a sprite will meet, then watches what the sprite does to it.
final class SpriteWorldTests: XCTestCase {
    private enum Kind {
        static let train = 1, helicopter = 2, airplane = 3, ship = 4, monster = 5, tornado = 6, explosion = 7
    }
    private let river = 2

    private func world() -> Engine {
        let engine = ToolFixture.engine()
        engine.setEnableDisasters(false)
        engine.setSpeed(3)
        return engine
    }

    private func find(_ type: Int, _ engine: Engine) -> Sprite? {
        engine.sprites().first { $0.type == type && $0.frame != 0 }
    }

    private func fill(_ engine: Engine, x: ClosedRange<Int>, y: ClosedRange<Int>, tile: Int) {
        for xx in x { for yy in y { ToolFixture.put(engine, xx, yy, tile) } }
    }

    // MARK: Monster

    func testMonsterFacesTheCornerOfTheMapItStartsIn() throws {
        // makeMonster picks a random river tile, so a river that fills only one
        // quarter of the map decides where the monster starts.
        let quarters: [(x: ClosedRange<Int>, y: ClosedRange<Int>, frame: Int)] = [
            (60...109, 52...94, 10), (10...50, 52...94, 1), (10...50, 5...48, 4), (60...109, 5...48, 7),
        ]
        for q in quarters {
            let engine = world()
            fill(engine, x: q.x, y: q.y, tile: river)
            engine.makeDisaster(.monster)
            let monster = try XCTUnwrap(find(Kind.monster, engine))
            XCTAssertEqual(monster.frame, q.frame, "river at \(q.x) x \(q.y)")
        }
    }

    func testMonsterDiesAtOnceInWater() throws {
        let engine = world()
        fill(engine, x: 10...109, y: 5...94, tile: river)
        engine.makeDisaster(.monster)
        XCTAssertNotNil(find(Kind.monster, engine))
        engine.tick()
        XCTAssertNil(find(Kind.monster, engine), "a fresh monster that steps into a river vanishes")
    }

    func testSecondMonsterJustResetsTheFirst() {
        let engine = world()
        engine.makeDisaster(.monster)
        engine.makeDisaster(.monster)
        XCTAssertEqual(engine.sprites().filter { $0.type == Kind.monster }.count, 1)
    }

    // MARK: Ships

    /// A powered seaport at the end of a wire, and a one-tile-wide channel
    /// along the top edge of the map for the ships to start in.
    private func harbour(_ engine: Engine, channel: Range<Int>? = 8..<31) {
        XCTAssertEqual(engine.apply(.coalPower, x: 20, y: 20), .ok)
        for x in 23...28 { XCTAssertEqual(engine.apply(.wire, x: x, y: 20), .ok) }
        XCTAssertEqual(engine.apply(.seaport, x: 30, y: 20), .ok)
        for x in channel ?? 1..<1 { ToolFixture.put(engine, x, 0, 4) }
    }

    private func tick(_ engine: Engine, upTo limit: Int, until done: () -> Bool) -> Bool {
        for _ in 0..<limit {
            if done() { return true }
            engine.tick()
        }
        return done()
    }

    func testAShipThatRunsOutOfChannelWrecksItself() throws {
        let engine = world()
        let recorder = FullRecorder()
        engine.delegate = recorder
        harbour(engine)
        XCTAssertTrue(tick(engine, upTo: 1500) { self.find(Kind.ship, engine) != nil }, "the seaport sends a ship")
        XCTAssertTrue(tick(engine, upTo: 600) { recorder.messages.contains { $0.index == 25 } },
                      "with nowhere to sail the ship blows up")
        XCTAssertNil(find(Kind.ship, engine))
        XCTAssertTrue(recorder.sounds.contains("ExplosionHigh"))
    }

    /// Starts a harbour with no channel, lets the test lay its own channel, then
    /// ticks until the seaport sends a ship and returns it.
    private func shipFrom(_ engine: Engine) throws -> Sprite {
        XCTAssertTrue(tick(engine, upTo: 2500) { self.find(Kind.ship, engine) != nil }, "the seaport sends a ship")
        return try XCTUnwrap(find(Kind.ship, engine))
    }

    /// Frames the ship shows over the next `ticks` ticks.
    private func frames(of type: Int, _ engine: Engine, ticks: Int) -> [Int] {
        var seen: [Int] = []
        for _ in 0..<ticks {
            engine.tick()
            if let sprite = find(type, engine), seen.last != sprite.frame { seen.append(sprite.frame) }
        }
        return seen
    }

    func testAShipFromTheBottomEdgeTurnsAcrossNorthWest() throws {
        let engine = world()
        harbour(engine, channel: nil)
        ToolFixture.put(engine, 60, 99, 4)
        ToolFixture.put(engine, 59, 98, 4)
        let ship = try shipFrom(engine)
        // A ship that enters at the bottom faces north (frame 1) but turns at once.
        // Going from 1 to 8 takes the short way round, through 0, which wraps to 8.
        XCTAssertTrue([1, 8].contains(ship.frame))
        XCTAssertTrue(([ship.frame] + frames(of: Kind.ship, engine, ticks: 40)).contains(8),
                      "it turns to the channel in the north west")
    }

    func testAShipFromTheEastEdgeTurnsNorth() throws {
        let engine = world()
        harbour(engine, channel: nil)
        ToolFixture.put(engine, 119, 50, 4)
        // The scan for a ship start only accepts a bare channel tile, but the ship
        // steers by the tile number alone, so this one leads it north.
        ToolFixture.put(engine, 119, 49, 4, flags: ToolFixture.bulldozable)
        let ship = try shipFrom(engine)
        // A ship that enters at the east faces west (frame 7); 7 to 1 goes through 8, and 8 wraps round to 1.
        let seen = [ship.frame] + frames(of: Kind.ship, engine, ticks: 40)
        XCTAssertTrue(seen.contains(8) && seen.contains(1), "it turns to the channel in the north: \(seen)")
    }

    func testAShipSailsOverAPowerLine() throws {
        let engine = world()
        harbour(engine, channel: nil)
        ToolFixture.put(engine, 10, 0, 4)
        ToolFixture.put(engine, 9, 1, 208) // a wire across the water, south west of the ship
        let start = try shipFrom(engine)
        for _ in 0..<7 { engine.tick() }
        let now = try XCTUnwrap(find(Kind.ship, engine))
        XCTAssertLessThan(now.x, start.x, "the ship heads south west, across the wire")
        XCTAssertGreaterThan(now.y, start.y)
    }

    func testAShipInOpenWaterWandersAndRunsAground() throws {
        // Water that is not a channel gives the ship nowhere to steer, so it drifts
        // in a random direction until it meets the land.
        let engine = world()
        harbour(engine, channel: nil)
        ToolFixture.put(engine, 10, 0, 4)
        fill(engine, x: 5...16, y: 0...3, tile: river)
        ToolFixture.put(engine, 10, 0, 4)
        _ = try shipFrom(engine)
        XCTAssertTrue(tick(engine, upTo: 600) { self.find(Kind.ship, engine) == nil }, "the ship ends its voyage")
    }

    func testFogHornsSoundInSanFrancisco() {
        let engine = Engine(seed: 1)
        let recorder = FullRecorder()
        engine.delegate = recorder
        XCTAssertTrue(engine.loadScenario(.sanFrancisco, resourceDirectory: Repo.content))
        // The horn is a roll of the dice each time a ship sounds off, so wait for one.
        XCTAssertTrue(tick(engine, upTo: 8000) { recorder.sounds.contains("FogHornLow") }, "a ship sounds its fog horn")
    }

    // MARK: What a monster tramples

    /// With no river on the map the monster starts at tile (60, 50) and takes its
    /// first step toward the pollution peak. Every tile around there holds
    /// `cell`, so whichever tile the step lands on is the one the monster ruins.
    private func trample(_ cell: UInt16, delegate: FullRecorder? = nil) -> (engine: Engine, ruined: [UInt16]) {
        let engine = world()
        engine.delegate = delegate
        for x in 60...72 { for y in 48...54 { engine.setTile(x: x, y: y, cell: cell) } }
        engine.makeDisaster(.monster)
        engine.tick()
        var after: [UInt16] = []
        for x in 60...72 { for y in 48...54 { after.append(engine.tile(x: x, y: y)) } }
        return (engine, after.filter { $0 != cell })
    }

    func testMonsterTurnsAFlammableTileIntoAnExplosion() {
        let burnable = ToolFixture.burnable
        let (_, ruined) = trample(UInt16(37) | burnable)
        XCTAssertEqual(ruined.count, 1, "one tile is trampled")
        XCTAssertTrue((857...867).contains(Int(ruined[0] & 0x3FF)), "the tile becomes a small explosion")
    }

    func testMonsterWashesAwayWiresAndRailOnWater() {
        for tile in [208, 209, 224, 225, 79, 95] {
            let (_, ruined) = trample(UInt16(tile) | ToolFixture.burnable | ToolFixture.conductive)
            XCTAssertEqual(ruined.map { Int($0 & 0x3FF) }, [2], "tile \(tile) drowns in a river")
        }
    }

    func testMonsterWashesAwayBridges() {
        // A road that cannot burn is a bridge: the monster tears it down to river.
        let (_, ruined) = trample(UInt16(66))
        XCTAssertEqual(ruined.map { Int($0 & 0x3FF) }, [2])
    }

    func testMonsterSetsAZoneAlightAndBlowsItUp() {
        let zone = UInt16(270) | ToolFixture.burnable | ToolFixture.zoneCenter
        let recorder = FullRecorder()
        let (engine, ruined) = trample(zone, delegate: recorder)
        XCTAssertFalse(ruined.isEmpty)
        XCTAssertNotNil(engine.sprites().first { $0.type == Kind.explosion }, "a building blowing up makes an explosion")
        // The explosion plays out in about a dozen ticks and is reported once. When it
        // ends it lights fires around it, but leaves the zones that surround it alone.
        XCTAssertTrue(tick(engine, upTo: 40) { !engine.sprites().contains { $0.type == Kind.explosion } })
        XCTAssertTrue(recorder.messages.contains { $0.index == 32 }, "explosion reported")
        XCTAssertTrue(recorder.sounds.contains("ExplosionHigh"))
    }

    func testMonsterSetsAnAirportAlight() {
        let airport = UInt16(716) | ToolFixture.burnable | ToolFixture.zoneCenter
        let (engine, ruined) = trample(airport)
        XCTAssertFalse(ruined.isEmpty)
        XCTAssertNotNil(engine.sprites().first { $0.type == Kind.explosion })
    }

    /// The pollution scan only runs every few hundred ticks, so wait for it.
    private func letPollutionShow(_ engine: Engine) {
        XCTAssertTrue(tick(engine, upTo: 1500) { (engine.overlay(.pollution).max() ?? 0) > 0 }, "the plant pollutes")
    }

    func testMonsterThatStartsAtThePollutionTurnsHomeAndDisappears() {
        let engine = world()
        XCTAssertEqual(engine.apply(.coalPower, x: 62, y: 51), .ok)
        letPollutionShow(engine)
        engine.makeDisaster(.monster) // starts at tile (60, 50), beside the plant
        XCTAssertNotNil(find(Kind.monster, engine))
        XCTAssertTrue(tick(engine, upTo: 10) { self.find(Kind.monster, engine) == nil },
                      "it has arrived, so it goes home and vanishes")
    }

    func testMonsterWithNoPollutionWalksOffTheMap() {
        let engine = world()
        engine.makeDisaster(.monster) // no pollution: it heads for the top left corner
        XCTAssertTrue(tick(engine, upTo: 1500) { self.find(Kind.monster, engine) == nil },
                      "a monster that walks off the map is gone")
    }

    // MARK: Aircraft

    func testPlanesLeaveAnAirportOnTheEastEdgeHeadingWest() throws {
        let engine = world()
        let recorder = FullRecorder()
        engine.delegate = recorder
        XCTAssertEqual(engine.apply(.coalPower, x: 100, y: 40), .ok)
        for x in 103...108 { XCTAssertEqual(engine.apply(.wire, x: x, y: 40), .ok) }
        XCTAssertEqual(engine.apply(.airport, x: 110, y: 40), .ok)
        XCTAssertTrue(tick(engine, upTo: 1500) { self.find(Kind.airplane, engine) != nil })
        let plane = try XCTUnwrap(find(Kind.airplane, engine))
        XCTAssertEqual(plane.frame, 7, "a plane that starts on the east edge takes off facing west")
        engine.makeDisaster(.airCrash)
        XCTAssertNil(find(Kind.airplane, engine))
        XCTAssertTrue(recorder.messages.contains { $0.index == 24 }, "plane crash reported")
    }

    func testAPlaneAndAHelicopterThatMeetCollide() {
        // One airport sends up a plane and a helicopter that wander the whole map
        // at random. Whether they pass within 30 pixels of each other depends on
        // those random walks, so this relies on the fixed seed: with seed 1 they
        // meet after about 2,000 ticks. The test asserts the outcome (a helicopter
        // and a plane crashing together), not where. Planes only collide with
        // disasters on.
        let engine = world()
        engine.setEnableDisasters(true)
        let recorder = FullRecorder()
        engine.delegate = recorder
        XCTAssertEqual(engine.apply(.coalPower, x: 52, y: 60), .ok)
        for x in 55...56 { XCTAssertEqual(engine.apply(.wire, x: x, y: 60), .ok) }
        XCTAssertEqual(engine.apply(.airport, x: 58, y: 60), .ok)
        XCTAssertTrue(tick(engine, upTo: 6000) { recorder.messages.contains { $0.index == 24 } },
                      "a plane crash is reported")
        let crashes = recorder.messages.map(\.index).filter { $0 == 24 || $0 == 27 }
        XCTAssertEqual(crashes, [27, 24], "the helicopter is struck first, then the plane that hit it")
    }

    // MARK: Sprite slots

    func testASpriteSlotIsReusedAfterTheCityIsReset() throws {
        let engine = world()
        engine.makeDisaster(.tornado)
        XCTAssertNotNil(find(Kind.tornado, engine))
        XCTAssertTrue(engine.loadCity(at: Repo.city("haight"))) // clears every sprite
        XCTAssertNil(find(Kind.tornado, engine))
        engine.makeDisaster(.tornado)
        XCTAssertEqual(find(Kind.tornado, engine)?.frame, 1, "a fresh tornado reuses the old sprite")
        XCTAssertEqual(engine.sprites().filter { $0.type == Kind.tornado }.count, 1)
    }

    func testAskingForATornadoAgainKeepsTheOldOne() throws {
        let engine = world()
        engine.makeDisaster(.tornado)
        let first = try XCTUnwrap(find(Kind.tornado, engine))
        engine.makeDisaster(.tornado)
        let second = try XCTUnwrap(find(Kind.tornado, engine))
        XCTAssertEqual(engine.sprites().filter { $0.type == Kind.tornado }.count, 1)
        XCTAssertEqual(first.x, second.x)
        XCTAssertEqual(first.y, second.y)
    }

    // MARK: Helicopters hunt disasters

    private func bostonWithHelicopter() throws -> (engine: Engine, recorder: FullRecorder) {
        let engine = Engine(seed: 1)
        let recorder = FullRecorder()
        engine.delegate = recorder
        XCTAssertTrue(engine.loadScenario(.boston, resourceDirectory: Repo.content))
        XCTAssertTrue(tick(engine, upTo: 3000) { self.find(Kind.helicopter, engine) != nil }, "a helicopter lifts off")
        return (engine, recorder)
    }

    /// A helicopter wanders for 1500 ticks. Then it flies toward a monster if
    /// there is one, else toward a tornado, else it lands where it started.
    private func waitForHelicopterToSettle(_ engine: Engine) {
        XCTAssertTrue(tick(engine, upTo: 1300) { self.find(Kind.helicopter, engine) == nil } == false,
                      "the helicopter keeps flying while it has fuel")
        for _ in 0..<150 { engine.tick() }
    }

    private func keepDisasterGoing(_ disaster: Disaster, kind: Int, engine: Engine) {
        let gone = tick(engine, upTo: 3000) {
            if self.find(kind, engine) == nil { engine.makeDisaster(disaster) }
            return self.find(Kind.helicopter, engine) == nil
        }
        XCTAssertTrue(gone, "the helicopter is eventually gone")
    }

    func testHelicopterLandsWhereItStarted() throws {
        let (engine, _) = try bostonWithHelicopter()
        waitForHelicopterToSettle(engine)
        XCTAssertTrue(tick(engine, upTo: 2000) { self.find(Kind.helicopter, engine) == nil }, "it lands and is gone")
    }

    func testHelicopterFliesIntoAMonster() throws {
        let (engine, recorder) = try bostonWithHelicopter()
        waitForHelicopterToSettle(engine)
        keepDisasterGoing(.monster, kind: Kind.monster, engine: engine)
        XCTAssertTrue(recorder.messages.contains { $0.index == 27 }, "the monster knocked the helicopter down")
    }

    func testHelicopterFliesIntoATornado() throws {
        let (engine, recorder) = try bostonWithHelicopter()
        waitForHelicopterToSettle(engine)
        keepDisasterGoing(.tornado, kind: Kind.tornado, engine: engine)
        XCTAssertTrue(recorder.messages.contains { $0.index == 27 }, "the tornado knocked the helicopter down")
    }

    // MARK: Tornadoes

    func testATornadoDiesOutEventually() {
        let engine = world()
        var lives = 0
        for _ in 0..<8 {
            engine.makeDisaster(.tornado)
            XCTAssertNotNil(find(Kind.tornado, engine))
            XCTAssertTrue(tick(engine, upTo: 3000) { self.find(Kind.tornado, engine) == nil },
                          "a tornado fades or blows off the map")
            lives += 1
        }
        XCTAssertEqual(lives, 8)
    }

    // MARK: Trains

    /// A bundled city with every rail taken up, so that the test decides where the
    /// only track runs. The city still has the population that trains need.
    private func cityWithoutRails() -> (engine: Engine, recorder: FullRecorder) {
        let engine = Engine(seed: 1)
        let recorder = FullRecorder()
        engine.delegate = recorder
        XCTAssertTrue(engine.loadCity(at: Repo.city("bruce")))
        engine.setEnableDisasters(false)
        for x in 0..<Engine.width {
            for y in 0..<Engine.height {
                let tile = Int(engine.tile(x: x, y: y) & 0x3FF)
                if (224...238).contains(tile) || tile == 221 || tile == 222 { ToolFixture.put(engine, x, y, 0) }
            }
        }
        return (engine, recorder)
    }

    /// Covers the ground around a sprite with track, 13 tiles wide and 7 tall, so a
    /// train starts quickly and wanders over the sprite's patch.
    private func layTrack(_ engine: Engine, at sprite: Sprite) {
        let row = (sprite.y + sprite.yHot) >> 4
        let column = (sprite.x + 48) >> 4
        for x in max(1, column - 6)...min(Engine.width - 2, column + 6) {
            for y in max(1, row - 3)...min(Engine.height - 2, row + 3) {
                ToolFixture.put(engine, x, y, 224, flags: ToolFixture.burnable | ToolFixture.bulldozable)
            }
        }
    }

    func testATrainDisappearsWhenItsTrackIsGone() throws {
        let (engine, _) = cityWithoutRails()
        let row = 40
        for x in 20...60 { ToolFixture.put(engine, x, row, 224, flags: ToolFixture.burnable | ToolFixture.bulldozable) }
        XCTAssertTrue(tick(engine, upTo: 3000) { self.find(Kind.train, engine) != nil }, "a train starts")
        for x in 20...60 { ToolFixture.put(engine, x, row, 0) }
        XCTAssertTrue(tick(engine, upTo: 100) { self.find(Kind.train, engine) == nil },
                      "with no rails left the train stops and then vanishes")
    }

    /// Raises `disaster`, lays track under it, and gives a train 150 ticks to
    /// run into it. A monster may wander off before a train
    /// arrives (that depends on its random walk), so it tries up to 12 times.
    private func crashATrain(into disaster: Disaster, kind: Int) throws {
        let (engine, recorder) = cityWithoutRails()
        for _ in 0..<12 {
            engine.makeDisaster(disaster)
            if let sprite = find(kind, engine) { layTrack(engine, at: sprite) }
            if tick(engine, upTo: 150, until: { recorder.messages.contains { $0.index == 26 } }) { break }
        }
        XCTAssertTrue(recorder.messages.contains { $0.index == 26 }, "train crash reported")
        XCTAssertTrue(recorder.sounds.contains("ExplosionHigh"))
    }

    func testAMonsterWrecksATrain() throws {
        try crashATrain(into: .monster, kind: Kind.monster)
    }

}
