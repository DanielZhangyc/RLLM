import Foundation

/// Feed存储错误类型
enum FeedStorageError: Error {
    /// 编码错误
    case encodingError
    /// 解码错误
    case decodingError
}

/// Feed存储服务，负责管理RSS订阅源的持久化存储
final class FeedStorage {
    // MARK: - Singleton
    
    /// 共享实例
    static let shared = FeedStorage()
    
    // MARK: - Constants
    
    /// UserDefaults中存储Feed列表的键
    private let feedsKey = "savedFeeds"
    
    // MARK: - Initialization
    
    /// 私有初始化方法，确保单例模式
    private init() {}
    
    // MARK: - Public Methods
    
    /// 从持久化存储中加载所有Feed
    /// - Returns: Feed列表
    /// - Throws: FeedStorageError.decodingError 当解码失败时
    func loadFeeds() throws -> [Feed] {
        guard let data = UserDefaults.standard.data(forKey: feedsKey) else {
            return []
        }
        
        do {
            return try JSONDecoder().decode([Feed].self, from: data)
        } catch {
            throw FeedStorageError.decodingError
        }
    }
    
    /// 保存Feed列表到持久化存储
    /// - Parameter feeds: 要保存的Feed列表
    /// - Throws: FeedStorageError.encodingError 当编码失败时
    func save(_ feeds: [Feed]) throws {
        do {
            let data = try JSONEncoder().encode(feeds)
            UserDefaults.standard.set(data, forKey: feedsKey)
        } catch {
            throw FeedStorageError.encodingError
        }
    }
}