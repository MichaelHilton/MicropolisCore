import Foundation
import MicropolisKit

@MainActor
@Observable
final class GameModel: EngineDelegate {
    let engine = Engine()
    let tileAtlas: TileAtlas
    var renderer: MapRenderer!  // Initialized in init after tileAtlas
    let spriteRenderer = SpriteRenderer()

    var year: Int = 0
    var month: Int = 0
    var funds: Int = 0
    var population: Int = 0
    var paused: Bool = false
    var speed: Int = 0
    var lastMessage: String?
    var mapVersion: Int = 0
    var selectedTool: Tool = .query
    var toolMessage: String?
    var currentMessage: String?
    var importantMessageGoTo: (x: Int, y: Int)?
    var autoGoto: Bool = true
    var showBudgetSheet: Bool = false
    var showGraphsWindow: Bool = false
    var showEvaluationWindow: Bool = false
    var cityName: String = "Unnamed City"
    var currentFileURL: URL?
    var hasUnsavedChanges: Bool = false
    var demandResidential: Float = 0
    var demandCommercial: Float = 0
    var demandIndustrial: Float = 0
    var cityScore: Int = 0
    var cityClass: Int = 0
    var zoneStatus: ZoneStatusInfo?

    nonisolated(unsafe) private var timer: Timer?
    private var messageTimer: Timer?

    init() {
        do {
            self.tileAtlas = try TileAtlas(atlasURL: Assets.tileAtlas)
        } catch {
            fatalError("Failed to load tile atlas: \(error)")
        }
        self.renderer = MapRenderer(tileAtlas: tileAtlas)

        engine.delegate = self

        let cityPath = Assets.city("haight")
        _ = engine.loadCity(at: cityPath)

        year = engine.year
        month = engine.month
        funds = engine.funds
        population = engine.population
        paused = engine.isPaused

        startTimer()
    }

    private func startTimer() {
        let intervals: [TimeInterval] = [0, 0.1, 0.05, 1.0 / 30.0, 1.0 / 30.0]
        let interval = intervals[min(speed, 3)]

        if speed == 0 {
            pauseSimulation()
        } else {
            resumeSimulation()
        }

        timer?.invalidate()
        if speed > 0 {
            timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    self?.frame()
                }
            }
            if let timer = timer {
                RunLoop.main.add(timer, forMode: .common)
            }
        }
    }

    func setSpeed(_ newSpeed: Int) {
        speed = newSpeed
        startTimer()
    }

    func pauseSimulation() {
        engine.pause()
        paused = true
    }

    func resumeSimulation() {
        engine.resume()
        paused = false
    }

    internal func frame() {
        let passes = [1, 1, 1, 4][min(speed - 1, 3)]
        for _ in 0..<passes {
            engine.tick()
        }
        renderer.update(cells: engine.mapSnapshot())
        mapVersion += 1
        population = engine.population
    }

    func newCity(seed: Int) {
        engine.generateMap(seed: seed)
        currentFileURL = nil
        hasUnsavedChanges = false
        cityName = "Unnamed City"
    }

    func loadCity(from url: URL) {
        if engine.loadCity(at: url) {
            currentFileURL = url
            hasUnsavedChanges = false
            cityName = url.deletingPathExtension().lastPathComponent
        }
    }

    func saveCity(to url: URL) {
        if engine.saveCity(at: url) {
            currentFileURL = url
            hasUnsavedChanges = false
        }
    }

    deinit {
        timer?.invalidate()
    }

    func engineDidLoadCity(filename: String) {}
    func engineDidGenerateMap(seed: Int) {}
    func engineDidTool(name: String, x: Int, y: Int) {}
    func engineMakeSound(channel: String, sound: String, x: Int, y: Int) {
        SoundManager.shared.play(soundName: sound)
    }
    func engineSendMessage(index: Int, x: Int, y: Int, picture: Bool, important: Bool) {
        currentMessage = Messages.text(for: index)
        if important && x >= 0 && y >= 0 {
            importantMessageGoTo = (x, y)
            if autoGoto {
                // Will be handled by the view to scroll the map
            }
        }
        messageTimer?.invalidate()
        messageTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.currentMessage = nil
                self?.importantMessageGoTo = nil
            }
        }
    }
    func engineAutoGoto(x: Int, y: Int, message: String) {
        if autoGoto && x >= 0 && y >= 0 {
            // Will be handled by the view to scroll the map
            importantMessageGoTo = (x, y)
        }
    }
    func engineShowBudgetAndWait() {
        showBudgetSheet = true
        pauseSimulation()
    }
    func engineShowZoneStatus(category: Int, density: Int, landValue: Int, crime: Int, pollution: Int, growth: Int, x: Int, y: Int) {
        self.zoneStatus = ZoneStatusInfo(category: category, density: density, landValue: landValue, crime: crime, pollution: pollution, growth: growth, x: x, y: y)
    }
    func engineUpdateDate(year: Int, month: Int) {
        self.year = year
        self.month = month
    }
    func engineUpdateFunds(funds: Int) {
        self.funds = funds
    }
    func engineUpdateDemand(residential: Float, commercial: Float, industrial: Float) {
        self.demandResidential = residential
        self.demandCommercial = commercial
        self.demandIndustrial = industrial
    }
    func engineUpdateCityName(name: String) {
        self.cityName = name
    }
    func engineUpdateEvaluation() {
        self.cityClass = engine.cityClass
    }
    func engineUpdateHistory() {}
    func engineUpdateBudget() {}
    func engineUpdatePaused(paused: Bool) {
        self.paused = paused
    }
    func engineUpdateSpeed(speed: Int) {
        self.speed = speed
    }
    func engineUpdateTaxRate(tax: Int) {}
    func engineStartEarthquake(strength: Int) {}
    func engineDidWinGame() {}
    func engineDidLoseGame() {}
}
