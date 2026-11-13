import CoreGraphics
import Foundation
import Testing
import MicropolisKit
@testable import MicropolisMac

/// Name tables and small pure helpers. None of these need the engine.
struct LookupTablesTests {
    // MARK: ZoneStatus

    @Test
    func zoneStatusNamesCoverTheirTablesAndNothingMore() {
        let tables: [(table: [String], first: Int, name: (Int) -> String)] = [
            (ZoneStatus.zones, 1, ZoneStatus.categoryName),
            (ZoneStatus.densities, 1, ZoneStatus.densityName),
            (ZoneStatus.values, 5, ZoneStatus.valueName),
            (ZoneStatus.crimeLevels, 9, ZoneStatus.crimeName),
            (ZoneStatus.pollutionLevels, 13, ZoneStatus.pollutionName),
            (ZoneStatus.growth, 17, ZoneStatus.growthName),
        ]
        for (table, first, name) in tables {
            for (offset, expected) in table.enumerated() {
                #expect(name(first + offset) == expected)
            }
            for invalid in [Int.min, -1, 0, first - 1, first + table.count, Int.max] {
                #expect(name(invalid) == "Unknown")
            }
        }
    }

    @Test
    func zoneStatusUsesEngineCategoryAndDetailTextIDs() {
        #expect(ZoneStatus.categoryName(8) == "Road")
        #expect(ZoneStatus.categoryName(11) == "Residential")
        #expect(ZoneStatus.categoryName(12) == "Commercial")
        #expect(ZoneStatus.categoryName(16) == "Coal Power")
        #expect(ZoneStatus.densityName(4) == "Very High")
        #expect(ZoneStatus.valueName(5) == "Slum")
        #expect(ZoneStatus.crimeName(9) == "Safe")
        #expect(ZoneStatus.pollutionName(13) == "None")
        #expect(ZoneStatus.growthName(18) == "Stable")
    }

    // MARK: EvaluationText

    @Test
    func evaluationTextNamesFallBackToQuestionMark() {
        #expect(EvaluationText.problemName(0) == "CRIME")
        #expect(EvaluationText.problemName(6) == "FIRES")
        #expect(EvaluationText.problemName(-1) == "?")
        #expect(EvaluationText.problemName(7) == "?")
        #expect(EvaluationText.className(0) == "VILLAGE")
        #expect(EvaluationText.className(5) == "MEGALOPOLIS")
        #expect(EvaluationText.className(-1) == "?")
        #expect(EvaluationText.className(6) == "?")
        #expect(EvaluationText.levelName(0) == "Easy")
        #expect(EvaluationText.levelName(2) == "Hard")
        #expect(EvaluationText.levelName(-1) == "?")
        #expect(EvaluationText.levelName(3) == "?")
    }

    @Test
    func evaluationHasOneNamePerEngineProblem() {
        // CityVotingProblems in micropolis.h: CRIME, POLLUTION, HOUSING, TAXES,
        // TRAFFIC, UNEMPLOYMENT, FIRE.
        #expect(EvaluationText.problems.count == 7)
    }

    // MARK: ScenarioText

    @Test
    func scenarioNamesAreDistinctAndEndInAYear() {
        let names = Scenario.allCases.map(ScenarioText.name)
        #expect(Set(names).count == Scenario.allCases.count)
        for name in names {
            let year = name.suffix(4)
            #expect(year.count == 4 && year.allSatisfy(\.isNumber), "\(name)")
        }
    }

    // MARK: ToolSpec

    @Test
    func toolStatusTextShowsCostOnlyWhenThereIsOne() {
        #expect(ToolSpec.spec(for: .query)?.statusText == "Query")
        #expect(ToolSpec.spec(for: .road)?.statusText == "Roads: $10")
    }

    @Test
    func toolSizeIsOneForGlyphsAndTheTileSizeOtherwise() {
        #expect(ToolSpec.spec(for: .query)?.size == 1)
        #expect(ToolSpec.spec(for: .road)?.size == 1)
        #expect(ToolSpec.spec(for: .residential)?.size == 3)
        #expect(ToolSpec.spec(for: .stadium)?.size == 4)
        #expect(ToolSpec.spec(for: .airport)?.size == 6)
    }

    @Test
    func footprintInsetsBuildingsButNotSingleTiles() {
        let road = ToolSpec.footprint(for: .road, at: (x: 10, y: 20))
        #expect(road == (x: 10, y: 20, size: 1))
        for (tool, size) in [(Tool.residential, 3), (.coalPower, 4), (.airport, 6)] {
            let box = ToolSpec.footprint(for: tool, at: (x: 10, y: 20))
            #expect(box == (x: 9, y: 19, size: size))
        }
        for tool in [Tool.network, .water, .land, .forest] {
            #expect(ToolSpec.footprint(for: tool, at: (x: 10, y: 20)) == (x: 10, y: 20, size: 1))
        }
    }

