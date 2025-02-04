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
    
    // MARK: - 数据加载
    
    private func loadQuotes() {
        quotes = coreDataManager.getAllQuotes()
        print("Loaded \(quotes.count) quotes from Core Data")
    }
    
    // MARK: - 多选相关
    
    /// 是否有选中的引用
    var hasSelectedQuotes: Bool {
        quotes.contains { $0.isSelected }
    }
    
    /// 是否所有引用都被选中
    var areAllQuotesSelected: Bool {
        !quotes.isEmpty && quotes.allSatisfy { $0.isSelected }
    }
    
    /// 切换引用的选中状态
    /// - Parameter quote: 要切换状态的引用
    func toggleQuoteSelection(_ quote: Quote) {
        if let index = quotes.firstIndex(where: { $0.id == quote.id }) {
            quotes[index].isSelected.toggle()
        }
    }
    
    /// 切换全选/取消全选
    /// - Parameter isSelected: 是否全选
    func toggleSelectAll(_ isSelected: Bool) {
        quotes.indices.forEach { index in
            quotes[index].isSelected = isSelected
        }
    }
    
    /// 重置所有选择状态
    func resetSelection() {
        quotes.indices.forEach { index in
            quotes[index].isSelected = false
        }
    }
    
    /// 删除选中的引用
    func deleteSelectedQuotes() {
        let selectedQuotes = quotes.enumerated().filter { $0.element.isSelected }
        let indexSet = IndexSet(selectedQuotes.map { $0.offset })
        deleteQuotes(at: indexSet)
    }
    
    // MARK: - 引用操作
    
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
                NSLocalizedString(isFullArticle ? "toast.quotes.article_saved.title" : "toast.quotes.text_saved.title", comment: "Quote saved title"),
                message: NSLocalizedString(isFullArticle ? "toast.quotes.article_saved.message" : "toast.quotes.text_saved.message", comment: "Quote saved message")
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
            NSLocalizedString("toast.quotes.deleted.title", comment: "Quotes deleted title"),
            message: String(format: NSLocalizedString("toast.quotes.deleted.message", comment: "Quotes deleted message"), count)
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
                NSLocalizedString(isFullArticle ? "toast.quotes.article_unsaved.title" : "toast.quotes.text_unsaved.title", comment: "Quote unsaved title"),
                message: NSLocalizedString(isFullArticle ? "toast.quotes.article_unsaved.message" : "toast.quotes.text_unsaved.message", comment: "Quote unsaved message")
            )
            print("Removed quote for article: \(articleURL)")
        }
    }
    
    /// 刷新收藏列表
    func refresh() {
        loadQuotes()
    }
}