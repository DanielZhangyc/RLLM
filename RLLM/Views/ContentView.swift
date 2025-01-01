import SwiftUI

struct ContentView: View {
    @StateObject var articlesViewModel = ArticlesViewModel()
    @StateObject var llmViewModel = LLMSettingsViewModel()
    @StateObject var aiInsightsViewModel = AIInsightsViewModel()
    @StateObject var quotesViewModel = QuotesViewModel.shared
    
    var body: some View {
        TabView {
            NavigationStack {
                ArticlesListView()
                    .environmentObject(quotesViewModel)
            }
            .tabItem {
                Label("文章", systemImage: "doc.text.fill")
            }
            
            NavigationStack {
                QuotesListView()
                    .environmentObject(quotesViewModel)
            }
            .tabItem {
                Label("收藏", systemImage: "bookmark.fill")
            }
            
            NavigationStack {
                AIInsightsView()
            }
            .tabItem {
                Label("AI总结", systemImage: "brain.fill")
            }
            
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("设置", systemImage: "gearshape.fill")
            }
        }
        .environmentObject(articlesViewModel)
        .environmentObject(llmViewModel)
        .environmentObject(aiInsightsViewModel)
        .environmentObject(quotesViewModel)
    }
}

#Preview {
    ContentView()
} 