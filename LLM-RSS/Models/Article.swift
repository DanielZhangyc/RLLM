import Foundation
import CryptoKit

struct Article: Identifiable, Codable {
    let id: UUID
    let title: String
    let content: String
    let url: String
    let publishDate: Date
    var feedTitle: String
    var feedId: UUID?
    let author: String?
    var isRead: Bool
    var summary: String?
    
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
