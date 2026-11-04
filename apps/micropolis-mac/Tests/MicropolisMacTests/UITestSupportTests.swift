import Testing
@testable import MicropolisMac

struct UITestSupportTests {
    @Test func uiTestFlagRequiresAnExplicitOne() {
        #expect(!UITestLaunchConfiguration.isEnabled(in: [:]))
        #expect(!UITestLaunchConfiguration.isEnabled(in: [UITestLaunchConfiguration.enabledKey: "true"]))
        #expect(UITestLaunchConfiguration.isEnabled(in: [UITestLaunchConfiguration.enabledKey: "1"]))
    }

    @MainActor
    @Test func uiTestLaunchUsesAPausedDeterministicCity() {
        let model = UITestLaunchConfiguration.makeModel(environment: [
            UITestLaunchConfiguration.enabledKey: "1"
        ])
        #expect(model.cityName == "haight")
        #expect(model.paused)
        #expect(model.speed == 0)
        #expect(!model.soundOn)
    }

    @Test func toolIdentifiersAreUniqueAndStable() {
        let identifiers = ToolSpec.all.map { UIIdentifier.tool($0.shortcut) }
        #expect(Set(identifiers).count == ToolSpec.all.count)
        #expect(UIIdentifier.tool("Q") == "tool.q")
        #expect(UIIdentifier.tool("Y") == "tool.y")
    }

    @Test func fixedIdentifiersUseTheirPublishedNames() {
        #expect(UIIdentifier.mapCanvas == "map.canvas")
        #expect(UIIdentifier.statusLine == "hud.statusLine")
        #expect(UIIdentifier.menu("SYSTEM") == "menu.system")
        #expect(UIIdentifier.terrain("Trees") == "terrain.trees")
        #expect(UIIdentifier.overlay("POWER") == "overlay.power")
        #expect(UIIdentifier.graph("RES") == "graph.res")
        #expect(UIIdentifier.budget("tax.increase") == "budget.tax.increase")
    }
}
