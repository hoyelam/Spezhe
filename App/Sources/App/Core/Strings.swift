import Foundation

// MARK: - Localization Constants
// Centralized localization strings using String(localized:) for compile-time safety
// and better organization. All user-facing strings should be defined here.

// swiftlint:disable line_length type_body_length file_length

public enum L10n {
    // MARK: - Common
    public enum Common {
        public static let cancel = String(localized: "common.cancel",
                                          defaultValue: "Cancel",
                                          comment: "Generic cancel button")
        public static let save = String(localized: "common.save",
                                        defaultValue: "Save",
                                        comment: "Generic save button")
        public static let delete = String(localized: "common.delete",
                                          defaultValue: "Delete",
                                          comment: "Generic delete button")
        public static let use = String(localized: "common.use",
                                       defaultValue: "Use",
                                       comment: "Generic use/select button")
        public static let select = String(localized: "common.select",
                                          defaultValue: "Select",
                                          comment: "Generic select button")
        public static let download = String(localized: "common.download",
                                            defaultValue: "Download",
                                            comment: "Generic download button")
        public static let grant = String(localized: "common.grant",
                                         defaultValue: "Grant",
                                         comment: "Grant permission button")
        public static let granted = String(localized: "common.granted",
                                           defaultValue: "Granted",
                                           comment: "Permission granted status")
        public static let notGranted = String(localized: "common.notGranted",
                                              defaultValue: "Not Granted",
                                              comment: "Permission not granted status")
        public static let required = String(localized: "common.required",
                                            defaultValue: "Required",
                                            comment: "Required badge text")
        public static let unknown = String(localized: "common.unknown",
                                           defaultValue: "Unknown",
                                           comment: "Unknown value placeholder")
    }

    // MARK: - Settings
    public enum Settings {
        public enum Tabs {
            public static let general = String(localized: "settings.tabs.general",
                                               defaultValue: "General",
                                               comment: "Settings tab: General")
            public static let models = String(localized: "settings.tabs.models",
                                              defaultValue: "Models",
                                              comment: "Settings tab: Models")
            public static let profiles = String(localized: "settings.tabs.profiles",
                                                defaultValue: "Profiles",
                                                comment: "Settings tab: Profiles")
            public static let permissions = String(localized: "settings.tabs.permissions",
                                                   defaultValue: "Permissions",
                                                   comment: "Settings tab: Permissions")
        }

        public enum General {
            public static let keyboardShortcutHeader = String(localized: "settings.general.keyboardShortcutHeader",
                                                              defaultValue: "Keyboard Shortcut",
                                                              comment: "Section header for keyboard shortcut")
            public static let toggleRecording = String(localized: "settings.general.toggleRecording",
                                                       defaultValue: "Toggle Recording:",
                                                       comment: "Label for toggle recording shortcut")
            public static let behaviorHeader = String(localized: "settings.general.behaviorHeader",
                                                      defaultValue: "Behavior",
                                                      comment: "Section header for behavior settings")
            public static let autoPasteToggle = String(localized: "settings.general.autoPasteToggle",
                                                       defaultValue: "Auto-paste transcription",
                                                       comment: "Toggle for auto-paste feature")
            public static let autoPasteAccessibilityWarning = String(localized: "settings.general.autoPasteAccessibilityWarning",
                                                                     defaultValue: "Accessibility permission required for auto-paste",
                                                                     comment: "Warning about accessibility permission")
            public static let soundFeedbackHeader = String(localized: "settings.general.soundFeedbackHeader",
                                                           defaultValue: "Sound Feedback",
                                                           comment: "Section header for sound settings")
            public static let soundFeedbackToggle = String(localized: "settings.general.soundFeedbackToggle",
                                                           defaultValue: "Play sounds when recording",
                                                           comment: "Toggle for sound feedback")
            public static let startSound = String(localized: "settings.general.startSound",
                                                  defaultValue: "Start sound",
                                                  comment: "Label for start sound picker")
            public static let stopSound = String(localized: "settings.general.stopSound",
                                                 defaultValue: "Stop sound",
                                                 comment: "Label for stop sound picker")
            public static let previewSoundHelp = String(localized: "settings.general.previewSoundHelp",
                                                        defaultValue: "Preview sound",
                                                        comment: "Help text for preview sound button")
            public static let storageHeader = String(localized: "settings.general.storageHeader",
                                                     defaultValue: "Storage",
                                                     comment: "Section header for storage settings")
            public static func storageLimitStepper(_ gb: Int) -> String {
                String(localized: "Recording storage limit: \(gb) GB",
                       comment: "Stepper for storage limit in GB")
            }
            public static let storageLimitDescription = String(localized: "settings.general.storageLimitDescription",
                                                               defaultValue: "Oldest recordings are deleted automatically when you exceed this limit.",
                                                               comment: "Description for storage limit")
            public static let currentSettingsHeader = String(localized: "settings.general.currentSettingsHeader",
                                                             defaultValue: "Current Settings",
                                                             comment: "Section header for current settings")
            public static let selectedModel = String(localized: "settings.general.selectedModel",
                                                     defaultValue: "Selected Model",
                                                     comment: "Label for selected model")
            public static let privacyHeader = String(localized: "settings.general.privacyHeader",
                                                     defaultValue: "Privacy",
                                                     comment: "Section header for privacy settings")
            public static let analyticsToggle = String(localized: "settings.general.analyticsToggle",
                                                       defaultValue: "Share anonymous usage analytics",
                                                       comment: "Toggle for analytics sharing")
        }

