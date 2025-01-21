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
    private let storageService = StorageService.shared
    
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
                // 从存储中加载该Feed的文章
                let savedArticles = storageService.loadArticles(for: feed.id)
                articles.append(contentsOf: savedArticles)
            }
            // 按发布日期排序
            articles.sort { $0.publishDate > $1.publishDate }
            Task {
                await refreshAllFeeds()
            }
        } catch {
            print("Error loading feeds: \(error.localizedDescription)")
            feeds = []
            self.error = error
            // 显示错误提示
            ToastManager.shared.showError(
                "加载失败",
                message: "无法加载订阅源列表，请重启应用"
            )
        }
    }
    
    // MARK: - Public Methods
    
    /// 刷新所有RSS源
    /// - Parameter forceRefresh: 是否强制刷新，忽略缓存
    func refreshAllFeeds(forceRefresh: Bool = true) async {
        print("\n=== ArticlesViewModel: Starting refreshAllFeeds() ===")
        
        await MainActor.run {
            print("Setting loading states...")
            isLoading = true
            error = nil
            // 设置所有Feed的加载状态为loading
            feeds.forEach { feed in
                feedLoadingStates[feed.id] = .loading
            }
        }
        
        print("Creating task group for \(feeds.count) feeds")
        
        // 用于统计成功和失败的数量
        var successCount = 0
        var failureCount = 0
        
        await withTaskGroup(of: (Feed, [Article])?.self) { group in
            // 创建并发任务
            for feed in feeds {
                print("Adding task for feed: \(feed.title)")
                group.addTask {
                    await self.loadFeedArticles(feed, forceRefresh: forceRefresh)
                }
            }
            
            // 处理每个任务的结果
            for await result in group {
                if let (feed, newArticles) = result {
                    print("\n✅ Successfully loaded feed: \(feed.title)")
                    print("Found \(newArticles.count) articles")
                    
                    successCount += 1
                    
                    // 从存储中加载该feed的已有文章
                    let savedArticles = storageService.loadArticles(for: feed.id)
                    print("Loaded \(savedArticles.count) saved articles")
                    
                    // 获取其他feed的文章
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
                    
                    // 合并已存储的文章和新文章
                    let mergedArticles = mergeArticles(existing: savedArticles, new: processedNewArticles)
                    
                    // 保存合并后的文章到存储
                    storageService.saveArticles(mergedArticles, for: feed.id)
                    
                    await MainActor.run {
                        // 更新内存中的文章列表
                        articles = otherArticles + mergedArticles
                        articles.sort { $0.publishDate > $1.publishDate }
                        feedLoadingStates[feed.id] = .loaded
                        objectWillChange.send()
                    }
                    
                    print("Total saved articles for \(feed.title): \(mergedArticles.count)")
                    print("Total articles in app: \(articles.count)")
                } else {
                    failureCount += 1
                }
            }
        }
        
        print("\n=== ArticlesViewModel: Completed refreshAllFeeds() ===")
        print("Success: \(successCount), Failures: \(failureCount)\n")
        
        await MainActor.run {
            isLoading = false
            feeds.forEach { feed in
                if feedLoadingStates[feed.id] == .loading {
                    feedLoadingStates[feed.id] = .idle
                }
            }
            
            // 显示刷新结果的toast
            if failureCount == 0 {
                if successCount > 0 {
                    HapticManager.shared.success()
                    ToastManager.shared.showSuccess(
                        "刷新成功",
                        message: "已更新\(successCount)个订阅源的内容"
                    )
                }
            } else {
                HapticManager.shared.error()
                ToastManager.shared.showError(
                    "刷新失败",
                    message: "成功\(successCount)个，失败\(failureCount)个"
                )
            }
        }
    }
    
    /// 刷新单个RSS源
    /// - Parameters:
    ///   - feed: 要刷新的源
    ///   - forceRefresh: 是否强制刷新，忽略缓存
    func refreshFeed(_ feed: Feed, forceRefresh: Bool = true) async {
        print("\n--- Refreshing single feed: \(feed.title) ---")
        
        await MainActor.run {
            feedLoadingStates[feed.id] = .loading
            objectWillChange.send()
        }
        
        if let (_, newArticles) = await loadFeedArticles(feed, forceRefresh: forceRefresh) {
            // 从存储中加载该feed的已有文章
            let savedArticles = storageService.loadArticles(for: feed.id)
            print("Loaded \(savedArticles.count) saved articles")
            
            // 获取其他feed的文章
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
            
            // 合并已存储的文章和新文章
            let mergedArticles = mergeArticles(existing: savedArticles, new: processedNewArticles)
            
            // 保存合并后的文章到存储
            storageService.saveArticles(mergedArticles, for: feed.id)
            
            await MainActor.run {
                // 更新内存中的文章列表
                articles = otherArticles + mergedArticles
                articles.sort { $0.publishDate > $1.publishDate }
                feedLoadingStates[feed.id] = .loaded
                objectWillChange.send()
            }
            
            print("Total saved articles for \(feed.title): \(mergedArticles.count)")
            print("Total articles in app: \(articles.count)")
        } else {
            await MainActor.run {
                if feedLoadingStates[feed.id] == .loading {
                    feedLoadingStates[feed.id] = .idle
                }
                objectWillChange.send()
                // 显示错误提示
                ToastManager.shared.showError(
                    "更新失败",
                    message: "无法更新源\"\(feed.title)\"，请检查网络连接"
                )
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
            // 显示成功提示
            ToastManager.shared.showWarning(
                "已删除订阅源",
                message: "已移除源\"\(feed.title)\"及其所有文章"
            )
        } catch {
            print("Error saving feeds after deletion: \(error.localizedDescription)")
            self.error = error
            // 显示错误提示
            ToastManager.shared.showError(
                "删除失败",
                message: "无法保存更改，请重试"
            )
        }
    }
    
    /// 将文章标记为已读
    /// - Parameter article: 要标记的文章
    func markAsRead(_ article: Article) {
        if let index = articles.firstIndex(where: { $0.id == article.id }) {
            articles[index].isRead = true
            // 显示提示
            ToastManager.shared.showInfo(
                "已读",
                message: "已将源\"\(article.title)\"标记为已读"
            )
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
                
                // 显示成功提示
                ToastManager.shared.showSuccess(
                    "更新成功",
                    message: "已更新源\"\(title)\"的设置"
                )
                
                // 立即刷新更新后的Feed的文章列表
                Task {
                    await refreshFeed(updatedFeed)
                }
            } catch {
                print("Error saving updated feeds: \(error.localizedDescription)")
                self.error = error
                Task { @MainActor in
                    feedLoadingStates[feed.id] = .failed(error)
                    // 显示错误提示
                    ToastManager.shared.showError(
                        "保存失败",
                        message: "无法保存源\"\(title)\"的设置更改"
                    )
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// 加载指定源的文章
    /// - Parameters:
    ///   - feed: Feed对象
    ///   - forceRefresh: 是否强制刷新，忽略缓存
    /// - Returns: Feed对象和文章列表的元组
    private func loadFeedArticles(_ feed: Feed, forceRefresh: Bool = false) async -> (Feed, [Article])? {
        print("\n=== Loading feed: \(feed.title) ===")
        print("Feed URL: \(feed.url)")
        
        do {
            print("Fetching articles from RSS service...")
            let articles = try await rssService.fetchArticles(from: feed, forceRefresh: forceRefresh)
            print("✅ Successfully fetched \(articles.count) articles from \(feed.title)")
            return (feed, articles)
        } catch {
            print("❌ Error loading feed \(feed.title)")
            print("Error details: \(error.localizedDescription)")
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
