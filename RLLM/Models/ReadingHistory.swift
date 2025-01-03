import Foundation

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
    
    private let defaults = UserDefaults.standard
    private let statsKey = "reading_stats"
    private let recordsKey = "reading_records"
    private let calendar = Calendar.current
    
    private init() {
        loadData()
    }
    
    private func loadData() {
        if let statsData = defaults.data(forKey: statsKey),
           let stats = try? JSONDecoder().decode([String: ReadingStats].self, from: statsData) {
            // 将字符串日期转换回Date类型
            dailyStats = Dictionary(uniqueKeysWithValues: stats.compactMap { key, value in
                guard let date = DateFormatter.yyyyMMdd.date(from: key) else { return nil }
                return (date, value)
            })
        }
        
        if let recordsData = defaults.data(forKey: recordsKey),
           let records = try? JSONDecoder().decode([ReadingRecord].self, from: recordsData) {
            // 按时间倒序排列，最新的在最前面
            readingRecords = records.sorted { $0.startTime > $1.startTime }
        }
    }
    
    private func saveData() {
        // 将Date类型转换为字符串以便存储
        let statsDict = Dictionary(uniqueKeysWithValues: dailyStats.map { date, stats in
            (DateFormatter.yyyyMMdd.string(from: date), stats)
        })
        
        if let encoded = try? JSONEncoder().encode(statsDict) {
            defaults.set(encoded, forKey: statsKey)
        }
        
        if let encoded = try? JSONEncoder().encode(readingRecords) {
            defaults.set(encoded, forKey: recordsKey)
        }
    }
    
    /// 添加或更新阅读记录
    func addRecord(_ record: ReadingRecord) {
        // 检查是否已存在该文章的记录
        if let existingIndex = readingRecords.firstIndex(where: { $0.articleId == record.articleId }) {
            // 更新现有记录
            let oldRecord = readingRecords[existingIndex]
            let updatedRecord = ReadingRecord(
                id: oldRecord.id,  // 保持原有的记录ID
                articleId: record.articleId,
                articleTitle: record.articleTitle,
                articleURL: record.articleURL,
                startTime: record.startTime,  // 使用新的开始时间
                duration: record.duration
            )
            readingRecords.remove(at: existingIndex)
            readingRecords.insert(updatedRecord, at: 0)  // 插入到最前面
        } else {
            // 添加新记录到最前面
            readingRecords.insert(record, at: 0)
        }
        
        updateDailyStats(with: record)
        saveData()
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
        let records = readingRecords.filter { 
            $0.startTime >= startDate && $0.startTime <= endDate 
        }
        
        let totalTime = records.reduce(0) { $0 + $1.duration }
        let articleCount = Set(records.map { $0.articleId }).count
        let actualReadingDays = getActualReadingDays(from: startDate, to: endDate)
        
        return ReadingStats(
            totalReadingTime: totalTime,
            articleCount: articleCount,
            date: startDate,
            actualReadingDays: max(1, actualReadingDays)  // 至少为1天
        )
    }
    
    /// 获取指定日期的阅读统计
    func getStats(for date: Date) -> ReadingStats {
        let startOfDay = calendar.startOfDay(for: date)
        if let stats = dailyStats[startOfDay] {
            // 如果是当天的统计，actualReadingDays 设为 1
            return ReadingStats(
                totalReadingTime: stats.totalReadingTime,
                articleCount: stats.articleCount,
                date: stats.date,
                actualReadingDays: 1
            )
        }
        return ReadingStats(date: startOfDay)
    }
    
    /// 获取指定日期范围的阅读记录
    func getRecords(from startDate: Date, to endDate: Date) -> [ReadingRecord] {
        readingRecords.filter { record in
            record.startTime >= startDate && record.startTime <= endDate
        }
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
        
        return dailyStats
            .filter { date, _ in date >= weekStart && date <= today }
            .reduce(0) { $0 + $1.value.totalReadingTime } / 60.0
    }
    
    /// 清除超过30天的历史记录
    func cleanOldRecords() {
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date())!
        
        // 清除旧的阅读记录
        readingRecords.removeAll { $0.startTime < thirtyDaysAgo }
        
        // 清除旧的统计数据
        dailyStats = dailyStats.filter { date, _ in date >= thirtyDaysAgo }
        
        saveData()
    }
    
    /// 清除所有阅读记录
    func clearAllRecords() {
        readingRecords.removeAll()
        dailyStats.removeAll()
        saveData()
    }
} 