import SwiftUI

@main
struct LLM_RSSApp: App {
    @StateObject private var articlesViewModel = ArticlesViewModel()
    
    var body: some Scene { 
        WindowGroup {
            ContentView()
                .environmentObject(articlesViewModel)
        }
    }
} 
