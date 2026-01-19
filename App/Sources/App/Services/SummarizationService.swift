import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

@MainActor
public class SummarizationService: ObservableObject {
    public static let shared = SummarizationService()

    @Published public private(set) var isAvailable = false
    @Published public private(set) var isProcessing = false

    private let oneLinerOnlyInstructions = """
        Create a very short title (maximum 60 characters) that captures the main topic of the text.

        Rules:
        - Output ONLY the title text, nothing else
        - Do NOT start with labels like "One-liner:", "Title:", "Summary:", etc.
        - Do NOT mention it's a transcription or recording
        - Start directly with the main topic
        - Use present tense
        - Keep it concise and scannable
        """

    private let summaryInstructions = """
        Act as an expert analyst. Provide a comprehensive summary of the text with the following structure:

        • Executive Overview (2 sentences): Capture the core argument and conclusion.
        • Key Takeaways (up to 5 bullet points): List the most critical points.
        • Key Terms (if any): Briefly define any complex jargon or technical terms used.

        CRITICAL RULES:
        - Do NOT use section labels like "Executive Overview:", "Key Takeaways:", etc.
        - Do NOT mention it's a transcription or recording
        - Start directly with the overview sentences
        - Maintain an objective tone
        - Maximum 300 words total
        - Use present tense
        """

    /// Minimum character count for transcription to warrant a summary (below this, only one-liner is generated)
    private let minCharsForSummary = 200

    private init() {
        logDebug("SummarizationService initialized", category: .app)
        checkAvailability()
    }

    public func checkAvailability() {
        if #available(macOS 26.0, *) {
            #if canImport(FoundationModels)
            isAvailable = SystemLanguageModel.default.isAvailable
            #else
            isAvailable = false
            #endif
        } else {
            isAvailable = false
        }

