import SwiftUI

struct FeedArticlesView: View {
    let feed: Feed
    @EnvironmentObject var articlesViewModel: ArticlesViewModel
    
    var feedArticles: [Article] {
        articlesViewModel.articles.filter { $0.feedTitle == feed.title }
    }
    
    var body: some View {
        List(feedArticles) { article in
            NavigationLink {
                ArticleDetailView(article: article)
            } label: {
                ArticleRowView(article: article)
            }
        }
        .navigationTitle(feed.title)
    }
} 