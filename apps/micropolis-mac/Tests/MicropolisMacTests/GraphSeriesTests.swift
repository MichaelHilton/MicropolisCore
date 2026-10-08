import Testing
import MicropolisKit
@testable import MicropolisMac

struct GraphSeriesTests {
    /// Haight after about 8 game years, so both the 10-year and the 120-year
    /// ranges hold data.
    private func ranHaight() -> Engine {
        let engine = Engine()
        engine.loadCity(at: Assets.city("haight"))
        for _ in 0..<6000 { engine.tick() }
        return engine
    }

    @Test
    func bothRangesGiveScaledValuesThatAreNotAllZero() {
        let engine = ranHaight()
        for longRange in [false, true] {
            let series = GraphSeries.series(engine: engine, kinds: Set(HistoryKind.allCases), longRange: longRange)
            #expect(series.count == HistoryKind.allCases.count)
            for (kind, values) in series {
                #expect(values.count == 120, "\(kind)")
                #expect(values.allSatisfy { (0...1).contains($0) }, "\(kind) long: \(longRange)")
            }
            #expect(series.contains { $0.1.contains { $0 > 0 } }, "long range: \(longRange)")
        }
    }

    @Test
    func onlyTheChosenSeriesAreReturned() {
        let engine = ranHaight()
        let series = GraphSeries.series(engine: engine, kinds: [.crime], longRange: false)
        #expect(series.map(\.0) == [.crime])
    }

    @Test
    func zoneSeriesShareOneScale() {
        let engine = ranHaight()
        let series = Dictionary(uniqueKeysWithValues:
            GraphSeries.series(engine: engine, kinds: [.residential, .commercial, .industrial], longRange: true))
        let peak = series.values.flatMap { $0 }.max() ?? 0
        #expect(peak == 1, "the tallest of the three reaches the top of the graph")
    }
}
