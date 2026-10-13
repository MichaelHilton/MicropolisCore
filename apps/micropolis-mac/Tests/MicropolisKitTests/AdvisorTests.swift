import XCTest
@testable import MicropolisKit

/// The advisor messages of `sendMessages` and the population milestones of
/// `checkGrowth`. Message numbers are the engine's `MESSAGE_*` values.
final class AdvisorTests: XCTestCase {
    private enum Msg {
        static let needRoads = 4, needStadium = 7, needSeaport = 8, needAirport = 9
        static let needFire = 13, needPolice = 14, taxTooHigh = 16
        static let roadFunding = 17, fireFunding = 18, policeFunding = 19
        static let town = 35, city = 36, capital = 37, metropolis = 38, megalopolis = 39
    }

    /// One year of ticks is 768, the advisor cycle is 64 city-time units of
    /// 16 ticks each; this covers every case of the advisor switch.
    private let oneAdvisorRound = 1100

    private func run(res: Int = 0, com: Int = 0, ind: Int = 0, tax: Int? = nil,
                     setUp: (Engine) -> Void = { _ in }) -> [Int] {
        let engine = Engine.blankTown()
        var town = Town(engine)
        town.add(.residential, res)
        town.add(.commercial, com)
        town.add(.industrial, ind)
        if let tax { engine.setTax(tax) }
        setUp(engine)
        let recorder = FullRecorder()
        engine.delegate = recorder
        return engine.messageNumbers(ticks: oneAdvisorRound, recorder: recorder)
    }

    // MARK: sendMessages

    func testManyZonesOnFewRoadsAskForMoreRoads() {
        // 30 zones on one 91-tile road: 2 x 30 zones is not above 91.
        XCTAssertFalse(run(res: 30).contains(Msg.needRoads))
        // 60 zones on the same road.
        XCTAssertTrue(run(res: 60).contains(Msg.needRoads))
    }

    func testABigResidentialAreaDemandsAStadium() {
        XCTAssertTrue(run(res: 40).contains(Msg.needStadium))
        XCTAssertFalse(run(res: 5).contains(Msg.needStadium), "under 500 residents")
    }

    func testAStadiumSilencesTheStadiumDemand() {
        let messages = run(res: 40) { engine in
            XCTAssertEqual(engine.apply(.stadium, x: 100, y: 50), .ok)
        }
        XCTAssertFalse(messages.contains(Msg.needStadium))
    }

    func testHeavyIndustryDemandsASeaport() {
        XCTAssertTrue(run(ind: 40).contains(Msg.needSeaport))
        let withPort = run(ind: 40) { engine in
            XCTAssertEqual(engine.apply(.seaport, x: 100, y: 50), .ok)
        }
        XCTAssertFalse(withPort.contains(Msg.needSeaport))
    }

    func testBigCommerceDemandsAnAirport() {
        XCTAssertTrue(run(com: 40).contains(Msg.needAirport))
    }

    func testACityWithoutStationsDemandsFireAndPolice() {
        // 20 zones is 100 people in the engine's census, over the limit of 60.
        let messages = run(res: 20)
        XCTAssertTrue(messages.contains(Msg.needFire))
        XCTAssertTrue(messages.contains(Msg.needPolice))
        let served = run(res: 20) { engine in
            XCTAssertEqual(engine.apply(.fireStation, x: 100, y: 50), .ok)
            XCTAssertEqual(engine.apply(.policeStation, x: 100, y: 60), .ok)
        }
        XCTAssertFalse(served.contains(Msg.needFire))
        XCTAssertFalse(served.contains(Msg.needPolice))
    }

    func testTaxAboveTwelveUpsetsCitizens() {
        XCTAssertTrue(run(res: 10, tax: 13).contains(Msg.taxTooHigh))
        XCTAssertFalse(run(res: 10, tax: 12).contains(Msg.taxTooHigh))
    }

