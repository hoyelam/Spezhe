import SwiftUI

struct ProfilesSettingsTab: View {
    @StateObject private var viewModel = ProfilesViewModel()
    private let featureFlags = FeatureFlagService.shared
    @State private var profileToDelete: TranscriptionProfile?
    @State private var showDeleteConfirmation = false

    var body: some View {
        Group {
            if featureFlags.profilesEnabled {
                profilesForm
            } else {
                EmptyView()
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private var profilesForm: some View {
        Form {
            Section {
                if viewModel.profiles.isEmpty {
                    Text(L10n.Profiles.noProfilesCreated)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                } else {
                    ForEach(viewModel.profiles) { profile in
                        ProfileRow(
                            profile: profile,
                            isActive: profile.id == viewModel.activeProfileId,
                            onSelect: { viewModel.setActiveProfile(profile) },
                            onEdit: { viewModel.editProfile(profile) },
                            onDelete: {
                                profileToDelete = profile
                                showDeleteConfirmation = true
                            }
                        )
                    }
                }
            } header: {
                HStack {
                    Text(L10n.Profiles.header)
                    Spacer()
                    Button(action: viewModel.createNewProfile) {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.borderless)
                }
            } footer: {
                if !viewModel.profiles.isEmpty {
                    Text(L10n.Profiles.footerDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Section {
                HStack {
                    Text(L10n.Profiles.activeProfile)
                    Spacer()
                    Picker("", selection: Binding(
                        get: { viewModel.activeProfileId },
                        set: { id in
                            if let id = id {
                                viewModel.setActiveProfile(viewModel.profiles.first { $0.id == id })
                            } else {
                                viewModel.setActiveProfile(nil)
                            }
                        }
                    )) {
                        Text(L10n.Profiles.noneUseDefaults).tag(nil as Int64?)
                        ForEach(viewModel.profiles) { profile in
                            Text(profile.name).tag(profile.id as Int64?)
                        }
                    }
                    .labelsHidden()
                    .frame(maxWidth: 200)
                }
            } header: {
                Text(L10n.Profiles.quickSelectionHeader)
            }

            if let error = viewModel.errorMessage {
                Section {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
        }
        .sheet(item: $viewModel.editingProfile) { profile in
            ProfileEditorView(
                profile: profile,
                onSave: viewModel.saveProfile
            )
        }
        .alert(L10n.Profiles.deleteProfileTitle, isPresented: $showDeleteConfirmation, presenting: profileToDelete) { profile in
            Button(L10n.Common.delete, role: .destructive) {
                viewModel.deleteProfile(profile)
            }
            Button(L10n.Common.cancel, role: .cancel) {}
        } message: { profile in
            Text(L10n.Profiles.deleteProfileMessage(profile.name))
        }
    }

}

struct ProfileRow: View {
    let profile: TranscriptionProfile
    let isActive: Bool
    let onSelect: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(profile.name)
                        .fontWeight(isActive ? .semibold : .regular)

                    if isActive {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.accentColor)
                            .font(.caption)
                    }
                }

                HStack(spacing: 8) {
                    if let language = profile.language, language != "auto" {
                        Label(SupportedLanguage.find(byId: language)?.name ?? language, systemImage: "globe")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if let modelName = profile.modelName {
                        Label(WhisperModel.model(named: modelName)?.displayName ?? modelName, systemImage: "cpu")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if profile.customPrompt != nil {
                        Label(L10n.Profiles.aiPromptLabel, systemImage: "sparkles")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            HStack(spacing: 8) {
                if !isActive {
                    Button(L10n.Common.use) {
                        onSelect()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                Button {
                    onEdit()
                } label: {
                    Image(systemName: "pencil")
                }
                .buttonStyle(.borderless)

                Button {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .foregroundColor(.red)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ProfilesSettingsTab()
        .frame(width: 500, height: 400)
}
