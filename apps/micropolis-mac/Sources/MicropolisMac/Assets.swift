import Foundation

enum Assets {
    static var root: URL {
        Bundle.module.resourceURL!.appendingPathComponent("Resources")
    }

    static func city(_ name: String) -> URL {
        root.appendingPathComponent("cities/\(name).cty")
    }

    static var allCities: [URL] {
        let citiesDir = root.appendingPathComponent("cities")
        let fileManager = FileManager.default
        guard let files = try? fileManager.contentsOfDirectory(at: citiesDir, includingPropertiesForKeys: nil) else {
            return []
        }
        return files.filter { $0.pathExtension == "cty" }.sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    static var tileAtlas: URL {
        root.appendingPathComponent("tiles/classic.png")
    }

    static func spriteSheet(_ name: String) -> URL {
        root.appendingPathComponent("sprites/classic-sprite-\(name).png")
    }

    static func sound(_ name: String) -> URL? {
        let soundsDir = root.appendingPathComponent("sounds")
        let fileManager = FileManager.default
        let soundFile = soundsDir.appendingPathComponent("\(name).mp3")
        guard fileManager.fileExists(atPath: soundFile.path) else {
            return nil
        }
        return soundFile
    }
}
