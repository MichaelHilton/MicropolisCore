import Foundation

/// Records delivery to the audio sink without playing sounds during the
/// explicitly enabled inventory UI tests.
final class InventorySoundSink: SoundPlaying {
    var soundEnabled = true
    private(set) var sounds: [String] = []

    func play(soundName: String) {
        if soundEnabled { sounds.append(soundName) }
    }
}
