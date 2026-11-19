import Foundation
import Testing
import MicropolisKit
@testable import MicropolisMac

@Suite(.serialized)
@MainActor
struct ButtonInventoryFixtureTests {
    private func configured(_ fixture: String) -> (GameModel, URL) {
        let path = FileManager.default.temporaryDirectory
            .appendingPathComponent("micropolis-fixture-\(UUID().uuidString).json")
        let model = GameModel(city: nil, sound: RecordingSound(), seed: 1, runsTimer: false)
        model.soundOn = false
        ButtonInventorySupport.configure(model, environment: [
            "MICROPOLIS_UI_TESTING": "1",
            "MICROPOLIS_INVENTORY_STATE": path.path,
            "MICROPOLIS_INVENTORY_FIXTURE": fixture
        ])
        return (model, path)
    }

    private func cleanup(_ path: URL) {
        ButtonInventorySupport.stopObserving()
        try? FileManager.default.removeItem(at: path)
    }

    @Test
    func normalLaunchCannotEnableFixturesWithoutBothExplicitFlags() {
        let model = GameModel(city: nil, sound: RecordingSound(), seed: 1, runsTimer: false)
        let before = model.engine.mapSnapshot()
        let funds = model.engine.funds
        let path = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        for environment in [
            ["MICROPOLIS_INVENTORY_STATE": path.path, "MICROPOLIS_INVENTORY_FIXTURE": "tools"],
            ["MICROPOLIS_UI_TESTING": "1", "MICROPOLIS_INVENTORY_FIXTURE": "tools"]
        ] {
            ButtonInventorySupport.configure(model, environment: environment)
            #expect(model.engine.mapSnapshot() == before)
            #expect(model.engine.funds == funds)
            #expect(!FileManager.default.fileExists(atPath: path.path))
        }
    }

    @Test
    func emptyFixtureIsDeterministicAndUntitled() {
        let (model, path) = configured("empty")
        defer { cleanup(path) }
        #expect(model.engine.funds == 100_000)
        #expect(model.currentFileURL == nil)
        #expect(model.engine.mapSnapshot().allSatisfy { $0 == 0 })
    }

    @Test
    func toolFixtureHasRoadResidentialAndWaterFootprints() {
        let (model, path) = configured("tools")
        defer { cleanup(path) }
        #expect(model.engine.tile(x: 10, y: 10) != 0)
        #expect(model.engine.tile(x: 16, y: 16) != 0)
        #expect(model.engine.tile(x: 29, y: 0) == 0)
        #expect(model.engine.tile(x: 30, y: 0) == 2)
        #expect(model.engine.funds == 100_000)
    }

    @Test
    func terrainFixtureHasExpectedBoundaryAndEditorMode() {
        let (model, path) = configured("terrain")
        defer { cleanup(path) }
        #expect(model.editMode == .terrain)
        #expect(model.engine.tile(x: 10, y: 10) == 0)
        #expect(model.engine.tile(x: 7, y: 10) == 2)
        #expect(model.engine.tile(x: 8, y: 8) == 0)
        #expect(model.engine.tile(x: 12, y: 12) == 0)
        #expect(model.engine.tile(x: 13, y: 12) == 2)
    }

    @Test
    func airCrashFixtureHasPlaneWithoutExplosion() {
        let (model, path) = configured("disaster.airCrash")
        defer { cleanup(path) }
        let sprites = model.engine.sprites().filter { $0.frame > 0 }
        #expect(sprites.contains { $0.type == 3 })
        #expect(!sprites.contains { $0.type == 7 })
    }

    @Test
    func soundOptionControlsEngineDeliveryAfterLoadingAMutedCity() {
        let saved = Engine(seed: 1)
        #expect(saved.loadCity(at: Assets.city("deadwood")))
        #expect(!saved.soundEnabled, "This fixture carries a disabled sound flag")
        for enabled in [false, true] {
            let (model, path) = configured("disaster.airCrash")
            defer { cleanup(path) }
            let sink = model.sound as! RecordingSound
            model.soundOn = enabled
            #expect(model.engine.soundEnabled == enabled)
            #expect(sink.soundEnabled == enabled)
            model.engine.makeDisaster(.airCrash)
            #expect(sink.played.contains("ExplosionHigh") == enabled)
            model.loadCity(from: Assets.city("deadwood"))
            #expect(model.engine.soundEnabled == enabled, "A city load must retain the current UI sound option")
        }
    }

    @Test(arguments: [Disaster.fire, .flood])
    func fireAndFloodEachCreateTheirExpectedTiles(_ disaster: Disaster) {
        let fixture = disaster == .fire ? "disaster.fire" : "disaster.flood"
        let (model, path) = configured(fixture)
        defer { cleanup(path) }
        model.engine.makeDisaster(disaster)
        let ids = model.engine.mapSnapshot().map { Int($0 & 0x3ff) }
        if disaster == .fire {
            #expect(ids.filter { (56...63).contains($0) }.count > 0)
        } else {
            #expect(ids.filter { (48...51).contains($0) }.count > 0)
        }
    }

    @Test
    func meltdownFixtureHasPlantAndOneDisasterRadiationFootprint() {
        let (model, path) = configured("disaster.meltdown")
        defer { cleanup(path) }
        #expect(model.engine.tile(x: 15, y: 15) != 0)
        model.engine.makeDisaster(.meltdown)
        let radiation = model.engine.mapSnapshot().filter { Int($0 & 0x3ff) == 52 }.count
        #expect(radiation > 0)
    }

    @Test
    func budgetPausedFixtureRetainsSpeedAndPause() {
        let (model, path) = configured("budgetPaused")
        defer { cleanup(path) }
        #expect(model.speed == 2)
        #expect(model.paused)
        #expect(model.engine.isPaused)
    }

    @Test
    func budgetYearEndFixtureAdvancesAcrossYearBoundaryWithinBoundedFrames() {
        let (model, path) = configured("budgetYearEnd")
        defer { cleanup(path) }
        #expect(model.engine.funds == 100_000)
        #expect(model.engine.year == 1900)
        #expect(model.engine.month == 11)
        let startingYear = model.engine.year
        model.setSpeed(3)
        var frames = 0
        while model.engine.year == startingYear && frames < 2_000 {
            model.frame()
            frames += 1
        }
        model.setSpeed(0)
        #expect(frames < 2_000)
        #expect(model.engine.year > startingYear)
    }
}
