import AppKit

/// Available system sounds for feedback
public enum SystemSoundName: String, CaseIterable, Identifiable {
    case tink = "Tink"
    case pop = "Pop"
    case glass = "Glass"
    case ping = "Ping"
    case blow = "Blow"
    case bottle = "Bottle"
    case frog = "Frog"
    case funk = "Funk"
    case hero = "Hero"
    case morse = "Morse"
    case purr = "Purr"
    case sosumi = "Sosumi"
    case submarine = "Submarine"
    case basso = "Basso"

    public var id: String { rawValue }

    public var displayName: String { rawValue }
}

@MainActor
public final class SoundFeedbackService {
    public static let shared = SoundFeedbackService()

    private let settings = AppSettings.shared
    private var cachedSounds: [String: NSSound] = [:]

    private init() {
        precacheSounds()
    }

    private func precacheSounds() {
        for soundName in SystemSoundName.allCases {
            if let sound = NSSound(named: soundName.rawValue) {
                cachedSounds[soundName.rawValue] = sound
            }
        }
    }

    public func playRecordingStartSound() {
        guard settings.soundFeedbackEnabled else { return }
        playSound(named: settings.recordingStartSound)
    }

    public func playRecordingStopSound() {
        guard settings.soundFeedbackEnabled else { return }
        playSound(named: settings.recordingStopSound)
    }

    public func previewSound(named soundName: String) {
        playSound(named: soundName)
    }

    private func playSound(named name: String) {
        if let cached = cachedSounds[name] {
            cached.stop()
            cached.play()
        } else if let sound = NSSound(named: name) {
            cachedSounds[name] = sound
            sound.play()
        }
    }
}
