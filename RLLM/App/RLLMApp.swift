import SwiftUI

@main
struct RLLMApp: App {
    @StateObject private var articlesViewModel = ArticlesViewModel()
    
    var body: some Scene { 
        WindowGroup {
            ContentView()
                .environmentObject(articlesViewModel)
        }
    }
} 
