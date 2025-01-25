import SwiftUI

/// 文章AI洞察视图
/// 展示单篇文章的AI分析结果
struct ArticleInsightView: View {
    // MARK: - Properties
    
    /// 文章内容
    let content: String
    
    /// 文章ID
    let articleId: String
    
    /// AI洞察视图模型
    @StateObject private var viewModel = AIInsightsViewModel()
    
    // MARK: - Initialization
    
    init(content: String, articleId: String) {
        self.content = content
        self.articleId = articleId
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if viewModel.isAnalyzing {
                    ProgressView(NSLocalizedString("article_insight.analyzing", comment: "Analyzing progress"))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let insight = viewModel.articleInsight {
                    insightContent(insight)
                } else if let error = viewModel.error {
                    ErrorView(
                        error: error,
                        retryAction: {
                            Task {
                                _ = await viewModel.analyzeArticle(content, articleId: articleId, forceRefresh: true)
                            }
                        }
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "wand.and.stars")
                            .font(.largeTitle)
                            .foregroundColor(.accentColor)
                        Text(NSLocalizedString("article_insight.click_to_start", comment: "Click to start analysis"))
                            .foregroundColor(.secondary)
                        Button(NSLocalizedString("article_insight.start", comment: "Start analysis")) {
                            Task {
                                _ = await viewModel.analyzeArticle(content, articleId: articleId)
                                HapticManager.shared.success()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                }
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 300)
        }
        .navigationTitle(NSLocalizedString("article.ai_insight", comment: "AI Deep Insight"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task {
                        _ = await viewModel.analyzeArticle(content, articleId: articleId, forceRefresh: true)
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(viewModel.isAnalyzing)
            }
        }
        .task {
            // 视图出现时检查缓存
            if InsightCache.shared.has(for: articleId) {
                _ = await viewModel.analyzeArticle(content, articleId: articleId)
            }
        }
    }
    
    // MARK: - Private Views
    
    /// 构建洞察内容视图
    /// - Parameter insight: 洞察结果
    /// - Returns: 洞察内容视图
    private func insightContent(_ insight: ArticleInsight) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // 主题标签
            VStack(alignment: .leading, spacing: 12) {
                Label(NSLocalizedString("article_insight.topic_tags", comment: "Topic tags"), systemImage: "tag")
                    .font(.headline)
                    .padding(.bottom, 8)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(insight.topics, id: \.self) { topic in
                            Text(topic)
                                .font(.subheadline)
                                .foregroundColor(.accentColor)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.accentColor.opacity(0.1))
                                .clipShape(Capsule())
                                .onTapGesture {
                                    HapticManager.shared.selection()
                                }
                        }
                    }
                    .padding(.horizontal, 2)
                }
            }
            .padding(.vertical, 4)
            
            Divider()
            
            // 核心摘要
            VStack(alignment: .leading, spacing: 12) {
                Label(NSLocalizedString("article_insight.core_summary", comment: "Core summary"), systemImage: "text.justify")
                    .font(.headline)
                    .padding(.bottom, 4)
                Text(insight.summary)
                    .font(.body)
            }
            
            Divider()
            
            // 关键观点
            VStack(alignment: .leading, spacing: 12) {
                Label(NSLocalizedString("article_insight.key_points", comment: "Key points"), systemImage: "list.bullet")
                    .font(.headline)
                    .padding(.bottom, 4)
                ForEach(insight.keyPoints, id: \.self) { point in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 6))
                            .padding(.top, 7)
                        Text(point)
                    }
                }
            }
            
            Divider()
            
            // 情感倾向
            VStack(alignment: .leading, spacing: 12) {
                Label(NSLocalizedString("article_insight.sentiment", comment: "Sentiment"), systemImage: "heart")
                    .font(.headline)
                    .padding(.bottom, 4)
                Text(insight.sentiment)
                    .font(.body)
            }
            
            // 背景补充（如果有）
            if let backgroundInfo = insight.backgroundInfo {
                Divider()
                VStack(alignment: .leading, spacing: 12) {
                    Label(NSLocalizedString("article_insight.background", comment: "Background"), systemImage: "info.circle")
                        .font(.headline)
                        .padding(.bottom, 4)
                    Text(backgroundInfo)
                        .font(.body)
                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - FlowLayout

/// 流式布局视图
/// 用于展示标签等需要自动换行的内容
private struct FlowLayout: Layout {
    let spacing: CGFloat
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(at: frame.origin, proposal: ProposedViewSize(frame.size))
        }
    }
    
    /// 计算流式布局结果
    private struct FlowResult {
        var size: CGSize = .zero
        var frames: [CGRect] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let viewSize = subview.sizeThatFits(.unspecified)
                
                if currentX + viewSize.width > maxWidth {
                    // 换行
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                frames.append(CGRect(x: currentX, y: currentY, width: viewSize.width, height: viewSize.height))
                currentX += viewSize.width + spacing
                lineHeight = max(lineHeight, viewSize.height)
            }
            
            size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
} 