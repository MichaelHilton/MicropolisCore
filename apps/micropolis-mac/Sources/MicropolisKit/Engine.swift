import Foundation
import MicropolisEngine

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

    public func tile(x: Int, y: Int) -> UInt16 {
        mp_map(handle)[x * Engine.height + y]
    }

    public func mapSnapshot() -> [UInt16] {
        let ptr = mp_map(handle)
        let count = Engine.width * Engine.height
        return Array(UnsafeBufferPointer(start: ptr, count: count))
    }
}
