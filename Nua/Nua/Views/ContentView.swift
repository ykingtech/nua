import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: TranslationViewModel
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            ScrollView { VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 10) { Image("NuaLogo").resizable().scaledToFit().frame(width: 48, height: 48).clipShape(RoundedRectangle(cornerRadius: 12)); Text("Nua").font(.largeTitle.bold()) }
                Text("Japanese, in the words they meant.").foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 8) {
                    Label("Original", systemImage: "character.cursor.ibeam")
                    TextEditor(text: $viewModel.input).frame(minHeight: 130).padding(8).background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
                    Button { viewModel.loadClipboard(); viewModel.translate() } label: { Label("Paste & Translate", systemImage: "doc.on.clipboard") }.buttonStyle(.borderedProminent).controlSize(.large)
                }
                if viewModel.isLoading { ProgressView("Translating…").frame(maxWidth: .infinity, alignment: .center) }
                if let error = viewModel.errorMessage { Label(error, systemImage: "exclamationmark.triangle").foregroundStyle(.red).font(.subheadline) }
                if let result = viewModel.result {
                    VStack(alignment: .leading, spacing: 10) { Text("Natural English").font(.headline); Text(result.naturalEnglish).font(.title3)
                        if let meaning = result.meaning, !meaning.isEmpty { Divider(); Text("Meaning").font(.headline); Text(meaning).foregroundStyle(.secondary) }
                        Button { viewModel.copyTranslation() } label: { Label("Copy Translation", systemImage: "doc.on.doc") }.buttonStyle(.bordered)
                    }.padding().background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                }
            }.padding() }.navigationBarTitleDisplayMode(.inline)
        }.onChange(of: scenePhase) { _, phase in if phase == .active { viewModel.loadClipboard() } }
    }
}
