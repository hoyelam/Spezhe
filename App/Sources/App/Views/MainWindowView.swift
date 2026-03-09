import SwiftUI

public struct MainWindowView: View {
    @EnvironmentObject private var viewModel: RecordingViewModel
    @EnvironmentObject private var recordingsStore: RecordingRepository
    @State private var selectedRecordingID: Int64?
    @State private var showInspector = false
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var showOnboarding = !UserDefaults.standard.bool(
        forKey: Constants.UserDefaultsKeys.hasCompletedOnboarding
    )

    public init() {}

    public var body: some View {
        splitView
    }

    private var splitView: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebarView
        } detail: {
            detailView
        }
        .inspector(isPresented: $showInspector) {
            inspectorContent
        }
        .toolbar {
            toolbarContent
        }
        .onChange(of: viewModel.newRecordingID) { _, newID in
            if let id = newID {
                selectedRecordingID = id
            }
        }
        .onChange(of: recordingsStore.recordings) { _, updatedRecordings in
            guard let selectedID = selectedRecordingID else { return }
            if updatedRecordings.first(where: { $0.id == selectedID }) == nil {
                selectedRecordingID = nil
            }
        }
        .alert(L10n.Alerts.downloadModelTitle, isPresented: $viewModel.showDownloadConfirmation) {
            Button(L10n.Common.download) {
                Task {
                    await viewModel.confirmDownload()
                }
            }
            Button(L10n.Alerts.useBaseModel, role: .cancel) {
                viewModel.declineDownload()
            }
        } message: {
            if let model = viewModel.pendingDownloadModel {
                Text(L10n.Alerts.downloadModelMessageFull(model.displayName, model.sizeDescription))
            }
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView(isPresented: $showOnboarding)
                .interactiveDismissDisabled()
        }
    }

    private var sidebarView: some View {
        RecordingsSidebarView(
            recordings: recordingsStore.recordings,
            selectedID: $selectedRecordingID,
            onDelete: deleteRecording
        )
        .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 300)
        .navigationTitle(L10n.MainWindow.recordingsTitle)
    }

    @ViewBuilder
    private var detailView: some View {
        if let recording = selectedRecording {
#if DEBUG
            let forceUnavailable = recording.id == recordingsStore.recordings.last?.id
#else
            let forceUnavailable = false
#endif
            RecordingDetailView(recording: recording, onTitleChange: { newTitle in
                updateRecordingTitle(id: recording.id, newTitle: newTitle)
            }, forceUnavailable: forceUnavailable)
            .id(recording.id)
        } else {
            EmptyStateView()
        }
    }

    @ViewBuilder
    private var inspectorContent: some View {
        if let recording = selectedRecording {
            RecordingInspectorView(recording: recording)
        } else {
            Text(L10n.Inspector.noRecordingSelected)
                .foregroundStyle(.secondary)
        }
    }

    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            RecordButtonToolbar()

            Button {
                showInspector.toggle()
            } label: {
                Image(systemName: "sidebar.right")
            }
            .help(showInspector ? L10n.MainWindow.hideInspector : L10n.MainWindow.showInspector)
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

    private var selectedRecording: Recording? {
        guard let id = selectedRecordingID else { return nil }
        return recordingsStore.recordings.first(where: { $0.id == id })
    }

    private func updateRecordingTitle(id: Int64?, newTitle: String) {
        guard let id,
              var recording = recordingsStore.recordings.first(where: { $0.id == id }) else { return }
        recording.title = newTitle
        do {
            try RecordingRepository.shared.update(recording)
        } catch {
            logError("Failed to update recording title: \(error)", category: .app)
        }
    }
}

struct RecordButtonToolbar: View {
    @EnvironmentObject private var viewModel: RecordingViewModel

    var body: some View {
        Button {
            Task {
                await viewModel.toggleRecording(source: .mainWindowButton)
            }
        } label: {
            Label(
                viewModel.state.isRecording ? L10n.MainWindow.stopRecording : L10n.MainWindow.record,
                systemImage: viewModel.state.isRecording ? "stop.circle.fill" : "record.circle"
            )
        }
        .tint(viewModel.state.isRecording ? .accentColor : nil)
        .disabled(viewModel.state.isProcessing)
        .help(viewModel.state.isRecording ? L10n.MainWindow.stopTooltip("⌘⌃1") : L10n.MainWindow.recordTooltip("⌘⌃1"))
    }
}

#Preview {
    MainWindowView()
        .environmentObject(RecordingViewModel())
        .environmentObject(RecordingRepository.shared)
}

#Preview("Split View Selection") {
    SplitViewSelectionPreview()
}

private struct SplitViewSelectionPreview: View {
    @State private var selectedRecordingID: Int64? = 1

    private let recordings: [Recording] = [
        Recording(
            id: 1,
            title: "Design Notes",
            transcriptionText: "Preview text for the first recording.",
            audioFileName: "preview-1.wav",
            createdAt: Date(),
            duration: 142,
            detectedLanguage: "en",
            wordCount: 6,
            modelUsed: "base",
            fileSize: 1_024
        ),
        Recording(
            id: 2,
            title: "Team Standup",
            transcriptionText: "Preview text for the second recording.",
            audioFileName: "preview-2.wav",
            createdAt: Date(),
            duration: 88,
            detectedLanguage: "en",
            wordCount: 5,
            modelUsed: "base",
            fileSize: 2_048
        )
    ]

    var body: some View {
        NavigationSplitView {
            List(recordings, selection: $selectedRecordingID) { recording in
                Text(recording.title)
                    .tag(recording.id)
            }
            .listStyle(.sidebar)
        } detail: {
            if let recording = recordings.first(where: { $0.id == selectedRecordingID }) {
                RecordingDetailView(recording: recording, onTitleChange: { _ in })
                    .id(recording.id)
            } else {
                Text("Select a recording")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 900, height: 500)
        .environmentObject(RecordingViewModel())
    }
}
