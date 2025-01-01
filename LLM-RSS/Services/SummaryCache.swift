import Foundation

/// 文章摘要缓存管理
class SummaryCache {
    /// 单例实例
    static let shared = SummaryCache()
    
    /// 缓存管理器
    private let cacheManager: CacheManager
    
    private init() {
        cacheManager = CacheManager(directoryName: "summaries")
    }
    
    /// 获取缓存的摘要
    /// - Parameter articleId: 文章ID
    /// - Returns: 缓存的摘要，如果不存在或已过期则返回nil
    func get(for articleId: String) -> String? {
        do {
            let data = try cacheManager.read(for: articleId)
            if !data.isEmpty {
                return String(data: data, encoding: .utf8)
            }
        } catch {
            print("读取摘要缓存失败：\(error.localizedDescription)")
        }
        return nil
    }
    
    /// 保存摘要到缓存
    /// - Parameters:
    ///   - summary: 摘要内容
    ///   - articleId: 文章ID
    func set(_ summary: String, for articleId: String) {
        guard let data = summary.data(using: .utf8) else { return }
        do {
            try cacheManager.write(data, for: articleId)
        } catch {
            print("保存摘要缓存失败：\(error.localizedDescription)")
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