    @Test
    func everyToolSpecHasUniqueToolAndShortcut() {
        let all = ToolSpec.all
        #expect(Set(all.map(\.tool)).count == all.count)
        #expect(Set(all.map(\.shortcut)).count == all.count)
    }

    // MARK: Terrain

    @Test
    func terrainToolCellsMapBackToTheirKind() {
        for tool in TerrainTool.allCases {
            #expect(TerrainKind(cell: tool.cell) == tool.kind, "\(tool.name)")
        }
    }

    @Test
    func terrainKindBoundaries() {
        #expect(TerrainKind(cell: 0) == .dirt)
        #expect(TerrainKind(cell: 1) == nil)
        #expect(TerrainKind(cell: 2) == .water)
        #expect(TerrainKind(cell: 20) == .water)
        #expect(TerrainKind(cell: 21) == .trees)
        #expect(TerrainKind(cell: 43) == .trees)
        #expect(TerrainKind(cell: 44) == nil)
        #expect(TerrainKind(cell: 64) == nil)
    }

    @Test
    func terrainKindIgnoresFlagBits() {
        #expect(TerrainKind(cell: 37 | 0x3000) == .trees)
        #expect(TerrainKind(cell: 2 | 0x8000) == .water)
    }

    // MARK: OverlayRenderer and MapOverlay

    @Test
    func rampEndsAreOpaqueAndDifferent() {
        #expect(OverlayRenderer.ramp(0).a == 255)
        #expect(OverlayRenderer.ramp(1).a == 255)
        #expect(OverlayRenderer.ramp(0) != OverlayRenderer.ramp(1))
    }

    @Test
    func rampClampsItsInput() {
        #expect(OverlayRenderer.ramp(-1) == OverlayRenderer.ramp(0))
        #expect(OverlayRenderer.ramp(2) == OverlayRenderer.ramp(1))
    }

    @Test
    func overlayTitlesAreDistinct() {
        let titles = MapOverlay.allCases.map(\.title)
        #expect(titles.allSatisfy { !$0.isEmpty })
        #expect(Set(titles).count == titles.count)
    }

    @Test
    func overlayDataLayersAndLegends() {
        for overlay in MapOverlay.allCases {
            let hasLayer = overlay != .cityForm && overlay != .transportation
            #expect((overlay.dataLayer != nil) == hasLayer, "\(overlay.title)")
            #expect(overlay.hasLegend == (hasLayer && overlay != .powerGrid), "\(overlay.title)")
        }
        #expect(MapOverlay.powerGrid.dataLayer == .power)
    }

    private func blankCells() -> [UInt16] {
        [UInt16](repeating: 0, count: Engine.width * Engine.height)
    }

    private func index(_ x: Int, _ y: Int) -> Int { x * Engine.height + y }
    private func pixel(_ x: Int, _ y: Int) -> Int { y * Engine.width + x }

    @Test
    func cityFormDrawsNothing() {
        let pixels = OverlayRenderer.pixels(for: .cityForm, cells: blankCells(), data: nil)
        #expect(pixels.count == Engine.width * Engine.height)
        #expect(pixels.allSatisfy { $0 == .clear })
    }

    @Test
    func powerGridColorsConductiveTilesByPower() {
        var cells = blankCells()
        cells[index(3, 4)] = 0xC000 | 210      // powered and conductive
        cells[index(5, 6)] = 0x4000 | 210      // conductive but unpowered
        cells[index(7, 8)] = 0x8000            // powered, not conductive
        let pixels = OverlayRenderer.pixels(for: .powerGrid, cells: cells, data: nil)
        #expect(pixels[pixel(3, 4)] == .init(r: 255, g: 255, b: 85, a: 255))
        #expect(pixels[pixel(5, 6)] == .init(r: 170, g: 0, b: 170, a: 255))
        #expect(pixels[pixel(7, 8)] == .clear)
    }

    @Test
    func powerGridPrefersTheEnginePowerLayerWhenGiven() {
        var cells = blankCells()
        cells[index(3, 4)] = 0x4000 | 210      // flag says unpowered
        var data = [Int16](repeating: 0, count: cells.count)
        data[index(3, 4)] = 1
        let pixels = OverlayRenderer.pixels(for: .powerGrid, cells: cells, data: data)
        #expect(pixels[pixel(3, 4)] == .init(r: 255, g: 255, b: 85, a: 255))
    }

