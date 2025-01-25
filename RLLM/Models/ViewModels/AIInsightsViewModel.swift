import SwiftUI
import Foundation

/// AI 洞察功能的视图模型
/// 负责处理 AI 分析相关的业务逻辑
///
/// 未来功能:
/// - 文章主题聚类
/// - 阅读偏好分析
/// - 关键词提取
/// - 文章推荐算法
/// - 阅读时间分析
class AIInsightsViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// 今日阅读内容的AI总结
    @Published var dailySummary: String?
    
    /// 热门话题列表
    @Published var topTopics: [String] = []
    
    /// 话题出现次数统计
    @Published var topicCounts: [String: Int] = [:]
    
    /// 关键观点列表
    @Published var keyPoints: [String]?
    
    /// 学习建议
    @Published var learningAdvice: String?
    
    /// 阅读时长
    @Published var readingTime: String?
    
    /// 文章洞察分析结果
    @Published var articleInsight: ArticleInsight?
    
    /// 是否正在进行分析
    @Published var isAnalyzing: Bool = false
    
    /// 错误信息
    @Published var error: Error?
    
    // MARK: - Private Properties
    
    /// LLM配置
    @AppStorage("llmConfig") private var storedConfig: Data?
    
    /// 阅读历史管理器
    private let historyManager = ReadingHistoryManager.shared
    
    /// 是否已有内容
    private var hasContent: Bool {
        dailySummary != nil && !dailySummary!.isEmpty && dailySummary != "今日暂无阅读记录" && dailySummary != "生成总结时出错"
    }
    
    /// 是否没有阅读记录
    var hasNoReadingRecords: Bool {
        dailySummary == "今日暂无阅读记录" || (dailySummary == nil && !isAnalyzing && error == nil)
    }
    
    // MARK: - Public Methods
    
    /// 解析每日总结
    /// - Parameter summary: LLM返回的总结文本
    private func parseDailySummary(_ summary: String) {
        print("开始解析每日总结，原始内容：\n\(summary)")
        
        let lines = summary.components(separatedBy: .newlines)
        var currentSection = ""
        var summaryText = ""
        var points: [String] = []
        var advice = ""
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            if trimmedLine.isEmpty { continue }
            
            if trimmedLine.contains("[核心摘要]") {
                currentSection = "summary"
                print("进入核心摘要部分")
                continue
            } else if trimmedLine.contains("[关键观点]") {
                currentSection = "points"
                print("进入关键观点部分")
                continue
            } else if trimmedLine.contains("[学习建议]") {
                currentSection = "advice"
                print("进入学习建议部分")
                continue
            }
            
            // 跳过格式说明行
            if trimmedLine.contains("（") { continue }
            
            switch currentSection {
            case "summary":
                if !trimmedLine.contains("[") {
                    summaryText = trimmedLine
                    print("解析到摘要：\(trimmedLine)")
                }
            case "points":
                if trimmedLine.hasPrefix("•") {
                    let point = trimmedLine.replacingOccurrences(of: "•", with: "")
                        .trimmingCharacters(in: .whitespaces)
                    points.append(point)
                    print("解析到观点：\(point)")
                }
            case "advice":
                if !trimmedLine.contains("[") {
                    advice = trimmedLine
                    print("解析到建议：\(trimmedLine)")
                }
            default:
                break
            }
        }
        
        print("解析完成：")
        print("摘要：\(summaryText)")
        print("观点数量：\(points.count)")
        print("建议：\(advice)")
        
        // 创建变量副本
        let finalSummaryText = summaryText
        let finalPoints = points
        let finalAdvice = advice
        
        Task { @MainActor in
            self.dailySummary = finalSummaryText
            self.keyPoints = finalPoints
            self.learningAdvice = finalAdvice
        }
    }
    
    /// 刷新AI洞察数据
    /// - Parameter forceRefresh: 是否强制刷新，忽略缓存
    func refreshInsights(forceRefresh: Bool = false) async {
        // 如果已有内容且不是强制刷新，则跳过
        if hasContent && !forceRefresh {
            print("已有内容，跳过刷新")
            return
        }
        
        // 如果正在分析中且不是强制刷新，则跳过
        if isAnalyzing && !forceRefresh {
            print("正在分析中，跳过刷新")
            return
        }
        
        print("开始刷新AI洞察数据，forceRefresh: \(forceRefresh)")
        
        await MainActor.run {
            isAnalyzing = true
            if forceRefresh {
                // 强制刷新时才清空现有内容
                dailySummary = nil
                topTopics = []
                topicCounts = [:]
                keyPoints = []
                learningAdvice = nil
                readingTime = nil
            }
            error = nil
        }
        
        // 检查LLM配置
        guard let configData = storedConfig,
              let config = try? JSONDecoder().decode(LLMConfig.self, from: configData) else {
            print("LLM配置解析失败")
            await MainActor.run {
                error = AIAnalysisError.configurationError("未找到有效的LLM配置")
                isAnalyzing = false
                // 清空所有内容
                dailySummary = nil
                topTopics = []
                topicCounts = [:]
                keyPoints = []
                learningAdvice = nil
                readingTime = nil
            }
            return
        }
        
        print("LLM配置解析成功：\(config.provider.rawValue), 模型：\(config.model)")
        
        // 获取今日阅读记录
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let todayRecords = historyManager.getRecords(from: today, to: Date())
        
        print("获取到今日阅读记录：\(todayRecords.count)条")
        
        // 如果今天没有阅读记录，显示提示信息
        guard !todayRecords.isEmpty else {
            print("今日无阅读记录")
            await MainActor.run {
                dailySummary = "今日暂无阅读记录"
                topTopics = []
                topicCounts = [:]
                keyPoints = []
                learningAdvice = nil
                readingTime = nil
                isAnalyzing = false
                error = nil
            }
            return
        }
        
        // 计算总阅读时长
        let totalDuration = todayRecords.reduce(0) { $0 + $1.duration }
        let hours = Int(totalDuration) / 3600
        let minutes = Int(totalDuration) % 3600 / 60
        let timeString: String
        if hours > 0 {
            timeString = String(format: NSLocalizedString("reading_history.hours_minutes", comment: "Hours and minutes"), hours, minutes)
        } else {
            timeString = String(format: NSLocalizedString(minutes == 1 ? "reading_history.minute" : "reading_history.minutes", comment: "Minutes"), minutes)
        }
        
        print("计算得到总阅读时长：\(timeString)")
        
        // 检查缓存
        if !forceRefresh, let cached = DailySummaryCache.shared.get(for: today) {
            print("使用缓存的每日总结")
            await MainActor.run {
                self.dailySummary = cached.summary
                self.keyPoints = cached.keyPoints
                self.learningAdvice = cached.learningAdvice
                self.readingTime = cached.readingTime
                self.topTopics = cached.topTopics
                self.topicCounts = cached.topicCounts
                self.isAnalyzing = false
            }
            return
        }
        
        do {
            // 使用async let并发执行两个请求
            async let summaryTask = LLMService.shared.generateDailySummary(for: todayRecords, config: config)
            async let topicsTask = LLMService.shared.analyzeTopics(for: todayRecords, config: config)
            
            // 等待两个任务完成
            let (summary, topicsAnalysis) = try await (summaryTask, topicsTask)
            
            print("今日总结生成成功，长度：\(summary.count)字符")
            print("话题分析成功，长度：\(topicsAnalysis.count)字符")
            
            // 解析结果
            parseDailySummary(summary)
            let (topics, counts) = parseTopicsAnalysis(topicsAnalysis, totalArticles: todayRecords.count)
            
            await MainActor.run {
                self.topTopics = topics
                self.topicCounts = counts
                self.readingTime = timeString
                self.error = nil
                self.isAnalyzing = false
                
                // 保存到缓存
                if let summary = self.dailySummary,
                   let keyPoints = self.keyPoints,
                   let learningAdvice = self.learningAdvice {
                    let cacheData = DailySummaryCache.DailySummaryData(
                        summary: summary,
                        keyPoints: keyPoints,
                        learningAdvice: learningAdvice,
                        readingTime: timeString,
                        topTopics: topics,
                        topicCounts: counts,
                        date: today
                    )
                    DailySummaryCache.shared.set(cacheData, for: today)
                }
            }
            
        } catch {
            print("刷新过程出错：\(error.localizedDescription)")
            if let llmError = error as? LLMService.LLMError {
                print("LLM服务错误：\(llmError)")
            }
            
            await MainActor.run {
                self.error = error
                self.dailySummary = "生成总结时出错"
                self.topTopics = []
                self.topicCounts = [:]
                self.keyPoints = []
                self.learningAdvice = nil
                self.readingTime = nil
                self.isAnalyzing = false
            }
        }
    }
    
    /// 分析指定文章内容
    /// - Parameters:
    ///   - content: 文章内容
    ///   - articleId: 文章ID
    ///   - forceRefresh: 是否强制刷新，忽略缓存
    /// - Returns: 分析是否成功
    func analyzeArticle(_ content: String, articleId: String, forceRefresh: Bool = false) async -> Bool {
        guard !content.isEmpty else {
            await MainActor.run {
                error = AIAnalysisError.contentError("文章内容为空")
            }
            return false
        }
        
        // 使用文章ID作为缓存key
        let cacheKey = articleId
        
        // 检查缓存（除非强制刷新）
        if !forceRefresh {
            if let cached = InsightCache.shared.get(for: cacheKey) {
                await MainActor.run {
                    self.articleInsight = cached
                }
                return true
            }
        }
        
        // 如果没有缓存或需要强制刷新，开始分析
        await MainActor.run {
            isAnalyzing = true
            articleInsight = nil
            error = nil
        }
        
        // 获取LLM配置
        guard let configData = storedConfig,
              let config = try? JSONDecoder().decode(LLMConfig.self, from: configData) else {
            await MainActor.run {
                error = AIAnalysisError.configurationError("未找到有效的LLM配置")
                isAnalyzing = false
            }
            return false
        }
        
        do {
            print("开始分析文章...")
            print("文章ID：\(cacheKey)")
            print("文章内容长度：\(content.count)字符")
            
            // 调用LLM服务
            print("正在调用LLM服务...")
            print("使用模型：\(config.model)")
            print("服务商：\(config.provider.rawValue)")
            
            let response = try await LLMService.shared.generateInsight(
                for: content,
                config: config
            )
            
            print("开始解析响应...")
            
            // 解析响应
            let lines = response.components(separatedBy: CharacterSet.newlines)
            print("总行数：\(lines.count)")
            
            var summary = ""
            var keyPoints: [String] = []
            var topics: [String] = []
            var sentiment = ""
            var backgroundInfo: String?
            
            var currentSection = ""
            var collectingSection = false
            
            for line in lines {
                let trimmedLine = line.trimmingCharacters(in: CharacterSet.whitespaces)
                if trimmedLine.isEmpty { continue }
                
                // 检查是否是新的段落标题
                if trimmedLine.contains("[核心摘要]") {
                    currentSection = "summary"
                    collectingSection = true
                    continue
                } else if trimmedLine.contains("[关键观点]") {
                    currentSection = "keyPoints"
                    collectingSection = true
                    continue
                } else if trimmedLine.contains("[主题标签]") {
                    currentSection = "topics"
                    collectingSection = true
                    continue
                } else if trimmedLine.contains("[情感倾向]") {
                    currentSection = "sentiment"
                    collectingSection = true
                    continue
                } else if trimmedLine.contains("[背景补充]") {
                    currentSection = "background"
                    collectingSection = true
                    continue
                }
                
                // 如果遇到下一个标记，停止收集当前段落
                if trimmedLine.hasPrefix("[") && trimmedLine.hasSuffix("]") {
                    collectingSection = false
                    continue
                }
                
                // 收集内容
                if collectingSection {
                    switch currentSection {
                    case "summary":
                        if summary.isEmpty {
                            summary = trimmedLine
                        }
                    case "keyPoints":
                        if trimmedLine.hasPrefix("-") || trimmedLine.hasPrefix("•") {
                            let point = trimmedLine.trimmingCharacters(in: CharacterSet(charactersIn: "- •"))
                                .trimmingCharacters(in: CharacterSet.whitespaces)
                            if !point.isEmpty {
                                keyPoints.append(point)
                            }
                        }
                    case "topics":
                        if topics.isEmpty {
                            topics = trimmedLine.components(separatedBy: ",")
                                .map { $0.trimmingCharacters(in: CharacterSet.whitespaces) }
                                .filter { !$0.isEmpty && !$0.hasPrefix("（") }
                        }
                    case "sentiment":
                        if sentiment.isEmpty {
                            sentiment = trimmedLine
                        }
                    case "background":
                        if backgroundInfo == nil {
                            backgroundInfo = trimmedLine
                        } else {
                            backgroundInfo! += "\n" + trimmedLine
                        }
                    default:
                        break
                    }
                }
            }
            
            // 检查必要字段
            var missingFields: [String] = []
            if summary.isEmpty { missingFields.append("核心摘要") }
            if keyPoints.isEmpty { missingFields.append("关键观点") }
            if topics.isEmpty { missingFields.append("主题标签") }
            if sentiment.isEmpty { missingFields.append("情感倾向") }
            
            if !missingFields.isEmpty {
                throw AIAnalysisError.parseError("响应缺少必要字段：\(missingFields.joined(separator: "、"))")
            }
            
            // 创建洞察结果
            let insight = ArticleInsight(
                summary: summary,
                keyPoints: keyPoints,
                topics: topics,
                sentiment: sentiment,
                backgroundInfo: backgroundInfo
            )
            
            // 保存到缓存
            InsightCache.shared.set(insight, for: cacheKey)
            
            await MainActor.run {
                self.articleInsight = insight
                self.isAnalyzing = false
                HapticManager.shared.success()
            }
            
            return true
            
        } catch let error as LLMService.LLMError {
            await MainActor.run {
                self.error = AIAnalysisError.llmServiceError(error.localizedDescription)
                self.isAnalyzing = false
            }
            return false
        } catch {
            await MainActor.run {
                self.error = AIAnalysisError.llmServiceError(error.localizedDescription)
                self.isAnalyzing = false
            }
            return false
        }
    }
    
    // MARK: - Private Methods
    
    /// 解析话题分析结果
    /// - Parameters:
    ///   - analysis: LLM返回的话题分析文本
    ///   - totalArticles: 文章总数
    /// - Returns: 话题列表和话题计数的元组
    private func parseTopicsAnalysis(_ analysis: String, totalArticles: Int) -> ([String], [String: Int]) {
        print("开始解析话题分析结果...")
        
        var topics: [String] = []
        var counts: [String: Int] = [:]
        
        // 按行分割文本
        let lines = analysis.components(separatedBy: .newlines)
        
        var isParsingTopics = false
        var isParsingCounts = false
        var currentTopics: [String] = []
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            if trimmedLine.isEmpty { continue }
            
            if trimmedLine.contains("[热门话题]") {
                isParsingTopics = true
                isParsingCounts = false
                currentTopics = []  // 重置当前话题列表
                continue
            } else if trimmedLine.contains("[话题分布]") {
                isParsingTopics = false
                isParsingCounts = true
                counts.removeAll()  // 重置计数
                continue
            }
            
            // 只跳过包含"使用英文逗号分隔"的说明行
            if trimmedLine.contains("使用英文逗号分隔") { continue }
            
            if isParsingTopics && !trimmedLine.hasPrefix("[") {
                // 解析话题列表
                let newTopics = trimmedLine.components(separatedBy: ",")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }
                currentTopics.append(contentsOf: newTopics)
            } else if isParsingCounts && !trimmedLine.hasPrefix("[") {
                // 解析话题计数
                let parts = trimmedLine.components(separatedBy: ":")
                if parts.count == 2 {
                    let topic = parts[0].trimmingCharacters(in: .whitespaces)
                    let countStr = parts[1].trimmingCharacters(in: .whitespaces)
                        .replacingOccurrences(of: "篇", with: "")
                        .trimmingCharacters(in: .whitespaces)
                    if let count = Int(countStr) {
                        // 确保计数不超过总文章数
                        counts[topic] = min(count, totalArticles)
                    }
                }
            }
        }
        
        // 使用当前解析到的话题列表
        topics = currentTopics
        
        // 确保topics和counts的键一致，并按计数排序
        topics = topics.filter { counts[$0] != nil }
            .sorted { (counts[$0] ?? 0) > (counts[$1] ?? 0) }
        
        print("解析完成：")
        print("总文章数：\(totalArticles)")
        print("话题列表：\(topics)")
        print("话题计数：\(counts)")
        
        return (topics, counts)
    }
} 
