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
        .navigationTitle(NSLocalizedString("quotes.title", comment: "Quotes title"))
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
    }
}

private struct EmptyQuotesView: View {
    var body: some View {
        ContentUnavailableView {
            Label(NSLocalizedString("quotes.save_quote", comment: "Save quotes title"), systemImage: "quote.bubble")
                .font(.title2)
        } description: {
            VStack(spacing: 12) {
                Text(NSLocalizedString("quotes.save_instruction", comment: "Save quotes instruction"))
                Text(NSLocalizedString("quotes.saved_display", comment: "Saved quotes display"))
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
                            Text(NSLocalizedString("quotes.delete", comment: "Delete quote"))
                                .font(.caption)
                        }
                        .frame(width: 60)
                        .padding(.vertical, 12)
                    }
                }
        }
    }
} 