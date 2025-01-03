import Foundation

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
        // 构建阅读记录的文本表示
        let recordsText = records.map { record -> String in
            """
            标题：\(record.articleTitle)
            阅读时长：\(Int(record.duration / 60))分钟
            开始时间：\(DateFormatter.timeOnly.string(from: record.startTime))
            """
        }.joined(separator: "\n\n")
        
        return LLMPrompts.format(LLMPrompts.dailySummary, with: [
            "reading_records": recordsText
        ])
    }
    
    private func buildTopicAnalysisPrompt(with records: [ReadingRecord]) -> String {
        // 构建阅读记录的文本表示
        let recordsText = records.map { record -> String in
            """
            标题：\(record.articleTitle)
            阅读时长：\(Int(record.duration / 60))分钟
            URL：\(record.articleURL)
            """
        }.joined(separator: "\n\n")
        
        return LLMPrompts.format(LLMPrompts.topicAnalysis, with: [
            "reading_records": recordsText
        ])
    }
    
    /// 生成今日阅读总结
    /// - Parameters:
    ///   - records: 阅读记录列表
    ///   - config: LLM配置
    /// - Returns: 生成的总结内容
    func generateDailySummary(for records: [ReadingRecord], config: LLMConfig) async throws -> String {
        let prompt = buildDailySummaryPrompt(with: records)
        return try await sendRequest(prompt: prompt, config: config)
    }
    
    /// 分析热门话题
    /// - Parameters:
    ///   - records: 阅读记录列表
    ///   - config: LLM配置
    /// - Returns: 话题分析结果
    func analyzeTopics(for records: [ReadingRecord], config: LLMConfig) async throws -> String {
        let prompt = buildTopicAnalysisPrompt(with: records)
        return try await sendRequest(prompt: prompt, config: config)
    }
    
    /// 发送请求到LLM服务
    /// - Parameters:
    ///   - prompt: 提示词
    ///   - config: LLM配置
    /// - Returns: LLM响应内容
    private func sendRequest(prompt: String, config: LLMConfig) async throws -> String {
        print("准备发送LLM请求：")
        print("提供商：\(config.provider.rawValue)")
        print("模型：\(config.model)")
        print("提示词长度：\(prompt.count)字符")
        
        let temperature = 0.3
        let connection = LLMConnectionManager.getConnection(for: config.provider, config: config, prompt: prompt, temperature: temperature)
        
        guard let url = URL(string: connection.endpoint) else {
            print("无效的URL：\(connection.endpoint)")
            throw LLMError.invalidURL
        }
        
        print("请求URL：\(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject: connection.body)
        connection.headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        
        print("请求头：\(connection.headers)")
        
        do {
            print("开始发送请求...")
            let (data, response) = try await URLSession.shared.data(for: request)
            print("收到响应，数据长度：\(data.count)字节")
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("无效的响应类型")
                throw LLMError.invalidResponse
            }
            
            print("HTTP状态码：\(httpResponse.statusCode)")
            
            if httpResponse.statusCode == 401 {
                print("认证失败")
                throw LLMError.authenticationFailed
            }
            
            if let responseStr = String(data: data, encoding: .utf8) {
                print("响应内容：\n\(responseStr)")
            }
            
            // 解析不同提供商的响应
            switch config.provider {
            case .openAI:
                let response = try JSONDecoder().decode(OpenAIResponse.self, from: data)
                guard let content = response.choices.first?.message.content else {
                    print("OpenAI响应缺少内容")
                    throw LLMError.noContent
                }
                print("成功解析OpenAI响应")
                return content
                
            case .anthropic:
                let response = try JSONDecoder().decode(AnthropicResponse.self, from: data)
                guard let content = response.content.first?.text else {
                    print("Anthropic响应缺少内容")
                    throw LLMError.noContent
                }
                print("成功解析Anthropic响应")
                return content
                
            case .custom:
                let response = try JSONDecoder().decode(CustomResponse.self, from: data)
                print("成功解析自定义响应")
                return response.text
                
            case .deepseek:
                let response = try JSONDecoder().decode(OpenAIResponse.self, from: data)
                guard let content = response.choices.first?.message.content else {
                    print("Deepseek响应缺少内容")
                    throw LLMError.noContent
                }
                print("成功解析Deepseek响应")
                return content
            }
            
        } catch {
            print("请求失败：\(error.localizedDescription)")
            if let decodingError = error as? DecodingError {
                print("解码错误：\(decodingError)")
                throw LLMError.decodingError(decodingError)
            }
            throw LLMError.networkError(error)
        }
    }
    
    func generateInsight(for content: String, config: LLMConfig) async throws -> String {
        let prompt = buildInsightPrompt(for: content)
        
        let temperature = 0.3
        let connection = LLMConnectionManager.getConnection(for: config.provider, config: config, prompt: prompt, temperature: temperature)
        
        guard let url = URL(string: connection.endpoint) else {
            throw LLMError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject: connection.body)
        connection.headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw LLMError.invalidResponse
            }
            
            if httpResponse.statusCode == 401 {
                throw LLMError.authenticationFailed
            }
            
            // 解析不同提供商的响应
            switch config.provider {
            case .openAI:
                let response = try JSONDecoder().decode(OpenAIResponse.self, from: data)
                guard let content = response.choices.first?.message.content else {
                    throw LLMError.noContent
                }
                return content
                
            case .anthropic:
                let response = try JSONDecoder().decode(AnthropicResponse.self, from: data)
                guard let content = response.content.first?.text else {
                    throw LLMError.noContent
                }
                return content
                
            case .custom:
                let response = try JSONDecoder().decode(CustomResponse.self, from: data)
                return response.text
                
            case .deepseek:
                let response = try JSONDecoder().decode(OpenAIResponse.self, from: data)
                guard let content = response.choices.first?.message.content else {
                    throw LLMError.noContent
                }
                return content
            }
            
        } catch {
            throw LLMError.networkError(error)
        }
    }
    
    func generateSummary(for article: Article, config: LLMConfig) async throws -> String {
        let prompt = buildSummaryPrompt(for: article)
        
        let connection = LLMConnectionManager.getConnection(for: config.provider, config: config, prompt: prompt, temperature: config.temperature)
        
        guard let url = URL(string: connection.endpoint) else {
            throw LLMError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject: connection.body)
        connection.headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw LLMError.invalidResponse
            }
            
            if httpResponse.statusCode == 401 {
                throw LLMError.authenticationFailed
            }
            
            // 解析不同提供商的响应
            switch config.provider {
            case .openAI:
                let response = try JSONDecoder().decode(OpenAIResponse.self, from: data)
                guard let content = response.choices.first?.message.content else {
                    throw LLMError.noContent
                }
                return content
                
            case .anthropic:
                let response = try JSONDecoder().decode(AnthropicResponse.self, from: data)
                guard let content = response.content.first?.text else {
                    throw LLMError.noContent
                }
                return content
                
            case .custom:
                let response = try JSONDecoder().decode(CustomResponse.self, from: data)
                return response.text
                
            case .deepseek:
                let response = try JSONDecoder().decode(OpenAIResponse.self, from: data)
                guard let content = response.choices.first?.message.content else {
                    throw LLMError.noContent
                }
                return content
            }
            
        } catch {
            throw LLMError.networkError(error)
        }
    }
    
    func fetchAvailableModels(config: LLMConfig) async throws -> [String] {
        let (endpoint, headers) = LLMConnectionManager.getModelEndpoint(for: config.provider, config: config)
        
        guard let url = URL(string: endpoint) else {
            throw LLMError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw LLMError.invalidResponse
            }
            
            if httpResponse.statusCode == 401 {
                throw LLMError.authenticationFailed
            }
            
            switch config.provider {
            case .openAI:
                let response = try JSONDecoder().decode(OpenAIModelsResponse.self, from: data)
                return response.data.map { $0.id }
                    .filter { $0.contains("gpt") } // 只返回 GPT 相关模型
                
            case .anthropic:
                let response = try JSONDecoder().decode(AnthropicModelsResponse.self, from: data)
                return response.models.map { $0.name }
                    .filter { $0.contains("claude") } // 只返回 Claude 相关模型
                
            case .custom:
                var models = config.provider.defaultModels
                // 先对其它模型按首字母排序
                models.sort()
                // 确保自定义选项始终在最后
                return models + ["自定义"]
                
            case .deepseek:
                let response = try JSONDecoder().decode(OpenAIModelsResponse.self, from: data)
                return response.data.map { $0.id }
                    .filter { $0.contains("deepseek") }
                    .sorted() // 按首字母排序
            }
            
        } catch {
            throw LLMError.networkError(error)
        }
    }
}

// API 响应模型
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

// 添加模型列表响应的结构
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