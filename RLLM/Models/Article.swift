import Foundation
import CryptoKit

/// 文章的数据模型
struct Article: Identifiable, Codable {
    // MARK: - Properties
    
    /// 文章的唯一标识符，基于URL生成的哈希值
    let id: UUID
    
    /// 文章的标题
    let title: String
    
    /// 文章的正文内容
    let content: String
    
    /// 文章的原始URL地址
    let url: String
    
    /// 文章的发布日期
    let publishDate: Date
    
    /// 文章所属的RSS源标题
    var feedTitle: String
    
    /// 文章所属的RSS源ID
    var feedId: UUID?
    
    /// 文章的作者信息
    let author: String?
    
    /// 文章是否已读
    var isRead: Bool
    
    /// 文章的AI生成摘要
    var summary: String?
    
    // MARK: - Initialization
    
    /// 创建一个新的Article实例
    /// - Parameters:
    ///   - id: 唯一标识符，默认基于URL生成
    ///   - title: 文章标题
    ///   - content: 文章内容
    ///   - url: 文章URL
    ///   - publishDate: 发布日期
    ///   - feedTitle: RSS源标题
    ///   - feedId: RSS源ID
    ///   - author: 作者信息
    ///   - isRead: 是否已读
    ///   - summary: AI生成的摘要
    init(id: UUID = UUID(), title: String, content: String, url: String, publishDate: Date, feedTitle: String, feedId: UUID? = nil, author: String? = nil, isRead: Bool = false, summary: String? = nil) {
        let urlData = url.data(using: .utf8) ?? Data()
        let hash = SHA256.hash(data: urlData)
        let hashData = Data(hash)
        self.id = UUID(uuid: (hashData.prefix(16) + hashData.prefix(16)).withUnsafeBytes { $0.load(as: uuid_t.self) })
        
        self.title = title
        self.content = content
        self.url = url
        self.publishDate = publishDate
        self.feedTitle = feedTitle
        self.feedId = feedId
        self.author = author
        self.isRead = isRead
        self.summary = summary
    }
    
    // MARK: - Methods
    
    /// 更新Article的属性并返回新的实例
    /// - Parameters:
    ///   - isRead: 新的已读状态，如果为nil则保持原值
    ///   - summary: 新的摘要内容，如果为nil则保持原值
    ///   - feedTitle: 新的RSS源标题，如果为nil则保持原值
    ///   - feedId: 新的RSS源ID，如果为nil则保持原值
    /// - Returns: 更新后的Article实例
    func updating(isRead: Bool? = nil, summary: String? = nil, feedTitle: String? = nil, feedId: UUID? = nil) -> Article {
        Article(
            id: self.id,
            title: self.title,
            content: self.content,
            url: self.url,
            publishDate: self.publishDate,
            feedTitle: feedTitle ?? self.feedTitle,
            feedId: feedId ?? self.feedId,
            author: self.author,
            isRead: isRead ?? self.isRead,
            summary: summary ?? self.summary
        )
    }
} 
