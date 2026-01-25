import Foundation

public enum RecordingState: Equatable {
    case idle
    case recording
    case loadingModel
    case processing
    case completed(String)
    case error(String)

    var isRecording: Bool {
        if case .recording = self { return true }
        return false
    }

    var isProcessing: Bool {
        if case .processing = self { return true }
        return false
    }

    var isLoadingModel: Bool {
        if case .loadingModel = self { return true }
        return false
    }

    /// Whether the state shows a loading indicator (loading model or transcribing)
    var isLoading: Bool {
        isLoadingModel || isProcessing
    }

    var statusText: String {
        switch self {
        case .idle:
            return L10n.Recording.State.ready
        case .recording:
            return L10n.Recording.State.recording
        case .loadingModel:
            return L10n.Recording.State.loadingModel
        case .processing:
            return L10n.Recording.State.transcribing
        case .completed:
            return L10n.Recording.State.done
        case .error(let message):
            return L10n.Recording.State.error(message)
        }
    }
}
