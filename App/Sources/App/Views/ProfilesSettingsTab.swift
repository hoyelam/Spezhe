import SwiftUI

struct ProfilesSettingsTab: View {
    @StateObject private var viewModel = ProfilesViewModel()
    @State private var profileToDelete: TranscriptionProfile?
    @State private var showDeleteConfirmation = false

    var body: some View {
        Form {
            Section {
                if viewModel.profiles.isEmpty {
                    Text("No profiles created yet")
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
                    Text("Profiles")
                    Spacer()
                    Button(action: viewModel.createNewProfile) {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.borderless)
                }
            } footer: {
                if !viewModel.profiles.isEmpty {
                    Text("Select a profile to use its settings when recording. Choose \"None\" to use app defaults.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Section {
                HStack {
                    Text("Active Profile")
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
                        Text("None (Use Defaults)").tag(nil as Int64?)
                        ForEach(viewModel.profiles) { profile in
                            Text(profile.name).tag(profile.id as Int64?)
                        }
                    }
                    .labelsHidden()
                    .frame(maxWidth: 200)
                }
            } header: {
                Text("Quick Selection")
            }

            if let error = viewModel.errorMessage {
                Section {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .sheet(item: $viewModel.editingProfile) { profile in
            ProfileEditorView(
                profile: profile,
                onSave: viewModel.saveProfile
            )
        }
        .alert("Delete Profile", isPresented: $showDeleteConfirmation, presenting: profileToDelete) { profile in
            Button("Delete", role: .destructive) {
                viewModel.deleteProfile(profile)
            }
            Button("Cancel", role: .cancel) {}
        } message: { profile in
            Text("Are you sure you want to delete \"\(profile.name)\"? This action cannot be undone.")
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
                        Label("AI Prompt", systemImage: "sparkles")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            HStack(spacing: 8) {
                if !isActive {
                    Button("Use") {
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
