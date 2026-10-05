import Testing
@testable import MicropolisMac

@MainActor
struct BudgetTests {
    @Test
    func policeFundingRoundTrip() {
        let model = GameModel()

        // Set police funding to 50%
        model.engine.setPolicePercent(0.5)

        // Read it back
        let value = model.engine.policePercent

        // Should be close to 0.5 (allow small floating point error)
        #expect(abs(value - 0.5) < 0.01)
    }

    @Test
    func roadFundingRoundTrip() {
        let model = GameModel()

        // Set road funding to 75%
        model.engine.setRoadPercent(0.75)

        let value = model.engine.roadPercent
        #expect(abs(value - 0.75) < 0.01)
    }

    @Test
    func fireFundingRoundTrip() {
        let model = GameModel()

        // Set fire funding to 25%
        model.engine.setFirePercent(0.25)

        let value = model.engine.firePercent
        #expect(abs(value - 0.25) < 0.01)
    }
}
