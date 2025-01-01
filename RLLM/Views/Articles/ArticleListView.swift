import SwiftUI

/// 显示指定Feed的文章列表视图
struct ArticleListView: View {
    // MARK: - Properties
    
    /// 当前显示的Feed
    let feed: Feed
    
    /// 文章视图模型
    @EnvironmentObject private var articlesViewModel: ArticlesViewModel
    
    /// 引用视图模型
    @EnvironmentObject private var quotesViewModel: QuotesViewModel
    
    /// 控制编辑sheet的显示状态
    @State private var showingEditSheet = false
    
    // MARK: - Body
    
    var body: some View {
        List {
            ForEach(articlesViewModel.getArticles(for: feed)) { article in
                NavigationLink(destination: LazyView(
                    ArticleDetailView(article: article)
                        .environmentObject(quotesViewModel)
                )) {
                    ArticleRowView(article: article)
                }
            }
        }
        .navigationTitle(feed.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingEditSheet = true }) {
                    Image(systemName: "gear")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            NavigationStack {
                FeedEditView(feed: feed)
            }
        }
        .refreshable {
            await articlesViewModel.refreshFeed(feed)
        }
    }
}

// MARK: - Helper Views

/// 用于延迟加载视图内容的包装器
private struct LazyView<Content: View>: View {
    // MARK: - Properties
    
    /// 构建视图的闭包
    private let build: () -> Content
    
    // MARK: - Initialization
    
    /// 创建一个延迟加载视图
    /// - Parameter build: 构建视图内容的闭包
    init(_ build: @autoclosure @escaping () -> Content) {
        self.build = build
    }
    
    // MARK: - Body
    
    var body: Content {
        build()
    }
} 