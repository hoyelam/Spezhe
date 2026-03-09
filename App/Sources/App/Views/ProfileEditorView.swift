import SwiftUI

struct ProfileEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var useCustomModel: Bool
    @State private var modelName: String
    @State private var useCustomLanguage: Bool
    @State private var language: String
    @StateObject private var modelManager = ModelManagerService.shared

    private let originalProfile: TranscriptionProfile
    private let onSave: (TranscriptionProfile) -> Bool

    private var isNewProfile: Bool {
        originalProfile.id == nil
    }

    private var availableModels: [WhisperModel] {
        let downloaded = modelManager.downloadedModels
        return WhisperModel.availableModels.filter { downloaded.contains($0.name) }
    }

    private var canSelectCustomModel: Bool {
        !availableModels.isEmpty
    }

    private var effectiveModel: WhisperModel? {
        let effectiveModelName = useCustomModel ? modelName : AppSettings.shared.selectedModelName
        return WhisperModel.model(named: effectiveModelName)
    }

    private var showMultilingualWarning: Bool {
        guard useCustomLanguage, language != "en" else { return false }
        return effectiveModel?.isMultilingual == false
    }

    init(profile: TranscriptionProfile, onSave: @escaping (TranscriptionProfile) -> Bool) {
        self.originalProfile = profile
        self.onSave = onSave

        _name = State(initialValue: profile.name)
        _useCustomModel = State(initialValue: profile.modelName != nil)
        _modelName = State(initialValue: profile.modelName ?? WhisperModel.defaultModel.name)
        _useCustomLanguage = State(initialValue: profile.language != nil && profile.language != "auto")
        _language = State(initialValue: profile.language ?? "auto")
    }

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section {
                    TextField(L10n.ProfileEditor.profileNamePlaceholder, text: $name)
                        .textFieldStyle(.roundedBorder)
                } header: {
                    Text(L10n.ProfileEditor.nameHeader)
                }

                Section {
                    Toggle(L10n.ProfileEditor.overrideModelToggle, isOn: $useCustomModel)
                        .disabled(!canSelectCustomModel && !useCustomModel)

                    if useCustomModel {
                        if canSelectCustomModel {
                            Picker(L10n.ProfileEditor.modelLabel, selection: $modelName) {
                                ForEach(availableModels, id: \.name) { model in
                                    HStack {
                                        Text(model.displayName)
                                        Text("(\(model.sizeDescription))")
                                            .foregroundColor(.secondary)
                                    }
                                    .tag(model.name)
                                }
                            }
                            .pickerStyle(.menu)
                        } else {
                            Text(L10n.ProfileEditor.downloadModelHint)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text(L10n.ProfileEditor.whisperModelHeader)
                } footer: {
                    if useCustomModel {
                        Text(L10n.ProfileEditor.modelOverrideDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Section {
                    Toggle(L10n.ProfileEditor.forceLanguageToggle, isOn: $useCustomLanguage)

                    if useCustomLanguage {
                        Picker(L10n.ProfileEditor.languageLabel, selection: $language) {
                            ForEach(SupportedLanguage.all.filter { $0.id != "auto" }, id: \.id) { lang in
                                Text(lang.displayName).tag(lang.id)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                } header: {
                    Text(L10n.ProfileEditor.languageHeader)
                } footer: {
                    VStack(alignment: .leading, spacing: 4) {
                        if useCustomLanguage {
                            Text(L10n.ProfileEditor.languageForceDescription)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text(L10n.ProfileEditor.languageAutoDescription)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        if showMultilingualWarning {
                            HStack(alignment: .top, spacing: 4) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text(L10n.ProfileEditor.multilingualWarning(effectiveModel?.displayName ?? L10n.Common.unknown))
                            }
                            .font(.caption)
                            .foregroundColor(.orange)
                        }
                    }
                }

            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)

            Divider()

            HStack {
                Button(L10n.Common.cancel) {
                    dismiss()
                }
                .keyboardShortcut(.escape, modifiers: [])

                Spacer()

                Button(isNewProfile ? L10n.ProfileEditor.createProfile : L10n.ProfileEditor.saveChanges) {
                    saveProfile()
                }
                .keyboardShortcut(.return, modifiers: [.command])
                .buttonStyle(.borderedProminent)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding()
        }
        .frame(width: 450, height: 520)
        .task {
            await modelManager.refreshDownloadedModels()
            syncModelSelectionIfNeeded()
        }
        .onChange(of: modelManager.downloadedModels) { _, _ in
            syncModelSelectionIfNeeded()
        }
        .onChange(of: useCustomModel) { _, _ in
            syncModelSelectionIfNeeded()
        }
    }

    private func saveProfile() {
        var updatedProfile = originalProfile
        updatedProfile.name = name.trimmingCharacters(in: .whitespaces)
        if useCustomModel, availableModels.contains(where: { $0.name == modelName }) {
            updatedProfile.modelName = modelName
        } else {
            updatedProfile.modelName = nil
        }
        updatedProfile.language = useCustomLanguage ? language : nil
        updatedProfile.updatedAt = Date()

        if onSave(updatedProfile) {
            dismiss()
        }
    }

    private func syncModelSelectionIfNeeded() {
        guard useCustomModel else { return }
        guard let firstAvailable = availableModels.first else { return }
        if !availableModels.contains(where: { $0.name == modelName }) {
            modelName = firstAvailable.name
        }
    }
}

#Preview {
    ProfileEditorView(
        profile: TranscriptionProfile(name: "Test Profile"),
        onSave: { _ in true }
    )
}
