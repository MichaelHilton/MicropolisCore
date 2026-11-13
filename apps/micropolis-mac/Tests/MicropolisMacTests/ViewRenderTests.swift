import SwiftUI
import AppKit
import Testing
import MicropolisKit
@testable import MicropolisMac

/// Hosts each view in an NSHostingView and lays it out, which runs its body.
/// That catches crashes from bad indexing or unwrapping, and checks the view
/// asks for some space.
@MainActor
struct ViewRenderTests {
    private func model(city: Bool = false) -> GameModel {
        GameModel(city: city ? Assets.city("haight") : nil, sound: RecordingSound(), seed: 1, runsTimer: false)
    }

    @discardableResult
    private func render<V: View>(_ view: V, model: GameModel, _ comment: Comment? = nil,
                                 sourceLocation: SourceLocation = #_sourceLocation) -> NSHostingView<some View> {
        let host = NSHostingView(rootView: view.environment(model))
        host.frame = NSRect(x: 0, y: 0, width: 800, height: 600)
        host.layoutSubtreeIfNeeded()
        #expect(host.fittingSize.width > 0 && host.fittingSize.height > 0, comment, sourceLocation: sourceLocation)
        return host
    }

    @Test func hud() { render(HUDView(), model: model(city: true)) }
    @Test func statusLine() { render(StatusLine(), model: model()) }
    @Test func menuStrip() { render(DOSMenuStrip(), model: model()) }

    @Test
    func statusLineShowsAToolMessage() {
        let m = model()
        m.toolMessage = "Not enough funds"
        render(StatusLine(), model: m)
        m.currentMessage = "Fire reported!"
        m.importantMessageGoTo = (10, 10)
        render(StatusLine(), model: m)
    }

    @Test func toolPalette() { render(ToolPalette(), model: model(city: true)) }

    @Test
    func toolPaletteWithEverythingSelectedAndDemandShowing() {
        let m = model(city: true)
        m.demandResidential = 1
        m.demandCommercial = -1
        m.demandIndustrial = 0.3
        for spec in ToolSpec.all {
            m.selectedTool = spec.tool
            render(ToolPalette(), model: m, "\(spec.name)")
        }
    }

    @Test
    func terrainPaletteWithAndWithoutUndo() {
        let m = model()
        render(TerrainPalette(), model: m, "no undo")
        m.beginTerrainStroke()
        #expect(m.terrainUndo != nil)
        for tool in TerrainTool.allCases {
            m.terrainTool = tool
            m.terrainFill.toggle()
            render(TerrainPalette(), model: m, "\(tool.name) with undo")
        }
    }

    @Test
    func evaluationBeforeAndAfterTheCityRuns() {
        let m = model(city: true)
        render(EvaluationView(), model: m, "fresh")
        for _ in 0..<300 { m.frame() }
        m.engineUpdateEvaluation()
        #expect(!m.evaluation.problems.isEmpty || m.evaluation.population > 0)
        render(EvaluationView(), model: m, "after 300 frames")
    }

    @Test
    func graphsInEachState() {
        let m = model(city: true)
        for _ in 0..<100 { m.frame() }
        render(GraphsView(), model: m)
    }

    @Test
    func mapsInEveryOverlay() {
        let m = model(city: true)
        for _ in 0..<50 { m.frame() }
        for overlay in MapOverlay.allCases {
            m.mapOverlay = overlay
            m.visibleTiles = CGRect(x: 10, y: 10, width: 50, height: 40)
            render(MapsView(), model: m, "\(overlay.title)")
        }
    }

    @Test
    func budgetSheet() {
        let m = model(city: true)
        m.showBudgetSheet = true
        render(BudgetView(), model: m)
    }

    @Test func newCity() { render(NewCityView(), model: model()) }

    @Test
    func zoneStatusPopoverForKnownAndUnknownValues() {
        let known = ZoneStatusInfo(category: 11, density: 2, landValue: 7, crime: 10, pollution: 15, growth: 19, x: 4, y: 5)
        let unknown = ZoneStatusInfo(category: -1, density: -1, landValue: -1, crime: -1, pollution: -1, growth: -1, x: 4, y: 5)
        for info in [known, unknown] {
            let host = NSHostingView(rootView: ZoneStatusPopover(info: info))
            host.layoutSubtreeIfNeeded()
            #expect(host.fittingSize.width > 0 && host.fittingSize.height > 0)
        }
    }

    @Test func systemMenu() { render(VStack { SystemMenuItems() }, model: model()) }
    @Test func optionsMenu() { render(VStack { OptionsMenuItems() }, model: model()) }
    @Test func disastersMenu() { render(VStack { DisastersMenuItems() }, model: model()) }
    @Test func windowsMenu() { render(VStack { WindowsMenuItems() }, model: model()) }

    @Test
    func disastersMenuWhenDisasterAreOff() {
        let m = model()
        m.disastersEnabled = false
        render(VStack { DisastersMenuItems() }, model: m)
    }
}
