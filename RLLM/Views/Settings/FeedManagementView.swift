import SwiftUI

struct FeedManagementView: View {
    @EnvironmentObject var articlesViewModel: ArticlesViewModel
    @State private var showingAddFeed = false
    @State private var error: Error?
    @State private var showingError = false
    
    var body: some View {
        List {
            ForEach(articlesViewModel.feeds) { feed in
                VStack(alignment: .leading) {
                    Text(feed.title)
                        .font(.headline)
                    Text(feed.url)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .onDelete { indexSet in
                for index in indexSet {
                    let feed = articlesViewModel.feeds[index]
                    articlesViewModel.deleteFeed(feed)
                }
            }
        }
        .navigationTitle("订阅源管理")
        .navigationBarItems(trailing: Button(action: {
            showingAddFeed = true
        }) {
            Image(systemName: "plus")
        })
        .sheet(isPresented: $showingAddFeed) {
            AddFeedView(viewModel: articlesViewModel)
        }
        .alert("错误", isPresented: $showingError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(error?.localizedDescription ?? "未知错误")
        }
    }
}

#Preview {
    NavigationView {
        FeedManagementView()
    }
} 