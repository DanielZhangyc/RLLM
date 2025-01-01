import SwiftUI

struct QuoteRowView: View {
    let quote: Quote
    
    private var previewContent: String {
        quote.content.removingHTMLTags()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if quote.isFullArticle {
                Label("全文收藏", systemImage: "doc.text.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(previewContent)
                .font(.body)
                .lineLimit(4)
                .multilineTextAlignment(.leading)
            
            HStack {
                Text(quote.articleTitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(quote.savedDate.formatted(.relative(presentation: .named)))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}