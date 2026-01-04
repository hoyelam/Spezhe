import SwiftUI

public struct RecordingHeaderView: View {
    let recording: Recording
    let onTitleChange: (String) -> Void

    @State private var isEditingTitle = false
    @State private var editedTitle: String = ""
    @FocusState private var isTitleFocused: Bool

    public init(recording: Recording, onTitleChange: @escaping (String) -> Void) {
        self.recording = recording
        self.onTitleChange = onTitleChange
    }

    public var body: some View {
        VStack(alignment: .center, spacing: 8) {
            if isEditingTitle {
                TextField("Title", text: $editedTitle, onCommit: saveTitle)
                    .textFieldStyle(.plain)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                    .focused($isTitleFocused)
                    .onAppear {
                        isTitleFocused = true
                    }
            } else {
                Text(recording.title)
                    .font(.title2.bold())
                    .onTapGesture(count: 2) {
                        editedTitle = recording.title
                        isEditingTitle = true
                    }
            }

            HStack(spacing: 16) {
                Text(recording.createdAt.formatted(date: .abbreviated, time: .shortened))
                Text(formatDuration(recording.duration))
                    .monospacedDigit()
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }

    private func saveTitle() {
        let trimmedTitle = editedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTitle.isEmpty && trimmedTitle != recording.title {
            onTitleChange(trimmedTitle)
        }
        isEditingTitle = false
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let totalSeconds = Int(duration)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
