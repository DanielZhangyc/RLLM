import Foundation

/// 每日总结缓存管理器
class DailySummaryCache {
    /// 单例实例
    static let shared = DailySummaryCache()
    
    /// 缓存管理器
    private let cacheManager: CacheManager
    
    private init() {
        cacheManager = CacheManager(directoryName: "daily_summaries")
    }
    
    /// 每日总结缓存数据结构
    struct DailySummaryData: Codable {
        let summary: String
        let keyPoints: [String]
        let learningAdvice: String
        let readingTime: String
        let topTopics: [String]
        let topicCounts: [String: Int]
        let date: Date
    }
    
    /// 获取缓存的每日总结
    /// - Parameter date: 日期（将使用这个日期的开始时间作为键）
    /// - Returns: 缓存的每日总结数据
    func get(for date: Date) -> DailySummaryData? {
        let key = dateKey(for: date)
        do {
            let data = try cacheManager.read(for: key)
            let summary = try JSONDecoder().decode(DailySummaryData.self, from: data)
            
            // 检查是否是同一天的数据
            let calendar = Calendar.current
            if calendar.isDate(summary.date, inSameDayAs: date) {
                return summary
            }
            return nil
        } catch {
            print("读取每日总结缓存失败：\(error)")
            return nil
        }
    }
    
    /// 保存每日总结到缓存
    /// - Parameters:
    ///   - summary: 总结数据
    ///   - date: 日期
    func set(_ summary: DailySummaryData, for date: Date) {
        let key = dateKey(for: date)
        do {
            let data = try JSONEncoder().encode(summary)
            try cacheManager.write(data, for: key)
        } catch {
            print("保存每日总结缓存失败：\(error)")
        }
    }
    
    /// 检查是否有缓存
    /// - Parameter date: 日期
    /// - Returns: 是否有缓存
    func has(for date: Date) -> Bool {
        let key = dateKey(for: date)
        return cacheManager.has(for: key)
    }
    
    /// 清除所有缓存
    func clear() {
        cacheManager.clearAll()
    }
    
    /// 获取缓存统计信息
    /// - Returns: 缓存统计信息
    func getStats() -> CacheStats {
        cacheManager.getStats()
    }
    
    /// 生成日期对应的缓存键
    /// - Parameter date: 日期
    /// - Returns: 缓存键
    private func dateKey(for date: Date) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return "\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
    }
} 