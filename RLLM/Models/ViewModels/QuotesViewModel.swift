import Foundation

class QuotesViewModel: ObservableObject {
    static let shared = QuotesViewModel()
    
    @Published var quotes: [Quote] = []
    private let defaults = UserDefaults.standard
    private let quotesKey = "saved_quotes"
    
    private init() {
        loadQuotes()
    }
    
    private func loadQuotes() {
        if let data = defaults.data(forKey: quotesKey),
           let decoded = try? JSONDecoder().decode([Quote].self, from: data) {
            quotes = decoded.sorted { $0.savedDate > $1.savedDate }
            print("Loaded \(quotes.count) quotes from storage")
        }
    }
    
    private func saveQuotes() {
        if let encoded = try? JSONEncoder().encode(quotes) {
            defaults.set(encoded, forKey: quotesKey)
            print("Saved \(quotes.count) quotes to storage")
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
            HapticManager.shared.success()
            print("Added new quote: \(isFullArticle ? "Full article" : "Text selection") from \(article.title)")
        } else {
            print("Quote already exists")
        }
    }
    
    func deleteQuotes(at offsets: IndexSet) {
        quotes.remove(atOffsets: offsets)
        saveQuotes()
        HapticManager.shared.lightImpact()
        print("Deleted quotes at offsets: \(offsets)")
    }
    
    func removeQuote(for articleURL: String, isFullArticle: Bool = false) {
        if let index = quotes.firstIndex(where: { 
            $0.articleURL == articleURL && $0.isFullArticle == isFullArticle 
        }) {
            quotes.remove(at: index)
            saveQuotes()
            HapticManager.shared.lightImpact()
            print("Removed quote for article: \(articleURL)")
        }
    }
}