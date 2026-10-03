import Testing
@testable import MicropolisMac

@MainActor
struct GameModelTests {
    @Test
    func yearAdvances() {
        let model = GameModel()
        let yearBefore = model.year

        for _ in 0..<2000 {
            model.frame()
        }

        let yearAfter = model.year
        #expect(yearAfter > yearBefore)
    }
}
