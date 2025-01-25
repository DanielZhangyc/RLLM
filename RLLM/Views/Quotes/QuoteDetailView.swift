import SwiftUI

struct QuoteDetailView: View {
    let quote: Quote
    @Environment(\.openURL) private var openURL
    @State private var contentHeight: CGFloat = .zero
    @AppStorage("fontSize") private var fontSize: Double = 17
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if quote.isFullArticle {
                    Label(NSLocalizedString("quote.full_article", comment: "Full article saved"), systemImage: "doc.text.fill")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                RichTextView(
                    html: quote.content,
                    baseURL: URL(string: quote.articleURL),
                    contentHeight: $contentHeight,
                    fontSize: fontSize
                )
                .frame(minHeight: 100)
                .frame(height: contentHeight > 0 ? contentHeight : nil)
                .animation(.easeInOut, value: contentHeight)
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(NSLocalizedString("quote.source_prefix", comment: "Source prefix") + quote.articleTitle)
                        .font(.subheadline)
                    
                    Text(NSLocalizedString("quote.save_time_prefix", comment: "Save time prefix") + quote.savedDate.formatted())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Button(NSLocalizedString("quote.view_original", comment: "View original")) {
                    if let url = URL(string: quote.articleURL) {
                        openURL(url)
                    }
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
        .navigationTitle(NSLocalizedString("quote.detail", comment: "Quote detail"))
    }
} 