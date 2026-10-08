import Foundation
import MicropolisEngine

public enum Tool: Int32, CaseIterable {
    case residential = 0, commercial, industrial, fireStation, policeStation, query, wire, bulldozer, railroad, road, stadium, park, seaport, coalPower, nuclearPower, airport, network, water, land, forest
}

public enum ToolResult: Int32 {
    case noMoney = -2, needBulldoze = -1, failed = 0, ok = 1
}

public struct Sprite {
    public let type: Int
    public let frame: Int
    public let x: Int
    public let y: Int
    public let xHot: Int
    public let yHot: Int
}

public enum HistoryKind: Int, CaseIterable {
    case residential = 0, commercial, industrial, money, crime, pollution
}

/// Data layers shown by the map window, one value per tile.
public enum OverlayKind: Int32, CaseIterable {
    case population = 0, growth, traffic, pollution, crime, landValue, police, fire, power
}

public enum Disaster: Int32, CaseIterable {
    case fire = 0, flood, earthquake, monster, tornado, meltdown, airCrash
}

public enum GameLevel: Int, CaseIterable {
    case easy = 0, medium, hard
}

/// The 8 built-in scenarios, numbered as the engine's Scenario enum.
public enum Scenario: Int32, CaseIterable {
    case dullsville = 1, sanFrancisco, hamburg, bern, tokyo, detroit, boston, rio
}

/// What the evaluation window shows.
public struct Evaluation: Equatable {
    public let yes: Int
    /// Worst problems first: engine problem id and percent of voters.
    public let problems: [(id: Int, votes: Int)]
    public let population: Int
    public let populationDelta: Int
    public let assessedValue: Int
    public let cityClass: Int
    public let gameLevel: Int
    public let score: Int
    public let scoreDelta: Int

    public static func == (a: Evaluation, b: Evaluation) -> Bool {
        a.yes == b.yes && a.problems.map(\.id) == b.problems.map(\.id)
            && a.problems.map(\.votes) == b.problems.map(\.votes)
            && a.population == b.population && a.populationDelta == b.populationDelta
            && a.assessedValue == b.assessedValue && a.cityClass == b.cityClass
            && a.gameLevel == b.gameLevel && a.score == b.score && a.scoreDelta == b.scoreDelta
    }
}

/// This year's tax take and what each department asked for.
public struct BudgetFigures: Equatable {
    public let taxesCollected: Int
    public let roadRequested: Int
    public let policeRequested: Int
    public let fireRequested: Int

    public init(taxesCollected: Int, roadRequested: Int, policeRequested: Int, fireRequested: Int) {
        self.taxesCollected = taxesCollected
        self.roadRequested = roadRequested
        self.policeRequested = policeRequested
        self.fireRequested = fireRequested
    }
}

public final class Engine {
    private let handle: OpaquePointer
    public weak var delegate: EngineDelegate?

    public static let width = 120
    public static let height = 100

    public init() {
        handle = mp_create()!
        setupCallbacks()
    }

