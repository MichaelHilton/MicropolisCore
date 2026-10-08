import AVFoundation

/// What the game needs from the sound system, so tests can record sounds
/// instead of playing them.
protocol SoundPlaying: AnyObject {
    var soundEnabled: Bool { get set }
    func play(soundName: String)
}

final class SoundManager: SoundPlaying {
    static let shared = SoundManager()

    private var players: [AVAudioPlayer] = []
    private var soundMapping: [String: URL] = [:]
    private var loggedSounds: Set<String> = []

    var soundEnabled = true

    init() {
        buildSoundMapping()
    }

    private func buildSoundMapping() {
        let soundsDir = Assets.root.appendingPathComponent("sounds")
        let fileManager = FileManager.default

        guard let files = try? fileManager.contentsOfDirectory(at: soundsDir, includingPropertiesForKeys: nil) else {
            return
        }

        let audioFiles = files.filter { $0.pathExtension == "mp3" }

        for file in audioFiles {
            let name = file.deletingPathExtension().lastPathComponent
            soundMapping[name] = file
        }
    }

    func play(soundName: String) {
        guard soundEnabled else { return }

        if !loggedSounds.contains(soundName) {
            print("Sound: \(soundName)")
            loggedSounds.insert(soundName)
        }

        // Try exact match first
        if let url = soundMapping[soundName] {
            playSound(url)
            return
        }

        // Try to find by prefix (e.g., "HonkHonk" matches "HonkHonkHigh")
        let possibleFiles = soundMapping.filter { $0.key.hasPrefix(soundName) }
        if let (_, url) = possibleFiles.randomElement() {
            playSound(url)
        }
    }

    private func playSound(_ url: URL) {
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.play()
            players.append(player)

            // Clean up finished players to avoid memory leak
            players.removeAll { $0.isPlaying == false }
        } catch {
            print("Failed to play sound: \(error)")
        }
    }
}
