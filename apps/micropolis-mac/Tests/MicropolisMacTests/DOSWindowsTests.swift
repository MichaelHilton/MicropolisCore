import Testing
import MicropolisKit
@testable import MicropolisMac

/// Tests for the windows that mirror the DOS game: budget, terrain editor,
/// map overlays, graphs, new city and scenarios.
@MainActor
struct DOSWindowsTests {
    // MARK: Budget

    @Test
    func budgetSheetArithmetic() {
        let sheet = BudgetSheet(
            figures: BudgetFigures(taxesCollected: 1000, roadRequested: 400, policeRequested: 300, fireRequested: 200),
            funds: 5000, taxRate: 7, roadLevel: 50, policeLevel: 100, fireLevel: 0)
        #expect(sheet.roadAllocated == 200)
        #expect(sheet.policeAllocated == 300)
        #expect(sheet.fireAllocated == 0)
        #expect(sheet.cashFlow == 500)
        #expect(sheet.currentFunds == 5500)
    }

    // MARK: New city and scenarios

    @Test
    func newCityUsesNameAndLevel() {
        let model = GameModel()
        model.newCity(name: "  Testville ", level: .hard, seed: 11)
        #expect(model.cityName == "Testville")
        #expect(model.funds == 5000)
        #expect(model.engine.gameLevel == .hard)
        #expect(model.evaluation.gameLevel == 2)
    }

    @Test
    func scenarioLoadsFromAppResources() {
        let model = GameModel()
        model.loadScenario(.tokyo)
        #expect(model.year == 1957)
        #expect(model.engine.mapSnapshot().filter { $0 & 0x0400 != 0 }.count > 20)
    }

    // MARK: Terrain editor

    private func flatModel() -> GameModel {
        let model = GameModel()
        model.newCity(name: "Flat", level: .easy, seed: 5)
        for x in 0..<Engine.width {
            for y in 0..<Engine.height {
                model.engine.setTile(x: x, y: y, cell: 0)
            }
        }
        return model
    }

    @Test
    func fillReplacesOnlyTheConnectedPatch() {
        let model = flatModel()
        // A wall of water at x == 10 splits the map; fill the left side with trees.
        for y in 0..<Engine.height { model.engine.setTile(x: 10, y: y, cell: 2) }
        model.terrainTool = .trees
        model.terrainFill = true
        model.beginTerrainStroke()
        model.applyTerrain(atX: 3, y: 3)

        #expect(TerrainKind(cell: model.engine.tile(x: 0, y: 0)) == .trees)
        #expect(TerrainKind(cell: model.engine.tile(x: 9, y: 99)) == .trees)
        #expect(TerrainKind(cell: model.engine.tile(x: 10, y: 50)) == .water)
        #expect(TerrainKind(cell: model.engine.tile(x: 11, y: 50)) == .dirt)
    }

    @Test
    func undoRestoresTheWholeStroke() {
        let model = flatModel()
        let before = model.engine.mapSnapshot()
        model.terrainTool = .water
        model.beginTerrainStroke()
        for x in 20..<30 { model.applyTerrain(atX: x, y: 20) }
        #expect(model.engine.mapSnapshot() != before)
        #expect(model.terrainUndo != nil)

        model.undoTerrain()
        #expect(model.engine.mapSnapshot() == before)
        #expect(model.terrainUndo == nil)
    }

    @Test
    func channelAndSmoothAreUndoable() {
        let model = flatModel()
        model.terrainTool = .channel
        model.beginTerrainStroke()
        model.applyTerrain(atX: 40, y: 40)
        #expect(model.engine.tile(x: 40, y: 40) & 0x3FF == 4)

        let beforeSmooth = model.engine.mapSnapshot()
        model.smoothTerrain()
        model.undoTerrain()
        #expect(model.engine.mapSnapshot() == beforeSmooth)
    }

    // MARK: Map overlays

    @Test
    func powerOverlayMarksPoweredAndUnpoweredConductors() {
        var cells = [UInt16](repeating: 0, count: Engine.width * Engine.height)
        cells[0 * Engine.height + 0] = 0x4000 | 0x8000 | 210   // powered wire at (0, 0)
        cells[1 * Engine.height + 0] = 0x4000 | 210            // unpowered wire at (1, 0)
        // With no grid data the renderer falls back to each tile's PWRBIT.
        let pixels = OverlayRenderer.pixels(for: .powerGrid, cells: cells, data: nil)
        #expect(pixels[0].a == 255)
        #expect(pixels[1].a == 255)
        #expect(pixels[0] != pixels[1])
        #expect(pixels[2] == .clear)
    }

    @Test
    func dataOverlayScalesToItsPeak() {
        let cells = [UInt16](repeating: 0, count: Engine.width * Engine.height)
        var data = [Int16](repeating: 0, count: Engine.width * Engine.height)
        data[5 * Engine.height + 7] = 200
        data[6 * Engine.height + 7] = 100
        let pixels = OverlayRenderer.pixels(for: .crime, cells: cells, data: data)
        #expect(pixels[7 * Engine.width + 5] == OverlayRenderer.ramp(1))
        #expect(pixels[7 * Engine.width + 6] == OverlayRenderer.ramp(0.5))
        #expect(pixels[0] == .clear)
        #expect(OverlayRenderer.image(from: pixels)?.width == Engine.width)
    }

    @Test
    func everyOverlayRendersForARealCity() {
        let model = GameModel()
        for _ in 0..<300 { model.frame() }
        let cells = model.engine.mapSnapshot()
        for overlay in MapOverlay.allCases {
            let data = overlay.dataLayer.map { model.engine.overlay($0) }
            let pixels = OverlayRenderer.pixels(for: overlay, cells: cells, data: data)
            #expect(pixels.count == Engine.width * Engine.height)
            if overlay != .cityForm {
                #expect(pixels.contains { $0.a > 0 }, "\(overlay.title) drew nothing")
            }
        }
    }

    // MARK: Graphs

    @Test
    func graphSeriesShareTheZoneScaleAndRunOldestFirst() {
        let model = GameModel()
        for _ in 0..<3000 { model.frame() }
        let series = GraphSeries.series(engine: model.engine, kinds: Set(HistoryKind.allCases), longRange: false)
        #expect(series.count == 6)
        for (_, values) in series {
            #expect(values.count == 120)
            #expect(values.allSatisfy { (0...1).contains($0) })
        }
        let zonePeak = series.filter { [.residential, .commercial, .industrial].contains($0.0) }
            .flatMap(\.1).max()
        #expect(zonePeak == 1)
        let raw = model.engine.history(.residential)
        let res = series.first { $0.0 == .residential }!.1
        #expect((res.last! == 0) == (raw[0] == 0))
    }

    @Test
    func graphYearLabels() {
        #expect(GraphSeries.yearLabels(year: 2155, longRange: false) == ["2145", "2150", "2155"])
        #expect(GraphSeries.yearLabels(year: 2155, longRange: true) == ["2035", "2095", "2155"])
    }
}
