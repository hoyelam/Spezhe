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
            return "Ready"
        case .recording:
            return "Recording..."
        case .loadingModel:
            return "Loading model..."
        case .processing:
            return "Transcribing..."
        case .completed:
            return "Done"
        case .error(let message):
            return "Error: \(message)"
        }
    }
}
