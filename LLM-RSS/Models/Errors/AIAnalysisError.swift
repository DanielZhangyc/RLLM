import Foundation

/// AI分析过程中可能出现的错误
enum AIAnalysisError: LocalizedError {
    /// 配置相关错误
    case configurationError(String)
    /// 网络请求错误
    case networkError(Error)
    /// 响应解析错误
    case parseError(String)
    /// LLM服务错误
    case llmServiceError(String)
    /// 内容处理错误
    case contentError(String)
    
    var errorDescription: String? {
        switch self {
        case .configurationError(let message):
            return "配置错误：\(message)"
        case .networkError(let error):
            return "网络错误：\(error.localizedDescription)"
        case .parseError(let message):
            return "解析错误：\(message)"
        case .llmServiceError(let message):
            return "LLM服务错误：\(message)"
        case .contentError(let message):
            return "内容错误：\(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .configurationError:
            return "请检查LLM服务配置是否正确，确保已设置正确的API密钥和服务地址。"
        case .networkError:
            return "请检查网络连接是否正常，或稍后重试。"
        case .parseError:
            return "LLM响应格式异常，请重试或调整提示词。"
        case .llmServiceError:
            return "LLM服务异常，请检查服务状态或更换其他模型。"
        case .contentError:
            return "请确保文章内容不为空且格式正确。"
        }
    }
    
    var failureReason: String? {
        switch self {
        case .configurationError:
            return "LLM服务配置无效或缺失"
        case .networkError:
            return "网络请求失败"
        case .parseError:
            return "响应格式不符合预期"
        case .llmServiceError:
            return "LLM服务调用失败"
        case .contentError:
            return "文章内容处理失败"
        }
    }
} 