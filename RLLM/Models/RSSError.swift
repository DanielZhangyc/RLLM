import Foundation

/// RSS相关操作的错误类型
enum RSSError: Error {
    /// 无效的URL
    case invalidURL
    /// 获取错误
    case fetchError(Error)
    /// 解析错误
    case parseError(Error)
    /// 重复的Feed
    case duplicateFeed
    /// 无效的Feed数据
    case invalidFeed
}

// MARK: - LocalizedError

extension RSSError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的URL"
        case .fetchError(let error):
            return "获取错误: \(error.localizedDescription)"
        case .parseError(let error):
            return "解析错误: \(error.localizedDescription)"
        case .duplicateFeed:
            return "订阅源已存在"
        case .invalidFeed:
            return "无效的Feed数据"
        }
    }
} 