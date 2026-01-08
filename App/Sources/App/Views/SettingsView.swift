import SwiftUI
import KeyboardShortcuts

public struct SettingsView: View {
    @StateObject private var settingsViewModel = SettingsViewModel()
    @StateObject private var modelViewModel = ModelDownloadViewModel()
    @EnvironmentObject private var recordingViewModel: RecordingViewModel

    public init() {}

    public var body: some View {
        TabView {
            GeneralSettingsTab(viewModel: settingsViewModel)
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            ModelSelectionView(viewModel: modelViewModel, selectedModelName: $settingsViewModel.selectedModelName)
                .tabItem {
                    Label("Models", systemImage: "cpu")
                }

            PermissionsTab(viewModel: settingsViewModel)
                .tabItem {
                    Label("Permissions", systemImage: "lock.shield")
                }
        }
        .frame(width: 500, height: 400)
        .onChange(of: settingsViewModel.selectedModelName) { _, _ in
            settingsViewModel.saveSettings()
            Task {
                await recordingViewModel.reloadModel()
            }
        }
        .onChange(of: settingsViewModel.autoPasteEnabled) { _, _ in
            settingsViewModel.saveSettings()
        }
    }
}

struct GeneralSettingsTab: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Form {
            Section {
                KeyboardShortcuts.Recorder("Toggle Recording:", name: .toggleRecording)
            } header: {
                Text("Keyboard Shortcut")
            }

            Section {
                Toggle("Auto-paste transcription", isOn: $viewModel.autoPasteEnabled)

                if viewModel.autoPasteEnabled && !viewModel.isAccessibilityEnabled {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Accessibility permission required for auto-paste")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("Behavior")
            }

            Section {
                LabeledContent("Selected Model") {
                    Text(AppSettings.shared.selectedModel.displayName)
                }
            } header: {
                Text("Current Settings")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct PermissionsTab: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Form {
            Section {
                HStack {
                    Text("Microphone Access")
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Granted")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Accessibility Access")
                    Spacer()
                    if viewModel.isAccessibilityEnabled {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Granted")
                            .foregroundColor(.secondary)
                    } else {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                        Text("Not Granted")
                            .foregroundColor(.secondary)
                    }
                }

                if !viewModel.isAccessibilityEnabled {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Accessibility access is required for auto-paste functionality.")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Button("Open System Preferences") {
                            viewModel.openAccessibilityPreferences()
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text("Permissions")
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            viewModel.refreshAccessibilityStatus()
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(RecordingViewModel())
}
