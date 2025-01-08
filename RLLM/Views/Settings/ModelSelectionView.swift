import SwiftUI

struct ModelSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ModelSelectionViewModel()
    @State private var searchText = ""
    let config: LLMConfig
    let onModelSelected: (String) -> Void
    
    private var filteredModels: [Model] {
        if searchText.isEmpty {
            return viewModel.models
        }
        return viewModel.models.filter { model in
            model.name.localizedCaseInsensitiveContains(searchText) ||
            (model.description?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            (model.provider?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(filteredModels) { model in
                    ModelCard(
                        model: model,
                        isSelected: model.id == config.model,
                        onTap: {
                            onModelSelected(model.id)
                            dismiss()
                        }
                    )
                    .transition(.opacity)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
        .navigationTitle("选择模型")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "搜索模型", suggestions: {
            if searchText.isEmpty {
                ForEach(viewModel.models.prefix(3)) { model in
                    Text(model.name)
                        .searchCompletion(model.name)
                }
            }
        })
        .animation(.easeInOut, value: filteredModels)
        .overlay {
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground).opacity(0.8))
            }
        }
        .alert("错误", isPresented: $viewModel.showError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "未知错误")
        }
        .task {
            await viewModel.fetchModels(config: config)
        }
    }
}

class ModelSelectionViewModel: ObservableObject {
    @Published var models: [Model] = []
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage: String?
    
    @MainActor
    func fetchModels(config: LLMConfig) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let models = try await LLMService.shared.fetchAvailableModels(config: config)
            self.models = models
        } catch {
            self.errorMessage = error.localizedDescription
            self.showError = true
        }
    }
} 