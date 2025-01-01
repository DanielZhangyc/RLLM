import Foundation

/// RSS服务，负责管理RSS订阅源的获取和缓存
actor RSSService {
    // MARK: - Singleton
    
    /// 共享实例
    static let shared = RSSService()
    
    // MARK: - Properties
    
    /// 文章缓存，键为Feed URL，值为缓存日期和文章列表
    private var cache: [String: (date: Date, articles: [Article])] = [:]
    
    /// 缓存有效期（3天）
    private let cacheValidityDuration: TimeInterval = 3 * 24 * 3600
    
    // MARK: - Initialization
    
    private init() { }
    
    // MARK: - Public Methods
    
    /// 获取指定Feed的文章列表
    /// - Parameters:
    ///   - feed: 要获取的Feed
    ///   - existingArticles: 已存在的文章列表，用于去重
    /// - Returns: 更新后的文章列表
    /// - Throws: RSSError
    func fetchArticles(from feed: Feed, existingArticles: [Article] = []) async throws -> [Article] {
        print("\n--- Fetching articles for \(feed.title) ---")
        print("Feed URL: \(feed.url)")
        
        // 检查缓存
        if isCacheValid(for: feed.url) {
            if let cachedData = cache[feed.url] {
                print("Using cached data with \(cachedData.articles.count) articles")
                return cachedData.articles
            }
        }
        
        print("Fetching fresh data from network")
        guard let feedURL = URL(string: feed.url) else {
            throw RSSError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: feedURL)
        let parser = RSSParser()
        let (_, parsedArticles) = try parser.parse(data: data)
        
        // 使用URL而不是ID来去重
        let existingUrls = Set(existingArticles.map { $0.url })
        let processedArticles = parsedArticles
            .filter { !existingUrls.contains($0.url) }
            .map { article in
                // 创建新的Article实例，设置feedTitle
                Article(
                    id: article.id,
                    title: article.title,
                    content: article.content,
                    url: article.url,
                    publishDate: article.publishDate,
                    feedTitle: feed.title,  // 设置正确的feedTitle
                    author: article.author,
                    isRead: article.isRead,
                    summary: article.summary
                )
            }
        
        print("Processed \(processedArticles.count) new articles")
        
        // 合并并按发布日期排序
        let mergedArticles = (existingArticles + processedArticles)
            .sorted { $0.publishDate > $1.publishDate }
        
        // 去除重复项（基于URL）
        let uniqueArticles = Dictionary<String, Article>(
            mergedArticles.map { ($0.url, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        .values
        .sorted { $0.publishDate > $1.publishDate }
        
        print("Caching \(uniqueArticles.count) unique articles")
        cache[feed.url] = (date: Date(), articles: Array(uniqueArticles))
        
        return Array(uniqueArticles)
    }
    
    // MARK: - Private Methods
    
    /// 检查指定URL的缓存是否有效
    /// - Parameter url: Feed的URL
    /// - Returns: 缓存是否有效
    private func isCacheValid(for url: String) -> Bool {
        guard let cacheEntry = cache[url] else { return false }
        return Date().timeIntervalSince(cacheEntry.date) < cacheValidityDuration
    }
    
    /// 解码HTML实体
    /// - Parameter text: 包含HTML实体的文本
    /// - Returns: 解码后的文本
    private func decodeHTMLEntities(_ text: String) -> String {
        guard let data = text.data(using: .utf8) else { return text }
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        
        if let attributedString = try? NSAttributedString(data: data, options: options, documentAttributes: nil) {
            return attributedString.string
        }
        return text
    }
    
    /// 验证Feed的有效性
    /// - Parameter url: Feed的URL字符串
    /// - Returns: 验证通过的Feed对象
    /// - Throws: RSSError
    func validateFeed(_ url: String) async throws -> Feed {
        print("Validating feed URL: \(url)")
        guard let feedURL = URL(string: url) else {
            throw RSSError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: feedURL)
        let parser = RSSParser()
        let (feed, _) = try parser.parse(data: data)
        
        return Feed(
            id: UUID(),
            title: feed.title,
            url: url,
            description: feed.description
        )
    }
}
