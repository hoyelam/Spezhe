import Foundation

public struct TranscriptionResult: Equatable {
    public let text: String
    public let duration: TimeInterval
    public let timestamp: Date
    public let detectedLanguage: String?

    public init(text: String, duration: TimeInterval = 0, timestamp: Date = Date(), detectedLanguage: String? = nil) {
        self.text = text
        self.duration = duration
        self.timestamp = timestamp
        self.detectedLanguage = detectedLanguage
    }
}