        if isAvailable {
            logInfo("Foundation Models is available", category: .app)
        } else {
            logWarning("Foundation Models is not available on this device", category: .app)
        }
    }

    /// Generates both a one-liner title and a longer summary from transcription text
    /// - Parameter transcription: The full transcription text
    /// - Returns: A tuple containing (oneLiner, summary), both optional
    public func generateSummaries(from transcription: String, languageCode: String? = nil) async -> (oneLiner: String?, summary: String?) {
        guard isAvailable else {
            logWarning("Summarization skipped: Foundation Models not available", category: .app)
            return (nil, nil)
        }

        let trimmedText = transcription.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            logWarning("Summarization skipped: Empty transcription", category: .app)
            return (nil, nil)
        }

        let wordCount = trimmedText.split(separator: " ").count
        if wordCount < 10 {
            logDebug("Summarization skipped: Transcription too short (\(wordCount) words)", category: .app)
            return (nil, nil)
        }

        // For very short transcriptions (1-2 sentences), use first sentence as one-liner directly
        let sentences = extractSentences(from: trimmedText)
        if sentences.count <= 2 {
            let firstSentence = sentences.first ?? trimmedText
            let oneLiner = truncateOneLiner(firstSentence)
            logDebug("Short transcription (\(sentences.count) sentence(s)): using first sentence as one-liner", category: .app)
            return (oneLiner, nil)
        }

        isProcessing = true
        defer { isProcessing = false }

        // Determine if we need a summary or just a one-liner
        let needsSummary = trimmedText.count >= minCharsForSummary
        let targetLanguageInstruction = languageInstruction(for: languageCode)
        if let languageInstruction = targetLanguageInstruction {
            logInfo("Summarization target language: \(languageInstruction)", category: .app)
        }

        if needsSummary {
            logInfo("Generating one-liner + summary for transcription (\(trimmedText.count) chars, \(wordCount) words)...", category: .app)
        } else {
            logInfo("Generating one-liner only for short transcription (\(trimmedText.count) chars, \(wordCount) words)...", category: .app)
        }

        let startTime = Date()

        guard #available(macOS 26.0, *) else {
            logWarning("Summarization skipped: macOS 26.0 required", category: .app)
            return (nil, nil)
        }

        #if canImport(FoundationModels)
        do {
            var oneLiner: String?
            var summary: String?

            // Generate one-liner
            let oneLinerSession = LanguageModelSession(instructions: withLanguageInstruction(oneLinerOnlyInstructions, instruction: targetLanguageInstruction))
            let oneLinerResponse = try await oneLinerSession.respond(to: trimmedText)
            let oneLinerText = oneLinerResponse.content.trimmingCharacters(in: .whitespacesAndNewlines)
            if !oneLinerText.isEmpty {
                oneLiner = cleanOneLiner(oneLinerText)
            }

            // Generate summary if needed
            if needsSummary {
                let summarySession = LanguageModelSession(instructions: withLanguageInstruction(summaryInstructions, instruction: targetLanguageInstruction))
                let summaryResponse = try await summarySession.respond(to: trimmedText)
                let rawSummary = summaryResponse.content.trimmingCharacters(in: .whitespacesAndNewlines)

                if !rawSummary.isEmpty, var cleanedSummary = cleanSummary(rawSummary) {
                    // Enforce summary length constraint: must be at most 50% of original length
                    let maxSummaryLength = trimmedText.count / 2
                    if cleanedSummary.count > maxSummaryLength {
                        cleanedSummary = truncateToLength(cleanedSummary, maxLength: maxSummaryLength)
                        logDebug("Summary truncated to \(cleanedSummary.count) chars (50% of original)", category: .app)
                    }

                    summary = cleanedSummary
                }
            }

            let duration = Date().timeIntervalSince(startTime)
            logInfo("Generation completed in \(String(format: "%.2f", duration))s", category: .app)
            if let ol = oneLiner {
                logDebug("One-liner (\(ol.count) chars): '\(ol)'", category: .app)
            }
            if let s = summary {
                logDebug("Summary (\(s.count) chars, \(String(format: "%.0f", Double(s.count) / Double(trimmedText.count) * 100))%% of original): '\(s)'", category: .app)
            }

            return (oneLiner, summary)

        } catch {
            logError("Failed to generate summaries: \(error.localizedDescription)", category: .app)
            return (nil, nil)
        }
        #else
        return (nil, nil)
        #endif
    }

    /// Cleans up a one-liner by removing common prefixes and enforcing length
    /// Returns nil if the AI indicates it cannot provide a summary
    private func cleanOneLiner(_ text: String) -> String? {
        var cleaned = text.trimmingCharacters(in: CharacterSet(charactersIn: "\""))

        // Check if the AI indicates it cannot provide a summary
        let lowercased = cleaned.lowercased()
        let cannotSummarizePhrases = [
            "i cannot",
            "i can't",
            "i'm unable",
            "i am unable",
            "unable to",
            "cannot create",
            "can't create",
            "cannot provide",
            "can't provide",
            "cannot generate",
            "can't generate",
            "not enough",
            "insufficient",
            "no meaningful",
            "doesn't contain",
            "does not contain",
            "too short",
            "too brief",
            "no clear topic",
            "no discernible",
            "sorry",
            "apolog"
        ]
        for phrase in cannotSummarizePhrases {
            if lowercased.contains(phrase) {
                logDebug("One-liner skipped: AI indicated it cannot summarize", category: .app)
                return nil
            }
        }

        // Remove common prefixes the model might add
        let prefixesToRemove = [
            "One-liner:", "One-Liner:", "ONE-LINER:",
            "Title:", "TITLE:",
            "Summary:", "SUMMARY:",
            "Line 1:", "Line 2:",
            "1.", "2.",
            "-"
        ]
        for prefix in prefixesToRemove {
            if cleaned.hasPrefix(prefix) {
                cleaned = String(cleaned.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces)
            }
        }

        // Enforce 60 character limit
        if cleaned.count > 60 {
            let truncated = String(cleaned.prefix(57))
            if let lastSpace = truncated.lastIndex(of: " ") {
                cleaned = String(truncated[..<lastSpace]) + "..."
            } else {
                cleaned = truncated + "..."
            }
        }

        return cleaned
    }

    private func withLanguageInstruction(_ base: String, instruction: String?) -> String {
        guard let instruction = instruction else { return base }
        return base + "\n\n" + instruction
    }

    private func languageInstruction(for languageCode: String?) -> String? {
        guard let code = languageCode, !code.isEmpty, code.lowercased() != "auto" else {
            return nil
        }

        let normalizedCode = code.replacingOccurrences(of: "_", with: "-")
        let primaryCode = normalizedCode.split(separator: "-").first.map(String.init) ?? normalizedCode
        let locale = Locale(identifier: "en")
        let languageName = locale.localizedString(forLanguageCode: primaryCode) ?? primaryCode
        return "Respond in \(languageName) (\(primaryCode))."
    }

    /// Cleans up a summary by removing common prefixes
    /// Returns nil if the AI indicates it cannot provide a summary
    private func cleanSummary(_ text: String) -> String? {
        var cleaned = text.trimmingCharacters(in: CharacterSet(charactersIn: "\""))

        // Check if the AI indicates it cannot provide a summary
        let lowercased = cleaned.lowercased()
        let cannotSummarizePhrases = [
            "i cannot",
            "i can't",
            "i'm unable",
            "i am unable",
            "unable to",
            "cannot create",
            "can't create",
            "cannot provide",
            "can't provide",
            "cannot generate",
            "can't generate",
            "not enough",
            "insufficient",
            "no meaningful",
            "doesn't contain",
            "does not contain",
            "too short",
            "too brief",
            "no clear topic",
            "no discernible",
            "sorry",
            "apolog"
        ]
        for phrase in cannotSummarizePhrases {
            if lowercased.contains(phrase) {
                logDebug("Summary skipped: AI indicated it cannot summarize", category: .app)
                return nil
            }
        }

        // Remove common prefixes the model might add at the start
        let prefixesToRemove = [
            "Summary:", "SUMMARY:",
            "Executive Overview:", "EXECUTIVE OVERVIEW:",
            "Overview:", "OVERVIEW:",
            "Line 2:", "2.",
            "Part 2:", "PART 2:",
            "The transcription", "This transcription",
            "The recording", "This recording",
            "-"
        ]
        for prefix in prefixesToRemove {
            if cleaned.lowercased().hasPrefix(prefix.lowercased()) {
                cleaned = String(cleaned.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces)
            }
        }

        // Remove inline section labels that might appear (but keep the content)
        let inlineLabelsToRemove = [
            "Executive Overview:",
            "Key Takeaways:",
            "Key Terms:",
            "Critical Takeaways:",
            "Definitions:"
        ]
        for label in inlineLabelsToRemove {
            cleaned = cleaned.replacingOccurrences(of: label, with: "", options: .caseInsensitive)
        }

        // Clean up any resulting double spaces or newlines
        while cleaned.contains("  ") {
            cleaned = cleaned.replacingOccurrences(of: "  ", with: " ")
        }

        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Truncates text to a maximum length, breaking at word boundary
    private func truncateToLength(_ text: String, maxLength: Int) -> String {
        guard text.count > maxLength else { return text }

        let truncated = String(text.prefix(maxLength - 3))
        if let lastSpace = truncated.lastIndex(of: " ") {
            return String(truncated[..<lastSpace]) + "..."
        } else {
            return truncated + "..."
        }
    }

    /// Extracts sentences from text using linguistic analysis
    private func extractSentences(from text: String) -> [String] {
        var sentences: [String] = []
        let range = text.startIndex..<text.endIndex

        text.enumerateSubstrings(in: range, options: .bySentences) { substring, _, _, _ in
            if let sentence = substring?.trimmingCharacters(in: .whitespacesAndNewlines), !sentence.isEmpty {
                sentences.append(sentence)
            }
        }

        return sentences
    }

    /// Truncates a sentence to fit the one-liner length limit (60 chars)
    private func truncateOneLiner(_ text: String) -> String {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if cleaned.count <= 60 {
            return cleaned
        }

        let truncated = String(cleaned.prefix(57))
        if let lastSpace = truncated.lastIndex(of: " ") {
            return String(truncated[..<lastSpace]) + "..."
        } else {
            return truncated + "..."
        }
    }

    /// Processes transcription text using a custom user-defined prompt
    /// - Parameters:
    ///   - transcription: The full transcription text to process
    ///   - customPrompt: The user's custom prompt/instructions for processing
    /// - Returns: The processed text, or nil if processing failed or is unavailable
    public func processWithCustomPrompt(transcription: String, customPrompt: String) async -> String? {
        guard isAvailable else {
            logWarning("Custom prompt processing skipped: Foundation Models not available", category: .app)
            return nil
        }

        let trimmedText = transcription.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPrompt = customPrompt.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedText.isEmpty else {
            logWarning("Custom prompt processing skipped: Empty transcription", category: .app)
            return nil
        }

        guard !trimmedPrompt.isEmpty else {
            logWarning("Custom prompt processing skipped: Empty prompt", category: .app)
            return nil
        }

        isProcessing = true
        defer { isProcessing = false }

        logInfo(
            "Processing transcription with custom prompt (prompt_chars=\(trimmedPrompt.count), text_chars=\(trimmedText.count))...",
            category: .app
        )
        let startTime = Date()

        guard #available(macOS 26.0, *) else {
            logWarning("Custom prompt processing skipped: macOS 26.0 required", category: .app)
            return nil
        }

        #if canImport(FoundationModels)
        do {
            let session = LanguageModelSession(instructions: trimmedPrompt)
            let response = try await session.respond(to: trimmedText)
            let processedText = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            if !processedText.isEmpty {
                let changed = processedText != trimmedText
                logInfo("Custom prompt processing changed text: \(changed)", category: .app)
            }

            let duration = Date().timeIntervalSince(startTime)
            logInfo("Custom prompt processing completed in \(String(format: "%.2f", duration))s (\(processedText.count) chars)", category: .app)

            return processedText.isEmpty ? nil : processedText
        } catch {
            logError("Failed to process with custom prompt: \(error.localizedDescription)", category: .app)
            return nil
        }
        #else
        return nil
        #endif
    }
}

public enum SummarizationError: LocalizedError {
    case notAvailable
    case emptyTranscription
    case generationFailed(String)

    public var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "AI summarization is not available on this device"
        case .emptyTranscription:
            return "Cannot summarize empty transcription"
        case .generationFailed(let reason):
            return "Summary generation failed: \(reason)"
        }
    }
}
