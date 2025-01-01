import SwiftUI

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var feedCount: Int = 0
    @Published var autoGenerateSummary = false
    
    private let articlesViewModel: ArticlesViewModel
    
    init(articlesViewModel: ArticlesViewModel) {
        self.articlesViewModel = articlesViewModel
    }
    
    func updateFeedCount() {
        feedCount = articlesViewModel.feeds.count
    }
} 