        public enum Permissions {
            public static let header = String(localized: "settings.permissions.header",
                                              defaultValue: "Permissions",
                                              comment: "Section header for permissions")
            public static let microphoneAccess = String(localized: "settings.permissions.microphoneAccess",
                                                        defaultValue: "Microphone Access",
                                                        comment: "Label for microphone permission")
            public static let accessibilityAccess = String(localized: "settings.permissions.accessibilityAccess",
                                                           defaultValue: "Accessibility Access",
                                                           comment: "Label for accessibility permission")
            public static let accessibilityDescription = String(localized: "settings.permissions.accessibilityDescription",
                                                                defaultValue: "Accessibility access is required for auto-paste functionality.",
                                                                comment: "Description for accessibility permission")
            public static let openSystemPreferences = String(localized: "settings.permissions.openSystemPreferences",
                                                             defaultValue: "Open System Preferences",
                                                             comment: "Button to open system preferences")
        }
    }

    // MARK: - Models
    public enum Models {
        public static let title = String(localized: "models.title",
                                         defaultValue: "Whisper Models",
                                         comment: "Title for models section")
        public static func storageUsed(_ size: String) -> String {
            String(localized: "Storage used: \(size)",
                   comment: "Display of storage used by models")
        }
        public static let anotherModelDownloading = String(localized: "models.anotherModelDownloading",
                                                           defaultValue: "Another model is downloading",
                                                           comment: "Message when another model is downloading")
        public static func downloadingProgress(_ completed: String, _ total: String) -> String {
            String(localized: "Downloading \(completed) of \(total)",
                   comment: "Download progress message")
        }
    }

    // MARK: - Profiles
    public enum Profiles {
        public static let header = String(localized: "profiles.header",
                                          defaultValue: "Profiles",
                                          comment: "Section header for profiles")
        public static let noProfilesCreated = String(localized: "profiles.noProfilesCreated",
                                                     defaultValue: "No profiles created yet",
                                                     comment: "Empty state for profiles list")
        public static let footerDescription = String(localized: "profiles.footerDescription",
                                                     defaultValue: "Select a profile to use its settings when recording. Choose \"None\" to use app defaults.",
                                                     comment: "Footer description for profiles")
        public static let quickSelectionHeader = String(localized: "profiles.quickSelectionHeader",
                                                        defaultValue: "Quick Selection",
                                                        comment: "Section header for quick selection")
        public static let activeProfile = String(localized: "profiles.activeProfile",
                                                 defaultValue: "Active Profile",
                                                 comment: "Label for active profile picker")
        public static let noneUseDefaults = String(localized: "profiles.noneUseDefaults",
                                                   defaultValue: "None (Use Defaults)",
                                                   comment: "Option to use default settings")
        public static let deleteProfileTitle = String(localized: "profiles.deleteProfileTitle",
                                                      defaultValue: "Delete Profile",
                                                      comment: "Title for delete profile alert")
        public static func deleteProfileMessage(_ name: String) -> String {
            String(localized: "Are you sure you want to delete \"\(name)\"? This action cannot be undone.",
                   comment: "Confirmation message for profile deletion")
        }
        public static let aiPromptLabel = String(localized: "profiles.aiPromptLabel",
                                                 defaultValue: "AI Prompt",
                                                 comment: "Label for AI prompt feature")
        public static let createProfilesHint = String(localized: "profiles.createProfilesHint",
                                                      defaultValue: "Create profiles in Settings > Profiles",
                                                      comment: "Hint to create profiles in settings")
        public static let selectProfile = String(localized: "profiles.selectProfile",
                                                 defaultValue: "Select Profile",
                                                 comment: "Title for profile picker popover")
    }

