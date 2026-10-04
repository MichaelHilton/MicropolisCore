import Foundation

enum Bresenham {
    static func line(from start: (x: Int, y: Int), to end: (x: Int, y: Int)) -> [(x: Int, y: Int)] {
        var points: [(x: Int, y: Int)] = []

        var x0 = start.x
        var y0 = start.y
        let x1 = end.x
        let y1 = end.y

        let dx = abs(x1 - x0)
        let dy = abs(y1 - y0)
        let sx = x0 < x1 ? 1 : -1
        let sy = y0 < y1 ? 1 : -1
        var err = dx - dy

        while true {
            points.append((x0, y0))

            if x0 == x1 && y0 == y1 { break }

            let e2 = 2 * err
            if e2 > -dy {
                err -= dy
                x0 += sx
            }
            if e2 < dx {
                err += dx
                y0 += sy
            }
        }

        return points
    }
}
