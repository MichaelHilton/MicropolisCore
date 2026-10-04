import Testing
@testable import MicropolisMac

struct BresenhamTests {
    @Test
    func lineFromOriginTo4And2() {
        let line = Bresenham.line(from: (0, 0), to: (4, 2))

        #expect(line.count > 0)
        #expect(line.first?.x == 0)
        #expect(line.first?.y == 0)
        #expect(line.last?.x == 4)
        #expect(line.last?.y == 2)

        // Line should be contiguous (each step moves at most 1 in x or y)
        for i in 1..<line.count {
            let prev = line[i - 1]
            let curr = line[i]
            let dx = abs(curr.x - prev.x)
            let dy = abs(curr.y - prev.y)
            #expect(dx + dy <= 2)  // At most one diagonal or one orthogonal step
        }
    }

    @Test
    func lineSinglePoint() {
        let line = Bresenham.line(from: (5, 5), to: (5, 5))
        #expect(line.count == 1)
        #expect(line[0].x == 5)
        #expect(line[0].y == 5)
    }

    @Test
    func lineHorizontal() {
        let line = Bresenham.line(from: (0, 0), to: (5, 0))
        #expect(line.count == 6)  // Includes both endpoints
        #expect(line.map { $0.y }.allSatisfy { $0 == 0 })
    }

    @Test
    func lineVertical() {
        let line = Bresenham.line(from: (0, 0), to: (0, 5))
        #expect(line.count == 6)  // Includes both endpoints
        #expect(line.map { $0.x }.allSatisfy { $0 == 0 })
    }
}
