import Foundation

/// LLM服务提供商枚举
/// 定义了支持的各种LLM服务提供商
enum LLMProvider: String, Codable, CaseIterable {
    // MARK: - Cases
    
    /// OpenAI API服务
    case openAI = "OpenAI"
    
    /// Anthropic API服务
    case anthropic = "Anthropic"
    
    /// 自定义API服务
    case custom = "自定义"
    
    /// Deepseek API服务
    case deepseek = "Deepseek"
    
    // MARK: - Static Properties
    
    /// 返回排序后的提供者列表，自定义始终在底部，其他选项按字母顺序排序
    static var sortedCases: [LLMProvider] {
        let allCases = Self.allCases.filter { $0 != .custom }
        let sorted = allCases.sorted { $0.rawValue.localizedStandardCompare($1.rawValue) == .orderedAscending }
        return sorted + [.custom]
    }
    
    // MARK: - Properties
    
    /// 获取提供商的默认API基础URL
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
    
    /// 获取提供商支持的默认模型列表
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

/// LLM配置结构体
/// 定义了与LLM服务交互所需的配置参数
struct LLMConfig: Codable, Equatable {
    // MARK: - Properties
    
    /// LLM服务提供商
    var provider: LLMProvider
    
    /// API基础URL
    var baseURL: String
    
    /// API密钥
    var apiKey: String
    
    /// 使用的模型名称
    var model: String
    
    /// 温度参数，控制输出的随机性
    var temperature: Double
    
    /// 最大输出token数
    var maxTokens: Int
    
    // MARK: - Static Properties
    
    /// 默认配置
    static let defaultConfig = LLMConfig(
        provider: .openAI,
        baseURL: "https://api.openai.com/v1",
        apiKey: "",
        model: "gpt-4o",
        temperature: 0.7,
        maxTokens: 1000
    )
    
    // MARK: - Equatable
    
    static func == (lhs: LLMConfig, rhs: LLMConfig) -> Bool {
        return lhs.provider == rhs.provider &&
               lhs.baseURL == rhs.baseURL &&
               lhs.apiKey == rhs.apiKey &&
               lhs.model == rhs.model &&
               lhs.temperature == rhs.temperature &&
               lhs.maxTokens == rhs.maxTokens
    }
}

/// LLM响应结构体
/// 定义了LLM服务返回的响应格式
struct LLMResponse: Decodable {
    // MARK: - Properties
    
    /// 响应内容
    let content: String
    
    /// 错误信息，如果有的话
    let error: String?
}

/// 模型信息结构体
/// 定义了LLM模型的详细信息
struct Model: Identifiable, Codable, Hashable {
    // MARK: - Properties
    
    /// 模型的唯一标识符
    let id: String
    
    /// 模型的显示名称
    let name: String
    
    /// 模型的描述信息
    let description: String?
    
    /// 模型的上下文长度限制
    let contextLength: Int?
    
    /// 模型的提供商信息
    let provider: String?
    
    // MARK: - Computed Properties
    
    /// 检查是否是思维链模型
    /// 通过模型名称中的关键词判断
    var isThinkingModel: Bool {
        let modelName = name.lowercased()
        let components = modelName.components(separatedBy: CharacterSet.alphanumerics.inverted)
        
        // 检查常见的思维链关键词
        if modelName.contains("thinking") || 
           modelName.contains("thought") || 
           modelName.contains("cot") {
            return true
        }
        
        // 检查 "o1" 是否作为独立标记出现
        return components.contains("o1")
    }
    
    // MARK: - Coding Keys
    
    enum CodingKeys: String, CodingKey {
        case id
        case description
        case contextLength = "context_length"
        case provider
    }
    
    // MARK: - Initialization
    
    /// 从解码器创建Model实例
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = id  // 使用id作为name
        description = try container.decodeIfPresent(String.self, forKey: .description)
        contextLength = try container.decodeIfPresent(Int.self, forKey: .contextLength)
        provider = try container.decodeIfPresent(String.self, forKey: .provider)
    }
    
    /// 创建一个新的Model实例
    /// - Parameters:
    ///   - id: 模型ID
    ///   - name: 模型名称，如果为nil则使用id
    ///   - description: 模型描述
    ///   - contextLength: 上下文长度限制
    ///   - provider: 提供商信息
    init(id: String, name: String? = nil, description: String? = nil, contextLength: Int? = nil, provider: String? = nil) {
        self.id = id
        self.name = name ?? id  // 如果没有提供name，使用id
        self.description = description
        self.contextLength = contextLength
        self.provider = provider
    }
    
    // MARK: - Hashable
    
    /// 实现Hashable协议的hash方法
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    /// 实现Equatable协议的相等性判断
    static func == (lhs: Model, rhs: Model) -> Bool {
        lhs.id == rhs.id
    }
} 