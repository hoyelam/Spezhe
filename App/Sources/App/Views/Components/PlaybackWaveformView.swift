import SwiftUI

public struct PlaybackWaveformView: View {
    let audioSamples: [Float]
    let currentProgress: Double

    public init(audioSamples: [Float], currentProgress: Double) {
        self.audioSamples = audioSamples
        self.currentProgress = currentProgress
    }

    public var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 2) {
                let barCount = sampleCount(for: geometry.size.width)
                ForEach(0..<barCount, id: \.self) { index in
                    let normalizedIndex = Double(index) / Double(barCount)
                    let sample = sampleValue(at: normalizedIndex)
                    let isPlayed = normalizedIndex <= currentProgress

                    RoundedRectangle(cornerRadius: 1)
                        .fill(isPlayed ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(width: 3, height: barHeight(for: sample, maxHeight: geometry.size.height))
                }
            }
            .frame(maxHeight: .infinity, alignment: .center)
        }
    }

    private func sampleCount(for width: CGFloat) -> Int {
        max(1, Int(width / 5))
    }

    private func sampleValue(at normalizedIndex: Double) -> Float {
        guard !audioSamples.isEmpty else { return 0.1 }

        let sampleIndex = Int(normalizedIndex * Double(audioSamples.count))
        let clampedIndex = min(max(0, sampleIndex), audioSamples.count - 1)
        return audioSamples[clampedIndex]
    }

    private func barHeight(for sample: Float, maxHeight: CGFloat) -> CGFloat {
        let minHeight: CGFloat = 4
        let normalizedSample = min(1.0, abs(sample) * 2)
        return max(minHeight, CGFloat(normalizedSample) * maxHeight * 0.9)
    }
}

#Preview {
    PlaybackWaveformView(
        audioSamples: (0..<100).map { _ in Float.random(in: 0.1...0.8) },
        currentProgress: 0.4
    )
    .frame(height: 60)
    .padding()
}
