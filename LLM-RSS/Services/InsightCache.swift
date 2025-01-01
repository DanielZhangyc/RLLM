import Foundation

/// AI洞察缓存管理
class InsightCache {
    /// 单例实例
    static let shared = InsightCache()
    
    /// 缓存管理器
    private let cacheManager: CacheManager
    
    private init() {
        cacheManager = CacheManager(directoryName: "insights")
    }
    
    /// 获取缓存的洞察结果
    /// - Parameter articleId: 文章ID
    /// - Returns: 缓存的洞察结果，如果不存在或已过期则返回nil
    func get(for articleId: String) -> ArticleInsight? {
        do {
            let data = try cacheManager.read(for: articleId)
            if !data.isEmpty {
                return try JSONDecoder().decode(ArticleInsight.self, from: data)
            }
        } catch {
            print("读取洞察缓存失败：\(error.localizedDescription)")
        }
        return nil
    }
    
    /// 保存洞察结果到缓存
    /// - Parameters:
    ///   - insight: 洞察结果
    ///   - articleId: 文章ID
    func set(_ insight: ArticleInsight, for articleId: String) {
        do {
            let data = try JSONEncoder().encode(insight)
            try cacheManager.write(data, for: articleId)
        } catch {
            print("保存洞察缓存失败：\(error.localizedDescription)")
        }
    }
    
    /// 检查是否存在缓存
    /// - Parameter articleId: 文章ID
    /// - Returns: 是否存在有效缓存
    func has(for articleId: String) -> Bool {
        cacheManager.has(for: articleId)
    }
    
    /// 清除所有缓存
    func clear() {
        cacheManager.clearAll()
    }
    
    /// 获取缓存统计信息
    /// - Returns: 缓存统计信息
    func getStats() -> CacheStats {
        cacheManager.getStats()
    }
} 