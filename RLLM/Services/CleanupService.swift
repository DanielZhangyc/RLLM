import Foundation

/// 数据清理服务
class CleanupService {
    static let shared = CleanupService()
    
    private let coreDataManager = CoreDataManager.shared
    private let defaults = UserDefaults.standard
    
    private let lastCleanupKey = "last_cleanup_date"
    private let cleanupIntervalKey = "cleanup_interval_days"
    private let articleAgeKey = "article_age_days"
    private let summaryAgeKey = "summary_age_days"
    private let maxArticlesPerFeedKey = "max_articles_per_feed"
    
    private init() {
        // 设置默认值
        if defaults.object(forKey: cleanupIntervalKey) == nil {
            defaults.set(7, forKey: cleanupIntervalKey) // 默认每7天清理一次
        }
        if defaults.object(forKey: articleAgeKey) == nil {
            defaults.set(90, forKey: articleAgeKey) // 默认保留90天的文章
        }
        if defaults.object(forKey: summaryAgeKey) == nil {
            defaults.set(30, forKey: summaryAgeKey) // 默认保留30天的每日总结
        }
        if defaults.object(forKey: maxArticlesPerFeedKey) == nil {
            defaults.set(100, forKey: maxArticlesPerFeedKey) // 默认每个Feed最多保留100篇文章
        }
    }
    
    /// 检查是否需要执行清理
    var needsCleanup: Bool {
        let now = Date()
        let lastCleanup = defaults.object(forKey: lastCleanupKey) as? Date ?? .distantPast
        let interval = TimeInterval(defaults.integer(forKey: cleanupIntervalKey) * 24 * 60 * 60)
        return now.timeIntervalSince(lastCleanup) >= interval
    }
    
    /// 执行清理操作
    func performCleanupIfNeeded() {
        guard needsCleanup else { return }
        
        let articleAge = defaults.integer(forKey: articleAgeKey)
        let summaryAge = defaults.integer(forKey: summaryAgeKey)
        let maxArticlesPerFeed = defaults.integer(forKey: maxArticlesPerFeedKey)
        
        coreDataManager.performCleanup(
            articleAge: articleAge,
            summaryAge: summaryAge,
            maxArticlesPerFeed: maxArticlesPerFeed
        )
        
        // 更新最后清理时间
        defaults.set(Date(), forKey: lastCleanupKey)
    }
    
    /// 更新清理配置
    /// - Parameters:
    ///   - cleanupInterval: 清理间隔（天）
    ///   - articleAge: 文章保留时间（天）
    ///   - summaryAge: 每日总结保留时间（天）
    ///   - maxArticlesPerFeed: 每个Feed保留的最大文章数量
    func updateConfig(
        cleanupInterval: Int? = nil,
        articleAge: Int? = nil,
        summaryAge: Int? = nil,
        maxArticlesPerFeed: Int? = nil
    ) {
        if let interval = cleanupInterval {
            defaults.set(interval, forKey: cleanupIntervalKey)
        }
        if let age = articleAge {
            defaults.set(age, forKey: articleAgeKey)
        }
        if let age = summaryAge {
            defaults.set(age, forKey: summaryAgeKey)
        }
        if let max = maxArticlesPerFeed {
            defaults.set(max, forKey: maxArticlesPerFeedKey)
        }
    }
    
    /// 获取当前配置
    /// - Returns: 清理配置信息
    func getConfig() -> (cleanupInterval: Int, articleAge: Int, summaryAge: Int, maxArticlesPerFeed: Int) {
        return (
            cleanupInterval: defaults.integer(forKey: cleanupIntervalKey),
            articleAge: defaults.integer(forKey: articleAgeKey),
            summaryAge: defaults.integer(forKey: summaryAgeKey),
            maxArticlesPerFeed: defaults.integer(forKey: maxArticlesPerFeedKey)
        )
    }
    
    /// 强制执行清理
    func forceCleanup() {
        performCleanupIfNeeded()
    }
} 