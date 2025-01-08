import Foundation

struct LLMConnection {
    let endpoint: String
    let headers: [String: String]
    let body: [String: Any]
}

class LLMConnectionManager {
    static func getConnection(for provider: LLMProvider, config: LLMConfig, prompt: String, temperature: Double) -> LLMConnection {
        var endpoint: String
        var headers: [String: String] = [
            "Content-Type": "application/json"
        ]
        var body: [String: Any]
        
        switch provider {
        case .openAI:
            endpoint = "\(config.baseURL)/chat/completions"
            headers["Authorization"] = "Bearer \(config.apiKey)"
            body = [
                "model": config.model,
                "messages": [
                    ["role": "system", "content": "你是一个专业的文章分析助手，善于深入分析文章并提供独到见解。你的输出必须严格遵循指定的格式。"],
                    ["role": "user", "content": prompt]
                ],
                "temperature": temperature,
                "max_tokens": config.maxTokens
            ]
            
        case .anthropic:
            endpoint = "\(config.baseURL)/v1/messages"
            headers["x-api-key"] = config.apiKey
            headers["anthropic-version"] = "2023-06-01"
            body = [
                "model": config.model,
                "max_tokens": config.maxTokens,
                "temperature": temperature,
                "messages": [["role": "user", "content": prompt]]
            ]
            
        case .deepseek:
            endpoint = "\(config.baseURL)/chat/completions"
            headers["Authorization"] = "Bearer \(config.apiKey)"
            body = [
                "model": config.model,
                "messages": [
                    ["role": "system", "content": "你是一个专业的文章分析助手，善于深入分析文章并提供独到见解。你的输出必须严格遵循指定的格式。"],
                    ["role": "user", "content": prompt]
                ],
                "temperature": temperature,
                "max_tokens": config.maxTokens
            ]
            
        case .custom:
            endpoint = "\(config.baseURL)/chat/completions"
            headers["Authorization"] = "Bearer \(config.apiKey)"
            body = [
                "model": config.model,
                "messages": [
                    ["role": "system", "content": "你是一个专业的文章分析助手，善于深入分析文章并提供独到见解。你的输出必须严格遵循指定的格式。"],
                    ["role": "user", "content": prompt]
                ],
                "temperature": temperature,
                "max_tokens": config.maxTokens
            ]
        }
        
        return LLMConnection(endpoint: endpoint, headers: headers, body: body)
    }
    
    static func getProviders() -> [LLMProvider] {
        // 返回排序后的提供者列表，自定义始终在底部，其他选项按字母顺序排序
        let allCases = LLMProvider.allCases.filter { $0 != .custom }
        let sorted = allCases.sorted { $0.rawValue.localizedStandardCompare($1.rawValue) == .orderedAscending }
        return sorted + [.custom]
    }
    
    static func getModelEndpoint(for provider: LLMProvider, config: LLMConfig) -> (endpoint: String, headers: [String: String]) {
        var endpoint: String
        var headers: [String: String] = [
            "Content-Type": "application/json"
        ]
        
        switch provider {
        case .openAI:
            endpoint = "\(config.baseURL)/models"
            headers["Authorization"] = "Bearer \(config.apiKey)"
        case .anthropic:
            endpoint = "\(config.baseURL)/v1/models"
            headers["x-api-key"] = config.apiKey
            headers["anthropic-version"] = "2023-06-01"
        case .deepseek:
            endpoint = "\(config.baseURL)/models"
            headers["Authorization"] = "Bearer \(config.apiKey)"
        case .custom:
            endpoint = "\(config.baseURL)/models"
            headers["Authorization"] = "Bearer \(config.apiKey)"
            headers["HTTP-Referer"] = "https://github.com/CaffeineShawn/RLLM"
            headers["X-Title"] = "RLLM"
        }
        
        return (endpoint, headers)
    }
}