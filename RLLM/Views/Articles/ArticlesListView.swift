import SwiftUI

struct ArticlesListView: View {
    @EnvironmentObject var articlesViewModel: ArticlesViewModel
    @State private var showAddFeedSheet = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    private var columns: [GridItem] {
        if horizontalSizeClass == .regular {
            return [GridItem(.adaptive(minimum: 300, maximum: 400))]
        } else {
            return [
                GridItem(.flexible()),
                GridItem(.flexible())
            ]
        }
    }
    
    var body: some View {
        ScrollView {
            if articlesViewModel.feeds.isEmpty {
                ContentUnavailableView {
                    Label("开始你的阅读之旅", systemImage: "doc.text.magnifyingglass")
                        .font(.title2)
                } description: {
                    Text("添加你感兴趣的RSS源，开始探索精彩内容")
                } actions: {
                    Button(action: { showAddFeedSheet = true }) {
                        Text("添加订阅源")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.accentColor)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(.top, 100)
            } else {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(articlesViewModel.feeds) { feed in
                        NavigationLink(destination: ArticleListView(feed: feed)) {
                            FeedCardView(
                                feed: feed,
                                articleCount: articlesViewModel.getArticleCount(for: feed),
                                lastUpdateTime: articlesViewModel.getLastUpdateTime(for: feed),
                                loadingState: articlesViewModel.feedLoadingStates[feed.id] ?? .idle
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
            }
        }
        .navigationTitle("文章")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAddFeedSheet = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddFeedSheet) {
            AddFeedView(viewModel: articlesViewModel)
        }
        .refreshable {
            print("\n=== ArticlesListView: Pull to refresh triggered ===")
            await articlesViewModel.refreshAllFeeds()
            print("=== ArticlesListView: Pull to refresh completed ===\n")
        }
    }
}

#Preview {
    NavigationView {
        ArticlesListView()
    }
} 

