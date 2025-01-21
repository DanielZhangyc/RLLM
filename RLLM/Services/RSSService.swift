import Foundation
import Alamofire

/// RSS服务，负责管理RSS订阅源的获取和缓存
actor RSSService {
    // MARK: - Singleton
    
    /// 共享实例
    static let shared = RSSService()
    
    // MARK: - Properties
    
    /// 文章缓存，键为Feed URL，值为最后更新时间和文章列表
    private var cache: [String: (lastUpdate: Date, articles: [Article])] = [:]
    
    /// 最小更新间隔（1小时）
    private let minimumUpdateInterval: TimeInterval = 3600
    
    // MARK: - Initialization
    
    private init() { }
    
    // MARK: - Public Methods
    
    /// 获取指定Feed的文章列表
    /// - Parameters:
    ///   - feed: 要获取的Feed
    ///   - existingArticles: 已存在的文章列表，用于去重
    ///   - forceRefresh: 是否强制刷新，忽略缓存
    /// - Returns: 更新后的文章列表
    /// - Throws: RSSError
    func fetchArticles(from feed: Feed, existingArticles: [Article] = [], forceRefresh: Bool = false) async throws -> [Article] {
        print("\n--- Fetching articles for \(feed.title) ---")
        print("Feed URL: \(feed.url)")
        
        // 检查是否需要更新
        if !forceRefresh,
           let cacheEntry = cache[feed.url],
           Date().timeIntervalSince(cacheEntry.lastUpdate) < minimumUpdateInterval {
            print("Using cached data, last update: \(cacheEntry.lastUpdate)")
            return cacheEntry.articles
        }
        
        print("Fetching fresh data from network")
        guard let feedURL = URL(string: feed.url) else {
            throw RSSError.invalidURL
        }
        
        let data = try await withCheckedThrowingContinuation { continuation in
            AF.request(feedURL)
                .validate()
                .responseData { response in
                    switch response.result {
                    case .success(let data):
                        continuation.resume(returning: data)
                    case .failure(let error):
                        continuation.resume(throwing: RSSError.fetchError(error))
                    }
                }
        }
        
        let parser = RSSParser()
        let (_, parsedArticles) = try parser.parse(data: data)
        
        // 使用URL作为唯一标识符进行去重
        let existingUrls = Set(existingArticles.map { $0.url })
        let newArticles = parsedArticles
            .filter { !existingUrls.contains($0.url) }
            .map { article in
                Article(
                    id: article.id,
                    title: article.title,
                    content: article.content,
                    url: article.url,
                    publishDate: article.publishDate,
                    feedTitle: feed.title,
                    author: article.author,
                    isRead: article.isRead,
                    summary: article.summary
                )
            }
        
        print("Found \(newArticles.count) new articles")
        
        // 合并新旧文章并按发布日期排序
        var allArticles = existingArticles
        allArticles.append(contentsOf: newArticles)
        allArticles.sort { $0.publishDate > $1.publishDate }
        
        // 更新缓存
        cache[feed.url] = (lastUpdate: Date(), articles: allArticles)
        print("Updated cache with \(allArticles.count) total articles")
        
        return allArticles
    }
    
    // MARK: - Private Methods
    
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
        
        let data = try await withCheckedThrowingContinuation { continuation in
            AF.request(feedURL)
                .validate()
                .responseData { response in
                    switch response.result {
                    case .success(let data):
                        continuation.resume(returning: data)
                    case .failure(let error):
                        continuation.resume(throwing: RSSError.fetchError(error))
                    }
                }
        }
        
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
