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
        .navigationTitle(NSLocalizedString("feed_management.title", comment: "Feed management title"))
        .navigationBarItems(trailing: Button(action: {
            showingAddFeed = true
        }) {
            Image(systemName: "plus")
        })
        .sheet(isPresented: $showingAddFeed) {
            AddFeedView(viewModel: articlesViewModel)
        }
        .alert(NSLocalizedString("feed_management.error", comment: "Error alert title"), isPresented: $showingError) {
            Button(NSLocalizedString("feed_management.ok", comment: "OK button"), role: .cancel) {}
        } message: {
            Text(error?.localizedDescription ?? NSLocalizedString("feed_management.unknown_error", comment: "Unknown error message"))
        }
    }
}

#Preview {
    NavigationView {
        FeedManagementView()
    }
} 