    @Test
    func transportationShowsRoadsAndRailOnly() {
        var cells = blankCells()
        cells[index(1, 2)] = 66                // road
        cells[index(2, 2)] = 206               // last road/bridge tile
        cells[index(3, 2)] = 230               // rail
        cells[index(4, 2)] = 210               // power line
        cells[index(5, 2)] = 0x8000 | 66       // flags do not matter
        let pixels = OverlayRenderer.pixels(for: .transportation, cells: cells, data: nil)
        #expect(pixels[pixel(1, 2)] == .init(r: 255, g: 255, b: 255, a: 255))
        #expect(pixels[pixel(2, 2)] == .init(r: 255, g: 255, b: 255, a: 255))
        #expect(pixels[pixel(3, 2)] == .init(r: 255, g: 85, b: 85, a: 255))
        #expect(pixels[pixel(4, 2)] == .clear)
        #expect(pixels[pixel(5, 2)] == .init(r: 255, g: 255, b: 255, a: 255))
    }

    @Test
    func populationGrowthIsGreenWhenPositiveRedWhenNegative() {
        var data = [Int16](repeating: 0, count: Engine.width * Engine.height)
        data[index(1, 1)] = 100
        data[index(2, 1)] = -50
        let pixels = OverlayRenderer.pixels(for: .populationGrowth, cells: blankCells(), data: data)
        #expect(pixels[pixel(1, 1)] == .init(r: 0, g: 255, b: 0, a: 255))   // the peak is full strength
        let weaker = pixels[pixel(2, 1)]
        #expect(weaker.r > 0 && weaker.r < 255 && weaker.g == 0 && weaker.a == 255)
        #expect(pixels[pixel(3, 1)] == .clear)
    }

    @Test
    func populationGrowthWithoutDataIsClear() {
        let pixels = OverlayRenderer.pixels(for: .populationGrowth, cells: blankCells(), data: nil)
        #expect(pixels.allSatisfy { $0 == .clear })
    }

    @Test
    func dataLayersScaleToTheirPeakAndSkipZeros() {
        var data = [Int16](repeating: 0, count: Engine.width * Engine.height)
        data[index(1, 1)] = 200
        data[index(2, 1)] = 100
        let pixels = OverlayRenderer.pixels(for: .crime, cells: blankCells(), data: data)
        #expect(pixels[pixel(1, 1)] == OverlayRenderer.ramp(1))
        #expect(pixels[pixel(2, 1)] == OverlayRenderer.ramp(0.5))
        #expect(pixels[pixel(3, 1)] == .clear)
        #expect(OverlayRenderer.pixels(for: .crime, cells: blankCells(), data: nil).allSatisfy { $0 == .clear })
    }

    @Test
    func imageHasMapDimensionsAndClearPixelsStayTransparent() throws {
        var pixels = [OverlayRenderer.RGBA](repeating: .clear, count: Engine.width * Engine.height)
        pixels[0] = .init(r: 10, g: 20, b: 30, a: 255)
        let image = try #require(OverlayRenderer.image(from: pixels))
        #expect(image.width == Engine.width && image.height == Engine.height)
        let data = try #require(image.dataProvider?.data as Data?)
        #expect(Array(data.prefix(4)) == [10, 20, 30, 255])
        #expect(Array(data.dropFirst(4).prefix(4)) == [0, 0, 0, 0])
    }

    // MARK: GraphSeries

    @Test
    func graphSeriesNamesAreNonEmptyAndDistinct() {
        let names = HistoryKind.allCases.map(GraphSeries.name)
        let shorts = HistoryKind.allCases.map(GraphSeries.shortName)
        #expect(names.allSatisfy { !$0.isEmpty } && Set(names).count == names.count)
        #expect(shorts.allSatisfy { !$0.isEmpty } && Set(shorts).count == shorts.count)
    }

    @Test
    func graphPathSpansTheWidthAndIsEmptyForTooFewValues() {
        let size = CGSize(width: 100, height: 100)
        let bounds = GraphSeries.path([0, 1], in: size).boundingRect
        #expect(bounds.minX == 0 && bounds.maxX == 100)
        #expect(GraphSeries.path([], in: size).isEmpty)
        #expect(GraphSeries.path([0.5], in: size).isEmpty)
    }

