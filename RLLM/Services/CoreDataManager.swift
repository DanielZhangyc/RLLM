import CoreData
import Foundation

/// CoreData 管理器
class CoreDataManager {
    static let shared = CoreDataManager()
    
    private init() {
        registerTransformers()
    }
    
    /// 注册Core Data转换器
    private func registerTransformers() {
        ValueTransformer.setValueTransformer(
            NSSecureUnarchiveFromDataTransformer(),
            forName: NSValueTransformerName.secureUnarchiveFromDataTransformerName
        )
    }
    
    // MARK: - Core Data stack
    
    /// 持久化容器
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "RLLM")
        print("Initializing Core Data persistent container")
        
        // 配置迁移选项
        let options = [
            NSMigratePersistentStoresAutomaticallyOption: true,
            NSInferMappingModelAutomaticallyOption: true,
            // 添加日志选项以便调试
            NSSQLitePragmasOption: ["journal_mode": "WAL"],
            NSSQLiteAnalyzeOption: true
        ] as [String : Any]
        
        // 获取存储文件URL
        let applicationSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let storeURL = applicationSupportURL.appendingPathComponent("RLLM.sqlite")
        print("Core Data store URL: \(storeURL.path)")
        
        // 确保目录存在
        do {
            try FileManager.default.createDirectory(
                at: applicationSupportURL,
                withIntermediateDirectories: true,
                attributes: nil
            )
            print("Application Support directory created/verified")
        } catch {
            print("Failed to create directory: \(error)")
            fatalError("Unable to create Application Support directory: \(error)")
        }
        
        // 尝试加载存储
        do {
            print("Attempting to add persistent store")
            try container.persistentStoreCoordinator.addPersistentStore(
                ofType: NSSQLiteStoreType,
                configurationName: nil,
                at: storeURL,
                options: options
            )
            print("Successfully added persistent store")
        } catch {
            print("Failed to load store: \(error), \(error.localizedDescription)")
            
            // 只有在文件存在时才尝试删除
            if FileManager.default.fileExists(atPath: storeURL.path) {
                // 尝试删除并重建存储
                do {
                    print("Attempting to delete existing store files")
                    try FileManager.default.removeItem(at: storeURL)
                    // 同时删除相关文件
                    try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("shm"))
                    try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("wal"))
                    print("Successfully deleted existing store files")
                } catch {
                    print("Failed to delete store files: \(error)")
                    fatalError("Unable to delete existing store files: \(error)")
                }
            }
            
            // 重新创建存储
            do {
                print("Attempting to recreate persistent store")
                try container.persistentStoreCoordinator.addPersistentStore(
                    ofType: NSSQLiteStoreType,
                    configurationName: nil,
                    at: storeURL,
                    options: options
                )
                print("Successfully recreated persistent store")
            } catch {
                print("Failed to recreate store: \(error)")
                fatalError("Unable to create persistent store: \(error)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        print("Core Data stack successfully initialized")
        
        return container
    }()
    
    /// 管理上下文
    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    // MARK: - Core Data operations
    
    /// 保存上下文
    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let error = error as NSError
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
    }
    
    // MARK: - Feed operations
    
    /// 创建或更新Feed
    /// - Parameter feed: Feed模型
    /// - Returns: FeedEntity实例
    @discardableResult
    func createOrUpdateFeed(_ feed: Feed) -> FeedEntity {
        let fetchRequest: NSFetchRequest<FeedEntity> = FeedEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", feed.id as CVarArg)
        
        do {
            let results = try viewContext.fetch(fetchRequest)
            let feedEntity = results.first ?? FeedEntity(context: viewContext)
            feedEntity.id = feed.id
            feedEntity.title = feed.title
            feedEntity.url = feed.url
            feedEntity.desc = feed.description
            feedEntity.iconName = feed.iconName
            saveContext()
            return feedEntity
        } catch {
            fatalError("Failed to fetch feed: \(error)")
        }
    }
    
    /// 获取所有Feed
    /// - Returns: Feed数组
    func getAllFeeds() -> [Feed] {
        let fetchRequest: NSFetchRequest<FeedEntity> = FeedEntity.fetchRequest()
        
        do {
            let feedEntities = try viewContext.fetch(fetchRequest)
            return feedEntities.map { entity in
                Feed(
                    id: entity.id ?? UUID(),
                    title: entity.title ?? "",
                    url: entity.url ?? "",
                    description: entity.desc,
                    iconName: entity.iconName ?? "newspaper.fill"
                )
            }
        } catch {
            print("Failed to fetch feeds: \(error)")
            return []
        }
    }
    
    /// 删除Feed
    /// - Parameter id: Feed的ID
    func deleteFeed(id: UUID) {
        let fetchRequest: NSFetchRequest<FeedEntity> = FeedEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            let results = try viewContext.fetch(fetchRequest)
            if let feedEntity = results.first {
                viewContext.delete(feedEntity)
                saveContext()
            }
        } catch {
            print("Failed to delete feed: \(error)")
        }
    }
    
    // MARK: - Article operations
    
    /// 创建或更新文章
    /// - Parameters:
    ///   - article: 文章模型
    ///   - feedId: Feed的ID
    /// - Returns: ArticleEntity实例
    @discardableResult
    func createOrUpdateArticle(_ article: Article, feedId: UUID) -> ArticleEntity {
        let fetchRequest: NSFetchRequest<ArticleEntity> = ArticleEntity.fetchRequest()
        // 使用URL作为唯一标识符
        fetchRequest.predicate = NSPredicate(format: "url == %@", article.url)
        
        do {
            let results = try viewContext.fetch(fetchRequest)
            let articleEntity = results.first ?? ArticleEntity(context: viewContext)
            
            // 如果是已存在的文章，只更新部分字段
            if results.first != nil {
                // 更新可能变化的字段
                articleEntity.title = article.title
                articleEntity.content = article.content
                articleEntity.author = article.author
                articleEntity.summary = article.summary
                
                // 不更新已读状态和发布日期等字段
                print("Updating existing article: \(article.title)")
            } else {
                // 新文章，设置所有字段
                articleEntity.id = article.id
                articleEntity.title = article.title
                articleEntity.content = article.content
                articleEntity.url = article.url
                articleEntity.publishDate = article.publishDate
                articleEntity.author = article.author
                articleEntity.isRead = article.isRead
                articleEntity.summary = article.summary
                print("Creating new article: \(article.title)")
            }
            
            // 关联到Feed
            let feedFetchRequest: NSFetchRequest<FeedEntity> = FeedEntity.fetchRequest()
            feedFetchRequest.predicate = NSPredicate(format: "id == %@", feedId as CVarArg)
            if let feedEntity = try viewContext.fetch(feedFetchRequest).first {
                articleEntity.feed = feedEntity
            }
            
            saveContext()
            return articleEntity
        } catch {
            fatalError("Failed to fetch article: \(error)")
        }
    }
    
    /// 获取Feed的所有文章
    /// - Parameter feedId: Feed的ID
    /// - Returns: 文章数组
    func getArticles(for feedId: UUID) -> [Article] {
        let fetchRequest: NSFetchRequest<ArticleEntity> = ArticleEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "feed.id == %@", feedId as CVarArg)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \ArticleEntity.publishDate, ascending: false)]
        
        do {
            let articleEntities = try viewContext.fetch(fetchRequest)
            return articleEntities.map { entity in
                Article(
                    id: entity.id ?? UUID(),
                    title: entity.title ?? "",
                    content: entity.content ?? "",
                    url: entity.url ?? "",
                    publishDate: entity.publishDate ?? Date(),
                    feedTitle: entity.feed?.title ?? "",
                    feedId: entity.feed?.id,
                    author: entity.author,
                    isRead: entity.isRead,
                    summary: entity.summary
                )
            }
        } catch {
            print("Failed to fetch articles: \(error)")
            return []
        }
    }
    
    /// 获取所有文章
    /// - Returns: 文章数组
    func getAllArticles() -> [Article] {
        let fetchRequest: NSFetchRequest<ArticleEntity> = ArticleEntity.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \ArticleEntity.publishDate, ascending: false)]
        
        do {
            let articleEntities = try viewContext.fetch(fetchRequest)
            return articleEntities.map { entity in
                Article(
                    id: entity.id ?? UUID(),
                    title: entity.title ?? "",
                    content: entity.content ?? "",
                    url: entity.url ?? "",
                    publishDate: entity.publishDate ?? Date(),
                    feedTitle: entity.feed?.title ?? "",
                    feedId: entity.feed?.id,
                    author: entity.author,
                    isRead: entity.isRead,
                    summary: entity.summary
                )
            }
        } catch {
            print("Failed to fetch articles: \(error)")
            return []
        }
    }
    
    /// 更新文章的已读状态
    /// - Parameters:
    ///   - id: 文章ID
    ///   - isRead: 是否已读
    func updateArticleReadStatus(id: UUID, isRead: Bool) {
        let fetchRequest: NSFetchRequest<ArticleEntity> = ArticleEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            let results = try viewContext.fetch(fetchRequest)
            if let articleEntity = results.first {
                articleEntity.isRead = isRead
                saveContext()
            }
        } catch {
            print("Failed to update article read status: \(error)")
        }
    }
    
    /// 更新文章的摘要
    /// - Parameters:
    ///   - id: 文章ID
    ///   - summary: 摘要内容
    func updateArticleSummary(id: UUID, summary: String) {
        let fetchRequest: NSFetchRequest<ArticleEntity> = ArticleEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            let results = try viewContext.fetch(fetchRequest)
            if let articleEntity = results.first {
                articleEntity.summary = summary
                saveContext()
            }
        } catch {
            print("Failed to update article summary: \(error)")
        }
    }
    
    // MARK: - Daily Summary operations
    
    /// 创建或更新每日总结
    /// - Parameter summary: DailySummaryCache.DailySummaryData 实例
    /// - Returns: DailySummaryEntity 实例
    @discardableResult
    func createOrUpdateDailySummary(_ summary: DailySummaryCache.DailySummaryData) -> DailySummaryEntity {
        let fetchRequest: NSFetchRequest<DailySummaryEntity> = DailySummaryEntity.fetchRequest()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: summary.date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        
        do {
            let results = try viewContext.fetch(fetchRequest)
            let summaryEntity = results.first ?? DailySummaryEntity(context: viewContext)
            
            summaryEntity.id = UUID()
            summaryEntity.date = summary.date
            summaryEntity.summary = summary.summary
            summaryEntity.keyPoints = summary.keyPoints as NSArray
            summaryEntity.learningAdvice = summary.learningAdvice
            summaryEntity.readingTime = summary.readingTime
            summaryEntity.topTopics = summary.topTopics as NSArray
            summaryEntity.topicCounts = summary.topicCounts as NSDictionary
            
            saveContext()
            return summaryEntity
        } catch {
            fatalError("Failed to fetch daily summary: \(error)")
        }
    }
    
    /// 获取指定日期的每日总结
    /// - Parameter date: 日期
    /// - Returns: DailySummaryCache.DailySummaryData? 实例
    func getDailySummary(for date: Date) -> DailySummaryCache.DailySummaryData? {
        let fetchRequest: NSFetchRequest<DailySummaryEntity> = DailySummaryEntity.fetchRequest()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        
        do {
            let results = try viewContext.fetch(fetchRequest)
            guard let entity = results.first else { return nil }
            
            return DailySummaryCache.DailySummaryData(
                summary: entity.summary ?? "",
                keyPoints: (entity.keyPoints as? [String]) ?? [],
                learningAdvice: entity.learningAdvice ?? "",
                readingTime: entity.readingTime ?? "",
                topTopics: (entity.topTopics as? [String]) ?? [],
                topicCounts: (entity.topicCounts as? [String: Int]) ?? [:],
                date: entity.date ?? date
            )
        } catch {
            print("Failed to fetch daily summary: \(error)")
            return nil
        }
    }
    
    // MARK: - Article Insight operations
    
    /// 创建或更新文章洞察
    /// - Parameters:
    ///   - insight: ArticleInsight 实例
    ///   - articleId: 文章ID
    /// - Returns: ArticleInsightEntity 实例
    @discardableResult
    func createOrUpdateArticleInsight(_ insight: ArticleInsight, articleId: UUID) -> ArticleInsightEntity {
        let fetchRequest: NSFetchRequest<ArticleInsightEntity> = ArticleInsightEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", insight.id as CVarArg)
        
        do {
            let results = try viewContext.fetch(fetchRequest)
            let insightEntity = results.first ?? ArticleInsightEntity(context: viewContext)
            
            insightEntity.id = insight.id
            insightEntity.summary = insight.summary
            insightEntity.keyPoints = insight.keyPoints as NSArray
            insightEntity.topics = insight.topics as NSArray
            insightEntity.sentiment = insight.sentiment
            insightEntity.backgroundInfo = insight.backgroundInfo
            
            // 关联到文章
            let articleFetchRequest: NSFetchRequest<ArticleEntity> = ArticleEntity.fetchRequest()
            articleFetchRequest.predicate = NSPredicate(format: "id == %@", articleId as CVarArg)
            if let articleEntity = try viewContext.fetch(articleFetchRequest).first {
                insightEntity.article = articleEntity
            }
            
            saveContext()
            return insightEntity
        } catch {
            fatalError("Failed to fetch article insight: \(error)")
        }
    }
    
    /// 获取文章的洞察
    /// - Parameter articleId: 文章ID
    /// - Returns: ArticleInsight? 实例
    func getArticleInsight(for articleId: UUID) -> ArticleInsight? {
        let fetchRequest: NSFetchRequest<ArticleInsightEntity> = ArticleInsightEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "article.id == %@", articleId as CVarArg)
        
        do {
            let results = try viewContext.fetch(fetchRequest)
            guard let entity = results.first else { return nil }
            
            return ArticleInsight(
                id: entity.id ?? UUID(),
                summary: entity.summary ?? "",
                keyPoints: (entity.keyPoints as? [String]) ?? [],
                topics: (entity.topics as? [String]) ?? [],
                sentiment: entity.sentiment ?? "",
                backgroundInfo: entity.backgroundInfo
            )
        } catch {
            print("Failed to fetch article insight: \(error)")
            return nil
        }
    }
    
    // MARK: - Quote operations
    
    /// 创建或更新收藏语段
    /// - Parameters:
    ///   - quote: Quote 实例
    ///   - articleId: 文章ID
    /// - Returns: QuoteEntity 实例
    @discardableResult
    func createOrUpdateQuote(_ quote: Quote, articleId: UUID) -> QuoteEntity {
        let fetchRequest: NSFetchRequest<QuoteEntity> = QuoteEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", quote.id as CVarArg)
        
        do {
            let results = try viewContext.fetch(fetchRequest)
            let quoteEntity = results.first ?? QuoteEntity(context: viewContext)
            
            quoteEntity.id = quote.id
            quoteEntity.content = quote.content
            quoteEntity.articleTitle = quote.articleTitle
            quoteEntity.articleURL = quote.articleURL
            quoteEntity.savedDate = quote.savedDate
            quoteEntity.isFullArticle = quote.isFullArticle
            
            // 关联到文章
            let articleFetchRequest: NSFetchRequest<ArticleEntity> = ArticleEntity.fetchRequest()
            articleFetchRequest.predicate = NSPredicate(format: "id == %@", articleId as CVarArg)
            if let articleEntity = try viewContext.fetch(articleFetchRequest).first {
                quoteEntity.article = articleEntity
            }
            
            saveContext()
            return quoteEntity
        } catch {
            fatalError("Failed to fetch quote: \(error)")
        }
    }
    
    /// 获取文章的所有收藏语段
    /// - Parameter articleId: 文章ID
    /// - Returns: Quote 数组
    func getQuotes(for articleId: UUID) -> [Quote] {
        let fetchRequest: NSFetchRequest<QuoteEntity> = QuoteEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "article.id == %@", articleId as CVarArg)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \QuoteEntity.savedDate, ascending: false)]
        
        do {
            let quoteEntities = try viewContext.fetch(fetchRequest)
            return quoteEntities.map { entity in
                Quote(
                    id: entity.id ?? UUID(),
                    content: entity.content ?? "",
                    articleTitle: entity.articleTitle ?? "",
                    articleURL: entity.articleURL ?? "",
                    savedDate: entity.savedDate ?? Date(),
                    isFullArticle: entity.isFullArticle
                )
            }
        } catch {
            print("Failed to fetch quotes: \(error)")
            return []
        }
    }
    
    /// 获取所有收藏语段
    /// - Returns: Quote 数组
    func getAllQuotes() -> [Quote] {
        let fetchRequest: NSFetchRequest<QuoteEntity> = QuoteEntity.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \QuoteEntity.savedDate, ascending: false)]
        
        do {
            let quoteEntities = try viewContext.fetch(fetchRequest)
            return quoteEntities.map { entity in
                Quote(
                    id: entity.id ?? UUID(),
                    content: entity.content ?? "",
                    articleTitle: entity.articleTitle ?? "",
                    articleURL: entity.articleURL ?? "",
                    savedDate: entity.savedDate ?? Date(),
                    isFullArticle: entity.isFullArticle
                )
            }
        } catch {
            print("Failed to fetch quotes: \(error)")
            return []
        }
    }
    
    /// 删除收藏语段
    /// - Parameter id: 语段ID
    func deleteQuote(id: UUID) {
        let fetchRequest: NSFetchRequest<QuoteEntity> = QuoteEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            let results = try viewContext.fetch(fetchRequest)
            if let quoteEntity = results.first {
                viewContext.delete(quoteEntity)
                saveContext()
            }
        } catch {
            print("Failed to delete quote: \(error)")
        }
    }
    
    // MARK: - Data Cleanup operations
    
    /// 清理过期的文章
    /// - Parameters:
    ///   - olderThan: 清理该日期之前的文章
    ///   - keepUnread: 是否保留未读文章
    ///   - maxArticlesPerFeed: 每个Feed保留的最大文章数量，nil表示不限制
    func cleanupArticles(olderThan date: Date, keepUnread: Bool = true, maxArticlesPerFeed: Int? = nil) {
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<FeedEntity> = FeedEntity.fetchRequest()
        
        do {
            let feeds = try context.fetch(fetchRequest)
            
            for feed in feeds {
                // 获取该Feed下的所有文章
                let articleRequest: NSFetchRequest<ArticleEntity> = ArticleEntity.fetchRequest()
                articleRequest.predicate = NSPredicate(format: "feed == %@", feed)
                articleRequest.sortDescriptors = [NSSortDescriptor(keyPath: \ArticleEntity.publishDate, ascending: false)]
                
                let articles = try context.fetch(articleRequest)
                
                // 如果设置了最大文章数量限制
                if let maxArticles = maxArticlesPerFeed, articles.count > maxArticles {
                    let articlesToDelete = articles[maxArticles...]
                    for article in articlesToDelete {
                        // 如果设置了保留未读文章且当前文章未读，则跳过
                        if keepUnread && !article.isRead {
                            continue
                        }
                        context.delete(article)
                    }
                }
                
                // 删除过期文章
                for article in articles {
                    if let publishDate = article.publishDate,
                       publishDate < date {
                        // 如果设置了保留未读文章且当前文章未读，则跳过
                        if keepUnread && !article.isRead {
                            continue
                        }
                        context.delete(article)
                    }
                }
            }
            
            saveContext()
        } catch {
            print("Failed to cleanup articles: \(error)")
        }
    }
    
    /// 清理过期的每日总结
    /// - Parameter olderThan: 清理该日期之前的总结
    func cleanupDailySummaries(olderThan date: Date) {
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<DailySummaryEntity> = DailySummaryEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date < %@", date as NSDate)
        
        do {
            let summaries = try context.fetch(fetchRequest)
            for summary in summaries {
                context.delete(summary)
            }
            saveContext()
        } catch {
            print("Failed to cleanup daily summaries: \(error)")
        }
    }
    
    /// 清理孤立的洞察数据（没有关联文章的洞察）
    func cleanupOrphanedInsights() {
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<ArticleInsightEntity> = ArticleInsightEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "article == nil")
        
        do {
            let insights = try context.fetch(fetchRequest)
            for insight in insights {
                context.delete(insight)
            }
            saveContext()
        } catch {
            print("Failed to cleanup orphaned insights: \(error)")
        }
    }
    
    /// 清理孤立的收藏语段（没有关联文章的语段）
    func cleanupOrphanedQuotes() {
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<QuoteEntity> = QuoteEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "article == nil")
        
        do {
            let quotes = try context.fetch(fetchRequest)
            for quote in quotes {
                context.delete(quote)
            }
            saveContext()
        } catch {
            print("Failed to cleanup orphaned quotes: \(error)")
        }
    }
    
    /// 执行所有清理操作
    /// - Parameters:
    ///   - articleAge: 文章保留时间（天数）
    ///   - summaryAge: 每日总结保留时间（天数）
    ///   - maxArticlesPerFeed: 每个Feed保留的最大文章数量
    func performCleanup(articleAge: Int = 90, summaryAge: Int = 30, maxArticlesPerFeed: Int = 100) {
        let calendar = Calendar.current
        let now = Date()
        
        // 清理过期文章（默认90天）
        let articleDate = calendar.date(byAdding: .day, value: -articleAge, to: now)!
        cleanupArticles(olderThan: articleDate, keepUnread: true, maxArticlesPerFeed: maxArticlesPerFeed)
        
        // 清理过期的每日总结（默认30天）
        let summaryDate = calendar.date(byAdding: .day, value: -summaryAge, to: now)!
        cleanupDailySummaries(olderThan: summaryDate)
        
        // 清理孤立数据
        cleanupOrphanedInsights()
        cleanupOrphanedQuotes()
    }
    
    // MARK: - Reading Records operations
    
    /// 清除所有阅读记录
    func clearAllReadingRecords() {
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "ReadingRecordEntity")
        
        // 创建批量删除请求
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        batchDeleteRequest.resultType = .resultTypeObjectIDs
        
        do {
            let result = try context.execute(batchDeleteRequest) as? NSBatchDeleteResult
            if let objectIDs = result?.result as? [NSManagedObjectID] {
                // 通知上下文对象已被删除
                let changes = [NSDeletedObjectsKey: objectIDs]
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [context])
            }
            // 保存上下文
            try context.save()
        } catch {
            print("Failed to clear reading records: \(error)")
        }
    }
    
    // MARK: - Reading Record operations
    
    /// 创建或更新阅读记录
    /// - Parameters:
    ///   - record: ReadingRecord 实例
    ///   - articleId: 文章ID
    /// - Returns: ReadingRecordEntity 实例
    @discardableResult
    func createOrUpdateReadingRecord(_ record: ReadingRecord, articleId: UUID) -> ReadingRecordEntity {
        let fetchRequest: NSFetchRequest<ReadingRecordEntity> = ReadingRecordEntity.fetchRequest()
        // 使用文章 ID 或 URL 作为查找条件
        fetchRequest.predicate = NSPredicate(format: "article.id == %@ OR articleURL == %@", 
            articleId as CVarArg,
            record.articleURL as CVarArg
        )
        
        do {
            let results = try viewContext.fetch(fetchRequest)
            let recordEntity = results.first ?? ReadingRecordEntity(context: viewContext)
            
            // 如果是更新现有记录,累加时长
            if results.first != nil {
                recordEntity.duration += record.duration
                // 保持最早的开始时间
                if let existingStartTime = recordEntity.startTime,
                   existingStartTime > record.startTime {
                    recordEntity.startTime = record.startTime
                }
            } else {
                // 新记录,设置所有字段
                recordEntity.id = record.id
                recordEntity.startTime = record.startTime
                recordEntity.duration = record.duration
                recordEntity.articleTitle = record.articleTitle
                recordEntity.articleURL = record.articleURL
            }
            
            // 尝试关联到文章
            let articleFetchRequest: NSFetchRequest<ArticleEntity> = ArticleEntity.fetchRequest()
            articleFetchRequest.predicate = NSPredicate(format: "id == %@ OR url == %@", 
                articleId as CVarArg, 
                record.articleURL as CVarArg
            )
            
            if let articleEntity = try viewContext.fetch(articleFetchRequest).first {
                recordEntity.article = articleEntity
                
                // 如果记录没有标题,使用文章的标题
                if recordEntity.articleTitle == nil || recordEntity.articleTitle?.isEmpty == true {
                    recordEntity.articleTitle = articleEntity.title
                }
            }
            
            saveContext()
            return recordEntity
        } catch {
            print("Failed to fetch reading record: \(error)")
            fatalError("Failed to fetch reading record: \(error)")
        }
    }
    
    /// 获取文章的所有阅读记录
    /// - Parameter articleId: 文章ID
    /// - Returns: ReadingRecord 数组
    func getReadingRecords(for articleId: UUID) -> [ReadingRecord] {
        let fetchRequest: NSFetchRequest<ReadingRecordEntity> = ReadingRecordEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "article.id == %@", articleId as CVarArg)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \ReadingRecordEntity.startTime, ascending: false)]
        
        do {
            let recordEntities = try viewContext.fetch(fetchRequest)
            return recordEntities.map { entity in
                ReadingRecord(
                    id: entity.id ?? UUID(),
                    articleId: entity.article?.id?.uuidString ?? "",
                    articleTitle: entity.articleTitle ?? entity.article?.title ?? "",
                    articleURL: entity.articleURL ?? entity.article?.url ?? "",
                    startTime: entity.startTime ?? Date(),
                    duration: entity.duration
                )
            }
        } catch {
            print("Failed to fetch reading records: \(error)")
            return []
        }
    }
    
    /// 获取指定日期范围内的阅读记录
    /// - Parameters:
    ///   - startDate: 开始日期
    ///   - endDate: 结束日期
    /// - Returns: ReadingRecord 数组
    func getReadingRecords(from startDate: Date, to endDate: Date) -> [ReadingRecord] {
        let fetchRequest: NSFetchRequest<ReadingRecordEntity> = ReadingRecordEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "startTime >= %@ AND startTime <= %@", startDate as NSDate, endDate as NSDate)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \ReadingRecordEntity.startTime, ascending: false)]
        
        do {
            let recordEntities = try viewContext.fetch(fetchRequest)
            return recordEntities.map { entity in
                let title = entity.articleTitle ?? entity.article?.title ?? ""
                
                return ReadingRecord(
                    id: entity.id ?? UUID(),
                    articleId: entity.article?.id?.uuidString ?? "",
                    articleTitle: title,
                    articleURL: entity.articleURL ?? entity.article?.url ?? "",
                    startTime: entity.startTime ?? Date(),
                    duration: entity.duration
                )
            }
        } catch {
            print("Failed to fetch reading records: \(error)")
            return []
        }
    }
    
    // MARK: - Reading Stats operations
    
    /// 创建或更新阅读统计
    /// - Parameter stats: ReadingStats 实例
    /// - Returns: ReadingStatsEntity 实例
    @discardableResult
    func createOrUpdateReadingStats(_ stats: ReadingStats) -> ReadingStatsEntity {
        let fetchRequest: NSFetchRequest<ReadingStatsEntity> = ReadingStatsEntity.fetchRequest()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: stats.date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        
        do {
            let results = try viewContext.fetch(fetchRequest)
            let statsEntity = results.first ?? ReadingStatsEntity(context: viewContext)
            
            statsEntity.date = stats.date
            statsEntity.totalReadingTime = stats.totalReadingTime
            statsEntity.articleCount = Int32(stats.articleCount)
            statsEntity.actualReadingDays = Int32(stats.actualReadingDays)
            
            saveContext()
            return statsEntity
        } catch {
            fatalError("Failed to fetch reading stats: \(error)")
        }
    }
    
    /// 获取指定日期的阅读统计
    /// - Parameter date: 日期
    /// - Returns: ReadingStats? 实例
    func getReadingStats(for date: Date) -> ReadingStats? {
        let fetchRequest: NSFetchRequest<ReadingStatsEntity> = ReadingStatsEntity.fetchRequest()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        
        do {
            let results = try viewContext.fetch(fetchRequest)
            guard let entity = results.first else { return nil }
            
            return ReadingStats(
                totalReadingTime: entity.totalReadingTime,
                articleCount: Int(entity.articleCount),
                date: entity.date ?? date,
                actualReadingDays: Int(entity.actualReadingDays)
            )
        } catch {
            print("Failed to fetch reading stats: \(error)")
            return nil
        }
    }
    
    /// 获取指定日期范围的阅读统计
    /// - Parameters:
    ///   - startDate: 开始日期
    ///   - endDate: 结束日期
    /// - Returns: ReadingStats 实例
    func getReadingStats(from startDate: Date, to endDate: Date) -> ReadingStats {
        let fetchRequest: NSFetchRequest<ReadingRecordEntity> = ReadingRecordEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "startTime >= %@ AND startTime <= %@", startDate as NSDate, endDate as NSDate)
        
        do {
            let records = try viewContext.fetch(fetchRequest)
            let totalTime = records.reduce(0) { $0 + $1.duration }
            let articleIds = Set(records.compactMap { $0.article?.id })
            let actualReadingDays = Set(records.compactMap { 
                $0.startTime.map { Calendar.current.startOfDay(for: $0) }
            }).count
            
            return ReadingStats(
                totalReadingTime: totalTime,
                articleCount: articleIds.count,
                date: startDate,
                actualReadingDays: max(1, actualReadingDays)
            )
        } catch {
            print("Failed to calculate reading stats: \(error)")
            return ReadingStats(date: startDate)
        }
    }
    
    /// 清理过期的阅读记录和统计数据
    /// - Parameter olderThan: 清理该日期之前的数据
    func cleanupReadingHistory(olderThan date: Date) {
        let context = persistentContainer.viewContext
        
        // 清理阅读记录
        let recordsFetchRequest: NSFetchRequest<ReadingRecordEntity> = ReadingRecordEntity.fetchRequest()
        recordsFetchRequest.predicate = NSPredicate(format: "startTime < %@", date as NSDate)
        
        // 清理阅读统计
        let statsFetchRequest: NSFetchRequest<ReadingStatsEntity> = ReadingStatsEntity.fetchRequest()
        statsFetchRequest.predicate = NSPredicate(format: "date < %@", date as NSDate)
        
        do {
            let oldRecords = try context.fetch(recordsFetchRequest)
            let oldStats = try context.fetch(statsFetchRequest)
            
            for record in oldRecords {
                context.delete(record)
            }
            
            for stats in oldStats {
                context.delete(stats)
            }
            
            saveContext()
        } catch {
            print("Failed to cleanup reading history: \(error)")
        }
    }
}