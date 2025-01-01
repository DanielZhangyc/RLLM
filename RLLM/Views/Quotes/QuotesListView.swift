import SwiftUI

struct QuotesListView: View {
    @EnvironmentObject private var viewModel: QuotesViewModel
    
    var body: some View {
        List {
            if viewModel.quotes.isEmpty {
                ContentUnavailableView("没有收藏的语段", 
                    systemImage: "quote.bubble",
                    description: Text("在阅读文章时长按选择文字即可收藏")
                )
            } else {
                ForEach(viewModel.quotes) { quote in
                    NavigationLink(destination: QuoteDetailView(quote: quote)) {
                        QuoteRowView(quote: quote)
                    }
                }
                .onDelete(perform: viewModel.deleteQuotes)
            }
        }
        .navigationTitle("收藏语段")
    }
} 