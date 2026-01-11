import SwiftUI
import KeyboardShortcuts

public struct RecordingPopupView: View {
    @EnvironmentObject private var viewModel: RecordingViewModel
    @StateObject private var settings = AppSettings.shared
    @StateObject private var profilesViewModel = ProfilesViewModel()
    @State private var showProfilePicker = false

    public var body: some View {
        VStack(spacing: 0) {
            // Content area - switches between waveform and loading indicator
            Group {
                if viewModel.state.isLoading {
                    // Loading state - show loading indicator with appropriate message
                    LoadingIndicatorView(state: viewModel.state)
                } else {
                    // Recording state - show waveform
                    WaveformView(level: viewModel.audioLevel, barCount: 40)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Bottom toolbar
            HStack {
                // Left side - Profile/Model selector
                ProfileSelectorButton(
                    activeProfile: profilesViewModel.activeProfile,
                    modelName: settings.selectedModel.displayName,
                    showPicker: $showProfilePicker
                )
                .popover(isPresented: $showProfilePicker, arrowEdge: .bottom) {
                    ProfilePickerPopover(viewModel: profilesViewModel)
                }

                Spacer()

                // Right side - Action buttons (only show during recording)
                if !viewModel.state.isLoading {
                    HStack(spacing: 16) {
                        // Stop button
                        Button {
                            Task {
                                await viewModel.stopRecording()
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Text("Stop")
                                    .font(.system(size: 13))
                                ToggleRecordingShortcutBadge()
                            }
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.primary)

                        // Cancel button
                        Button {
                            Task {
                                await viewModel.cancelRecording()
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Text("Cancel")
                                    .font(.system(size: 13))
                                KeyboardShortcutBadge(keys: ["esc"])
                            }
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.primary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        }
        .frame(width: 420, height: 140)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onReceive(NotificationCenter.default.publisher(for: .cycleProfileShortcut)) { _ in
            guard viewModel.state.isRecording else { return }
            profilesViewModel.cycleToNextProfile()
        }
    }
}

// Loading indicator for model loading or transcribing
struct LoadingIndicatorView: View {
    let state: RecordingState

    private var title: String {
        state.isLoadingModel ? "Loading model..." : "Transcribing..."
    }

    private var subtitle: String {
        state.isLoadingModel ? "Preparing speech recognition" : "Converting speech to text"
    }

    var body: some View {
        HStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.0)
                .progressViewStyle(CircularProgressViewStyle())
                .tint(.accentColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
    }
}

// Keyboard shortcut badge component
struct KeyboardShortcutBadge: View {
    let keys: [String]

    var body: some View {
        HStack(spacing: 2) {
            ForEach(keys, id: \.self) { key in
                Text(key)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(nsColor: .controlBackgroundColor))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            }
        }
    }
}

// Dynamic keyboard shortcut badge that observes settings changes
struct ToggleRecordingShortcutBadge: View {
    @State private var shortcutKeys: [String] = ["⌥", "Space"]

    var body: some View {
        KeyboardShortcutBadge(keys: shortcutKeys)
            .onAppear {
                updateShortcut()
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("KeyboardShortcuts_shortcutByNameDidChange"))) { _ in
                updateShortcut()
            }
    }

    private func updateShortcut() {
        if let shortcut = KeyboardShortcuts.getShortcut(for: .toggleRecording) {
            shortcutKeys = shortcutToKeys(shortcut)
        } else {
            shortcutKeys = ["⌥", "Space"] // Default fallback
        }
    }

    private func shortcutToKeys(_ shortcut: KeyboardShortcuts.Shortcut) -> [String] {
        var keys: [String] = []

        // Add modifier symbols in standard order
        if shortcut.modifiers.contains(.control) {
            keys.append("⌃")
        }
        if shortcut.modifiers.contains(.option) {
            keys.append("⌥")
        }
        if shortcut.modifiers.contains(.shift) {
            keys.append("⇧")
        }
        if shortcut.modifiers.contains(.command) {
            keys.append("⌘")
        }

        // Add the key
        if let key = shortcut.key {
            keys.append(keyToString(key))
        }

        return keys
    }

    private func keyToString(_ key: KeyboardShortcuts.Key) -> String {
        // Map Carbon key codes to characters
        let carbonKeyCodeMap: [Int: String] = [
            // Letters
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
            8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
            16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6",
            23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0",
            30: "]", 31: "O", 32: "U", 33: "[", 34: "I", 35: "P", 37: "L",
            38: "J", 39: "'", 40: "K", 41: ";", 42: "\\", 43: ",", 44: "/",
            45: "N", 46: "M", 47: ".",
            // Special keys
            36: "↩", 48: "⇥", 49: "Space", 51: "⌫", 53: "⎋",
            // Arrow keys
            123: "←", 124: "→", 125: "↓", 126: "↑",
            // Function keys
            122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5", 97: "F6",
            98: "F7", 100: "F8", 101: "F9", 109: "F10", 103: "F11", 111: "F12",
            // Numpad
            82: "0", 83: "1", 84: "2", 85: "3", 86: "4", 87: "5",
            88: "6", 89: "7", 91: "8", 92: "9",
            50: "`"
        ]

        if let character = carbonKeyCodeMap[key.rawValue] {
            return character
        }

        // Fallback for unmapped keys
        return "Key \(key.rawValue)"
    }
}

// Profile selector button for the toolbar
struct ProfileSelectorButton: View {
    let activeProfile: TranscriptionProfile?
    let modelName: String
    @Binding var showPicker: Bool

    var body: some View {
        Button {
            showPicker.toggle()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: activeProfile != nil ? "person.crop.rectangle.stack.fill" : "rectangle.dashed")
                    .font(.system(size: 14))
                    .foregroundColor(activeProfile != nil ? .accentColor : .secondary)

                VStack(alignment: .leading, spacing: 1) {
                    if let profile = activeProfile {
                        Text(profile.name)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.primary)
                        Text(modelName)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    } else {
                        Text("No Profile")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Text(modelName)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }

                Image(systemName: "chevron.down")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(.plain)
    }
}

// Popover for quick profile selection
struct ProfilePickerPopover: View {
    @ObservedObject var viewModel: ProfilesViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Select Profile")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.top, 10)
                .padding(.bottom, 6)

            Divider()

            ScrollView {
                VStack(spacing: 2) {
                    // None option
                    ProfilePickerRow(
                        name: "None (Use Defaults)",
                        isSelected: viewModel.activeProfileId == nil,
                        onSelect: { viewModel.setActiveProfile(nil) }
                    )

                    if !viewModel.profiles.isEmpty {
                        Divider()
                            .padding(.vertical, 4)
                    }

                    ForEach(viewModel.profiles) { profile in
                        ProfilePickerRow(
                            name: profile.name,
                            subtitle: profileSubtitle(for: profile),
                            isSelected: profile.id == viewModel.activeProfileId,
                            onSelect: { viewModel.setActiveProfile(profile) }
                        )
                    }
                }
                .padding(.vertical, 6)
            }
            .frame(maxHeight: 200)

            if viewModel.profiles.isEmpty {
                Divider()
                Text("Create profiles in Settings > Profiles")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
            }
        }
        .frame(width: 220)
    }

    private func profileSubtitle(for profile: TranscriptionProfile) -> String? {
        var parts: [String] = []
        if let lang = profile.language, lang != "auto" {
            parts.append(SupportedLanguage.find(byId: lang)?.name ?? lang)
        }
        if profile.customPrompt != nil {
            parts.append("AI Prompt")
        }
        return parts.isEmpty ? nil : parts.joined(separator: " + ")
    }
}

struct ProfilePickerRow: View {
    let name: String
    var subtitle: String? = nil
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.system(size: 13))
                        .foregroundColor(.primary)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
    }
}

#Preview {
    RecordingPopupView()
        .environmentObject(RecordingViewModel())
        .frame(width: 450, height: 180)
}
