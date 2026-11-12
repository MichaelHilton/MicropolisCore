import Foundation

enum Assets {
    static var root: URL {
        resourceRoot(in: Bundle.module.resourceURL!)
    }

    /// Xcode nests the copied folder inside its resource directory; SwiftPM
    /// can use that folder itself as the bundle's resource directory.
    static func resourceRoot(in directory: URL) -> URL {
        let nested = directory.appendingPathComponent("Resources")
        if FileManager.default.fileExists(atPath: nested.appendingPathComponent("tiles/classic.png").path) {
            return nested
        }
        return directory
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
