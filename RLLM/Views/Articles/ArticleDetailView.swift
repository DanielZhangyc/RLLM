import SwiftUI
import SafariServices

struct ArticleDetailView: View {
    let article: Article
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.openURL) var openURL
    @AppStorage("fontSize") private var fontSize: Double = 17
    @StateObject private var contentViewModel = ArticleContentViewModel()
    @State private var showSummary = true
    @State private var summary: String? = nil
    @State private var isLoadingSummary = false
    @State private var contentHeight: CGFloat = .zero
    @EnvironmentObject private var llmViewModel: LLMSettingsViewModel
    @State private var error: Error?
    @EnvironmentObject private var quotesViewModel: QuotesViewModel
    @State private var showInsightView = false
    @StateObject private var historyManager = ReadingHistoryManager.shared
    @State private var readingStartTime: Date?
    @State private var scrollOffset: CGFloat = 0
    @Environment(\.scenePhase) private var scenePhase
    @State private var accumulatedTime: TimeInterval = 0
    @State private var lastActiveTime: Date?
    
    init(article: Article) {
        self.article = article
        // 检查缓存并设置初始值
        if let cached = SummaryCache.shared.get(for: article.id.uuidString) {
            _summary = State(initialValue: cached)
        }
    }
    
    private var isArticleSaved: Bool {
        quotesViewModel.quotes.contains { quote in
            quote.articleURL == article.url && quote.isFullArticle
        }
    }
    
    private var completionPercentage: Double {
        guard contentHeight > 0 else { return 0 }
        let visibleHeight = UIScreen.main.bounds.height
        let progress = min(max(0, (scrollOffset + visibleHeight) / contentHeight), 1)
        return progress
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // 标题部分
                Text(article.title)
                    .font(.system(.title, design: .serif))
                    .fontWeight(.bold)
                    .padding(.bottom, 8)
                
                // 元信息部分
                HStack {
                    Text(article.feedTitle)
                    Spacer()
                    Text(article.publishDate.formatted())
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                
                if let author = article.author {
                    Text("作者：\(author)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                    .padding(.vertical, 4)
                
                // AI 概括模块
                VStack(alignment: .leading, spacing: 8) {
                    if showSummary {
                        if isLoadingSummary {
                            HStack {
                                Label("正在生成概括...", systemImage: "sparkles")
                                    .foregroundColor(.secondary)
                                Spacer()
                                ProgressView()
                            }
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        } else if let summary = summary {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Label("AI概括", systemImage: "sparkles")
                                        .font(.headline)
                                    Spacer()
                                    Image(systemName: "chevron.up")
                                        .foregroundColor(.secondary)
                                }
                                
                                Text(summary)
                                    .font(.subheadline)
                                
                                if error != nil {
                                    Button("重新生成") {
                                        generateSummary(forceRefresh: true)
                                    }
                                    .font(.footnote)
                                    .foregroundColor(.accentColor)
                                }
                            }
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .onTapGesture {
                                withAnimation { showSummary.toggle() }
                            }
                        } else {
                            HStack {
                                Label("AI概括", systemImage: "sparkles")
                                Spacer()
                                Text("生成")
                                    .foregroundColor(.accentColor)
                            }
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .onTapGesture {
                                generateSummary()
                            }
                        }
                    } else {
                        HStack {
                            Label("AI概括", systemImage: "sparkles")
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.secondary)
                        }
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .onTapGesture {
                            withAnimation { showSummary.toggle() }
                        }
                    }
                }
                .padding(.vertical, 8)
                
                // AI 洞察按钮
                HStack {
                    Label("AI深度洞察", systemImage: "brain.fill")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.vertical, 4)
                .onTapGesture {
                    showInsightView = true
                }
                
                // 文章内容
                RichTextView(
                    html: article.content,
                    baseURL: URL(string: article.url),
                    contentHeight: $contentHeight,
                    fontSize: fontSize
                )
                .frame(height: contentHeight)
                
                // 底部操作栏
                HStack {
                    Button(action: { contentViewModel.showWebView = true }) {
                        Label("浏览器打开", systemImage: "safari")
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        if isArticleSaved {
                            quotesViewModel.removeQuote(for: article.url, isFullArticle: true)
                        } else {
                            quotesViewModel.addQuote(article.content, from: article, isFullArticle: true)
                        }
                    }) {
                        Label(isArticleSaved ? "取消收藏" : "收藏全文", 
                              systemImage: isArticleSaved ? "bookmark.fill" : "bookmark")
                    }
                }
                .buttonStyle(.bordered)
                .padding(.top, 16)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(GeometryReader { proxy in
                Color.clear.preference(
                    key: ScrollOffsetPreferenceKey.self,
                    value: proxy.frame(in: .named("scroll")).minY
                )
            })
        }
        .coordinateSpace(name: "scroll")
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
            scrollOffset = value
        }
        .onAppear {
            readingStartTime = Date()
            lastActiveTime = Date()
        }
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .active:
                // 恢复计时
                lastActiveTime = Date()
            case .background, .inactive:
                // 暂停计时，累加已读时间
                if let lastActive = lastActiveTime {
                    accumulatedTime += Date().timeIntervalSince(lastActive)
                }
            @unknown default:
                break
            }
        }
        .onDisappear {
            // 计算总阅读时间
            if let startTime = readingStartTime,
               let lastActive = lastActiveTime {
                let finalSessionTime = Date().timeIntervalSince(lastActive)
                let totalDuration = accumulatedTime + finalSessionTime
                
                if totalDuration >= ReadingHistoryManager.minimumReadingDuration {
                    let record = ReadingRecord(
                        articleId: article.id.uuidString,
                        articleTitle: article.title,
                        articleURL: article.url,
                        startTime: startTime,
                        duration: totalDuration
                    )
                    historyManager.addRecord(record)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $contentViewModel.showWebView) {
            if let url = URL(string: article.url) {
                SafariView(url: url)
            }
        }
        .sheet(isPresented: $showInsightView) {
            NavigationStack {
                ArticleInsightView(content: article.content, articleId: article.id.uuidString)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    let activityVC = UIActivityViewController(
                        activityItems: [URL(string: article.url)!],
                        applicationActivities: nil
                    )
                    
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first,
                       let viewController = window.rootViewController {
                        viewController.present(activityVC, animated: true)
                    }
                }) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("SaveQuote"))) { notification in
            if let content = notification.userInfo?["content"] as? String {
                quotesViewModel.addQuote(content, from: article)
            }
        }
    }
    
    private func generateSummary(forceRefresh: Bool = false) {
        guard !llmViewModel.config.apiKey.isEmpty else {
            summary = "请先在设置中配置 API Key"
            return
        }
        
        // 检查缓存
        if !forceRefresh, let cached = SummaryCache.shared.get(for: article.id.uuidString) {
            summary = cached
            return
        }
        
        isLoadingSummary = true
        error = nil
        
        Task {
            do {
                let result = try await LLMService.shared.generateSummary(
                    for: article,
                    config: llmViewModel.config
                )
                await MainActor.run {
                    summary = result
                    isLoadingSummary = false
                    // 保存到缓存
                    SummaryCache.shared.set(result, for: article.id.uuidString)
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    summary = "生成概括失败：\(error.localizedDescription)"
                    isLoadingSummary = false
                }
            }
        }
    }
}

// 将内容处理逻辑移到 ViewModel 中
class ArticleContentViewModel: ObservableObject {
    @Published var paragraphs: [String] = []
    @Published var showWebView = false
    
    func processContent(_ content: String) {
        // 在后台线程处理内容
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let processed = self?.removingHTMLEntities(from: content) ?? []
            
            DispatchQueue.main.async {
                self?.paragraphs = processed
            }
        }
    }
    
    private func removingHTMLEntities(from content: String) -> [String] {
        guard let data = content.data(using: .utf8) else { return [content] }
        
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        
        if let attributedString = try? NSAttributedString(data: data, options: options, documentAttributes: nil) {
            return attributedString.string
                .components(separatedBy: .newlines)
                .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        }
        
        return [content]
    }
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
} 