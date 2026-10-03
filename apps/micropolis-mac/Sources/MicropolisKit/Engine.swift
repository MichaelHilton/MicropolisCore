import Foundation
import MicropolisEngine

public enum Tool: Int32, CaseIterable {
    case residential = 0, commercial, industrial, fireStation, policeStation, query, wire, bulldozer, railroad, road, stadium, park, seaport, coalPower, nuclearPower, airport, network, water, land, forest
}

public enum ToolResult: Int32 {
    case noMoney = -2, needBulldoze = -1, failed = 0, ok = 1
}

public struct Sprite {
    public let type: Int
    public let frame: Int
    public let x: Int
    public let y: Int
    public let xHot: Int
    public let yHot: Int
}

public enum HistoryKind: Int {
    case residential = 0, commercial = 1, industrial = 2
}

public final class Engine {
    private let handle: OpaquePointer

    public static let width = 120
    public static let height = 100

    public init() {
        handle = mp_create()!
    }

    deinit {
        mp_destroy(handle)
    }

    @discardableResult
    public func loadCity(at url: URL) -> Bool {
        mp_load_city(handle, url.path) != 0
    }

    public func tick() {
        mp_tick(handle)
    }

    public var funds: Int {
        Int(mp_total_funds(handle))
    }

    public var year: Int {
        Int(mp_city_year(handle))
    }

    public var month: Int {
        Int(mp_city_month(handle))
    }

    public var population: Int {
        Int(mp_city_pop(handle))
    }

    public var score: Int {
        Int(mp_city_score(handle))
    }

    public var cityClass: Int {
        Int(mp_city_class(handle))
    }

    public var tax: Int {
        Int(mp_city_tax(handle))
    }

    public func setTax(_ tax: Int) {
        mp_set_city_tax(handle, Int32(tax))
    }

    public func tile(x: Int, y: Int) -> UInt16 {
        mp_map(handle)[x * Engine.height + y]
    }

    public func mapSnapshot() -> [UInt16] {
        let ptr = mp_map(handle)
        let count = Engine.width * Engine.height
        return Array(UnsafeBufferPointer(start: ptr, count: count))
    }

    public func getDemands() -> (residential: Float, commercial: Float, industrial: Float) {
        var r: Float = 0, c: Float = 0, i: Float = 0
        mp_get_demands(handle, &r, &c, &i)
        return (r, c, i)
    }

    public var roadPercent: Float {
        mp_road_percent(handle)
    }

    public var policePercent: Float {
        mp_police_percent(handle)
    }

    public var firePercent: Float {
        mp_fire_percent(handle)
    }

    public func setRoadPercent(_ p: Float) {
        mp_set_road_percent(handle, p)
    }

    public func setPolicePercent(_ p: Float) {
        mp_set_police_percent(handle, p)
    }

    public func setFirePercent(_ p: Float) {
        mp_set_fire_percent(handle, p)
    }

    public func setFunds(_ funds: Int) {
        mp_set_funds(handle, Int(funds))
    }

    public func setPasses(_ passes: Int) {
        mp_set_passes(handle, Int32(passes))
    }

    public func setSpeed(_ speed: Int) {
        mp_set_speed(handle, Int32(speed))
    }

    public func pause() {
        mp_pause(handle)
    }

    public func resume() {
        mp_resume(handle)
    }

    public var isPaused: Bool {
        mp_is_paused(handle) != 0
    }

    public func setAutoBudget(_ enable: Bool) {
        mp_set_auto_budget(handle, enable ? 1 : 0)
    }

    public func setAutoBulldoze(_ enable: Bool) {
        mp_set_auto_bulldoze(handle, enable ? 1 : 0)
    }

    public func setEnableDisasters(_ enable: Bool) {
        mp_set_enable_disasters(handle, enable ? 1 : 0)
    }

    public func generateMap(seed: Int) {
        mp_generate_map(handle, Int32(seed))
    }

    public func apply(_ tool: Tool, x: Int, y: Int) -> ToolResult {
        let result = mp_do_tool(handle, Int32(tool.rawValue), Int32(x), Int32(y))
        return ToolResult(rawValue: result) ?? .failed
    }

    public func saveCity(at url: URL) -> Bool {
        mp_save_city(handle, url.path) != 0
    }

    public func makeDisaster(_ which: Int) {
        mp_make_disaster(handle, Int32(which))
    }

    public func sprites() -> [Sprite] {
        var buffer = [MPSprite](repeating: MPSprite(type: 0, frame: 0, x: 0, y: 0, xHot: 0, yHot: 0), count: 64)
        let count = Int(mp_get_sprites(handle, &buffer, 64))
        return buffer.prefix(count).map { Sprite(type: Int($0.type), frame: Int($0.frame), x: Int($0.x), y: Int($0.y), xHot: Int($0.xHot), yHot: Int($0.yHot)) }
    }

    public func history(_ kind: HistoryKind) -> [Int] {
        var buffer = [Int16](repeating: 0, count: 480)
        mp_get_history(handle, Int32(kind.rawValue), &buffer)
        return buffer.map { Int($0) }
    }
}
