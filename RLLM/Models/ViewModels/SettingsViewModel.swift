import SwiftUI

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var feedCount: Int = 0
    @Published var autoGenerateSummary = false
    
    init() {}
    
    func updateFeedCount(feeds: [Feed]) {
        feedCount = feeds.count
    }
} 