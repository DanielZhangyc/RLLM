import SwiftUI

struct QuoteRowView: View {
    let quote: Quote
    @Environment(\.colorScheme) private var colorScheme
    
    private var previewContent: String {
        quote.content.removingHTMLTags()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 内容区域
            VStack(alignment: .leading, spacing: 8) {
                if quote.isFullArticle {
                    Text("全文收藏")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 10)
                        .background(
                            Capsule()
                                .fill(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                                .overlay(
                                    Capsule()
                                        .stroke(
                                            Color(.separator).opacity(colorScheme == .dark ? 0.3 : 0),
                                            lineWidth: colorScheme == .dark ? 0.5 : 0
                                        )
                                )
                        )
                }
                
                Text(previewContent)
                    .font(.body)
                    .lineLimit(4)
                    .multilineTextAlignment(.leading)
            }
            
            // 底部信息区域
            HStack(spacing: 8) {
                // 文章标题
                HStack(spacing: 4) {
                    Image(systemName: "link")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(quote.articleTitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // 保存时间
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(quote.savedDate.formatted(.relative(presentation: .named)))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
                .shadow(
                    color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.05),
                    radius: colorScheme == .dark ? 3 : 2,
                    x: 0,
                    y: colorScheme == .dark ? 2 : 1
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            Color(.separator).opacity(colorScheme == .dark ? 0.3 : 0),
                            lineWidth: colorScheme == .dark ? 1 : 0
                        )
                )
        )
    }
}