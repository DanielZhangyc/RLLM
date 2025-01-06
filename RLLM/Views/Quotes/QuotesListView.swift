import SwiftUI

struct QuotesListView: View {
    @EnvironmentObject private var viewModel: QuotesViewModel
    
    var body: some View {
        List {
            Group {
                if viewModel.quotes.isEmpty {
                    EmptyQuotesView()
                } else {
                    QuotesList(quotes: viewModel.quotes)
                }
            }
        }
        .navigationTitle("收藏")
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
    }
}

private struct EmptyQuotesView: View {
    var body: some View {
        ContentUnavailableView {
            Label("收藏精彩语段", systemImage: "quote.bubble")
                .font(.title2)
        } description: {
            VStack(spacing: 12) {
                Text("在阅读文章时长按选择文字即可收藏")
                Text("收藏的语段将在这里显示")
                    .foregroundColor(.secondary)
            }
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets())
        .listRowSeparator(.hidden)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
}

private struct QuotesList: View {
    let quotes: [Quote]
    @EnvironmentObject private var viewModel: QuotesViewModel
    
    var body: some View {
        ForEach(quotes) { quote in
            QuoteRowView(quote: quote)
                .contentShape(Rectangle())
                .background(
                    NavigationLink(destination: QuoteDetailView(quote: quote)) {
                        EmptyView()
                    }
                    .opacity(0)
                )
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        if let index = viewModel.quotes.firstIndex(where: { $0.id == quote.id }) {
                            viewModel.deleteQuotes(at: IndexSet([index]))
                        }
                    } label: {
                        VStack {
                            Image(systemName: "trash")
                                .font(.title2)
                            Text("删除")
                                .font(.caption)
                        }
                        .frame(width: 60)
                        .padding(.vertical, 12)
                    }
                }
        }
    }
} 