    /// The year-end budget with auto-budget off takes the department
    /// percentages the player chose. The engine only turns the money spent
    /// into road, fire and police effects when a percentage is set, so the
    /// budget window sets them again once the year is over, as this does.
    func testUnderfundedDepartmentsComplainTheFollowingYear() {
        let engine = Engine(seed: 1)
        XCTAssertTrue(engine.loadCity(at: Repo.city("haight")))
        engine.setSpeed(3)
        engine.setAutoBudget(false)
        for set in [engine.setRoadPercent, engine.setFirePercent, engine.setPolicePercent] { set(0.2) }
        let recorder = FullRecorder()
        engine.delegate = recorder
        let year = engine.year
        while engine.year == year { engine.tick() }
        for _ in 0..<40 { engine.tick() }
        XCTAssertEqual(recorder.budgetRequests, 1)
        for set in [engine.setRoadPercent, engine.setFirePercent, engine.setPolicePercent] { set(0.2) }
        let messages = engine.messageNumbers(ticks: oneAdvisorRound, recorder: recorder)
        XCTAssertTrue(messages.contains(Msg.roadFunding), "\(messages)")
        XCTAssertTrue(messages.contains(Msg.fireFunding), "\(messages)")
        XCTAssertTrue(messages.contains(Msg.policeFunding), "\(messages)")
    }

    func testFullyFundedDepartmentsDoNotComplain() {
        let engine = Engine(seed: 1)
        XCTAssertTrue(engine.loadCity(at: Repo.city("haight")))
        engine.setSpeed(3)
        let recorder = FullRecorder()
        engine.delegate = recorder
        let messages = engine.messageNumbers(ticks: 2000, recorder: recorder)
        XCTAssertFalse(messages.contains(Msg.roadFunding))
        XCTAssertFalse(messages.contains(Msg.fireFunding))
        XCTAssertFalse(messages.contains(Msg.policeFunding))
    }

    // MARK: checkGrowth

    /// Zone counts that put the city safely inside each class. A grown
    /// residential zone is 800 people, and a few percent of them leave in
    /// the first seconds, so each count has room on both sides.
    private enum Zones {
        static let town = 6          // 4,800: over 2,000
        static let city = 25         // 20,000: over 10,000
        static let capital = 90      // 72,000: over 50,000
        static let metropolis = 190  // 152,000: over 100,000
        static let megalopolis = 800 // 640,000: over 500,000
    }

    /// Adds zones until the town has `total`, lets two growth checks pass
    /// and returns the new messages.
    private func grow(_ town: inout Town, to total: Int, engine: Engine, recorder: FullRecorder) -> [Int] {
        town.add(.residential, total - town.placed)
        return engine.messageNumbers(ticks: 70, recorder: recorder)
    }

    func testEachNewCityClassIsAnnounced() {
        let engine = Engine.blankTown()
        var town = Town(engine)
        town.add(.residential, 1)
        let recorder = FullRecorder()
        engine.delegate = recorder
        // The first check only records the starting population.
        _ = engine.messageNumbers(ticks: 70, recorder: recorder)
        XCTAssertEqual(engine.cityClass, 0)

        XCTAssertTrue(grow(&town, to: Zones.town, engine: engine, recorder: recorder).contains(Msg.town))
        XCTAssertTrue(grow(&town, to: Zones.city, engine: engine, recorder: recorder).contains(Msg.city))
        XCTAssertTrue(grow(&town, to: Zones.capital, engine: engine, recorder: recorder).contains(Msg.capital))
        XCTAssertTrue(grow(&town, to: Zones.metropolis, engine: engine, recorder: recorder).contains(Msg.metropolis))
        XCTAssertTrue(grow(&town, to: Zones.megalopolis, engine: engine, recorder: recorder).contains(Msg.megalopolis))
        let announced = recorder.messages.map(\.index).filter { (Msg.town...Msg.megalopolis).contains($0) }
        XCTAssertEqual(announced, [Msg.town, Msg.city, Msg.capital, Msg.metropolis, Msg.megalopolis])
    }

    func testAShrinkingCityIsToldItsNewClassButNotWhenItBecomesAVillage() {
        let engine = Engine.blankTown()
        var town = Town(engine)
        town.add(.residential, Zones.capital)
        let recorder = FullRecorder()
        engine.delegate = recorder
        _ = engine.messageNumbers(ticks: 70, recorder: recorder)

        // Bulldoze every zone: the city falls from capital through to village.
        for x in 0..<Engine.width { for y in 0..<Engine.height { engine.setTile(x: x, y: y, cell: 0) } }
        let messages = engine.messageNumbers(ticks: 70, recorder: recorder)
        XCTAssertFalse(messages.contains { (Msg.town...Msg.megalopolis).contains($0) },
                       "a village is never announced: \(messages)")
    }
}
