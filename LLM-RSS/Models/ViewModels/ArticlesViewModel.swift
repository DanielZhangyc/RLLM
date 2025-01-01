import SwiftUI

/// 文章列表视图模型，负责管理RSS源和文章的状态
@MainActor
class ArticlesViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var feeds: [Feed] = []
    @Published var articles: [Article] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var feedLoadingStates: [UUID: LoadingState] = [:]
    
    // MARK: - Private Properties
    
    private let rssService = RSSService.shared
    private let feedStorage = FeedStorage.shared
    
    // MARK: - Types
    
    enum LoadingState: Equatable {
        case idle
        case loading
        case failed(Error)
        case loaded
        
        static func == (lhs: LoadingState, rhs: LoadingState) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.loading, .loading),
                 (.loaded, .loaded), (.failed, .failed):
                return true
            default:
                return false
            }
        }
    }
    
    // MARK: - Initialization
    
    init() {
        do {
            feeds = try feedStorage.loadFeeds()
            // 初始化所有Feed的加载状态为idle
            feeds.forEach { feed in
                feedLoadingStates[feed.id] = .idle
            }
            Task {
                await refreshAllFeeds()
            }
        } catch {
            print("Error loading feeds: \(error.localizedDescription)")
            feeds = []
            self.error = error
        }
    }
    
    // MARK: - Public Methods
    
    /// 刷新所有RSS源
    func refreshAllFeeds() async {
        isLoading = true
        error = nil
        print("\n--- Starting refresh all feeds ---")
        
        // 设置所有Feed的加载状态为loading
        feeds.forEach { feed in
            feedLoadingStates[feed.id] = .loading
        }
        
        // 创建一个临时的文章数组来存储所有文章
        var currentArticles = articles
        
        await withTaskGroup(of: (Feed, [Article])?.self) { group in
            // 创建并发任务
            for feed in feeds {
                group.addTask {
                    await self.loadFeedArticles(feed)
                }
            }
            
            // 处理每个任务的结果
            for await result in group {
                if let (feed, newArticles) = result {
                    print("\n✅ Successfully loaded feed: \(feed.title)")
                    print("Found \(newArticles.count) articles")
                    
                    // 移除当前feed的旧文章
                    currentArticles.removeAll { article in
                        if let feedId = article.feedId {
                            return feedId == feed.id
                        }
                        return article.feedTitle == feed.title
                    }
                    
                    // 确保新文章都有正确的feedId和feedTitle
                    let processedNewArticles = newArticles.map { article in
                        var updatedArticle = article
                        updatedArticle.feedId = feed.id
                        updatedArticle.feedTitle = feed.title
                        return updatedArticle
                    }
                    
                    // 合并新文章
                    let mergedArticles = mergeArticles(existing: currentArticles, new: processedNewArticles)
                    currentArticles = mergedArticles
                    
                    // 更新UI
                    articles = currentArticles
                    articles.sort { $0.publishDate > $1.publishDate }
                    
                    // 更新加载状态为已完成
                    feedLoadingStates[feed.id] = .loaded
                    
                    print("Total articles for \(feed.title): \(processedNewArticles.count)")
                    print("Total articles in app: \(articles.count)")
                    
                    // 确保UI更新
                    objectWillChange.send()
                }
            }
        }
        
        print("\n--- Finished refreshing all feeds ---\n")
        isLoading = false
        
        // 检查任何未设置为loaded的Feed，将其设置为idle
        feeds.forEach { feed in
            if feedLoadingStates[feed.id] == .loading {
                feedLoadingStates[feed.id] = .idle
            }
        }
    }
    
    /// 刷新单个RSS源
    /// - Parameter feed: 要刷新的源
    func refreshFeed(_ feed: Feed) async {
        print("\n--- Refreshing single feed: \(feed.title) ---")
        
        // 设置加载状态
        feedLoadingStates[feed.id] = .loading
        objectWillChange.send()
        
        if let (_, newArticles) = await loadFeedArticles(feed) {
            // 获取除了当前feed以外的所有文章
            let otherArticles = articles.filter { article in
                if let feedId = article.feedId {
                    return feedId != feed.id
                }
                return article.feedTitle != feed.title
            }
            
            // 确保新文章都有正确的feedId和feedTitle
            let processedNewArticles = newArticles.map { article in
                var updatedArticle = article
                updatedArticle.feedId = feed.id
                updatedArticle.feedTitle = feed.title
                return updatedArticle
            }
            
            // 合并新文章
            let mergedArticles = mergeArticles(existing: otherArticles, new: processedNewArticles)
            
            // 更新并排序文章列表
            articles = mergedArticles.sorted { $0.publishDate > $1.publishDate }
            
            // 更新加载状态为已完成
            feedLoadingStates[feed.id] = .loaded
            
            print("Updated articles for \(feed.title): \(processedNewArticles.count)")
            print("Total articles in app: \(articles.count)")
        } else {
            // 如果加载失败，将状态设置为idle（因为loadFeedArticles已经设置了失败状态）
            if feedLoadingStates[feed.id] == .loading {
                feedLoadingStates[feed.id] = .idle
            }
            print("Failed to refresh feed: \(feed.title)")
        }
        
        // 确保UI更新
        objectWillChange.send()
    }
    
    /// 验证RSS源的有效性
    /// - Parameter url: RSS源的URL
    /// - Returns: 验证通过的Feed对象
    /// - Throws: RSSError
    func validateFeed(_ url: String) async throws -> Feed {
        return try await rssService.validateFeed(url)
    }
    
    /// 添加新的RSS源
    /// - Parameter feed: 要添加的Feed对象
    /// - Throws: RSSError.duplicateFeed 当Feed已存在时
    func addFeed(_ feed: Feed) async throws {
        guard !feeds.contains(where: { $0.url == feed.url }) else {
            throw RSSError.duplicateFeed
        }
        
        feeds.append(feed)
        try feedStorage.save(feeds)
        await refreshFeed(feed)
    }
    
    /// 删除RSS源
    /// - Parameter feed: 要删除的Feed对象
    func deleteFeed(_ feed: Feed) {
        feeds.removeAll { $0.id == feed.id }
        do {
            try feedStorage.save(feeds)
            articles.removeAll { $0.feedTitle == feed.title }
        } catch {
            print("Error saving feeds after deletion: \(error.localizedDescription)")
            self.error = error
        }
    }
    
    /// 将文章标记为已读
    /// - Parameter article: 要标记的文章
    func markAsRead(_ article: Article) {
        if let index = articles.firstIndex(where: { $0.id == article.id }) {
            articles[index].isRead = true
        }
    }
    
    /// 获取指定源的文章数量
    /// - Parameter feed: Feed对象
    /// - Returns: 文章数量
    func getArticleCount(for feed: Feed) -> Int {
        articles.filter { article in
            if let feedId = article.feedId {
                return feedId == feed.id
            }
            return article.feedTitle == feed.title
        }.count
    }
    
    /// 获取指定源的最后更新时间
    /// - Parameter feed: Feed对象
    /// - Returns: 最后更新时间
    func getLastUpdateTime(for feed: Feed) -> Date? {
        articles
            .filter { article in
                if let feedId = article.feedId {
                    return feedId == feed.id
                }
                return article.feedTitle == feed.title
            }
            .map { $0.publishDate }
            .max()
    }
    
    /// 获取指定源的所有文章
    /// - Parameter feed: Feed对象
    /// - Returns: 文章列表
    func getArticles(for feed: Feed) -> [Article] {
        // 使用Feed ID作为主要匹配条件，标题作为备选匹配条件
        articles.filter { article in
            // 优先使用Feed ID匹配
            if let feedId = article.feedId {
                return feedId == feed.id
            }
            // 如果没有Feed ID，则使用标题匹配
            return article.feedTitle == feed.title
        }
    }
    
    /// 更新RSS源的信息
    /// - Parameters:
    ///   - feed: 要更新的Feed对象
    ///   - title: 新标题
    ///   - icon: 新图标
    func updateFeed(_ feed: Feed, title: String, icon: String) {
        if let index = feeds.firstIndex(where: { $0.id == feed.id }) {
            let updatedFeed = feed.updating(
                title: title,
                iconName: icon
            )
            
            // 更新feeds数组中的Feed
            feeds[index] = updatedFeed
            
            // 更新所有相关文章的feedTitle和feedId
            let oldTitle = feed.title
            articles = articles.map { article in
                if article.feedTitle == oldTitle || article.feedId == feed.id {
                    var updatedArticle = article
                    updatedArticle.feedTitle = title
                    updatedArticle.feedId = feed.id
                    return updatedArticle
                }
                return article
            }
            
            // 保存更新后的feeds
            do {
                try feedStorage.save(feeds)
                print("Updated feed: \(updatedFeed.title)")
                print("New icon: \(updatedFeed.iconName)")
                
                // 立即刷新更新后的Feed的文章列表
                Task {
                    // 等待刷新完成
                    await refreshFeed(updatedFeed)
                    // 确保UI更新
                    objectWillChange.send()
                }
            } catch {
                print("Error saving updated feeds: \(error.localizedDescription)")
                self.error = error
                // 如果保存失败，设置加载状态为失败
                feedLoadingStates[feed.id] = .failed(error)
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// 加载指定源的文章
    /// - Parameter feed: Feed对象
    /// - Returns: Feed对象和文章列表的元组
    private func loadFeedArticles(_ feed: Feed) async -> (Feed, [Article])? {
        print("\n--- Loading feed: \(feed.title) ---")
        print("Feed URL: \(feed.url)")
        
        do {
            let articles = try await rssService.fetchArticles(from: feed)
            print("Successfully fetched \(articles.count) articles from \(feed.title)")
            return (feed, articles)
        } catch {
            print("❌ Error loading feed \(feed.title): \(error.localizedDescription)")
            feedLoadingStates[feed.id] = .failed(error)
            return nil
        }
    }
    
    /// 合并新旧文章列表，保持文章状态
    /// - Parameters:
    ///   - existing: 现有的文章列表
    ///   - new: 新的文章列表
    /// - Returns: 合并后的文章列表
    private func mergeArticles(existing: [Article], new: [Article]) -> [Article] {
        print("Merging articles - Existing: \(existing.count), New: \(new.count)")
        
        // 创建一个已存在URL的集合，用于快速查找
        let existingUrls = Set(existing.map { $0.url })
        
        // 分离新文章中的新增和重复的文章
        let (duplicates, newArticles) = new.reduce(into: ([Article](), [Article]())) { result, article in
            if existingUrls.contains(article.url) {
                result.0.append(article)
            } else {
                result.1.append(article)
            }
        }
        
        // 更新重复文章的状态
        let updatedExisting = existing.map { existingArticle -> Article in
            if let duplicate = duplicates.first(where: { $0.url == existingArticle.url }) {
                var updated = duplicate
                updated.isRead = existingArticle.isRead
                return updated
            }
            return existingArticle
        }
        
        return updatedExisting + newArticles
    }
} 