    // MARK: - Profile Editor
    public enum ProfileEditor {
        public static let nameHeader = String(localized: "profileEditor.nameHeader",
                                              defaultValue: "Name",
                                              comment: "Section header for profile name")
        public static let profileNamePlaceholder = String(localized: "profileEditor.profileNamePlaceholder",
                                                          defaultValue: "Profile Name",
                                                          comment: "Placeholder for profile name field")
        public static let whisperModelHeader = String(localized: "profileEditor.whisperModelHeader",
                                                      defaultValue: "Whisper Model",
                                                      comment: "Section header for model selection")
        public static let overrideModelToggle = String(localized: "profileEditor.overrideModelToggle",
                                                       defaultValue: "Override app default model",
                                                       comment: "Toggle for model override")
        public static let modelLabel = String(localized: "profileEditor.modelLabel",
                                              defaultValue: "Model",
                                              comment: "Label for model picker")
        public static let downloadModelHint = String(localized: "profileEditor.downloadModelHint",
                                                     defaultValue: "Download a model in Settings > Models to enable overrides.",
                                                     comment: "Hint to download models")
        public static let modelOverrideDescription = String(localized: "profileEditor.modelOverrideDescription",
                                                            defaultValue: "The selected model will be used instead of the app's default model.",
                                                            comment: "Description for model override")
        public static let languageHeader = String(localized: "profileEditor.languageHeader",
                                                  defaultValue: "Transcription Language",
                                                  comment: "Section header for language selection")
        public static let forceLanguageToggle = String(localized: "profileEditor.forceLanguageToggle",
                                                       defaultValue: "Force specific language",
                                                       comment: "Toggle for language forcing")
        public static let languageLabel = String(localized: "profileEditor.languageLabel",
                                                 defaultValue: "Language",
                                                 comment: "Label for language picker")
        public static let languageForceDescription = String(localized: "profileEditor.languageForceDescription",
                                                            defaultValue: "Forces Whisper to transcribe in the selected language instead of auto-detecting.",
                                                            comment: "Description for language forcing")
        public static let languageAutoDescription = String(localized: "profileEditor.languageAutoDescription",
                                                           defaultValue: "Language will be automatically detected from the audio.",
                                                           comment: "Description for auto language detection")
        public static func multilingualWarning(_ modelName: String) -> String {
            String(localized: "The \(modelName) model is English-only. Language forcing may not work. Use Large V3, Medium, Small, or Base for multilingual support.",
                   comment: "Warning about English-only model")
        }
        public static let aiPostProcessingHeader = String(localized: "profileEditor.aiPostProcessingHeader",
                                                          defaultValue: "AI Post-Processing",
                                                          comment: "Section header for AI processing")
        public static let customPromptToggle = String(localized: "profileEditor.customPromptToggle",
                                                      defaultValue: "Apply custom AI prompt",
                                                      comment: "Toggle for custom AI prompt")
        public static let customPromptDescription = String(localized: "profileEditor.customPromptDescription",
                                                           defaultValue: "The transcription will be processed with this prompt. Examples: \"Make it professional and fix grammar\" or \"Format as bullet points\"",
                                                           comment: "Description for custom prompt feature")
        public static let createProfile = String(localized: "profileEditor.createProfile",
                                                 defaultValue: "Create Profile",
                                                 comment: "Button to create new profile")
        public static let saveChanges = String(localized: "profileEditor.saveChanges",
                                               defaultValue: "Save Changes",
                                               comment: "Button to save profile changes")
    }

    // MARK: - Onboarding
    public enum Onboarding {
        public static let skip = String(localized: "onboarding.skip",
                                        defaultValue: "Skip",
                                        comment: "Skip onboarding button")
        public static let back = String(localized: "onboarding.back",
                                        defaultValue: "Back",
                                        comment: "Back button in onboarding")
        public static let `continue` = String(localized: "onboarding.continue",
                                              defaultValue: "Continue",
                                              comment: "Continue button in onboarding")
        public static let getStarted = String(localized: "onboarding.getStarted",
                                              defaultValue: "Get Started",
                                              comment: "Get started button on final onboarding step")

