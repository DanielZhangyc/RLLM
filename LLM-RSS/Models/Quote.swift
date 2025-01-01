import Foundation

/// 文章引用模型
/// 用于保存用户在阅读文章时标记的重要引用内容
/// 
/// 未来功能:
/// - 支持用户在阅读时长按选择文本保存为引用
/// - 在"收藏"标签页中展示所有保存的引用
/// - 支持为引用添加标签和笔记
/// - 支持引用的分类管理和搜索
struct Quote: Identifiable, Codable {
    let id: UUID
    let content: String      // 引用内容
    let articleTitle: String // 来源文章标题
    let articleURL: String   // 来源文章链接
    let savedDate: Date      // 保存时间
    let isFullArticle: Bool  // 是否为全文收藏
    
    init(id: UUID = UUID(), 
         content: String, 
         articleTitle: String, 
         articleURL: String, 
         savedDate: Date = Date(), 
         isFullArticle: Bool = false) {
        self.id = id
        self.content = content
        self.articleTitle = articleTitle
        self.articleURL = articleURL
        self.savedDate = savedDate
        self.isFullArticle = isFullArticle
    }
} 