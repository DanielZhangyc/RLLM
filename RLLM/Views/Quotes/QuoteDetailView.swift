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
                    Label("全文收藏", systemImage: "doc.text.fill")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                RichTextView(
                    html: quote.content,
                    baseURL: URL(string: quote.articleURL),
                    contentHeight: $contentHeight,
                    fontSize: fontSize
                )
                .frame(height: contentHeight)
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("来源：\(quote.articleTitle)")
                        .font(.subheadline)
                    
                    Text("保存时间：\(quote.savedDate.formatted())")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Button("查看原文") {
                    if let url = URL(string: quote.articleURL) {
                        openURL(url)
                    }
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
        .navigationTitle("收藏详情")
    }
} 