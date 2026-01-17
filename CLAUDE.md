# Spezhe

Spezhe is a macOS voice-to-text dictation app that runs entirely on-device using WhisperKit.

## Project Structure

```
spezhe/
├── spezhe/                  # Main app target (entry point)
│   └── SpezheApp.swift      # @main App struct
├── App/                     # Swift Package containing all app logic
│   ├── Package.swift
│   └── Sources/App/
│       ├── Core/            # App delegate, constants, logging, theming
│       ├── Database/        # GRDB models and repositories
│       ├── Models/          # Data models (profiles, settings, whisper models)
│       ├── Services/        # Business logic services
│       ├── ViewModels/      # SwiftUI view models
│       ├── Views/           # SwiftUI views
│       └── Windows/         # Floating panel controller
├── spezhe.xcodeproj/        # Xcode project
└── spezhe-site/             # Website submodule (github.com/hoyelam/Spezhe-website)
```

## Key Dependencies

- **WhisperKit** (0.9.0+) - On-device speech recognition using Whisper models
- **KeyboardShortcuts** - Global hotkey registration
- **GRDB** - SQLite database for recordings and profiles
- **Mixpanel** - Analytics (anonymous usage tracking)

## Architecture

### Services

- `AudioRecordingService` - Captures audio via AVAudioEngine, resamples to 16kHz
- `TranscriptionService` - Loads WhisperKit models and transcribes audio
- `ModelManagerService` - Downloads and manages Whisper models
- `ClipboardService` - Copies transcribed text to clipboard
- `SoundFeedbackService` - Audio feedback for recording start/stop
- `AnalyticsService` - Mixpanel event tracking

### Database

Uses GRDB with the following tables:
- `recordings` - Stored recordings with transcriptions
- `transcription_profiles` - User-defined profiles (model, language, prompts)

### Key Features

- **On-device processing** - All audio/transcription stays local
- **Global hotkey** - Press to record from anywhere
- **Transcription profiles** - Different models/languages per use case
- **Language forcing** - Override auto-detection for specific languages
- **Model warm-up** - Pre-compiles CoreML models for faster first transcription

## Development

### Requirements

- macOS 14.0+
- Xcode 15+
- Swift 5.9+

### Building

Open `spezhe.xcodeproj` in Xcode. The App package will resolve dependencies automatically.

### Running

The app requires:
- Microphone permission
- Accessibility permission (for global hotkeys)

## Code Conventions

- Use `@MainActor` for UI-related classes
- Use structured concurrency (async/await)
- Log using `logDebug`, `logInfo`, `logWarning`, `logError` with categories
- Database models conform to `FetchableRecord` and `MutablePersistableRecord`
- ViewModels are `@Observable` or `ObservableObject` classes
