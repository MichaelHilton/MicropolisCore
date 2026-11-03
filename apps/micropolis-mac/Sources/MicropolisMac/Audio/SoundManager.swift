import AVFoundation

protocol SoundPlayer: AnyObject {
    var isPlaying: Bool { get }
    @discardableResult func play() -> Bool
}

extension AVAudioPlayer: SoundPlayer {}

/// What the game needs from the sound system, so tests can record sounds
/// instead of playing them.
protocol SoundPlaying: AnyObject {
    var soundEnabled: Bool { get set }
    func play(soundName: String)
}

final class SoundManager: SoundPlaying {
    static let shared = SoundManager()

    typealias DirectoryContents = (URL) -> [URL]?
    typealias PlayerFactory = (URL) throws -> any SoundPlayer
    typealias Logger = (String) -> Void

    private var players: [any SoundPlayer] = []
    private var soundMapping: [String: URL] = [:]
    private var loggedSounds: Set<String> = []
    private let makePlayer: PlayerFactory
    private let log: Logger

    var soundEnabled = true

    init() {
        self.makePlayer = Self.makeAVAudioPlayer
        self.log = { print($0) }
        buildSoundMapping(
            in: Assets.root.appendingPathComponent("sounds"),
            directoryContents: { directory in
                try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            }
        )
    }

    init(
        soundDirectory: URL,
        directoryContents: @escaping DirectoryContents,
        makePlayer: @escaping PlayerFactory,
        log: @escaping Logger
    ) {
        self.makePlayer = makePlayer
        self.log = log
        buildSoundMapping(in: soundDirectory, directoryContents: directoryContents)
    }

    static func makeAVAudioPlayer(url: URL) throws -> any SoundPlayer {
        let player = try AVAudioPlayer(contentsOf: url)
        return player
    }

    private func buildSoundMapping(in soundDirectory: URL, directoryContents: DirectoryContents) {
        guard let files = directoryContents(soundDirectory) else {
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
            log("Sound: \(soundName)")
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
            let player = try makePlayer(url)
            player.play()
            players.append(player)

            // Clean up finished players to avoid memory leak
            players.removeAll { $0.isPlaying == false }
        } catch {
            log("Failed to play sound: \(error)")
        }
    }
}
