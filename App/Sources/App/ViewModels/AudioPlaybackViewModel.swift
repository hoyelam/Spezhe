import Foundation
import AVFoundation
import Combine

@MainActor
public final class AudioPlaybackViewModel: ObservableObject {
    @Published public private(set) var isPlaying = false
    @Published public private(set) var currentTime: TimeInterval = 0
    @Published public private(set) var duration: TimeInterval = 0
    @Published public private(set) var progress: Double = 0
    @Published public private(set) var waveformSamples: [Float] = []

    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    private let recording: Recording

    public init(recording: Recording) {
        self.recording = recording
        self.duration = recording.duration
        loadAudio()
    }

    private func loadAudio() {
        let fileURL = AudioFileManager.shared.audioURL(for: recording.audioFileName)

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            logError("Audio file not found: \(recording.audioFileName)", category: .audio)
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: fileURL)
            audioPlayer?.prepareToPlay()
            audioPlayer?.delegate = AudioPlayerDelegateHandler.shared
            duration = audioPlayer?.duration ?? recording.duration

            AudioPlayerDelegateHandler.shared.onPlaybackFinished = { [weak self] in
                Task { @MainActor in
                    self?.handlePlaybackFinished()
                }
            }

            waveformSamples = AudioFileManager.shared.loadWaveformSamples(from: recording.audioFileName)

            logInfo("Audio loaded: \(recording.audioFileName), duration: \(duration)s", category: .audio)
        } catch {
            logError("Failed to load audio: \(error)", category: .audio)
        }
    }

    public func togglePlayback() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    public func play() {
        guard let player = audioPlayer else { return }

        player.play()
        isPlaying = true
        startTimer()
        logDebug("Playback started", category: .audio)
    }

    public func pause() {
        audioPlayer?.pause()
        isPlaying = false
        stopTimer()
        logDebug("Playback paused at \(currentTime)s", category: .audio)
    }

    public func stop() {
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
        isPlaying = false
        currentTime = 0
        progress = 0
        stopTimer()
        logDebug("Playback stopped", category: .audio)
    }

    public func skip(seconds: TimeInterval) {
        let newTime = max(0, min(duration, currentTime + seconds))
        seek(to: newTime)
    }

    public func seek(to time: TimeInterval) {
        let clampedTime = max(0, min(duration, time))
        audioPlayer?.currentTime = clampedTime
        currentTime = clampedTime
        progress = duration > 0 ? clampedTime / duration : 0
        logDebug("Seek to \(clampedTime)s", category: .audio)
    }

    public func seek(toProgress newProgress: Double) {
        let clampedProgress = max(0, min(1, newProgress))
        seek(to: clampedProgress * duration)
    }

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateProgress()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func updateProgress() {
        guard let player = audioPlayer else { return }
        currentTime = player.currentTime
        progress = duration > 0 ? currentTime / duration : 0
    }

    private func handlePlaybackFinished() {
        isPlaying = false
        stopTimer()
        currentTime = duration
        progress = 1
        logDebug("Playback finished", category: .audio)
    }

}

private final class AudioPlayerDelegateHandler: NSObject, AVAudioPlayerDelegate, @unchecked Sendable {
    @MainActor static let shared = AudioPlayerDelegateHandler()

    @MainActor var onPlaybackFinished: (() -> Void)?

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            AudioPlayerDelegateHandler.shared.onPlaybackFinished?()
        }
    }
}
