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
    @AppStorage("lastArticleId") private var lastArticleId: String = ""
    @AppStorage("lastAccumulatedTime") private var lastAccumulatedTime: Double = 0
    @Environment(\.dismiss) private var dismiss
    @AppStorage("llmConfig") private var storedConfig: Data?
    
    init(article: Article) {
        self.article = article
        // 检查缓存并设置初始值
        if let cached = SummaryCache.shared.get(for: article.id.uuidString) {
            _summary = State(initialValue: cached)
        }
        
        // 如果是同一篇文章，恢复累计时间
        if lastArticleId == article.id.uuidString {
            _accumulatedTime = State(initialValue: lastAccumulatedTime)
        } else {
            // 新文章，重置累计时间
            lastArticleId = article.id.uuidString
            lastAccumulatedTime = 0
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
                    Text(String(format: NSLocalizedString("article.author", comment: "Author with name"), author))
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
                                Label(NSLocalizedString("article.generating_summary", comment: "Generating summary"), systemImage: "sparkles")
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
                                    Label(NSLocalizedString("article.ai_summary", comment: "AI Summary"), systemImage: "sparkles")
                                        .font(.headline)
                                    Spacer()
                                    Image(systemName: "chevron.up")
                                        .foregroundColor(.secondary)
                                }
                                
                                Text(summary)
                                    .font(.subheadline)
                                
                                if error != nil {
                                    Button(NSLocalizedString("article.regenerate", comment: "Regenerate summary")) {
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
                                HapticManager.shared.selection()
                            }
                        } else {
                            HStack {
                                Label(NSLocalizedString("article.ai_summary", comment: "AI Summary"), systemImage: "sparkles")
                                Spacer()
                                Text(NSLocalizedString("article.generate", comment: "Generate summary"))
                                    .foregroundColor(.accentColor)
                            }
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .onTapGesture {
                                generateSummary()
                                HapticManager.shared.selection()
                            }
                        }
                    } else {
                        HStack {
                            Label(NSLocalizedString("article.ai_summary", comment: "AI Summary"), systemImage: "sparkles")
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.secondary)
                        }
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .onTapGesture {
                            withAnimation { showSummary.toggle() }
                            HapticManager.shared.selection()
                        }
                    }
                }
                .padding(.vertical, 8)
                
                // AI 洞察按钮
                HStack {
                    Label(NSLocalizedString("article.ai_insight", comment: "AI Deep Insight"), systemImage: "brain.fill")
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
                        Label(NSLocalizedString("article.open_in_browser", comment: "Open in browser"), systemImage: "safari")
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        if isArticleSaved {
                            quotesViewModel.removeQuote(for: article.url, isFullArticle: true)
                        } else {
                            quotesViewModel.addQuote(article.content, from: article, isFullArticle: true)
                        }
                    }) {
                        Label(isArticleSaved ? NSLocalizedString("article.unsave", comment: "Unsave article") : NSLocalizedString("article.save_full", comment: "Save full article"), 
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
            // 只在readingStartTime为nil时初始化
            if readingStartTime == nil {
                readingStartTime = Date()
                print("📖 首次开始阅读，时间：\(Date())")
            } else {
                print("📖 继续阅读，当前累计时间：\(accumulatedTime)秒")
            }
            lastActiveTime = Date()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            print("🔄 场景状态变化：\(newPhase)")
            switch newPhase {
            case .active:
                // 只有从非活跃状态恢复时才重置计时
                if oldPhase != .active {
                    lastActiveTime = Date()
                    print("▶️ 恢复计时，累计：\(Int(accumulatedTime))秒")
                }
            case .background:
                if let lastActive = lastActiveTime {
                    let sessionTime = Date().timeIntervalSince(lastActive)
                    // 只有当会话时间大于1秒时才累加
                    if sessionTime > 1 {
                        accumulatedTime += sessionTime
                        lastAccumulatedTime = accumulatedTime
                        print("⏸ 进入后台，本次：\(Int(sessionTime))秒，累计：\(Int(accumulatedTime))秒")
                    }
                    lastActiveTime = Date()
                }
            case .inactive:
                // 进入非活跃状态时不重置计时器
                break
            @unknown default:
                break
            }
        }
        .onDisappear {
            if let startTime = readingStartTime,
               let lastActive = lastActiveTime {
                let finalSessionTime = Date().timeIntervalSince(lastActive)
                // 只有当最后一段时间大于1秒时才计入总时长
                let totalDuration = finalSessionTime > 1 
                    ? accumulatedTime + finalSessionTime
                    : accumulatedTime
                
                if totalDuration >= ReadingHistoryManager.minimumReadingDuration {
                    let record = ReadingRecord(
                        articleId: article.id.uuidString,
                        articleTitle: article.title,
                        articleURL: article.url,
                        startTime: startTime,
                        duration: totalDuration
                    )
                    historyManager.addRecord(record)
                    print("✅ 保存阅读记录：\(Int(totalDuration))秒")
                    
                    // 保存记录后重置
                    lastArticleId = ""
                    lastAccumulatedTime = 0
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
        guard let configData = storedConfig,
              let config = try? JSONDecoder().decode(LLMConfig.self, from: configData) else {
            summary = NSLocalizedString("article.llm_not_configured", comment: "LLM not configured")
            return
        }
        
        guard !config.apiKey.isEmpty else {
            summary = NSLocalizedString("article.api_key_missing", comment: "API key missing")
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
                    config: config
                )
                await MainActor.run {
                    summary = result
                    isLoadingSummary = false
                    // 保存到缓存
                    SummaryCache.shared.set(result, for: article.id.uuidString)
                    HapticManager.shared.success()
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    summary = String(format: NSLocalizedString("article.summary_error", comment: "Summary generation error"), error.localizedDescription)
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