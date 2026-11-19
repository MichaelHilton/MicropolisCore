import Foundation
import CoreGraphics
import MicropolisKit

/// Fixture setup and read-only observations for the explicitly requested
/// button-inventory runner. No filesystem observer runs in a normal launch.
@MainActor
enum ButtonInventorySupport {
    private static var observer: Timer?
    private static var active = false
    private static var frames = 0
    private static var earthquakes = 0
    private static var printImageSize = [Int]()
    private static var printHasContent = false

    static func didAdvanceFrame(_ engine: Engine) {
        if active && !engine.isPaused && engine.speed > 0 { frames += 1 }
    }
    static func didStartEarthquake() { if active { earthquakes += 1 } }

    static func didPreparePrintImage(_ image: CGImage) {
        guard active else { return }
        printImageSize = [image.width, image.height]
        if let bytes = image.dataProvider?.data as Data? {
            printHasContent = Set(bytes).count > 1
        }
    }

    static func stopObserving() {
        observer?.invalidate()
        observer = nil
        active = false
    }

    static func configure(_ model: GameModel, environment: [String: String]) {
        guard environment["MICROPOLIS_UI_TESTING"] == "1",
              let path = environment["MICROPOLIS_INVENTORY_STATE"] else { return }
        active = true
        frames = 0
        earthquakes = 0
        printImageSize = []
        printHasContent = false
        let fixture = environment["MICROPOLIS_INVENTORY_FIXTURE"] ?? "default"
        if fixture == "empty" || fixture == "tools" || fixture == "terrain" {
            for x in 0..<Engine.width {
                for y in 0..<Engine.height {
                    let cell: UInt16 = fixture == "terrain" ? ((8...12).contains(x) && (8...12).contains(y) ? 0 : 2) : 0
                    model.engine.setTile(x: x, y: y, cell: cell)
                }
            }
            model.engine.setFunds(100_000)
            model.cityName = "Inventory Fixture"
            model.currentFileURL = nil
            if fixture == "tools" {
                _ = model.engine.apply(.road, x: 10, y: 10)
                _ = model.engine.apply(.residential, x: 16, y: 16)
                for x in 30..<Engine.width {
                    for y in 0..<Engine.height { model.engine.setTile(x: x, y: y, cell: 2) }
                }
                model.engine.setFunds(100_000)
            }
        } else if fixture.hasPrefix("sample.") {
            model.loadCity(from: Assets.city(String(fixture.dropFirst(7))))
        } else if fixture.hasPrefix("scenario."),
                  let raw = Int32(fixture.dropFirst(9)), let scenario = Scenario(rawValue: raw) {
            model.loadScenario(scenario)
        } else if fixture == "disaster.flood" {
            // Many river edges beside bare land ensure a single seeded command
            // finds a floodable shoreline without retries masking a wrong action.
            for x in 0..<Engine.width {
                for y in 0..<Engine.height { model.engine.setTile(x: x, y: y, cell: x % 2 == 0 ? 5 : 0) }
            }
        } else if fixture == "disaster.fire" || fixture == "disaster.earthquake" {
            for x in 0..<Engine.width {
                for y in 0..<Engine.height { model.engine.setTile(x: x, y: y, cell: 240 | 0x3000) }
            }
        } else if fixture == "disaster.meltdown" {
            for x in 0..<Engine.width {
                for y in 0..<Engine.height { model.engine.setTile(x: x, y: y, cell: 0) }
            }
            model.engine.setFunds(100_000)
            _ = model.engine.apply(.nuclearPower, x: 15, y: 15)
        } else if fixture == "disaster.airCrash" {
            model.loadCity(from: Assets.city("deadwood"))
            model.engine.setEnableDisasters(false)
            model.engine.resume()
            model.engine.setSpeed(3)
            for _ in 0..<3_000 {
                let sprites = model.engine.sprites()
                if sprites.contains(where: { $0.type == 3 && $0.frame > 0 }) &&
                    !sprites.contains(where: { $0.type == 7 && $0.frame > 0 }) { break }
                model.engine.tick()
            }
            model.disastersEnabled = true
        } else if fixture == "graphHistories" {
            model.autoBudget = true
            model.disastersEnabled = false
            model.engine.setSpeed(3)
            model.engine.resume()
            for _ in 0..<6_000 { model.engine.tick() }
            model.autoBudget = false
            model.disastersEnabled = true
            model.historyVersion += 1
        } else if fixture == "budgetYearEnd" {
            model.setSpeed(0)
            model.engine.setCityTime(47)
            model.engine.setFunds(100_000)
            // Refresh cached year/month without advancing simulation time.
            model.engine.tick()
        } else if fixture == "budgetPaused" {
            model.setSpeed(2)
            model.pauseSimulation()
        }
        model.engine.fixRandomSeed(1)
        model.funds = model.engine.funds
        model.year = model.engine.year
        model.month = model.engine.month
        model.mapVersion += 1
        if fixture != "budgetPaused" { model.setSpeed(0) }
        if let raw = environment["MICROPOLIS_INVENTORY_APPEARANCE"],
           let package = GraphicsPackage(rawValue: raw == "saved"
                ? GraphicsPackage.preferences.string(forKey: GraphicsPackage.preferenceKey) ?? "classic" : raw) {
            model.setGraphicsPackage(package)
        }
        if fixture == "graphicsError" {
            let other: GraphicsPackage = model.graphicsPackage == .classic ? .retroSquare : .classic
            model.setGraphicsPackage(other, atlasURL: URL(fileURLWithPath: path + ".missing-atlas"))
        }
        if fixture == "won" { model.outcome = .won }
        if fixture == "lost" { model.outcome = .lost }
        if fixture == "terrain" { model.editMode = .terrain }
        if ["empty", "tools", "terrain"].contains(fixture) {
            model.centerEditView(onTileX: 0, y: 0)
        }
        publish(model, to: path)
        observer?.invalidate()
        observer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak model] _ in
            Task { @MainActor in
                guard let model else { return }
                publish(model, to: path)
            }
        }
        if let observer { RunLoop.main.add(observer, forMode: .common) }
    }

    private static func fingerprint(_ cells: [UInt16]) -> String {
        var hash: UInt64 = 14695981039346656037
        for cell in cells {
            hash = (hash ^ UInt64(cell & 255)) &* 1099511628211
            hash = (hash ^ UInt64(cell >> 8)) &* 1099511628211
        }
        return String(hash, radix: 16)
    }

    private static func publish(_ model: GameModel, to path: String) {
        let cells = model.engine.mapSnapshot()
        let ids = cells.map { Int($0 & 0x3ff) }
        let view = model.visibleTiles
        let state: [String: Any] = [
            "cityName": model.cityName, "funds": model.engine.funds,
            "year": model.engine.year, "month": model.engine.month,
            "mapFingerprint": fingerprint(cells), "tiles": cells.map(Int.init),
            "currentFileURL": model.currentFileURL?.path ?? "",
            "gameLevel": model.engine.gameLevel.rawValue,
            "speed": model.speed, "paused": model.paused,
            "tickCount": frames, "earthquakeCount": earthquakes,
            "printImageSize": printImageSize, "printImageHasContent": printHasContent,
            "cityScore": model.cityScore, "population": model.population,
            "currentMessage": model.currentMessage ?? "",
            "importantMessageGoTo": model.importantMessageGoTo.map { [$0.x, $0.y] } ?? [],
            "scrollRequest": model.scrollRequest.map { [$0.x, $0.y, $0.id] } ?? [],
            "autoBulldoze": model.engine.autoBulldoze, "autoBudget": model.engine.autoBudget,
            "autoGoto": model.autoGoto, "soundOn": model.soundOn,
            "audioEvents": (model.sound as? InventorySoundSink)?.sounds ?? [],
            "animateAll": model.engine.animateAll, "frequentAnimation": model.engine.frequentAnimation,
            "disastersEnabled": model.engine.disastersEnabled,
            "graphicsPackage": model.graphicsPackage.rawValue,
            "graphicsPreference": GraphicsPackage.preferences.string(forKey: GraphicsPackage.preferenceKey) ?? "",
            "graphicsError": model.graphicsError ?? "",
            "outcome": model.outcome.map { $0 == .won ? "won" : "lost" } ?? "",
            "editMode": model.editMode == .city ? "city" : "terrain",
            "selectedTool": Int(model.selectedTool.rawValue),
            "terrainTool": model.terrainTool.name.lowercased(),
            "terrainFill": model.terrainFill, "canUndo": model.terrainUndo != nil,
            "queryOpen": model.zoneStatus != nil,
            "mapOverlay": String(describing: model.mapOverlay),
            "viewport": [view.minX, view.minY, view.width, view.height],
            "taxRate": model.engine.tax,
            "roadPercent": Double(model.engine.roadPercent),
            "policePercent": Double(model.engine.policePercent),
            "firePercent": Double(model.engine.firePercent),
            "sprites": model.engine.sprites().filter { $0.frame > 0 }.map {
                ["type": $0.type, "frame": $0.frame, "x": $0.x, "y": $0.y]
            },
            "fireTileCount": ids.filter { (56...63).contains($0) }.count,
            "floodTileCount": ids.filter { (48...51).contains($0) }.count,
            "radiationTileCount": ids.filter { $0 == 52 }.count
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: state, options: [.sortedKeys]) else { return }
        do {
            try data.write(to: URL(fileURLWithPath: path), options: .atomic)
        } catch {
            // Missing/unwritable observations must fail the runner's state()
            // assertion rather than terminating an otherwise usable app.
        }
    }
}
