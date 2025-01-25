import SwiftUI

struct ContentView: View {
    @EnvironmentObject var articlesViewModel: ArticlesViewModel
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
                Label(NSLocalizedString("tab.articles", comment: "Articles tab"), systemImage: "doc.text.fill")
            }
            
            NavigationStack {
                QuotesListView()
                    .environmentObject(quotesViewModel)
            }
            .tabItem {
                Label(NSLocalizedString("tab.quotes", comment: "Quotes tab"), systemImage: "bookmark.fill")
            }
            
            NavigationStack {
                AIInsightsView()
            }
            .tabItem {
                Label(NSLocalizedString("tab.ai_summary", comment: "AI Summary tab"), systemImage: "brain.fill")
            }
            
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label(NSLocalizedString("tab.settings", comment: "Settings tab"), systemImage: "gearshape.fill")
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