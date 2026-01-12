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

            ProfilesSettingsTab()
                .tabItem {
                    Label("Profiles", systemImage: "person.crop.rectangle.stack")
                }

            PermissionsTab(viewModel: settingsViewModel)
                .tabItem {
                    Label("Permissions", systemImage: "lock.shield")
                }
        }
        .frame(width: 500, height: 450)
        .onChange(of: settingsViewModel.selectedModelName) { oldValue, newValue in
            guard oldValue != newValue else { return }
            settingsViewModel.saveSettings()
            Task {
                await recordingViewModel.reloadModelIfNeeded(newValue)
            }
        }
        .onChange(of: settingsViewModel.autoPasteEnabled) { _, _ in
            settingsViewModel.saveSettings()
        }
        .onChange(of: settingsViewModel.analyticsEnabled) { _, _ in
            settingsViewModel.saveSettings()
            AnalyticsService.shared.setEnabled(settingsViewModel.analyticsEnabled)
        }
        .onChange(of: settingsViewModel.soundFeedbackEnabled) { _, _ in
            settingsViewModel.saveSettings()
        }
        .onChange(of: settingsViewModel.recordingStartSound) { _, _ in
            settingsViewModel.saveSettings()
        }
        .onChange(of: settingsViewModel.recordingStopSound) { _, _ in
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
                Toggle("Play sounds when recording", isOn: $viewModel.soundFeedbackEnabled)

                if viewModel.soundFeedbackEnabled {
                    HStack {
                        Text("Start sound")
                        Spacer()
                        Picker("", selection: $viewModel.recordingStartSound) {
                            ForEach(SystemSoundName.allCases) { sound in
                                Text(sound.displayName).tag(sound.rawValue)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 120)

                        Button {
                            SoundFeedbackService.shared.previewSound(named: viewModel.recordingStartSound)
                        } label: {
                            Image(systemName: "speaker.wave.2")
                        }
                        .buttonStyle(.borderless)
                        .help("Preview sound")
                    }

                    HStack {
                        Text("Stop sound")
                        Spacer()
                        Picker("", selection: $viewModel.recordingStopSound) {
                            ForEach(SystemSoundName.allCases) { sound in
                                Text(sound.displayName).tag(sound.rawValue)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 120)

                        Button {
                            SoundFeedbackService.shared.previewSound(named: viewModel.recordingStopSound)
                        } label: {
                            Image(systemName: "speaker.wave.2")
                        }
                        .buttonStyle(.borderless)
                        .help("Preview sound")
                    }
                }
            } header: {
                Text("Sound Feedback")
            }

            Section {
                LabeledContent("Selected Model") {
                    Text(AppSettings.shared.selectedModel.displayName)
                }
            } header: {
                Text("Current Settings")
            }

            Section {
                Toggle("Share anonymous usage analytics", isOn: $viewModel.analyticsEnabled)
            } header: {
                Text("Privacy")
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