        public enum Welcome {
            public static let title = String(localized: "onboarding.welcome.title",
                                             defaultValue: "Welcome to Spezhe",
                                             comment: "Main title on welcome screen")
            public static let subtitle = String(localized: "onboarding.welcome.subtitle",
                                                defaultValue: "Voice transcription, simplified.",
                                                comment: "Subtitle on welcome screen")
            public static let recordAnywhereTitle = String(localized: "onboarding.welcome.recordAnywhereTitle",
                                                           defaultValue: "Record Anywhere",
                                                           comment: "Feature title: Record Anywhere")
            public static let recordAnywhereDescription = String(localized: "onboarding.welcome.recordAnywhereDescription",
                                                                 defaultValue: "Use the global shortcut to capture audio from any app",
                                                                 comment: "Feature description: Record Anywhere")
            public static let instantTranscriptionTitle = String(localized: "onboarding.welcome.instantTranscriptionTitle",
                                                                 defaultValue: "Instant Transcription",
                                                                 comment: "Feature title: Instant Transcription")
            public static let instantTranscriptionDescription = String(localized: "onboarding.welcome.instantTranscriptionDescription",
                                                                       defaultValue: "Powered by OpenAI Whisper for accurate speech-to-text",
                                                                       comment: "Feature description: Instant Transcription")
            public static let autoPasteTitle = String(localized: "onboarding.welcome.autoPasteTitle",
                                                      defaultValue: "Auto-Paste",
                                                      comment: "Feature title: Auto-Paste")
            public static let autoPasteDescription = String(localized: "onboarding.welcome.autoPasteDescription",
                                                            defaultValue: "Transcribed text is automatically copied and pasted",
                                                            comment: "Feature description: Auto-Paste")
        }

        public enum Permissions {
            public static let title = String(localized: "onboarding.permissions.title",
                                             defaultValue: "Permissions Required",
                                             comment: "Title for permissions step")
            public static let subtitle = String(localized: "onboarding.permissions.subtitle",
                                                defaultValue: "Spezhe needs access to your microphone to record audio.",
                                                comment: "Subtitle for permissions step")
            public static let microphoneTitle = String(localized: "onboarding.permissions.microphoneTitle",
                                                       defaultValue: "Microphone",
                                                       comment: "Permission title: Microphone")
            public static let microphoneDescription = String(localized: "onboarding.permissions.microphoneDescription",
                                                             defaultValue: "Required for voice recording",
                                                             comment: "Permission description: Microphone")
            public static let accessibilityTitle = String(localized: "onboarding.permissions.accessibilityTitle",
                                                          defaultValue: "Accessibility",
                                                          comment: "Permission title: Accessibility")
            public static let accessibilityDescription = String(localized: "onboarding.permissions.accessibilityDescription",
                                                                defaultValue: "Optional - enables auto-paste feature",
                                                                comment: "Permission description: Accessibility")
        }

        public enum Shortcut {
            public static let title = String(localized: "onboarding.shortcut.title",
                                             defaultValue: "Your Recording Shortcut",
                                             comment: "Title for shortcut tutorial")
            public static let subtitle = String(localized: "onboarding.shortcut.subtitle",
                                                defaultValue: "Use this shortcut from anywhere to start recording.",
                                                comment: "Subtitle for shortcut tutorial")
            public static let tryItOut = String(localized: "onboarding.shortcut.tryItOut",
                                                defaultValue: "Try it out",
                                                comment: "Header for try it out section")
            public static let tryItPlaceholder = String(localized: "onboarding.shortcut.tryItPlaceholder",
                                                        defaultValue: "Click here, then press the shortcut to record...",
                                                        comment: "Placeholder for try it text field")
            public static let customizeHint = String(localized: "onboarding.shortcut.customizeHint",
                                                     defaultValue: "You can customize this shortcut in Settings.",
                                                     comment: "Hint about customizing shortcut")
        }

        public enum Ready {
            public static let title = String(localized: "onboarding.ready.title",
                                             defaultValue: "You're All Set!",
                                             comment: "Title for ready step")
            public static let subtitle = String(localized: "onboarding.ready.subtitle",
                                                defaultValue: "Spezhe is ready to transcribe your voice.",
                                                comment: "Subtitle for ready step")
            public static let menuBarTip = String(localized: "onboarding.ready.menuBarTip",
                                                  defaultValue: "Look for the waveform icon in your menu bar",
                                                  comment: "Tip about menu bar icon")
            public static let shortcutTip = String(localized: "onboarding.ready.shortcutTip",
                                                   defaultValue: "Press Option + Space to start recording anytime",
                                                   comment: "Tip about keyboard shortcut")
            public static let settingsTip = String(localized: "onboarding.ready.settingsTip",
                                                   defaultValue: "Access settings from the menu bar or press Command + ,",
                                                   comment: "Tip about accessing settings")
        }
    }

