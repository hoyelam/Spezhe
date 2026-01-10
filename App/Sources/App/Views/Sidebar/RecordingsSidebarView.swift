import SwiftUI
import KeyboardShortcuts

public struct RecordingsSidebarView: View {
    let recordings: [Recording]
    @Binding var selectedID: Int64?
    @EnvironmentObject private var viewModel: RecordingViewModel
    let onDelete: (Recording) -> Void

    public init(
        recordings: [Recording],
        selectedID: Binding<Int64?>,
        onDelete: @escaping (Recording) -> Void
    ) {
        self.recordings = recordings
        self._selectedID = selectedID
        self.onDelete = onDelete
    }

    public var body: some View {
        List(selection: $selectedID) {
            ForEach(recordings) { recording in
                RecordingRowView(recording: recording)
                    .tag(recording.id)
                    .contextMenu {
                        Button(role: .destructive) {
                            onDelete(recording)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
            .onDelete(perform: deleteRecordings)
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                Divider()
                VStack(spacing: 8) {
                    RecordButtonCircular()
                    ToggleRecordingShortcutBadge()
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.secondaryBackground)
            }
        }
    }

    private func deleteRecordings(at offsets: IndexSet) {
        for index in offsets {
            let recording = recordings[index]
            onDelete(recording)
        }
    }
}
