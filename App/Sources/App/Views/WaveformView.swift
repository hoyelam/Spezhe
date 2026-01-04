import SwiftUI

public struct WaveformView: View {
    let level: Float
    let barCount: Int

    public init(level: Float, barCount: Int = 12) {
        self.level = level
        self.barCount = barCount
    }

    public var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(barColor(for: index))
                    .frame(width: 4)
                    .frame(height: barHeight(for: index))
                    .animation(.easeOut(duration: 0.08), value: level)
            }
        }
    }

    private func barHeight(for index: Int) -> CGFloat {
        let baseHeight: CGFloat = 6
        let maxHeight: CGFloat = 36

        let normalizedLevel = CGFloat(level)

        let centerIndex = Double(barCount) / 2.0
        let distanceFromCenter = abs(Double(index) - centerIndex) / centerIndex
        let centerWeight = 1.0 - (distanceFromCenter * 0.5)

        let randomSeed = sin(Double(index) * 1.5 + Double(level) * 10) * 0.5 + 0.5
        let variation = CGFloat(centerWeight * randomSeed)

        let height = baseHeight + (maxHeight - baseHeight) * normalizedLevel * variation
        return max(baseHeight, min(maxHeight, height))
    }

    private func barColor(for index: Int) -> Color {
        let intensity = Double(level)
        if intensity > 0.7 {
            return .orange
        } else if intensity > 0.4 {
            return .green
        } else {
            return .blue
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        WaveformView(level: 0.0)
        WaveformView(level: 0.3)
        WaveformView(level: 0.6)
        WaveformView(level: 0.9)
    }
    .padding()
    .frame(width: 200, height: 200)
}