    // MARK: - Recording
    public enum Recording {
        public enum State {
            public static let ready = String(localized: "recording.state.ready",
                                             defaultValue: "Ready",
                                             comment: "Recording state: ready to record")
            public static let recording = String(localized: "recording.state.recording",
                                                 defaultValue: "Recording...",
                                                 comment: "Recording state: actively recording")
            public static let loadingModel = String(localized: "recording.state.loadingModel",
                                                    defaultValue: "Loading model...",
                                                    comment: "Recording state: loading AI model")
            public static let transcribing = String(localized: "recording.state.transcribing",
                                                    defaultValue: "Transcribing...",
                                                    comment: "Recording state: transcribing audio")
            public static let done = String(localized: "recording.state.done",
                                            defaultValue: "Done",
                                            comment: "Recording state: completed")
            public static func error(_ message: String) -> String {
                String(localized: "Error: \(message)",
                       comment: "Recording state: error with message")
            }
        }

        public enum Popup {
            public static let loadingModelTitle = String(localized: "recording.popup.loadingModelTitle",
                                                         defaultValue: "Loading model...",
                                                         comment: "Loading indicator title for model loading")
            public static let loadingModelSubtitle = String(localized: "recording.popup.loadingModelSubtitle",
                                                            defaultValue: "Preparing speech recognition",
                                                            comment: "Loading indicator subtitle for model loading")
            public static let transcribingTitle = String(localized: "recording.popup.transcribingTitle",
                                                         defaultValue: "Transcribing...",
                                                         comment: "Loading indicator title for transcribing")
            public static let transcribingSubtitle = String(localized: "recording.popup.transcribingSubtitle",
                                                            defaultValue: "Converting speech to text",
                                                            comment: "Loading indicator subtitle for transcribing")
            public static let modelLabel = String(localized: "recording.popup.modelLabel",
                                                  defaultValue: "Model",
                                                  comment: "Label for model display in popup")
            public static let stop = String(localized: "recording.popup.stop",
                                            defaultValue: "Stop",
                                            comment: "Stop recording button")
            public static let noProfile = String(localized: "recording.popup.noProfile",
                                                 defaultValue: "No Profile",
                                                 comment: "Label when no profile is selected")
        }

        public enum Detail {
            public static let originalTranscription = String(localized: "recording.detail.originalTranscription",
                                                             defaultValue: "Original Transcription",
                                                             comment: "Label for original transcription")
            public static let aiProcessed = String(localized: "recording.detail.aiProcessed",
                                                   defaultValue: "AI Processed",
                                                   comment: "Label for AI processed transcription")
            public static let showProcessed = String(localized: "recording.detail.showProcessed",
                                                     defaultValue: "Show Processed",
                                                     comment: "Button to show processed text")
            public static let showOriginal = String(localized: "recording.detail.showOriginal",
                                                    defaultValue: "Show Original",
                                                    comment: "Button to show original text")
            public static let audioUnavailable = String(localized: "recording.detail.audioUnavailable",
                                                        defaultValue: "Audio unavailable",
                                                        comment: "Message when audio file is unavailable")
            public static let titlePlaceholder = String(localized: "recording.detail.titlePlaceholder",
                                                        defaultValue: "Title",
                                                        comment: "Placeholder for recording title")
        }

        public enum Empty {
            public static let title = String(localized: "recording.empty.title",
                                             defaultValue: "No Recording Selected",
                                             comment: "Title for empty state")
            public static let subtitle = String(localized: "recording.empty.subtitle",
                                                defaultValue: "Select a recording from the sidebar or create a new one",
                                                comment: "Subtitle for empty state")
        }
    }

