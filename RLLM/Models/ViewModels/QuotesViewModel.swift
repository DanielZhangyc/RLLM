import Foundation
import SwiftUI

class QuotesViewModel: ObservableObject {
    static let shared = QuotesViewModel()
    
    @Published var quotes: [Quote] = []
    private let defaults = UserDefaults.standard
    private let quotesKey = "saved_quotes"
    
    private init() {
        loadQuotes()
    }
    
    private func loadQuotes() {
        do {
            if let data = defaults.data(forKey: quotesKey) {
                let decoded = try JSONDecoder().decode([Quote].self, from: data)
                quotes = decoded.sorted { $0.savedDate > $1.savedDate }
                print("Loaded \(quotes.count) quotes from storage")
            }
        } catch {
            print("Failed to load quotes: \(error)")
            ToastManager.shared.showError(
                "加载收藏失败",
                message: "无法加载已保存的收藏内容，请尝试重启应用"
            )
        }
    }
    
    private func saveQuotes() {
        do {
            let encoded = try JSONEncoder().encode(quotes)
            defaults.set(encoded, forKey: quotesKey)
            print("Saved \(quotes.count) quotes to storage")
        } catch {
            print("Failed to save quotes: \(error)")
            ToastManager.shared.showError(
                "保存失败",
                message: "无法保存更改，请确保设备有足够存储空间"
            )
        }
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
            quotes.insert(quote, at: 0)
            saveQuotes()
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
        
        quotes.remove(atOffsets: offsets)
        saveQuotes()
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
            quotes.remove(at: index)
            saveQuotes()
            HapticManager.shared.lightImpact()
            // 显示取消收藏提示
            ToastManager.shared.showWarning(
                isFullArticle ? "已取消收藏" : "已移除收藏",
                message: isFullArticle ? "已将文章从收藏中移除" : "已将文本从收藏中移除"
            )
            print("Removed quote for article: \(articleURL)")
        }
    }
}