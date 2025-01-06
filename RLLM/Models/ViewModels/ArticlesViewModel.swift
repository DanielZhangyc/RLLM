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
        await MainActor.run {
            isLoading = true
            error = nil
            // 设置所有Feed的加载状态为loading
            feeds.forEach { feed in
                feedLoadingStates[feed.id] = .loading
            }
        }
        
        print("\n--- Starting refresh all feeds ---")
        
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
                    
                    // 在MainActor上下文中更新UI和状态
                    await MainActor.run {
                        articles = currentArticles
                        articles.sort { $0.publishDate > $1.publishDate }
                        feedLoadingStates[feed.id] = .loaded
                        objectWillChange.send()
                        HapticManager.shared.selection()
                    }
                    
                    print("Total articles for \(feed.title): \(processedNewArticles.count)")
                    print("Total articles in app: \(articles.count)")
                }
            }
        }
        
        print("\n--- Finished refreshing all feeds ---\n")
        
        await MainActor.run {
            isLoading = false
            feeds.forEach { feed in
                if feedLoadingStates[feed.id] == .loading {
                    feedLoadingStates[feed.id] = .idle
                }
            }
            HapticManager.shared.selection()
        }
    }
    
    /// 刷新单个RSS源
    /// - Parameter feed: 要刷新的源
    func refreshFeed(_ feed: Feed) async {
        print("\n--- Refreshing single feed: \(feed.title) ---")
        
        await MainActor.run {
            feedLoadingStates[feed.id] = .loading
            objectWillChange.send()
        }
        
        if let (_, newArticles) = await loadFeedArticles(feed) {
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
            
            await MainActor.run {
                articles = mergedArticles.sorted { $0.publishDate > $1.publishDate }
                feedLoadingStates[feed.id] = .loaded
                objectWillChange.send()
                HapticManager.shared.selection()
            }
            
            print("Updated articles for \(feed.title): \(processedNewArticles.count)")
            print("Total articles in app: \(articles.count)")
        } else {
            await MainActor.run {
                if feedLoadingStates[feed.id] == .loading {
                    feedLoadingStates[feed.id] = .idle
                }
                objectWillChange.send()
            }
            print("Failed to refresh feed: \(feed.title)")
        }
    }
    
    /// 验证RSS源的有效性
    /// - Parameter url: RSS源的URL
    /// - Returns: 验证通过的Feed对象
    /// - Throws: RSSError
    func validateFeed(_ url: String) async throws -> Feed {
        print("开始验证RSS源: \(url)")
        let feed = try await rssService.validateFeed(url)
        print("RSS源验证成功: \(feed.title)")
        return feed
    }
    
    /// 添加新的RSS源
    /// - Parameter feed: 要添加的Feed对象
    /// - Throws: RSSError.duplicateFeed 当Feed已存在时
    func addFeed(_ feed: Feed) async throws {
        print("正在添加RSS源: \(feed.title)")
        
        // 检查是否已存在相同URL的源
        if let existingFeed = feeds.first(where: { $0.url == feed.url }) {
            print("发现重复的RSS源: \(existingFeed.title)")
            throw RSSError.duplicateFeed
        }
        
        // 检查是否已存在相同标题的源
        if let existingFeed = feeds.first(where: { $0.title == feed.title }) {
            print("发现标题重复的RSS源: \(existingFeed.title)")
            // 为新源生成一个不重复的标题
            var newTitle = feed.title
            var counter = 1
            while feeds.contains(where: { $0.title == newTitle }) {
                newTitle = "\(feed.title) (\(counter))"
                counter += 1
            }
            var updatedFeed = feed
            updatedFeed.title = newTitle
            feeds.append(updatedFeed)
            try feedStorage.save(feeds)
            await refreshFeed(updatedFeed)
            print("RSS源添加成功(使用新标题): \(newTitle)")
        } else {
            // 添加新源
            feeds.append(feed)
            try feedStorage.save(feeds)
            await refreshFeed(feed)
            print("RSS源添加成功: \(feed.title)")
        }
        
        // 发送更新通知
        await MainActor.run {
            objectWillChange.send()
        }
        
        HapticManager.shared.selection()
    }
    
    /// 删除RSS源
    /// - Parameter feed: 要删除的Feed对象
    func deleteFeed(_ feed: Feed) {
        feeds.removeAll { $0.id == feed.id }
        do {
            try feedStorage.save(feeds)
            articles.removeAll { article in
                if let feedId = article.feedId {
                    return feedId == feed.id
                }
                return false
            }
            objectWillChange.send()
            HapticManager.shared.lightImpact()
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
    ///   - color: 新图标颜色
    func updateFeed(_ feed: Feed, title: String, icon: String, color: String) {
        if let index = feeds.firstIndex(where: { $0.id == feed.id }) {
            let updatedFeed = feed.updating(
                title: title,
                iconName: icon,
                iconColor: color
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
                print("New color: \(updatedFeed.iconColor ?? "AccentColor")")
                
                // 立即刷新更新后的Feed的文章列表
                Task {
                    await refreshFeed(updatedFeed)
                }
            } catch {
                print("Error saving updated feeds: \(error.localizedDescription)")
                self.error = error
                Task { @MainActor in
                    feedLoadingStates[feed.id] = .failed(error)
                }
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
            await MainActor.run {
                feedLoadingStates[feed.id] = .failed(error)
            }
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
