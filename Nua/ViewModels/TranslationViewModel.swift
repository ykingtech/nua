import SwiftUI
import UIKit

@MainActor final class TranslationViewModel: ObservableObject {
    @Published var input = ""
    @Published var result: TranslationResult?
    @Published var isLoading = false
    @Published var errorMessage: String?
    private let service: GeminiServing

    init(service: GeminiServing = GeminiService()) { self.service = service }

    func loadClipboard() {
        if let text = UIPasteboard.general.string, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, text != input { input = text }
    }

    func translate() {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { errorMessage = "Paste a Japanese message first."; return }
        errorMessage = nil; result = nil; isLoading = true
        Task {
            do { result = try await service.translate(japanese: text) }
            catch { errorMessage = (error as? LocalizedError)?.errorDescription ?? "Something went wrong. Please try again." }
            isLoading = false
        }
    }

    func copyTranslation() {
        guard let result else { return }
        UIPasteboard.general.string = result.naturalEnglish + (result.meaning.map { "\n\nMeaning: \($0)" } ?? "")
    }
}
