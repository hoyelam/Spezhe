import SwiftUI

public struct EmptyStateView: View {
    public init() {}

    public var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform.circle")
                .font(.system(size: 64))
                .foregroundStyle(.tertiary)

            Text("No Recording Selected")
                .font(.title2)
                .foregroundColor(.secondary)

            Text("Select a recording from the sidebar or create a new one")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    EmptyStateView()
}
