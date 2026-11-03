import Foundation
import Testing
@testable import MicropolisMac

private final class FakeSoundPlayer: SoundPlayer {
    var isPlaying: Bool
    private(set) var playCount = 0

    init(isPlaying: Bool = true) {
        self.isPlaying = isPlaying
    }

    func play() -> Bool {
        playCount += 1
        return true
    }
}

private enum FakeAudioError: Error {
    case cannotCreatePlayer
}

struct SoundManagerTests {
    private let testDirectory = URL(fileURLWithPath: "/sounds")

    private func soundURL(_ name: String, ext: String = "mp3") -> URL {
        URL(fileURLWithPath: "/sounds/\(name).\(ext)")
    }

    @Test
    func indexesOnlyMP3FilesAndPlaysAnExactMatch() {
        let exact = soundURL("HonkHonk")
        let player = FakeSoundPlayer()
        var requestedURLs: [URL] = []
        let manager = SoundManager(
            soundDirectory: testDirectory,
            directoryContents: { _ in [exact, self.soundURL("notes", ext: "txt")] },
            makePlayer: { url in requestedURLs.append(url); return player },
            log: { _ in }
        )

        manager.play(soundName: "HonkHonk")

        #expect(requestedURLs == [exact])
        #expect(player.playCount == 1)
    }

    @Test
    func disabledSoundDoesNotLogOrCreateAPlayer() {
        var factoryCalls = 0
        var logs: [String] = []
        let manager = SoundManager(
            soundDirectory: testDirectory,
            directoryContents: { _ in [self.soundURL("beep")] },
            makePlayer: { _ in factoryCalls += 1; return FakeSoundPlayer() },
            log: { logs.append($0) }
        )
        manager.soundEnabled = false

        manager.play(soundName: "beep")

        #expect(factoryCalls == 0)
        #expect(logs.isEmpty)
    }

    @Test
    func usesTheOnlyPrefixMatchWhenExactNameIsMissing() {
        let prefixMatch = soundURL("HonkHonkHigh")
        var requestedURLs: [URL] = []
        let manager = SoundManager(
            soundDirectory: testDirectory,
            directoryContents: { _ in [prefixMatch] },
            makePlayer: { url in requestedURLs.append(url); return FakeSoundPlayer() },
            log: { _ in }
        )

        manager.play(soundName: "HonkHonk")

        #expect(requestedURLs == [prefixMatch])
    }

    @Test
    func missingSoundDoesNotCreateAPlayerAndLogsOnlyOnce() {
        var factoryCalls = 0
        var logs: [String] = []
        let manager = SoundManager(
            soundDirectory: testDirectory,
            directoryContents: { _ in [] },
            makePlayer: { _ in factoryCalls += 1; return FakeSoundPlayer() },
            log: { logs.append($0) }
        )

        manager.play(soundName: "missing")
        manager.play(soundName: "missing")

        #expect(factoryCalls == 0)
        #expect(logs == ["Sound: missing"])
    }

    @Test
    func discardsAPlayerThatFinishedImmediately() {
        weak var releasedPlayer: FakeSoundPlayer?
        let manager = SoundManager(
            soundDirectory: testDirectory,
            directoryContents: { _ in [self.soundURL("beep")] },
            makePlayer: { _ in
                let player = FakeSoundPlayer(isPlaying: false)
                releasedPlayer = player
                return player
            },
            log: { _ in }
        )

        manager.play(soundName: "beep")

        #expect(releasedPlayer == nil)
    }

    @Test
    func logsPlayerCreationFailure() {
        var logs: [String] = []
        let manager = SoundManager(
            soundDirectory: testDirectory,
            directoryContents: { _ in [self.soundURL("beep")] },
            makePlayer: { _ in throw FakeAudioError.cannotCreatePlayer },
            log: { logs.append($0) }
        )

        manager.play(soundName: "beep")

        #expect(logs.count == 2)
        #expect(logs[0] == "Sound: beep")
        #expect(logs[1].contains("Failed to play sound"))
    }

    @Test
    func unreadableDirectoryProducesNoMappings() {
        var factoryCalls = 0
        let manager = SoundManager(
            soundDirectory: testDirectory,
            directoryContents: { _ in nil },
            makePlayer: { _ in factoryCalls += 1; return FakeSoundPlayer() },
            log: { _ in }
        )

        manager.play(soundName: "beep")

        #expect(factoryCalls == 0)
    }

    @Test
    func defaultPlayerFactoryRejectsANonAudioFile() {
        #expect(throws: Error.self) {
            try SoundManager.makeAVAudioPlayer(url: soundURL("not-audio", ext: "txt"))
        }
    }

    @Test
    func defaultDependenciesLoadAndCreateAPlayerWithoutPlayback() throws {
        let manager = SoundManager()
        manager.soundEnabled = false
        manager.play(soundName: "beep")

        let sound = try #require(Assets.sound("beep"))
        let player = try SoundManager.makeAVAudioPlayer(url: sound)
        #expect(!player.isPlaying)
    }
}
