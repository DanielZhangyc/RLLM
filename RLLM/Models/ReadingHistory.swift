import Foundation
import CoreData

/// 阅读记录模型
struct ReadingRecord: Codable, Identifiable {
    let id: UUID
    let articleId: String
    let articleTitle: String
    let articleURL: String
    let startTime: Date
    let duration: TimeInterval  // 阅读时长（秒）
    
    init(
        id: UUID = UUID(),
        articleId: String,
        articleTitle: String,
        articleURL: String,
        startTime: Date = Date(),
        duration: TimeInterval
    ) {
        self.id = id
        self.articleId = articleId
        self.articleTitle = articleTitle
        self.articleURL = articleURL
        self.startTime = startTime
        self.duration = duration
    }
}

/// 阅读统计模型
struct ReadingStats: Codable {
    var totalReadingTime: TimeInterval  // 总阅读时长
    var articleCount: Int  // 阅读文章数
    var date: Date  // 统计日期
    var actualReadingDays: Int = 1  // 实际阅读天数，默认为1
    
    init(
        totalReadingTime: TimeInterval = 0,
        articleCount: Int = 0,
        date: Date = Date(),
        actualReadingDays: Int = 1
    ) {
        self.totalReadingTime = totalReadingTime
        self.articleCount = articleCount
        self.date = date
        self.actualReadingDays = actualReadingDays
    }
    
    /// 计算平均每日阅读时长（仅在查看周/月统计时有意义，且只计入有阅读记录的天数）
    var averageDailyTime: TimeInterval {
        // 如果总阅读时长为0，直接返回0
        guard totalReadingTime > 0 else { return 0 }
        
        // 如果是当天的统计，直接返回总时长
        guard let daysCount = Calendar.current.dateComponents([.day], from: date, to: Date()).day,
              daysCount > 0 else {
            return totalReadingTime
        }
        
        // 使用实际阅读天数计算平均值
        return totalReadingTime / Double(max(1, actualReadingDays))
    }
}

/// 阅读历史管理器
class ReadingHistoryManager: ObservableObject {
    static let shared = ReadingHistoryManager()
    
    /// 最小记录阅读时长（秒）
    static let minimumReadingDuration: TimeInterval = 30
    
    @Published var dailyStats: [Date: ReadingStats] = [:]
    @Published var readingRecords: [ReadingRecord] = []
    
    private let coreDataManager = CoreDataManager.shared
    private let calendar = Calendar.current
    
    private init() {
        loadData()
    }
    
    private func loadData() {
        // 加载今天的统计数据
        let today = calendar.startOfDay(for: Date())
        if let stats = coreDataManager.getReadingStats(for: today) {
            dailyStats[today] = stats
        }
        
        // 加载最近30天的阅读记录
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: today)!
        readingRecords = coreDataManager.getReadingRecords(from: thirtyDaysAgo, to: Date())
    }
    
    /// 添加或更新阅读记录
    func addRecord(_ record: ReadingRecord) {
        guard let articleId = UUID(uuidString: record.articleId) else { return }
        
        // 查找是否存在同一文章的记录
        if let existingIndex = readingRecords.firstIndex(where: { $0.articleId == record.articleId }) {
            let existingRecord = readingRecords[existingIndex]
            // 创建新记录,累加时长,保留最早的开始时间
            let updatedRecord = ReadingRecord(
                id: UUID(), // 生成新的ID
                articleId: record.articleId,
                articleTitle: record.articleTitle,
                articleURL: record.articleURL,
                startTime: min(existingRecord.startTime, record.startTime), // 保留最早的开始时间
                duration: existingRecord.duration + record.duration // 累加时长
            )
            // 更新Core Data中的记录
            _ = coreDataManager.createOrUpdateReadingRecord(updatedRecord, articleId: articleId)
            // 更新内存中的记录
            readingRecords[existingIndex] = updatedRecord
        } else {
            // 如果是新文章,直接添加记录
            _ = coreDataManager.createOrUpdateReadingRecord(record, articleId: articleId)
            readingRecords.insert(record, at: 0)
        }
        
        // 更新统计数据
        updateDailyStats(with: record)
    }
    
    /// 更新每日统计数据
    private func updateDailyStats(with record: ReadingRecord) {
        let date = calendar.startOfDay(for: record.startTime)
        var stats = dailyStats[date] ?? ReadingStats(date: date)
        
        // 如果是更新现有记录，不增加文章计数
        let isExistingArticle = readingRecords.contains { 
            $0.articleId == record.articleId && 
            calendar.isDate($0.startTime, inSameDayAs: record.startTime)
        }
        
        if !isExistingArticle {
            stats.articleCount += 1
        }
        
        stats.totalReadingTime += record.duration
        
        // 更新Core Data中的统计数据
        _ = coreDataManager.createOrUpdateReadingStats(stats)
        
        // 更新内存中的统计数据
        dailyStats[date] = stats
    }
    
    /// 获取指定日期范围内有阅读记录的天数
    private func getActualReadingDays(from startDate: Date, to endDate: Date) -> Int {
        let daysWithReading = Set(readingRecords
            .filter { $0.startTime >= startDate && $0.startTime <= endDate }
            .map { calendar.startOfDay(for: $0.startTime) }
        )
        return daysWithReading.count
    }
    
    /// 获取指定日期范围的阅读统计
    func getStats(from startDate: Date, to endDate: Date) -> ReadingStats {
        coreDataManager.getReadingStats(from: startDate, to: endDate)
    }
    
    /// 获取指定日期的阅读统计
    func getStats(for date: Date) -> ReadingStats {
        let startOfDay = calendar.startOfDay(for: date)
        if let stats = coreDataManager.getReadingStats(for: startOfDay) {
            return stats
        }
        return ReadingStats(date: startOfDay)
    }
    
    /// 获取指定日期范围的阅读记录
    func getRecords(from startDate: Date, to endDate: Date) -> [ReadingRecord] {
        coreDataManager.getReadingRecords(from: startDate, to: endDate)
    }
    
    /// 获取今日阅读时长（分钟）
    var todayReadingMinutes: Double {
        let today = calendar.startOfDay(for: Date())
        return dailyStats[today]?.totalReadingTime ?? 0 / 60.0
    }
    
    /// 获取本周阅读时长（分钟）
    var weeklyReadingMinutes: Double {
        let calendar = Calendar.current
        let today = Date()
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) else {
            return 0
        }
        
        let stats = getStats(from: weekStart, to: today)
        return stats.totalReadingTime / 60.0
    }
    
    /// 清除超过30天的历史记录
    func cleanOldRecords() {
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date())!
        coreDataManager.cleanupReadingHistory(olderThan: thirtyDaysAgo)
        loadData() // 重新加载数据
    }
    
    /// 清除所有阅读记录
    func clearAllRecords() {
        let longTimeAgo = Date.distantPast
        coreDataManager.cleanupReadingHistory(olderThan: longTimeAgo)
        dailyStats.removeAll()
        readingRecords.removeAll()
    }
}