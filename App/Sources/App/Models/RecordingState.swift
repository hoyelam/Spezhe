import Foundation

public enum RecordingState: Equatable {
    case idle
    case recording
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

    var statusText: String {
        switch self {
        case .idle:
            return "Ready"
        case .recording:
            return "Recording..."
        case .processing:
            return "Transcribing..."
        case .completed:
            return "Done"
        case .error(let message):
            return "Error: \(message)"
        }
    }
}