    private func setupCallbacks() {
        var cb = MPCallbacks()
        cb.context = Unmanaged.passUnretained(self).toOpaque()

        cb.didLoadCity = { ctx, filename in
            let engine = Unmanaged<Engine>.fromOpaque(ctx!).takeUnretainedValue()
            engine.delegate?.engineDidLoadCity(filename: String(cString: filename!))
        }

        cb.didGenerateMap = { ctx, seed in
            let engine = Unmanaged<Engine>.fromOpaque(ctx!).takeUnretainedValue()
            engine.delegate?.engineDidGenerateMap(seed: Int(seed))
        }

        cb.didTool = { ctx, name, x, y in
            let engine = Unmanaged<Engine>.fromOpaque(ctx!).takeUnretainedValue()
            engine.delegate?.engineDidTool(name: String(cString: name!), x: Int(x), y: Int(y))
        }

        cb.makeSound = { ctx, channel, sound, x, y in
            let engine = Unmanaged<Engine>.fromOpaque(ctx!).takeUnretainedValue()
            engine.delegate?.engineMakeSound(channel: String(cString: channel!), sound: String(cString: sound!), x: Int(x), y: Int(y))
        }

        cb.sendMessage = { ctx, messageIndex, x, y, picture, important in
            let engine = Unmanaged<Engine>.fromOpaque(ctx!).takeUnretainedValue()
            engine.delegate?.engineSendMessage(index: Int(messageIndex), x: Int(x), y: Int(y), picture: picture != 0, important: important != 0)
        }

        cb.autoGoto = { ctx, x, y, message in
            let engine = Unmanaged<Engine>.fromOpaque(ctx!).takeUnretainedValue()
            engine.delegate?.engineAutoGoto(x: Int(x), y: Int(y), message: String(cString: message!))
        }

        cb.showBudgetAndWait = { ctx in
            let engine = Unmanaged<Engine>.fromOpaque(ctx!).takeUnretainedValue()
            engine.delegate?.engineShowBudgetAndWait()
        }

        cb.showZoneStatus = { ctx, tileCategory, density, landValue, crime, pollution, growth, x, y in
            let engine = Unmanaged<Engine>.fromOpaque(ctx!).takeUnretainedValue()
            engine.delegate?.engineShowZoneStatus(category: Int(tileCategory), density: Int(density), landValue: Int(landValue), crime: Int(crime), pollution: Int(pollution), growth: Int(growth), x: Int(x), y: Int(y))
        }

        cb.updateDate = { ctx, year, month in
            let engine = Unmanaged<Engine>.fromOpaque(ctx!).takeUnretainedValue()
            engine.delegate?.engineUpdateDate(year: Int(year), month: Int(month))
        }

        cb.updateFunds = { ctx, funds in
            let engine = Unmanaged<Engine>.fromOpaque(ctx!).takeUnretainedValue()
            engine.delegate?.engineUpdateFunds(funds: Int(funds))
        }

        cb.updateDemand = { ctx, r, c, i in
            let engine = Unmanaged<Engine>.fromOpaque(ctx!).takeUnretainedValue()
            engine.delegate?.engineUpdateDemand(residential: r, commercial: c, industrial: i)
        }

        cb.updateCityName = { ctx, name in
            let engine = Unmanaged<Engine>.fromOpaque(ctx!).takeUnretainedValue()
            engine.delegate?.engineUpdateCityName(name: String(cString: name!))
        }

        cb.updateEvaluation = { ctx in
            let engine = Unmanaged<Engine>.fromOpaque(ctx!).takeUnretainedValue()
            engine.delegate?.engineUpdateEvaluation()
        }

        cb.updateHistory = { ctx in
            let engine = Unmanaged<Engine>.fromOpaque(ctx!).takeUnretainedValue()
            engine.delegate?.engineUpdateHistory()
        }

        cb.updateBudget = { ctx in
            let engine = Unmanaged<Engine>.fromOpaque(ctx!).takeUnretainedValue()
            engine.delegate?.engineUpdateBudget()
        }

        cb.updatePaused = { ctx, paused in
            let engine = Unmanaged<Engine>.fromOpaque(ctx!).takeUnretainedValue()
            engine.delegate?.engineUpdatePaused(paused: paused != 0)
        }

        cb.updateSpeed = { ctx, speed in
            let engine = Unmanaged<Engine>.fromOpaque(ctx!).takeUnretainedValue()
            engine.delegate?.engineUpdateSpeed(speed: Int(speed))
        }

        cb.updateTaxRate = { ctx, tax in
            let engine = Unmanaged<Engine>.fromOpaque(ctx!).takeUnretainedValue()
            engine.delegate?.engineUpdateTaxRate(tax: Int(tax))
        }

        cb.startEarthquake = { ctx, strength in
            let engine = Unmanaged<Engine>.fromOpaque(ctx!).takeUnretainedValue()
            engine.delegate?.engineStartEarthquake(strength: Int(strength))
        }

        cb.didWinGame = { ctx in
            let engine = Unmanaged<Engine>.fromOpaque(ctx!).takeUnretainedValue()
            engine.delegate?.engineDidWinGame()
        }

        cb.didLoseGame = { ctx in
            let engine = Unmanaged<Engine>.fromOpaque(ctx!).takeUnretainedValue()
            engine.delegate?.engineDidLoseGame()
        }

        mp_set_callbacks(handle, &cb)
    }

    deinit {
        mp_destroy(handle)
    }

    @discardableResult
    public func loadCity(at url: URL) -> Bool {
        mp_load_city(handle, url.path) != 0
    }

    public func tick() {
        mp_tick(handle)
    }

    public var funds: Int {
        Int(mp_total_funds(handle))
    }

    public var year: Int {
        Int(mp_city_year(handle))
    }

    public var month: Int {
        Int(mp_city_month(handle))
    }

    public var population: Int {
        Int(mp_city_pop(handle))
    }

    public var score: Int {
        Int(mp_city_score(handle))
    }

    public var cityClass: Int {
        Int(mp_city_class(handle))
    }

    public var tax: Int {
        Int(mp_city_tax(handle))
    }

    public func setTax(_ tax: Int) {
        mp_set_city_tax(handle, Int32(tax))
    }

    public func tile(x: Int, y: Int) -> UInt16 {
        mp_map(handle)[x * Engine.height + y]
    }

    public func mapSnapshot() -> [UInt16] {
        let ptr = mp_map(handle)
        let count = Engine.width * Engine.height
        return Array(UnsafeBufferPointer(start: ptr, count: count))
    }

    public func getDemands() -> (residential: Float, commercial: Float, industrial: Float) {
        var r: Float = 0, c: Float = 0, i: Float = 0
        mp_get_demands(handle, &r, &c, &i)
        return (r, c, i)
    }

    public var roadPercent: Float {
        mp_road_percent(handle)
    }

    public var policePercent: Float {
        mp_police_percent(handle)
    }

    public var firePercent: Float {
        mp_fire_percent(handle)
    }

