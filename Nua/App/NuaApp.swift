import SwiftUI

@main
struct NuaApp: App {
    @StateObject private var viewModel = TranslationViewModel()

    var body: some Scene {
        WindowGroup { ContentView(viewModel: viewModel) }
    }
}
