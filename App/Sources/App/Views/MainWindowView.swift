import SwiftUI

public struct MainWindowView: View {
    @ObservedObject var viewModel: RecordingViewModel
    @StateObject private var recordingsStore = RecordingRepository.shared
    @State private var selectedRecordingID: Int64?
    @State private var showInspector = false
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    public init(viewModel: RecordingViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            RecordingsSidebarView(
                recordings: recordingsStore.recordings,
                selectedID: $selectedRecordingID,
                viewModel: viewModel,
                onDelete: deleteRecording
            )
            .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 300)
            .navigationTitle("Recordings")
        } detail: {
            if let id = selectedRecordingID,
               let recording = recordingsStore.recordings.first(where: { $0.id == id }) {
                RecordingDetailView(recording: recording, onTitleChange: { newTitle in
                    updateRecordingTitle(id: id, newTitle: newTitle)
                })
            } else {
                EmptyStateView()
            }
        }
        .inspector(isPresented: $showInspector) {
            if let id = selectedRecordingID,
               let recording = recordingsStore.recordings.first(where: { $0.id == id }) {
                RecordingInspectorView(recording: recording)
            } else {
                Text("No Recording Selected")
                    .foregroundStyle(.secondary)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                RecordButtonToolbar(viewModel: viewModel)

                Button {
                    showInspector.toggle()
                } label: {
                    Image(systemName: "sidebar.right")
                }
                .help(showInspector ? "Hide Inspector" : "Show Inspector")
            }
        }
        .onReceive(viewModel.$newRecordingID) { newID in
            if let id = newID {
                selectedRecordingID = id
            }
        }
    }

    private func deleteRecording(_ recording: Recording) {
        do {
            try AudioFileManager.shared.deleteAudio(fileName: recording.audioFileName)
            try RecordingRepository.shared.delete(recording)

            if selectedRecordingID == recording.id {
                selectedRecordingID = nil
            }
        } catch {
            logError("Failed to delete recording: \(error)", category: .app)
        }
    }

    private func updateRecordingTitle(id: Int64, newTitle: String) {
        guard var recording = recordingsStore.recordings.first(where: { $0.id == id }) else { return }
        recording.title = newTitle
        do {
            try RecordingRepository.shared.update(recording)
        } catch {
            logError("Failed to update recording title: \(error)", category: .app)
        }
    }
}

struct RecordButtonToolbar: View {
    @ObservedObject var viewModel: RecordingViewModel

    var body: some View {
        Button {
            Task {
                await viewModel.toggleRecording()
            }
        } label: {
            Label(
                viewModel.state.isRecording ? "Stop" : "Record",
                systemImage: viewModel.state.isRecording ? "stop.circle.fill" : "record.circle"
            )
        }
        .tint(viewModel.state.isRecording ? .red : nil)
        .disabled(viewModel.state.isProcessing)
        .help(viewModel.state.isRecording ? "Stop Recording (⌘⌃1)" : "Start Recording (⌘⌃1)")
    }
}

#Preview {
    MainWindowView(viewModel: RecordingViewModel())
}
