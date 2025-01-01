import SwiftUI

class LLMSettingsViewModel: ObservableObject {
    @AppStorage("llmConfig") private var storedConfig: Data?
    
    @Published var config: LLMConfig
    @Published var availableModels: [String]
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
        self.availableModels = []
        self.isTestingConnection = false
        self.testResult = nil
        
        // 初始化后立即获取模型列表
        Task {
            await fetchModels()
        }
    }
    
    func updateProvider(_ provider: LLMProvider) {
        config.provider = provider
        config.baseURL = provider.defaultBaseURL
        config.model = ""  // 清空当前选择的模型
        saveConfig()
        Task {
            await fetchModels()
        }
    }
    
    @MainActor
    func fetchModels() async {
        guard !config.apiKey.isEmpty && !config.baseURL.isEmpty else {
            print("API Key 或 Base URL 为空")
            return
        }
        
        isLoadingModels = true
        error = nil
        
        do {
            print("开始获取模型列表")
            var models = try await LLMService.shared.fetchAvailableModels(config: config)
            
            // 如果包含"自定义"，将其移到列表末尾
            if let customIndex = models.firstIndex(of: "自定义") {
                models.remove(at: customIndex)
                models.append("自定义")
            }
            
            // 对其它模型按首字母排序
            let sortedModels = models.filter { $0 != "自定义" }.sorted()
            availableModels = sortedModels + models.filter { $0 == "自定义" }
            
            print("获取到排序后的模型列表: \(availableModels)")
            
            if !availableModels.isEmpty && (config.model.isEmpty || !availableModels.contains(config.model)) {
                config.model = availableModels[0]
                saveConfig()
            }
        } catch {
            print("获取模型列表失败: \(error)")
            self.error = error
            availableModels = []
        }
        
        isLoadingModels = false
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
                    self.testResult = "连接成功"
                }
            } catch {
                await MainActor.run {
                    self.testResult = "连接失败: \(error.localizedDescription)"
                }
            }
            await MainActor.run {
                self.isTestingConnection = false
            }
        }
    }
}