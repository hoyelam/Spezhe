import SwiftUI

struct ProfileEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var useCustomModel: Bool
    @State private var modelName: String
    @State private var useCustomLanguage: Bool
    @State private var language: String
    @State private var useCustomPrompt: Bool
    @State private var customPrompt: String

    private let originalProfile: TranscriptionProfile
    private let onSave: (TranscriptionProfile) -> Bool

    private var isNewProfile: Bool {
        originalProfile.id == nil
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
        _useCustomPrompt = State(initialValue: profile.customPrompt != nil)
        _customPrompt = State(initialValue: profile.customPrompt ?? "")
    }

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section {
                    TextField("Profile Name", text: $name)
                        .textFieldStyle(.roundedBorder)
                } header: {
                    Text("Name")
                }

                Section {
                    Toggle("Override app default model", isOn: $useCustomModel)

                    if useCustomModel {
                        Picker("Model", selection: $modelName) {
                            ForEach(WhisperModel.availableModels, id: \.name) { model in
                                HStack {
                                    Text(model.displayName)
                                    Text("(\(model.sizeDescription))")
                                        .foregroundColor(.secondary)
                                }
                                .tag(model.name)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                } header: {
                    Text("Whisper Model")
                } footer: {
                    if useCustomModel {
                        Text("The selected model will be used instead of the app's default model.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Section {
                    Toggle("Force specific language", isOn: $useCustomLanguage)

                    if useCustomLanguage {
                        Picker("Language", selection: $language) {
                            ForEach(SupportedLanguage.all.filter { $0.id != "auto" }, id: \.id) { lang in
                                Text(lang.displayName).tag(lang.id)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                } header: {
                    Text("Transcription Language")
                } footer: {
                    VStack(alignment: .leading, spacing: 4) {
                        if useCustomLanguage {
                            Text("Forces Whisper to transcribe in the selected language instead of auto-detecting.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Language will be automatically detected from the audio.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        if showMultilingualWarning {
                            HStack(alignment: .top, spacing: 4) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("The \(effectiveModel?.displayName ?? "selected model") model is English-only. Language forcing may not work. Use Large V3, Medium, Small, or Base for multilingual support.")
                            }
                            .font(.caption)
                            .foregroundColor(.orange)
                        }
                    }
                }

                Section {
                    Toggle("Apply custom AI prompt", isOn: $useCustomPrompt)

                    if useCustomPrompt {
                        TextEditor(text: $customPrompt)
                            .frame(minHeight: 80)
                            .font(.system(.body, design: .monospaced))
                            .scrollContentBackground(.hidden)
                            .padding(8)
                            .background(Color(nsColor: .textBackgroundColor))
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                } header: {
                    Text("AI Post-Processing")
                } footer: {
                    if useCustomPrompt {
                        Text("The transcription will be processed with this prompt. Examples: \"Make it professional and fix grammar\" or \"Format as bullet points\"")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)

            Divider()

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape, modifiers: [])

                Spacer()

                Button(isNewProfile ? "Create Profile" : "Save Changes") {
                    saveProfile()
                }
                .keyboardShortcut(.return, modifiers: [.command])
                .buttonStyle(.borderedProminent)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding()
        }
        .frame(width: 450, height: 520)
    }

    private func saveProfile() {
        var updatedProfile = originalProfile
        updatedProfile.name = name.trimmingCharacters(in: .whitespaces)
        updatedProfile.modelName = useCustomModel ? modelName : nil
        updatedProfile.language = useCustomLanguage ? language : nil
        updatedProfile.customPrompt = useCustomPrompt && !customPrompt.trimmingCharacters(in: .whitespaces).isEmpty
            ? customPrompt.trimmingCharacters(in: .whitespaces)
            : nil
        updatedProfile.updatedAt = Date()

        if onSave(updatedProfile) {
            dismiss()
        }
    }
}

#Preview {
    ProfileEditorView(
        profile: TranscriptionProfile(name: "Test Profile"),
        onSave: { _ in true }
    )
}