    @Test
    func yearLabelsRunFromStartThroughMiddleToNow() {
        #expect(GraphSeries.yearLabels(year: 1950, longRange: false) == ["1940", "1945", "1950"])
        #expect(GraphSeries.yearLabels(year: 2000, longRange: true) == ["1880", "1940", "2000"])
    }

    // MARK: Assets

    @Test(arguments: [false, true])
    func resourceRootSupportsSwiftPMAndXcodeBundles(nested: Bool) throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let expected = nested ? directory.appendingPathComponent("Resources") : directory
        try FileManager.default.createDirectory(at: expected.appendingPathComponent("tiles"), withIntermediateDirectories: true)
        try Data().write(to: expected.appendingPathComponent("tiles/classic.png"))
        #expect(Assets.resourceRoot(in: directory).path == expected.path)
    }

    @Test
    func allCitiesAreSortedCtyFiles() {
        let cities = Assets.allCities
        #expect(!cities.isEmpty)
        #expect(cities.allSatisfy { $0.pathExtension == "cty" })
        #expect(cities.map(\.lastPathComponent) == cities.map(\.lastPathComponent).sorted())
    }

    @Test
    func haightExistsOnDisk() {
        #expect(FileManager.default.fileExists(atPath: Assets.city("haight").path))
        #expect(Assets.allCities.map(\.lastPathComponent).contains("haight.cty"))
    }

    @Test
    func soundLookup() throws {
        #expect(Assets.sound("no-such-sound") == nil)
        let url = try #require(Assets.sound("beep"))
        #expect(url.lastPathComponent == "beep.mp3")
        #expect(FileManager.default.fileExists(atPath: url.path))
    }

    @Test
    func spriteSheetNamesFollowTheClassicPattern() {
        let url = Assets.spriteSheet("monster")
        #expect(url.lastPathComponent == "classic-sprite-monster.png")
        #expect(FileManager.default.fileExists(atPath: url.path))
    }

    // MARK: DemandGauge

    @Test
    func demandBarsRiseAboveTheMidlineAndDropBelowIt() {
        let half: CGFloat = 22
        for value: Float in [0.5, 1, 2] {
            let bar = DemandGauge.barLayout(value, halfHeight: half)
            #expect(bar.top + bar.height == half)
        }
        for value: Float in [-0.5, -1, -2] {
            #expect(DemandGauge.barLayout(value, halfHeight: half).top == half)
        }
        #expect(DemandGauge.barLayout(0, halfHeight: half).height == 0)
        #expect(DemandGauge.barLayout(0.5, halfHeight: half).height == 11)
        #expect(DemandGauge.barLayout(2, halfHeight: half).height == half)
        #expect(DemandGauge.barLayout(-2, halfHeight: half).height == half)
    }

    // MARK: BudgetSheet

    private func sheet(requests: (Int, Int, Int) = (400, 300, 200), taxes: Int = 1000, funds: Int = 5000,
                       levels: (Int, Int, Int)) -> BudgetSheet {
        BudgetSheet(
            figures: BudgetFigures(taxesCollected: taxes, roadRequested: requests.0,
                                   policeRequested: requests.1, fireRequested: requests.2),
            funds: funds, taxRate: 7, roadLevel: levels.0, policeLevel: levels.1, fireLevel: levels.2)
    }

    @Test
    func budgetWithNothingRequestedKeepsAllTaxes() {
        let s = sheet(requests: (0, 0, 0), levels: (100, 100, 100))
        #expect(s.cashFlow == 1000)
        #expect(s.currentFunds == 6000)
    }

    @Test
    func budgetFullVersusNoFunding() {
        let full = sheet(levels: (100, 100, 100))
        #expect(full.cashFlow == 1000 - 900)
        let none = sheet(levels: (0, 0, 0))
        #expect(none.cashFlow == 1000)
        #expect(none.currentFunds == 6000)
    }

    @Test
    func budgetOverspendingLowersFundsBelowCurrent() {
        let s = sheet(taxes: 100, levels: (100, 100, 100))
        #expect(s.cashFlow == -800)
        #expect(s.currentFunds == 4200)
        #expect(s.currentFunds < s.funds)
    }

    @Test
    func budgetAllocationRoundsDown() {
        // 333 * 50 / 100 is 166.5; integer division drops the half.
        let s = sheet(requests: (333, 333, 333), levels: (50, 50, 50))
        #expect(s.roadAllocated == 166)
    }

    @Test
    func budgetMoneyFormatting() {
        #expect(BudgetSheet.money(-1234) == "-$1,234")
        #expect(BudgetSheet.money(0) == "$0")
        #expect(BudgetSheet.money(1234567) == "$1,234,567")
    }
}
