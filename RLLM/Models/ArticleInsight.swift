import Foundation

/// 表示文章的AI分析洞察结果
struct ArticleInsight: Identifiable, Codable, Equatable {
    // MARK: - Properties
    
    /// 洞察结果的唯一标识符
    let id: UUID
    
    /// 文章的核心摘要
    let summary: String
    
    /// 文章的关键观点列表
    let keyPoints: [String]
    
    /// 文章的主题标签
    let topics: [String]
    
    /// 文章的情感倾向描述
    let sentiment: String
    
    /// 相关背景信息补充
    let backgroundInfo: String?
    
    // MARK: - Initialization
    
    /// 创建一个新的ArticleInsight实例
    /// - Parameters:
    ///   - id: 唯一标识符，默认自动生成
    ///   - summary: 文章核心摘要
    ///   - keyPoints: 关键观点列表
    ///   - topics: 主题标签列表
    ///   - sentiment: 情感倾向描述
    ///   - backgroundInfo: 背景信息补充，可选
    init(
        id: UUID = UUID(),
        summary: String,
        keyPoints: [String],
        topics: [String],
        sentiment: String,
        backgroundInfo: String? = nil
    ) {
        self.id = id
        self.summary = summary
        self.keyPoints = keyPoints
        self.topics = topics
        self.sentiment = sentiment
        self.backgroundInfo = backgroundInfo
    }
    
    // MARK: - Equatable
    
    static func == (lhs: ArticleInsight, rhs: ArticleInsight) -> Bool {
        lhs.id == rhs.id &&
        lhs.summary == rhs.summary &&
        lhs.keyPoints == rhs.keyPoints &&
        lhs.topics == rhs.topics &&
        lhs.sentiment == rhs.sentiment &&
        lhs.backgroundInfo == rhs.backgroundInfo
    }
} 