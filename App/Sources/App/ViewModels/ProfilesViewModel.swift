import Foundation
import Combine

@MainActor
public class ProfilesViewModel: ObservableObject {
    @Published public var profiles: [TranscriptionProfile] = []
    @Published public var activeProfileId: Int64?
    @Published public var editingProfile: TranscriptionProfile?
    @Published public var errorMessage: String?

    private let profileRepository = ProfileRepository.shared
    private let settings = AppSettings.shared
    private var cancellables = Set<AnyCancellable>()

    public init() {
        setupBindings()
    }

    private func setupBindings() {
        profileRepository.$profiles
            .receive(on: DispatchQueue.main)
            .sink { [weak self] profiles in
                self?.profiles = profiles
            }
            .store(in: &cancellables)

        settings.$activeProfileId
            .receive(on: DispatchQueue.main)
            .sink { [weak self] id in
                self?.activeProfileId = id
            }
            .store(in: &cancellables)
    }

    public func createNewProfile() {
        editingProfile = TranscriptionProfile(name: "")
    }

    public func editProfile(_ profile: TranscriptionProfile) {
        editingProfile = profile
    }

    public func saveProfile(_ profile: TranscriptionProfile) -> Bool {
        do {
            var mutableProfile = profile
            if profile.id == nil {
                try profileRepository.insert(&mutableProfile)
                logInfo("Created new profile: \(mutableProfile.name)", category: .app)
            } else {
                try profileRepository.update(mutableProfile)
                logInfo("Updated profile: \(mutableProfile.name)", category: .app)
            }
            errorMessage = nil
            return true
        } catch {
            errorMessage = L10n.Errors.profileSaveFailed(error.localizedDescription)
            logError("Failed to save profile: \(error)", category: .app)
            return false
        }
    }

    public func deleteProfile(_ profile: TranscriptionProfile) {
        do {
            // If deleting the active profile, clear the selection
            if profile.id == activeProfileId {
                setActiveProfile(nil)
            }
            try profileRepository.delete(profile)
            logInfo("Deleted profile: \(profile.name)", category: .app)
            errorMessage = nil
        } catch {
            errorMessage = L10n.Errors.profileDeleteFailed(error.localizedDescription)
            logError("Failed to delete profile: \(error)", category: .app)
        }
    }

    public func setActiveProfile(_ profile: TranscriptionProfile?) {
        settings.activeProfileId = profile?.id
        logInfo("Set active profile: \(profile?.name ?? "None")", category: .app)
    }

    public func cancelEditing() {
        editingProfile = nil
    }

    public var activeProfile: TranscriptionProfile? {
        guard let id = activeProfileId else { return nil }
        return profiles.first { $0.id == id }
    }

    public func cycleToNextProfile() {
        guard !profiles.isEmpty else { return }

        if let currentId = activeProfileId,
           let currentIndex = profiles.firstIndex(where: { $0.id == currentId }) {
            let nextIndex = (currentIndex + 1) % (profiles.count + 1)
            if nextIndex == profiles.count {
                setActiveProfile(nil)
            } else {
                setActiveProfile(profiles[nextIndex])
            }
        } else {
            setActiveProfile(profiles.first)
        }
    }
}
