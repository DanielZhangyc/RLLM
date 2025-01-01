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
            return ["gpt-4", "gpt-3.5-turbo"]
        case .anthropic:
            return ["claude-3-opus", "claude-3-sonnet", "claude-3-haiku"]
        case .custom:
            return []
        case .deepseek:
            return ["deepseek-chat"]
        }
    }
    
    var summaryPrompt: (Article) -> String {
        switch self {
        case .openAI:
            return { article in
                """
                请对以下文章进行概括总结。要求：
                1. 提取文章的核心主题和关键信息
                2. 用简洁的语言总结主要观点
                3. 突出文章的价值和意义
                4. 总结控制在200字以内
                
                文章标题：\(article.title)
                文章内容：\(article.content)
                """
            }
        case .anthropic:
            return { article in
                """
                Human: 请帮我总结这篇文章的主要内容。需要：提取核心主题、关键信息点、主要观点，并突出其价值。请用简洁的语言，控制在200字以内。

                文章标题：\(article.title)
                文章内容：\(article.content)

                Assistant: 让我为您总结这篇文章的要点：
                """
            }
        case .custom:
            return { article in
                """
                [INST]请总结以下文章：
                标题：\(article.title)
                内容：\(article.content)
                [/INST]
                """
            }
        case .deepseek:
            return { article in
                """
                [{
                    "role": "system",
                    "content": "你是一个专业的文章分析助手，善于提取文章重点并进行精准总结。"
                },
                {
                    "role": "user",
                    "content": "请总结以下文章：\n标题：\(article.title)\n内容：\(article.content)\n要求：\n1. 提取核心主题\n2. 总结关键信息\n3. 控制在200字以内"
                }]
                """
            }
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
        model: "gpt-3.5-turbo",
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