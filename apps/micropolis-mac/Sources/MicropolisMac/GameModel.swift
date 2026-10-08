import AppKit
import MicropolisKit

/// Which palette the edit window shows: city tools, or the DOS terrain editor.
enum EditMode {
    case city, terrain
}

/// A request for the edit window to scroll so a tile is centered. `id`
/// changes on every request so the view can tell new ones from old ones.
struct ScrollRequest: Equatable {
    let x: Int
    let y: Int
    let id: Int
}

enum GameOutcome: Equatable {
    case won, lost
}

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
    var showBudgetSheet: Bool = false
    var showNewCitySheet: Bool = false
    var cityName: String = "Unnamed City"
    var currentFileURL: URL?
    var hasUnsavedChanges: Bool = false
    var demandResidential: Float = 0
    var demandCommercial: Float = 0
    var demandIndustrial: Float = 0
    var cityScore: Int = 0
    var cityClass: Int = 0
    var zoneStatus: ZoneStatusInfo?
    var evaluation: Evaluation
    var historyVersion: Int = 0
    var outcome: GameOutcome?

    // OPTIONS menu. Each one is pushed to the engine (or sound manager) when set.
    var autoBulldoze: Bool = true { didSet { engine.setAutoBulldoze(autoBulldoze) } }
    var autoBudget: Bool = false { didSet { engine.setAutoBudget(autoBudget) } }
    var autoGoto: Bool = true
    var soundOn: Bool = true { didSet { SoundManager.shared.soundEnabled = soundOn } }
    var animateAll: Bool = true { didSet { pushAnimation() } }
    var frequentAnimation: Bool = true { didSet { pushAnimation() } }
    var disastersEnabled: Bool = true { didSet { engine.setEnableDisasters(disastersEnabled) } }

    // Map window and edit window navigation.
    var mapOverlay: MapOverlay = .cityForm
    /// The part of the map the edit window shows, in tiles.
    var visibleTiles: CGRect = .zero
    private(set) var scrollRequest: ScrollRequest?

    // Terrain editor.
    var editMode: EditMode = .city
    var terrainTool: TerrainTool = .dirt
    var terrainFill: Bool = false
    private(set) var terrainUndo: [UInt16]?

    nonisolated(unsafe) private var timer: Timer?
    private var messageTimer: Timer?

    init() {
        do {
            self.tileAtlas = try TileAtlas(atlasURL: Assets.tileAtlas)
        } catch {
            fatalError("Failed to load tile atlas: \(error)")
        }
        self.evaluation = engine.evaluation()
        self.renderer = MapRenderer(tileAtlas: tileAtlas)

        engine.delegate = self

        let cityPath = Assets.city("haight")
        _ = engine.loadCity(at: cityPath)
        engine.setAutoBulldoze(autoBulldoze)
        engine.setAutoBudget(autoBudget)
        engine.setEnableDisasters(disastersEnabled)

        refreshCityState()
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
        let passes = [1, 1, 1, 4][min(max(speed, 1) - 1, 3)]
        for _ in 0..<passes {
            engine.tick()
        }
        renderer.update(cells: engine.mapSnapshot())
        mapVersion += 1
        population = engine.population
    }

    private func pushAnimation() {
        engine.setAnimation(animateAll: animateAll, frequent: frequentAnimation)
    }

    /// Re-reads everything the windows show after the city is replaced.
    private func refreshCityState() {
        year = engine.year
        month = engine.month
        funds = engine.funds
        population = engine.population
        paused = engine.isPaused
        cityClass = engine.cityClass
        cityScore = engine.score
        evaluation = engine.evaluation()
        historyVersion += 1
        terrainUndo = nil
        outcome = nil
        mapVersion += 1
    }

    // MARK: - SYSTEM menu

    /// DOS "Start New City": a fresh map, the chosen name, and the starting
    /// funds for the chosen level.
    func newCity(name: String, level: GameLevel, seed: Int = Int.random(in: 1...9999)) {
        engine.generateMap(seed: seed)
        engine.setGameLevel(level)
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        cityName = trimmed.isEmpty ? "Unnamed City" : trimmed
        engine.setCityName(cityName)
        currentFileURL = nil
        hasUnsavedChanges = false
        refreshCityState()
    }

    func newCity(seed: Int) {
        newCity(name: "Unnamed City", level: .easy, seed: seed)
    }

    func loadCity(from url: URL) {
        if engine.loadCity(at: url) {
            currentFileURL = url
            hasUnsavedChanges = false
            cityName = url.deletingPathExtension().lastPathComponent
            refreshCityState()
        }
    }

    func loadScenario(_ scenario: Scenario) {
        if engine.loadScenario(scenario, resourceDirectory: Assets.root) {
            currentFileURL = nil
            hasUnsavedChanges = false
            refreshCityState()
        }
    }

    func saveCity(to url: URL) {
        if engine.saveCity(at: url) {
            currentFileURL = url
            hasUnsavedChanges = false
        }
    }

    func showOpenPanel() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.init(filenameExtension: "cty")!]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false

        panel.begin { response in
            if response == .OK, let url = panel.url {
                self.loadCity(from: url)
            }
        }
    }

    func showSavePanel() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.init(filenameExtension: "cty")!]
        panel.nameFieldStringValue = cityName + ".cty"

        panel.begin { response in
            if response == .OK, let url = panel.url {
                self.saveCity(to: url)
            }
        }
    }

    func save() {
        if let url = currentFileURL {
            saveCity(to: url)
        } else {
            showSavePanel()
        }
    }

    /// DOS "Print": prints the whole city map, scaled to fit the page.
    func printMap() {
        renderer.update(cells: engine.mapSnapshot())
        guard let image = renderer.makeImage() else { return }
        let size = NSSize(width: image.width, height: image.height)
        let imageView = NSImageView(frame: NSRect(origin: .zero, size: size))
        imageView.image = NSImage(cgImage: image, size: size)
        imageView.imageScaling = .scaleProportionallyUpOrDown

        let info = NSPrintInfo.shared.copy() as! NSPrintInfo
        info.horizontalPagination = .fit
        info.verticalPagination = .fit
        info.orientation = .landscape
        let operation = NSPrintOperation(view: imageView, printInfo: info)
        operation.jobTitle = cityName
        operation.runModal(for: NSApp.keyWindow ?? NSWindow(), delegate: nil, didRun: nil, contextInfo: nil)
    }

    func showAbout() {
        NSApp.orderFrontStandardAboutPanel(options: [
            .applicationName: "Micropolis",
            .credits: NSAttributedString(string: "Based on the SimCity source released by Electronic Arts under the GPL."),
        ])
    }

    // MARK: - Map window

    func centerEditView(onTileX x: Int, y: Int) {
        let clampedX = max(0, min(Engine.width - 1, x))
        let clampedY = max(0, min(Engine.height - 1, y))
        scrollRequest = ScrollRequest(x: clampedX, y: clampedY, id: (scrollRequest?.id ?? 0) + 1)
    }

    // MARK: - Terrain editor

    /// Called once at the start of each click or drag, before any edits, so
    /// Undo restores the map as it was before the whole stroke.
    func beginTerrainStroke() {
        terrainUndo = engine.mapSnapshot()
    }

    func applyTerrain(atX x: Int, y: Int) {
        if terrainFill {
            fillTerrain(fromX: x, y: y)
        } else {
            paintTerrain(atX: x, y: y)
        }
        mapVersion += 1
    }

    private func paintTerrain(atX x: Int, y: Int) {
        engine.setTile(x: x, y: y, cell: terrainTool.cell)
    }

    /// Flood-fills the patch of same terrain under (x, y) with the selected
    /// terrain. Buildings and roads stop the fill.
    private func fillTerrain(fromX startX: Int, y startY: Int) {
        let cells = engine.mapSnapshot()
        let index = { (x: Int, y: Int) in x * Engine.height + y }
        guard let target = TerrainKind(cell: cells[index(startX, startY)]),
              target != terrainTool.kind else { return }

        var seen = [Bool](repeating: false, count: cells.count)
        var stack = [(startX, startY)]
        seen[index(startX, startY)] = true
        while let (x, y) = stack.popLast() {
            engine.setTile(x: x, y: y, cell: terrainTool.cell)
            for (nx, ny) in [(x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)] {
                guard nx >= 0, nx < Engine.width, ny >= 0, ny < Engine.height else { continue }
                let i = index(nx, ny)
                if !seen[i], TerrainKind(cell: cells[i]) == target {
                    seen[i] = true
                    stack.append((nx, ny))
                }
            }
        }
    }

    func smoothTerrain() {
        beginTerrainStroke()
        engine.smoothTerrain()
        mapVersion += 1
    }

    /// Single-level undo, as in the DOS editor: puts back the map from
    /// before the last stroke, fill or smooth.
    func undoTerrain() {
        guard let saved = terrainUndo else { return }
        let current = engine.mapSnapshot()
        for x in 0..<Engine.width {
            for y in 0..<Engine.height {
                let i = x * Engine.height + y
                if current[i] != saved[i] {
                    engine.setTile(x: x, y: y, cell: saved[i])
                }
            }
        }
        terrainUndo = nil
        mapVersion += 1
    }

    deinit {
        timer?.invalidate()
    }

    // MARK: - EngineDelegate

    func engineDidLoadCity(filename: String) {}
    func engineDidGenerateMap(seed: Int) {}
    func engineDidTool(name: String, x: Int, y: Int) {}
    func engineMakeSound(channel: String, sound: String, x: Int, y: Int) {
        guard soundOn else { return }
        SoundManager.shared.play(soundName: sound)
    }
    func engineSendMessage(index: Int, x: Int, y: Int, picture: Bool, important: Bool) {
        currentMessage = Messages.text(for: index)
        if important && x >= 0 && y >= 0 {
            importantMessageGoTo = (x, y)
            if autoGoto {
                centerEditView(onTileX: x, y: y)
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
            importantMessageGoTo = (x, y)
            centerEditView(onTileX: x, y: y)
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
        self.cityScore = engine.score
        self.evaluation = engine.evaluation()
    }
    func engineUpdateHistory() {
        historyVersion += 1
    }
    func engineUpdateBudget() {}
    func engineUpdatePaused(paused: Bool) {
        self.paused = paused
    }
    func engineUpdateSpeed(speed: Int) {
        self.speed = speed
    }
    func engineUpdateTaxRate(tax: Int) {}
    func engineStartEarthquake(strength: Int) {}
    func engineDidWinGame() {
        outcome = .won
    }
    func engineDidLoseGame() {
        outcome = .lost
    }
}
