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
    
    /// 文章洞察分析结果
    @Published var articleInsight: ArticleInsight?
    
    /// 是否正在进行分析
    @Published var isAnalyzing: Bool = false
    
    /// 错误信息
    @Published var error: Error?
    
    // MARK: - Private Properties
    
    /// LLM配置
    @AppStorage("llmConfig") private var storedConfig: Data?
    
    // MARK: - Public Methods
    
    /// 刷新AI洞察数据
    func refreshInsights() async {
        guard let _ = storedConfig else { return }
        
        // TODO: 分析最近阅读的文章，生成总结和话题分析
        await MainActor.run {
            dailySummary = "今日暂无总结"
            topTopics = ["技术", "科技", "AI"]
            topicCounts = [
                "技术": 5,
                "科技": 3,
                "AI": 2
            ]
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
            
            for (_, line) in lines.enumerated() {
                let trimmedLine = line.trimmingCharacters(in: CharacterSet.whitespaces)
                if trimmedLine.isEmpty { continue }
                
                // 检查是否是新的段落标题
                if trimmedLine.contains("[核心摘要]") {
                    print("找到核心摘要部分")
                    currentSection = "summary"
                    collectingSection = true
                    continue
                } else if trimmedLine.contains("[关键观点]") {
                    print("找到关键观点部分")
                    currentSection = "keyPoints"
                    collectingSection = true
                    continue
                } else if trimmedLine.contains("[主题标签]") {
                    print("找到主题标签部分")
                    currentSection = "topics"
                    collectingSection = true
                    continue
                } else if trimmedLine.contains("[情感倾向]") {
                    print("找到情感倾向部分")
                    currentSection = "sentiment"
                    collectingSection = true
                    continue
                } else if trimmedLine.contains("[背景补充]") {
                    print("找到背景补充部分")
                    currentSection = "background"
                    collectingSection = true
                    continue
                }
                
                // 如果遇到下一个标记，停止收集当前段落
                if trimmedLine.hasPrefix("[") && trimmedLine.hasSuffix("]") {
                    print("遇到新的段落标记，停止收集当前段落")
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
            }
            
            return true
            
        } catch let error as AIAnalysisError {
            await MainActor.run {
                self.error = error
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
} 
