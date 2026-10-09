import XCTest
@testable import MicropolisKit

/// Fixed-seed runs reduced to one hash each. A hash may change only when
/// game behavior changes on purpose; then record the new value here and say
/// why in the commit. Deleting dead engine code must never change one.
final class BehaviorLockTests: XCTestCase {
    /// 64-bit FNV-1a. Swift's Hasher is seeded per process, so it can't be used.
    private struct Fingerprint {
        private(set) var value: UInt64 = 0xcbf2_9ce4_8422_2325

        mutating func add(_ number: Int) {
            for byte in withUnsafeBytes(of: Int64(number).littleEndian, Array.init) {
                value = (value ^ UInt64(byte)) &* 0x0000_0100_0000_01b3
            }
        }

        mutating func add<S: Sequence>(_ numbers: S) where S.Element: BinaryInteger {
            for number in numbers { add(Int(number)) }
        }
    }

    private func fingerprint(_ engine: Engine) -> UInt64 {
        var print = Fingerprint()
        print.add(engine.mapSnapshot())
        print.add([engine.funds, engine.population, engine.year, engine.month])
        for kind in HistoryKind.allCases {
            print.add(engine.history(kind))
        }
        let evaluation = engine.evaluation()
        print.add([evaluation.yes, evaluation.population, evaluation.populationDelta,
                   evaluation.assessedValue, evaluation.cityClass, evaluation.score, evaluation.scoreDelta])
        print.add(evaluation.problems.flatMap { [$0.id, $0.votes] })
        print.add(engine.sprites().flatMap { [$0.type, $0.x, $0.y, $0.frame] })
        return print.value
    }

    private func run(_ engine: Engine, ticks: Int) {
        engine.setSpeed(3)
        for _ in 0..<ticks { engine.tick() }
    }

    func testHaightRunsTheSameAsBefore() {
        let engine = Engine(seed: 1234)
        XCTAssertTrue(engine.loadCity(at: Repo.city("haight")))
        engine.setEnableDisasters(true)
        run(engine, ticks: 3000)
        XCTAssertEqual(fingerprint(engine), 17_606_856_765_599_483_938)
    }

    func testGeneratedMapsMatchBefore() {
        let expected: [UInt64] = [
            12_375_091_067_891_641_126, 1_273_736_728_496_595_046, 15_450_135_359_159_625_017,
            4_825_878_825_225_762_036, 6_181_527_616_297_933,
        ]
        for seed in 1...5 {
            let engine = Engine(seed: 1234)
            engine.generateMap(seed: seed)
            var print = Fingerprint()
            print.add(engine.mapSnapshot())
            XCTAssertEqual(print.value, expected[seed - 1], "seed \(seed)")
        }
    }

    func testScenariosRunTheSameAsBefore() {
        let expected: [Scenario: UInt64] = [
            .dullsville: 11_616_353_177_429_419_176, .sanFrancisco: 10_499_401_142_174_924_006,
            .hamburg: 7_460_703_079_917_731_154, .bern: 3_184_402_497_921_529_348,
            .tokyo: 3_195_535_774_621_490_274, .detroit: 5_755_558_939_284_944_727,
            .boston: 12_233_755_066_900_106_327, .rio: 13_451_623_446_788_563_051,
        ]
        for scenario in Scenario.allCases {
            let engine = Engine(seed: 1234)
            XCTAssertTrue(engine.loadScenario(scenario, resourceDirectory: Repo.content), "\(scenario)")
            run(engine, ticks: 500)
            XCTAssertEqual(fingerprint(engine), expected[scenario], "\(scenario)")
        }
    }
}
