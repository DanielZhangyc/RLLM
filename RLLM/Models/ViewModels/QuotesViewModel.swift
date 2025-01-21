import Foundation
import SwiftUI
import CoreData

class QuotesViewModel: ObservableObject {
    static let shared = QuotesViewModel()
    
    @Published var quotes: [Quote] = []
    private let coreDataManager = CoreDataManager.shared
    
    private init() {
        loadQuotes()
    }
    
    private func loadQuotes() {
        quotes = coreDataManager.getAllQuotes()
        print("Loaded \(quotes.count) quotes from Core Data")
    }
    
    func addQuote(_ content: String, from article: Article, isFullArticle: Bool = false) {
        let quote = Quote(
            content: content,
            articleTitle: article.title,
            articleURL: article.url,
            savedDate: Date(),
            isFullArticle: isFullArticle
        )
        
        // 检查是否已存在完全相同的引用（包括内容）
        if !quotes.contains(where: { 
            $0.articleURL == article.url && 
            $0.isFullArticle == isFullArticle && 
            $0.content == content
        }) {
            // 保存到Core Data
            _ = coreDataManager.createOrUpdateQuote(quote, articleId: article.id)
            
            // 更新本地数组
            quotes.insert(quote, at: 0)
            
            HapticManager.shared.lightImpact()
            // 显示成功提示
            ToastManager.shared.showSuccess(
                isFullArticle ? "文章已收藏" : "文本已收藏",
                message: isFullArticle ? "已将整篇文章添加到收藏" : "已将选中文本添加到收藏"
            )
            print("Added new quote: \(isFullArticle ? "Full article" : "Text selection") from \(article.title)")
        } else {
            print("Quote already exists")
        }
    }
    
    func deleteQuotes(at offsets: IndexSet) {
        // 获取要删除的数量
        let count = offsets.count
        
        // 从Core Data中删除
        for index in offsets {
            let quote = quotes[index]
            coreDataManager.deleteQuote(id: quote.id)
        }
        
        // 更新本地数组
        quotes.remove(atOffsets: offsets)
        
        HapticManager.shared.lightImpact()
        
        // 显示删除提示
        ToastManager.shared.showWarning(
            "已删除收藏",
            message: "已移除\(count)条收藏内容"
        )
        print("Deleted quotes at offsets: \(offsets)")
    }
    
    func removeQuote(for articleURL: String, isFullArticle: Bool = false) {
        if let index = quotes.firstIndex(where: { 
            $0.articleURL == articleURL && $0.isFullArticle == isFullArticle 
        }) {
            // 从Core Data中删除
            let quote = quotes[index]
            coreDataManager.deleteQuote(id: quote.id)
            
            // 更新本地数组
            quotes.remove(at: index)
            
            HapticManager.shared.lightImpact()
            // 显示取消收藏提示
            ToastManager.shared.showWarning(
                isFullArticle ? "已取消收藏" : "已移除收藏",
                message: isFullArticle ? "已将文章从收藏中移除" : "已将文本从收藏中移除"
            )
            print("Removed quote for article: \(articleURL)")
        }
    }
    
    /// 刷新收藏列表
    func refresh() {
        loadQuotes()
    }
}