    public func setRoadPercent(_ p: Float) {
        mp_set_road_percent(handle, p)
    }

    public func setPolicePercent(_ p: Float) {
        mp_set_police_percent(handle, p)
    }

    public func setFirePercent(_ p: Float) {
        mp_set_fire_percent(handle, p)
    }

    public func setFunds(_ funds: Int) {
        mp_set_funds(handle, Int(funds))
    }

    public func setPasses(_ passes: Int) {
        mp_set_passes(handle, Int32(passes))
    }

    public func setSpeed(_ speed: Int) {
        mp_set_speed(handle, Int32(speed))
    }

    public func pause() {
        mp_pause(handle)
    }

    public func resume() {
        mp_resume(handle)
    }

    public var isPaused: Bool {
        mp_is_paused(handle) != 0
    }

    public func setAutoBudget(_ enable: Bool) {
        mp_set_auto_budget(handle, enable ? 1 : 0)
    }

    public func setAutoBulldoze(_ enable: Bool) {
        mp_set_auto_bulldoze(handle, enable ? 1 : 0)
    }

    public func setEnableDisasters(_ enable: Bool) {
        mp_set_enable_disasters(handle, enable ? 1 : 0)
    }

    public func generateMap(seed: Int) {
        mp_generate_map(handle, Int32(seed))
    }

    public func apply(_ tool: Tool, x: Int, y: Int) -> ToolResult {
        let result = mp_do_tool(handle, Int32(tool.rawValue), Int32(x), Int32(y))
        return ToolResult(rawValue: result) ?? .failed
    }

    public func saveCity(at url: URL) -> Bool {
        mp_save_city(handle, url.path) != 0
    }

    public func makeDisaster(_ disaster: Disaster) {
        mp_make_disaster(handle, disaster.rawValue)
    }

    public func sprites() -> [Sprite] {
        var buffer = [MPSprite](repeating: MPSprite(type: 0, frame: 0, x: 0, y: 0, xHot: 0, yHot: 0), count: 64)
        let count = Int(mp_get_sprites(handle, &buffer, 64))
        return buffer.prefix(count).map { Sprite(type: Int($0.type), frame: Int($0.frame), x: Int($0.x), y: Int($0.y), xHot: Int($0.xHot), yHot: Int($0.yHot)) }
    }

    public func history(_ kind: HistoryKind) -> [Int] {
        var buffer = [Int16](repeating: 0, count: 480)
        mp_get_history(handle, Int32(kind.rawValue), &buffer)
        return buffer.map { Int($0) }
    }

    /// One value per tile, column-major (index `x * height + y`) like the map.
    public func overlay(_ kind: OverlayKind) -> [Int16] {
        var buffer = [Int16](repeating: 0, count: Engine.width * Engine.height)
        mp_get_overlay(handle, kind.rawValue, &buffer)
        return buffer
    }

    public func evaluation() -> Evaluation {
        var e = MPEvaluation()
        mp_get_evaluation(handle, &e)
        let ids = [e.problems.0, e.problems.1, e.problems.2, e.problems.3]
        let votes = [e.problemVotes.0, e.problemVotes.1, e.problemVotes.2, e.problemVotes.3]
        let problems = zip(ids, votes).filter { $0.0 >= 0 }.map { (id: Int($0.0), votes: Int($0.1)) }
        return Evaluation(yes: Int(e.yes), problems: problems, population: e.population,
                          populationDelta: e.populationDelta, assessedValue: e.assessedValue,
                          cityClass: Int(e.cityClass), gameLevel: Int(e.gameLevel),
                          score: Int(e.score), scoreDelta: Int(e.scoreDelta))
    }

    public func budgetFigures() -> BudgetFigures {
        var b = MPBudget()
        mp_get_budget(handle, &b)
        return BudgetFigures(taxesCollected: b.taxFund, roadRequested: b.roadFund,
                             policeRequested: b.policeFund, fireRequested: b.fireFund)
    }

    public var gameLevel: GameLevel {
        GameLevel(rawValue: Int(mp_game_level(handle))) ?? .easy
    }

    /// Sets the level and its starting funds ($20,000, $10,000 or $5,000).
    public func setGameLevel(_ level: GameLevel) {
        mp_set_game_level(handle, Int32(level.rawValue))
    }

    public func setCityName(_ name: String) {
        mp_set_city_name(handle, name)
    }

    /// `resourceDirectory` must contain `cities/scenario_*.cty`.
    @discardableResult
    public func loadScenario(_ scenario: Scenario, resourceDirectory: URL) -> Bool {
        mp_load_scenario(handle, scenario.rawValue, resourceDirectory.path) != 0
    }

    public func setTile(x: Int, y: Int, cell: UInt16) {
        mp_set_tile(handle, Int32(x), Int32(y), cell)
    }

    public func smoothTerrain() {
        mp_smooth_terrain(handle)
    }

    public func setAnimation(animateAll: Bool, frequent: Bool) {
        mp_set_animation(handle, animateAll ? 1 : 0, frequent ? 1 : 0)
    }
}