    // MARK: - Inspector
    public enum Inspector {
        public static let detailsHeader = String(localized: "inspector.detailsHeader",
                                                 defaultValue: "Details",
                                                 comment: "Section header for recording details")
        public static let duration = String(localized: "inspector.duration",
                                            defaultValue: "Duration",
                                            comment: "Label for duration")
        public static let created = String(localized: "inspector.created",
                                           defaultValue: "Created",
                                           comment: "Label for creation date")
        public static let fileSize = String(localized: "inspector.fileSize",
                                            defaultValue: "File Size",
                                            comment: "Label for file size")
        public static let transcriptionHeader = String(localized: "inspector.transcriptionHeader",
                                                       defaultValue: "Transcription",
                                                       comment: "Section header for transcription info")
        public static let wordCount = String(localized: "inspector.wordCount",
                                             defaultValue: "Word Count",
                                             comment: "Label for word count")
        public static let language = String(localized: "inspector.language",
                                            defaultValue: "Language",
                                            comment: "Label for detected language")
        public static let processingHeader = String(localized: "inspector.processingHeader",
                                                    defaultValue: "Processing",
                                                    comment: "Section header for processing info")
        public static let modelUsed = String(localized: "inspector.modelUsed",
                                             defaultValue: "Model Used",
                                             comment: "Label for model used")
        public static let profile = String(localized: "inspector.profile",
                                           defaultValue: "Profile",
                                           comment: "Label for profile used")
        public static let noRecordingSelected = String(localized: "inspector.noRecordingSelected",
                                                       defaultValue: "No Recording Selected",
                                                       comment: "Message when no recording is selected")
    }

    // MARK: - Menu Bar
    public enum MenuBar {
        public static let lastTranscription = String(localized: "menuBar.lastTranscription",
                                                     defaultValue: "Last transcription:",
                                                     comment: "Label for last transcription preview")
        public static func shortcutLabel(_ shortcut: String) -> String {
            String(localized: "Shortcut: \(shortcut)",
                   comment: "Label showing keyboard shortcut")
        }
        public static let modelLabel = String(localized: "menuBar.modelLabel",
                                              defaultValue: "Model:",
                                              comment: "Label for current model")
    }

    // MARK: - Main Window
    public enum MainWindow {
        public static let recordingsTitle = String(localized: "mainWindow.recordingsTitle",
                                                   defaultValue: "Recordings",
                                                   comment: "Navigation title for recordings sidebar")
        public static let hideInspector = String(localized: "mainWindow.hideInspector",
                                                 defaultValue: "Hide Inspector",
                                                 comment: "Tooltip for hide inspector button")
        public static let showInspector = String(localized: "mainWindow.showInspector",
                                                 defaultValue: "Show Inspector",
                                                 comment: "Tooltip for show inspector button")
        public static let record = String(localized: "mainWindow.record",
                                          defaultValue: "Record",
                                          comment: "Record button label")
        public static let stopRecording = String(localized: "mainWindow.stopRecording",
                                                 defaultValue: "Stop",
                                                 comment: "Stop recording button label")
        public static func recordTooltip(_ shortcut: String) -> String {
            String(localized: "Start Recording (\(shortcut))",
                   comment: "Tooltip for record button")
        }
        public static func stopTooltip(_ shortcut: String) -> String {
            String(localized: "Stop Recording (\(shortcut))",
                   comment: "Tooltip for stop button")
        }
    }

    // MARK: - Alerts
    public enum Alerts {
        public static let downloadModelTitle = String(localized: "alerts.downloadModelTitle",
                                                      defaultValue: "Download Model?",
                                                      comment: "Title for download model alert")
        public static func downloadModelMessage(_ name: String, _ size: String) -> String {
            "\(name) (\(size)) needs to be downloaded."
        }
        public static func downloadModelMessageFull(_ name: String, _ size: String) -> String {
            "\(name) (\(size)) needs to be downloaded. This requires an internet connection and \(size) of disk space."
        }
        public static let useBaseModel = String(localized: "alerts.useBaseModel",
                                                defaultValue: "Use Base Model",
                                                comment: "Button to use base model instead")
    }

    // MARK: - Errors
    public enum Errors {
        public static let profileSaveFailedPrefix = String(localized: "errors.profileSaveFailedPrefix",
                                                           defaultValue: "Failed to save profile:",
                                                           comment: "Error prefix when profile save fails")
        public static func profileSaveFailed(_ error: String) -> String {
            "\(profileSaveFailedPrefix) \(error)"
        }
        public static let profileDeleteFailedPrefix = String(localized: "errors.profileDeleteFailedPrefix",
                                                             defaultValue: "Failed to delete profile:",
                                                             comment: "Error prefix when profile deletion fails")
        public static func profileDeleteFailed(_ error: String) -> String {
            "\(profileDeleteFailedPrefix) \(error)"
        }
    }
}

// swiftlint:enable line_length type_body_length file_length
