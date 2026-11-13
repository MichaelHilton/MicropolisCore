import Foundation
import XCTest
@testable import MicropolisKit

/// Bounded property checks over reproducible action sequences. Keep the corpus
/// small enough for every PR; promote any failing prefix to a named regression.
final class GeneratedEditingTests: XCTestCase {
    // Engine's public seed boundary is a signed 32-bit value.
    private let seeds: [UInt64] = [1, 42, 0xC0FFEE, 0x5EEDBEEF]

    private struct Generator {
        var state: UInt64

        // SplitMix64 uses explicit wrapping arithmetic and no system randomness.
        mutating func pick(_ count: Int) -> Int {
            state &+= 0x9E3779B97F4A7C15
            var value = state
            value = (value ^ (value >> 30)) &* 0xBF58476D1CE4E5B9
            value = (value ^ (value >> 27)) &* 0x94D049BB133111EB
            return Int((value ^ (value >> 31)) % UInt64(count))
        }
    }

    private struct Action {
        let tool: Tool
        let x: Int
        let y: Int
    }

    private struct State: Equatable {
        let map: [UInt16]
        let funds: Int
        let tax: Int
        let autoBulldoze: Bool

        init(_ engine: Engine) {
            map = engine.mapSnapshot()
            funds = engine.funds
            tax = engine.tax
            autoBulldoze = engine.autoBulldoze
        }
    }

    private func actions(seed: UInt64) -> [Action] {
        var random = Generator(state: seed)
        // Ensure every seed exercises success, obstruction, bounds, and funds
        // rejection before exploring overlapping and scattered random edits.
        var actions = [Action(tool: .road, x: 50, y: 50),
                       Action(tool: .residential, x: 50, y: 50),
                       Action(tool: .road, x: -1, y: 0),
                       Action(tool: .airport, x: 75, y: 75)]
        for _ in 0..<124 {
            let tool = Tool.allCases[random.pick(Tool.allCases.count)]
            let x: Int
            let y: Int
            switch random.pick(3) {
            case 0:
                x = [-1, 0, Engine.width - 1, Engine.width][random.pick(4)]
                y = [-1, 0, Engine.height - 1, Engine.height][random.pick(4)]
            case 1:
                x = 45 + random.pick(16)
                y = 45 + random.pick(16)
            default:
                x = random.pick(Engine.width)
                y = random.pick(Engine.height)
            }
            actions.append(Action(tool: tool, x: x, y: y))
        }
        return actions
    }

    private func engine(seed: UInt64) -> Engine {
        let engine = ToolFixture.engine(autoBulldoze: false)
        engine.fixRandomSeed(Int(seed))
        engine.setFunds(5_000)
        engine.setTax(Int(seed % 21))
        return engine
    }

    private func context(_ seed: UInt64, _ index: Int, _ action: Action) -> String {
        "seed=\(seed), prefixLength=\(index + 1), \(action.tool) at (\(action.x),\(action.y))"
    }

    @discardableResult
    private func assertState(_ actual: State, equals expected: State, context: String,
                             file: StaticString = #filePath, line: UInt = #line) -> Bool {
        guard actual != expected else { return true }
        let difference = zip(actual.map, expected.map).enumerated().first { $0.element.0 != $0.element.1 }
        let tile = difference.map {
            "tile (\($0.offset / Engine.height),\($0.offset % Engine.height)): \($0.element.0) != \($0.element.1)"
        } ?? "tiles unchanged"
        XCTFail("\(context): \(tile); funds \(actual.funds) != \(expected.funds); tax \(actual.tax) != \(expected.tax); autoBulldoze \(actual.autoBulldoze) != \(expected.autoBulldoze)", file: file, line: line)
        return false
    }

    func testRejectedGeneratedEditsAreAtomicAndQueriesAreReadOnly() {
        let exercised = Set(seeds.flatMap { actions(seed: $0).map { $0.tool.rawValue } })
        XCTAssertEqual(exercised, Set(Tool.allCases.map(\.rawValue)), "The fixed corpus must exercise every tool")
        for seed in seeds {
            let engine = engine(seed: seed)
            var succeeded = 0
            var rejected = 0
            for (index, action) in actions(seed: seed).enumerated() {
                let before = State(engine)
                let result = engine.apply(action.tool, x: action.x, y: action.y)
                if result == .ok { succeeded += 1 } else { rejected += 1 }
                if result != .ok || action.tool == .query {
                    guard assertState(State(engine), equals: before, context: context(seed, index, action)) else { return }
                }
            }
            XCTAssertGreaterThan(succeeded, 0, "seed=\(seed)")
            XCTAssertGreaterThan(rejected, 0, "seed=\(seed)")
        }
    }

    func testGeneratedActionsReplayIdenticallyAtEveryStep() {
        for seed in seeds {
            let first = engine(seed: seed)
            let second = engine(seed: seed)
            for (index, action) in actions(seed: seed).enumerated() {
                let message = context(seed, index, action)
                let firstResult = first.apply(action.tool, x: action.x, y: action.y)
                let secondResult = second.apply(action.tool, x: action.x, y: action.y)
                guard firstResult == secondResult else {
                    XCTFail("\(message): result \(firstResult) != \(secondResult)")
                    return
                }
                guard assertState(State(first), equals: State(second), context: message) else { return }
            }
        }
    }

    func testGeneratedInfrastructureEditsSurviveRepeatedSaveLoad() throws {
        // Loading scans zones, recomputes power and installs coal smoke. Exact
        // tile equality is appropriate for infrastructure, not those runtime
        // building transformations. Replay/atomicity above still use all tools.
        let infrastructure: [Tool] = [.road, .wire, .railroad, .bulldozer, .park,
                                      .forest, .network, .water, .land, .query]
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        for seed in seeds {
            let edited = engine(seed: seed)
            for action in actions(seed: seed) where infrastructure.contains(action.tool) {
                edited.apply(action.tool, x: action.x, y: action.y)
            }
            let expected = State(edited)
            let firstURL = directory.appendingPathComponent("\(seed)-first.cty")
            XCTAssertTrue(edited.saveCity(at: firstURL), "seed=\(seed)")
            let loaded = engine(seed: seed)
            XCTAssertTrue(loaded.loadCity(at: firstURL), "seed=\(seed)")
            guard assertState(State(loaded), equals: expected, context: "seed=\(seed), first load") else { return }
            let secondURL = directory.appendingPathComponent("\(seed)-second.cty")
            XCTAssertTrue(loaded.saveCity(at: secondURL), "seed=\(seed)")
            let reloaded = engine(seed: seed)
            XCTAssertTrue(reloaded.loadCity(at: secondURL), "seed=\(seed)")
            guard assertState(State(reloaded), equals: expected, context: "seed=\(seed), second load") else { return }
        }
    }
}
