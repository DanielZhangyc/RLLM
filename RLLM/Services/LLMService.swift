import Foundation
import Alamofire

class LLMService {
    private let connectionManager = LLMConnectionManager()
    enum LLMError: LocalizedError {
        case invalidURL
        case networkError(Error)
        case invalidResponse
        case authenticationFailed
        case decodingError(Error)
        case noContent
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "无效的 URL"
            case .networkError(let error):
                return "网络错误: \(error.localizedDescription)"
            case .invalidResponse:
                return "无效的响应"
            case .authenticationFailed:
                return "认证失败，请检查 API Key"
            case .decodingError(let error):
                return "解析错误: \(error.localizedDescription)"
            case .noContent:
                return "未获取到有效内容"
            }
        }
    }
    
    static let shared = LLMService()
    private init() {}
    
    // MARK: - Private Methods
    
    private func buildSummaryPrompt(for article: Article) -> String {
        return LLMPrompts.format(LLMPrompts.summary, with: [
            "article_content": article.content.removingHTMLTags()
        ])
    }
    
    private func buildInsightPrompt(for content: String) -> String {
        return LLMPrompts.format(LLMPrompts.insight, with: [
            "article_content": content
        ])
    }
    
    private func buildDailySummaryPrompt(with records: [ReadingRecord]) -> String {
        let recordsText = records.map { record in
            """
            标题：\(record.articleTitle)
            阅读时长：\(record.duration)秒
            链接：\(record.articleURL)
            """
        }.joined(separator: "\n\n")
        
        return LLMPrompts.format(LLMPrompts.dailySummary, with: [
            "reading_records": recordsText
        ])
    }
    
    private func buildTopicAnalysisPrompt(with records: [ReadingRecord]) -> String {
        let recordsText = records.map { record in
            """
            标题：\(record.articleTitle)
            阅读时长：\(record.duration)秒
            链接：\(record.articleURL)
            """
        }.joined(separator: "\n\n")
        
        return LLMPrompts.format(LLMPrompts.topicAnalysis, with: [
            "reading_records": recordsText
        ])
    }
    
    // MARK: - Network Request Methods
    
    private func sendRequest<T: Decodable>(endpoint: String, 
                                         headers: [String: String], 
                                         body: [String: Any],
                                         responseType: T.Type) async throws -> T {
        print("准备发送LLM请求：")
        print("请求URL：\(endpoint)")
        print("请求头：\(headers)")
        
        return try await withCheckedThrowingContinuation { continuation in
            AF.request(endpoint,
                      method: .post,
                      parameters: body,
                      encoding: JSONEncoding.default,
                      headers: HTTPHeaders(headers))
            .validate()
            .responseDecodable(of: T.self) { response in
                switch response.result {
                case .success(let value):
                    print("请求成功，响应数据长度：\(response.data?.count ?? 0)字节")
                    continuation.resume(returning: value)
                    
                case .failure(let error):
                    print("请求失败：\(error.localizedDescription)")
                    if let statusCode = response.response?.statusCode {
                        if statusCode == 401 {
                            continuation.resume(throwing: LLMError.authenticationFailed)
                        } else {
                            continuation.resume(throwing: LLMError.networkError(error))
                        }
                    } else {
                        continuation.resume(throwing: LLMError.networkError(error))
                    }
                }
            }
        }
    }
    
    private func sendModelRequest<T: Decodable>(endpoint: String,
                                              headers: [String: String],
                                              responseType: T.Type) async throws -> T {
        print("准备获取模型列表：")
        print("请求URL：\(endpoint)")
        print("请求头：\(headers)")
        
        return try await withCheckedThrowingContinuation { continuation in
            AF.request(endpoint,
                      method: .get,
                      headers: HTTPHeaders(headers))
            .validate()
            .responseDecodable(of: T.self) { response in
                switch response.result {
                case .success(let value):
                    print("请求成功，响应数据长度：\(response.data?.count ?? 0)字节")
                    continuation.resume(returning: value)
                    
                case .failure(let error):
                    print("请求失败：\(error.localizedDescription)")
                    if let statusCode = response.response?.statusCode {
                        if statusCode == 401 {
                            continuation.resume(throwing: LLMError.authenticationFailed)
                        } else {
                            continuation.resume(throwing: LLMError.networkError(error))
                        }
                    } else {
                        continuation.resume(throwing: LLMError.networkError(error))
                    }
                }
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// 生成今日阅读总结
    /// - Parameters:
    ///   - records: 阅读记录列表
    ///   - config: LLM配置
    /// - Returns: 生成的总结内容
    func generateDailySummary(for records: [ReadingRecord], config: LLMConfig) async throws -> String {
        let prompt = buildDailySummaryPrompt(with: records)
        let connection = LLMConnectionManager.getConnection(for: config.provider, config: config, prompt: prompt, temperature: 0.3)
        
        guard let url = URL(string: connection.endpoint) else {
            throw LLMError.invalidURL
        }
        
        let response: OpenAIResponse = try await sendRequest(
            endpoint: url.absoluteString,
            headers: connection.headers,
            body: connection.body,
            responseType: OpenAIResponse.self
        )
        
        guard let content = response.choices.first?.message.content else {
            throw LLMError.noContent
        }
        
        return content
    }
    
    /// 分析热门话题
    /// - Parameters:
    ///   - records: 阅读记录列表
    ///   - config: LLM配置
    /// - Returns: 话题分析结果
    func analyzeTopics(for records: [ReadingRecord], config: LLMConfig) async throws -> String {
        let prompt = buildTopicAnalysisPrompt(with: records)
        let connection = LLMConnectionManager.getConnection(for: config.provider, config: config, prompt: prompt, temperature: 0.3)
        
        guard let url = URL(string: connection.endpoint) else {
            throw LLMError.invalidURL
        }
        
        let response: OpenAIResponse = try await sendRequest(
            endpoint: url.absoluteString,
            headers: connection.headers,
            body: connection.body,
            responseType: OpenAIResponse.self
        )
        
        guard let content = response.choices.first?.message.content else {
            throw LLMError.noContent
        }
        
        return content
    }
    
    func generateInsight(for content: String, config: LLMConfig) async throws -> String {
        let prompt = buildInsightPrompt(for: content)
        let connection = LLMConnectionManager.getConnection(for: config.provider, config: config, prompt: prompt, temperature: 0.3)
        
        guard let url = URL(string: connection.endpoint) else {
            throw LLMError.invalidURL
        }
        
        let response: OpenAIResponse = try await sendRequest(
            endpoint: url.absoluteString,
            headers: connection.headers,
            body: connection.body,
            responseType: OpenAIResponse.self
        )
        
        guard let content = response.choices.first?.message.content else {
            throw LLMError.noContent
        }
        
        return content
    }
    
    func generateSummary(for article: Article, config: LLMConfig) async throws -> String {
        let prompt = buildSummaryPrompt(for: article)
        let connection = LLMConnectionManager.getConnection(for: config.provider, config: config, prompt: prompt, temperature: config.temperature)
        
        guard let url = URL(string: connection.endpoint) else {
            throw LLMError.invalidURL
        }
        
        let response: OpenAIResponse = try await sendRequest(
            endpoint: url.absoluteString,
            headers: connection.headers,
            body: connection.body,
            responseType: OpenAIResponse.self
        )
        
        guard let content = response.choices.first?.message.content else {
            throw LLMError.noContent
        }
        
        return content
    }
    
    func fetchAvailableModels(config: LLMConfig) async throws -> [String] {
        let (endpoint, headers) = LLMConnectionManager.getModelEndpoint(for: config.provider, config: config)
        
        guard let url = URL(string: endpoint) else {
            throw LLMError.invalidURL
        }
        
        switch config.provider {
        case .openAI:
            let response: OpenAIModelsResponse = try await sendModelRequest(
                endpoint: url.absoluteString,
                headers: headers,
                responseType: OpenAIModelsResponse.self
            )
            return response.data.map { $0.id }
                .filter { $0.contains("gpt") }
            
        case .anthropic:
            let response: AnthropicModelsResponse = try await sendModelRequest(
                endpoint: url.absoluteString,
                headers: headers,
                responseType: AnthropicModelsResponse.self
            )
            return response.models.map { $0.name }
                .filter { $0.contains("claude") }
            
        case .custom:
            var models = config.provider.defaultModels
            models.sort()
            return models + ["自定义"]
            
        case .deepseek:
            let response: OpenAIModelsResponse = try await sendModelRequest(
                endpoint: url.absoluteString,
                headers: headers,
                responseType: OpenAIModelsResponse.self
            )
            return response.data.map { $0.id }
                .filter { $0.contains("deepseek") }
                .sorted()
        }
    }
}

// MARK: - API Response Models

private struct OpenAIResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable {
            let content: String
        }
        let message: Message
    }
    let choices: [Choice]
}

private struct AnthropicResponse: Codable {
    struct Content: Codable {
        let text: String
    }
    let content: [Content]
}

private struct CustomResponse: Codable {
    let text: String
}

private struct OpenAIModelsResponse: Codable {
    struct Model: Codable {
        let id: String
    }
    let data: [Model]
}

private struct AnthropicModelsResponse: Codable {
    struct Model: Codable {
        let name: String
    }
    let models: [Model]
}