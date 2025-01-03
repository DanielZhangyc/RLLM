import Foundation

enum LLMProvider: String, Codable, CaseIterable {
    case openAI = "OpenAI"
    case anthropic = "Anthropic"
    case custom = "自定义"
    case deepseek = "Deepseek"
    
    /// 返回排序后的提供者列表，自定义始终在底部，其他选项按字母顺序排序
    static var sortedCases: [LLMProvider] {
        let allCases = Self.allCases.filter { $0 != .custom }
        let sorted = allCases.sorted { $0.rawValue.localizedStandardCompare($1.rawValue) == .orderedAscending }
        return sorted + [.custom]
    }
    
    var defaultBaseURL: String {
        switch self {
        case .openAI:
            return "https://api.openai.com/v1"
        case .anthropic:
            return "https://api.anthropic.com"
        case .custom:
            return ""
        case .deepseek:
            return "https://api.deepseek.com"
        }
    }
    
    var defaultModels: [String] {
        switch self {
        case .openAI:
            return ["gpt-4", "gpt-3.5-turbo", "gpt-4o"]
        case .anthropic:
            return ["claude-3-opus", "claude-3-sonnet", "claude-3-haiku"]
        case .custom:
            return []
        case .deepseek:
            return ["deepseek-chat"]
        }
    }
}

struct LLMConfig: Codable, Equatable {
    var provider: LLMProvider
    var baseURL: String
    var apiKey: String
    var model: String
    var temperature: Double
    var maxTokens: Int
    
    static let defaultConfig = LLMConfig(
        provider: .openAI,
        baseURL: "https://api.openai.com/v1",
        apiKey: "",
        model: "gpt-4o",
        temperature: 0.7,
        maxTokens: 1000
    )
    
    static func == (lhs: LLMConfig, rhs: LLMConfig) -> Bool {
        return lhs.provider == rhs.provider &&
               lhs.baseURL == rhs.baseURL &&
               lhs.apiKey == rhs.apiKey &&
               lhs.model == rhs.model &&
               lhs.temperature == rhs.temperature &&
               lhs.maxTokens == rhs.maxTokens
    }
}

struct LLMResponse: Decodable {
    let content: String
    let error: String?
} 