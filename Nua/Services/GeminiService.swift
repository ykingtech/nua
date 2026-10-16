import Foundation

enum GeminiError: LocalizedError {
    case missingWorkerURL, invalidResponse, server(String), rateLimited, emptyResponse
    var errorDescription: String? {
        switch self {
        case .missingWorkerURL: return "Nua’s translation service isn’t configured yet."
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
    private let workerURL: URL?

    init(session: URLSession = .shared) {
        self.session = session
        let configuredURL = (Bundle.main.object(forInfoDictionaryKey: "NUA_WORKER_URL") as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        self.workerURL = configuredURL.hasPrefix("http") ? URL(string: configuredURL) : nil
    }

    func translate(japanese: String) async throws -> TranslationResult {
        guard let workerURL else { throw GeminiError.missingWorkerURL }
        var request = URLRequest(url: workerURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(TranslationRequest(japanese: japanese))
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw GeminiError.invalidResponse }
        if http.statusCode == 429 { throw GeminiError.rateLimited }
        guard (200..<300).contains(http.statusCode) else {
            switch http.statusCode {
            default:
                let message = (try? JSONDecoder().decode(WorkerError.self, from: data))?.error
                throw GeminiError.server(message ?? "Nua couldn’t translate this message. Please try again.")
            }
        }
        let result = try JSONDecoder().decode(TranslationResult.self, from: data)
        guard !result.naturalEnglish.isEmpty else { throw GeminiError.emptyResponse }
        return result
    }
}

private struct TranslationRequest: Encodable { let japanese: String }
private struct WorkerError: Decodable { let error: String }
