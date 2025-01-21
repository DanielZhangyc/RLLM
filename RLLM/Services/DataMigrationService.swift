import Foundation
import CoreData
import os

/// 数据迁移服务
class DataMigrationService {
    static let shared = DataMigrationService()
    
    private let defaults = UserDefaults.standard
    private let migrationKey = "data_migration_completed"
    private let coreDataManager = CoreDataManager.shared
    private let storageService = StorageService.shared
    private let quotesViewModel = QuotesViewModel.shared
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Migration")
    
    private init() {}
    
    /// 检查是否需要执行迁移
    var needsMigration: Bool {
        !defaults.bool(forKey: migrationKey)
    }
    
    /// 执行数据迁移
    func performMigration() {
        guard needsMigration else {
            logger.info("No migration needed")
            return
        }
        
        logger.info("Starting data migration...")
        
        // 迁移Feed数据
        let feeds = storageService.loadFeeds()
        logger.info("Found \(feeds.count) feeds to migrate")
        
        for feed in feeds {
            logger.info("Migrating feed: \(feed.title)")
            _ = coreDataManager.createOrUpdateFeed(feed)
            
            // 迁移该Feed下的所有文章
            let articles = storageService.loadArticles(for: feed.id)
            logger.info("Found \(articles.count) articles for feed: \(feed.title)")
            
            for article in articles {
                let _ = coreDataManager.createOrUpdateArticle(article, feedId: feed.id)
                
                // 迁移该文章的收藏语段
                let quotes = quotesViewModel.quotes.filter { $0.articleURL == article.url }
                if !quotes.isEmpty {
                    logger.info("Migrating \(quotes.count) quotes for article: \(article.title)")
                }
                
                for quote in quotes {
                    _ = coreDataManager.createOrUpdateQuote(quote, articleId: article.id)
                }
            }
            
            // 迁移完成后删除UserDefaults中的文章数据
            storageService.removeArticles(for: feed.id)
            logger.info("Removed old articles data for feed: \(feed.title)")
        }
        
        // 迁移阅读历史数据
        migrateReadingHistory()
        
        // 标记迁移完成
        defaults.set(true, forKey: migrationKey)
        
        // 清理旧数据
        defaults.removeObject(forKey: StorageService.feedsKey)
        defaults.removeObject(forKey: "saved_quotes") // 清理旧的quotes数据
        defaults.removeObject(forKey: "reading_stats") // 清理旧的阅读统计数据
        defaults.removeObject(forKey: "reading_records") // 清理旧的阅读记录数据
        storageService.clearAllData()
        
        logger.info("Migration completed successfully")
    }
    
    /// 迁移阅读历史数据
    private func migrateReadingHistory() {
        logger.info("Starting reading history migration...")
        
        // 迁移阅读统计数据
        if let statsData = defaults.data(forKey: "reading_stats"),
           let stats = try? JSONDecoder().decode([String: ReadingStats].self, from: statsData) {
            logger.info("Found \(stats.count) reading stats to migrate")
            
            for (dateString, stat) in stats {
                guard let date = DateFormatter.yyyyMMdd.date(from: dateString) else { continue }
                let readingStats = ReadingStats(
                    totalReadingTime: stat.totalReadingTime,
                    articleCount: stat.articleCount,
                    date: date,
                    actualReadingDays: stat.actualReadingDays
                )
                _ = coreDataManager.createOrUpdateReadingStats(readingStats)
            }
        }
        
        // 迁移阅读记录数据
        if let recordsData = defaults.data(forKey: "reading_records"),
           let records = try? JSONDecoder().decode([ReadingRecord].self, from: recordsData) {
            logger.info("Found \(records.count) reading records to migrate")
            
            for record in records {
                if let articleId = UUID(uuidString: record.articleId) {
                    _ = coreDataManager.createOrUpdateReadingRecord(record, articleId: articleId)
                }
            }
        }
        
        logger.info("Reading history migration completed")
    }
    
    /// 重置迁移状态（用于测试）
    func resetMigrationStatus() {
        defaults.set(false, forKey: migrationKey)
        logger.info("Migration status reset")
    }
}
