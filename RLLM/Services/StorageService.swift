import Foundation

class StorageService {
    static let shared = StorageService()
    
    static let feedsKey = "saved_feeds"
    static let articlesKey = "saved_articles"
    private let defaults = UserDefaults.standard
    
    private init() {}
    
    // MARK: - Feeds
    func saveFeeds(_ feeds: [Feed]) {
        if let encoded = try? JSONEncoder().encode(feeds) {
            defaults.set(encoded, forKey: Self.feedsKey)
        }
    }
    
    func loadFeeds() -> [Feed] {
        guard let data = defaults.data(forKey: Self.feedsKey),
              let feeds = try? JSONDecoder().decode([Feed].self, from: data) else {
            return []
        }
        return feeds
    }
    
    // MARK: - Articles
    func saveArticles(_ articles: [Article], for feedId: UUID) {
        if let encoded = try? JSONEncoder().encode(articles) {
            defaults.set(encoded, forKey: "\(Self.articlesKey)_\(feedId)")
        }
    }
    
    func loadArticles(for feedId: UUID) -> [Article] {
        guard let data = defaults.data(forKey: "\(Self.articlesKey)_\(feedId)"),
              let articles = try? JSONDecoder().decode([Article].self, from: data) else {
            return []
        }
        return articles
    }
    
    func loadAllArticles() -> [UUID: [Article]] {
        var articlesMap: [UUID: [Article]] = [:]
        let feeds = loadFeeds()
        
        for feed in feeds {
            articlesMap[feed.id] = loadArticles(for: feed.id)
        }
        
        return articlesMap
    }
    
    func removeArticles(for feedId: UUID) {
        defaults.removeObject(forKey: "\(Self.articlesKey)_\(feedId)")
    }
    
    // MARK: - Data Cleanup
    
    /// 清理所有存储的数据
    func clearAllData() {
        // 删除所有feeds数据
        defaults.removeObject(forKey: Self.feedsKey)
        
        // 删除所有articles数据
        let feeds = loadFeeds()
        for feed in feeds {
            removeArticles(for: feed.id)
        }
        
        // 同步UserDefaults
        defaults.synchronize()
    }
} 