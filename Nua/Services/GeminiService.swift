import Foundation

enum GeminiError: LocalizedError {
    case missingAPIKey, invalidResponse, server(String), rateLimited, emptyResponse
    var errorDescription: String? {
        switch self {
        case .missingAPIKey: return "Gemini isn’t configured yet. Add GEMINI_API_KEY to the app configuration."
        case .invalidResponse: return "Gemini returned an unexpected response. Please try again."
        case .server(let message): return message
        case .rateLimited: return "Gemini is busy right now. Please try again in a moment."
        case .emptyResponse: return "No translation was returned. Please try again."
        }
    }
}

protocol GeminiServing { func translate(japanese: String) async throws -> TranslationResult }

final class GeminiService: GeminiServing {
    private let session: URLSession
    private let apiKey: String
    private let model: String

    init(session: URLSession = .shared) {
        self.session = session
        self.apiKey = (Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        self.model = Bundle.main.object(forInfoDictionaryKey: "GEMINI_MODEL") as? String ?? "gemini-2.5-flash"
    }

    func translate(japanese: String) async throws -> TranslationResult {
        guard !apiKey.isEmpty, !apiKey.hasPrefix("$(") else { throw GeminiError.missingAPIKey }
        let endpoint = "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)"
        guard let url = URL(string: endpoint) else { throw GeminiError.invalidResponse }
        let prompt = """
        You translate Japanese chat messages into natural conversational English. Preserve the real intended meaning, tone, emotion, slang, implied context, teasing, friendliness, sarcasm, politeness, and casual texting style. Do not translate mechanically word-for-word. Do not invent context. Return ONLY valid JSON with keys naturalEnglish (string) and meaning (string or null). Keep meaning brief and null for simple messages.
        Japanese message:
        \(japanese)
        """
        let body: [String: Any] = ["contents": [["parts": [["text": prompt]]]], "generationConfig": ["responseMimeType": "application/json", "temperature": 0.2]]
        var request = URLRequest(url: url); request.httpMethod = "POST"; request.setValue("application/json", forHTTPHeaderField: "Content-Type"); request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw GeminiError.invalidResponse }
        if http.statusCode == 429 { throw GeminiError.rateLimited }
        guard (200..<300).contains(http.statusCode) else { throw GeminiError.server("Gemini couldn’t translate this message. Please try again.") }
        let envelope = try JSONDecoder().decode(GeminiEnvelope.self, from: data)
        guard let text = envelope.candidates?.first?.content.parts.first?.text, let json = text.data(using: .utf8), let result = try? JSONDecoder().decode(TranslationResult.self, from: json), !result.naturalEnglish.isEmpty else { throw GeminiError.emptyResponse }
        return result
    }
}

private struct GeminiEnvelope: Decodable { let candidates: [Candidate]? }
private struct Candidate: Decodable { let content: CandidateContent }
private struct CandidateContent: Decodable { let parts: [Part] }
private struct Part: Decodable { let text: String? }
