import SwiftUI
import KeyboardShortcuts

public struct SettingsView: View {
    @StateObject private var settingsViewModel = SettingsViewModel()
    @StateObject private var modelViewModel = ModelDownloadViewModel()
    @EnvironmentObject private var recordingViewModel: RecordingViewModel
    private let featureFlags = FeatureFlagService.shared

    public init() {}

    public var body: some View {
        TabView {
            GeneralSettingsTab(viewModel: settingsViewModel)
                .tabItem {
                    Label(L10n.Settings.Tabs.general, systemImage: "gear")
                }

            ModelSelectionView(viewModel: modelViewModel, selectedModelName: $settingsViewModel.selectedModelName)
                .tabItem {
                    Label(L10n.Settings.Tabs.models, systemImage: "cpu")
                }

            if featureFlags.profilesEnabled {
                ProfilesSettingsTab()
                    .tabItem {
                        Label(L10n.Settings.Tabs.profiles, systemImage: "person.crop.rectangle.stack")
                    }
            }

            PermissionsTab(viewModel: settingsViewModel)
                .tabItem {
                    Label(L10n.Settings.Tabs.permissions, systemImage: "lock.shield")
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
        .onChange(of: settingsViewModel.recordingStorageLimitGB) { _, _ in
            settingsViewModel.saveSettings()
            RecordingRetentionService.shared.enforceLimit()
        }
    }
}

struct GeneralSettingsTab: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Form {
            Section {
                KeyboardShortcuts.Recorder(L10n.Settings.General.toggleRecording, name: .toggleRecording)
            } header: {
                Text(L10n.Settings.General.keyboardShortcutHeader)
            }

            Section {
                Toggle(L10n.Settings.General.autoPasteToggle, isOn: $viewModel.autoPasteEnabled)

                if viewModel.autoPasteEnabled && !viewModel.isAccessibilityEnabled {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(L10n.Settings.General.autoPasteAccessibilityWarning)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text(L10n.Settings.General.behaviorHeader)
            }

            Section {
                Toggle(L10n.Settings.General.soundFeedbackToggle, isOn: $viewModel.soundFeedbackEnabled)

                if viewModel.soundFeedbackEnabled {
                    HStack {
                        Text(L10n.Settings.General.startSound)
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
                        .help(L10n.Settings.General.previewSoundHelp)
                    }

                    HStack {
                        Text(L10n.Settings.General.stopSound)
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
                        .help(L10n.Settings.General.previewSoundHelp)
                    }
                }
            } header: {
                Text(L10n.Settings.General.soundFeedbackHeader)
            }

            Section {
                Stepper(
                    L10n.Settings.General.storageLimitStepper(viewModel.recordingStorageLimitGB),
                    value: $viewModel.recordingStorageLimitGB,
                    in: 1...12
                )

                Text(L10n.Settings.General.storageLimitDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                Text(L10n.Settings.General.storageHeader)
            }

            Section {
                LabeledContent(L10n.Settings.General.selectedModel) {
                    Text(AppSettings.shared.selectedModel.displayName)
                }
            } header: {
                Text(L10n.Settings.General.currentSettingsHeader)
            }

            Section {
                Toggle(L10n.Settings.General.analyticsToggle, isOn: $viewModel.analyticsEnabled)
            } header: {
                Text(L10n.Settings.General.privacyHeader)
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
                    Text(L10n.Settings.Permissions.microphoneAccess)
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(L10n.Common.granted)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text(L10n.Settings.Permissions.accessibilityAccess)
                    Spacer()
                    if viewModel.isAccessibilityEnabled {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(L10n.Common.granted)
                            .foregroundColor(.secondary)
                    } else {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                        Text(L10n.Common.notGranted)
                            .foregroundColor(.secondary)
                    }
                }

                if !viewModel.isAccessibilityEnabled {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(L10n.Settings.Permissions.accessibilityDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Button(L10n.Settings.Permissions.openSystemPreferences) {
                            viewModel.openAccessibilityPreferences()
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text(L10n.Settings.Permissions.header)
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
