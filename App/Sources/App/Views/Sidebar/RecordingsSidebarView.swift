import SwiftUI

public struct RecordingsSidebarView: View {
    let recordings: [Recording]
    @Binding var selectedID: Int64?
    @ObservedObject var viewModel: RecordingViewModel
    let onDelete: (Recording) -> Void

    public init(
        recordings: [Recording],
        selectedID: Binding<Int64?>,
        viewModel: RecordingViewModel,
        onDelete: @escaping (Recording) -> Void
    ) {
        self.recordings = recordings
        self._selectedID = selectedID
        self.viewModel = viewModel
        self.onDelete = onDelete
    }

    public var body: some View {
        VStack(spacing: 0) {
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

            Divider()

            HStack {
                Spacer()
                RecordButtonCircular(viewModel: viewModel)
                Spacer()
            }
            .padding()
            .background(.bar)
        }
    }

    private func deleteRecordings(at offsets: IndexSet) {
        for index in offsets {
            let recording = recordings[index]
            onDelete(recording)
        }
    }
}
