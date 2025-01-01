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
                VStack(spacing: 20) {
                    Text("还没有添加任何订阅源")
                        .font(.headline)
                    Button("添加订阅源") {
                        showAddFeedSheet = true
                    }
                }
                .frame(maxHeight: .infinity)
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
        .navigationTitle("订阅")
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
            await articlesViewModel.refreshAllFeeds()
        }
    }
}

#Preview {
    NavigationView {
        ArticlesListView()
    }
} 

