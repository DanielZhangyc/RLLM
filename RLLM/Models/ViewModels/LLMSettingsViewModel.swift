import SwiftUI

class LLMSettingsViewModel: ObservableObject {
    @AppStorage("llmConfig") private var storedConfig: Data?
    
    @Published var config: LLMConfig
    @Published var isTestingConnection = false
    @Published var testResult: String?
    @Published var isLoadingModels = false
    @Published var error: Error?
    
    init() {
        let initialConfig: LLMConfig
        if let storedData = UserDefaults.standard.data(forKey: "llmConfig"),
           let decoded = try? JSONDecoder().decode(LLMConfig.self, from: storedData) {
            initialConfig = decoded
        } else {
            initialConfig = .defaultConfig
        }
        
        self.config = initialConfig
        self.isTestingConnection = false
        self.testResult = nil
    }
    
    func updateProvider(_ provider: LLMProvider) {
        config.provider = provider
        config.baseURL = provider.defaultBaseURL
        config.model = ""  // 清空当前选择的模型
        saveConfig()
    }
    
    func saveConfig() {
        if let encoded = try? JSONEncoder().encode(config) {
            storedConfig = encoded
        }
    }
    
    func testConnection() {
        isTestingConnection = true
        testResult = nil
        
        Task {
            do {
                _ = try await LLMService.shared.fetchAvailableModels(config: config)
                await MainActor.run {
                    self.testResult = NSLocalizedString("settings.test_success", comment: "Test success")
                }
            } catch {
                await MainActor.run {
                    self.testResult = NSLocalizedString("settings.test_failed", comment: "Test failed") + ": \(error.localizedDescription)"
                }
            }
            await MainActor.run {
                self.isTestingConnection = false
            }
        }
    }
}