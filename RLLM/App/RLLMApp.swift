import SwiftUI
import Alamofire
import os

@main
struct RLLMApp: App {
    @StateObject private var articlesViewModel = ArticlesViewModel()
    @StateObject private var llmSettingsViewModel = LLMSettingsViewModel()
    private let logger = Logger(subsystem: "xy0v0.RLLM", category: "URLScheme")
    @State private var showError = false
    @State private var errorMessage = ""
    
    init() {
        // 检查是否有旧数据需要迁移
        let storageService = StorageService.shared
        let oldFeeds = storageService.loadFeeds()
        
        if !oldFeeds.isEmpty {
            // 只有在存在旧数据时才执行迁移
            DataMigrationService.shared.resetMigrationStatus()
            DataMigrationService.shared.performMigration()
        }
        
        // 检查并执行数据清理
        CleanupService.shared.performCleanupIfNeeded()
        // 在应用启动时主动请求网络权限
        requestNetworkPermission()
    }
    
    var body: some Scene { 
        WindowGroup {
            ContentView()
                .environmentObject(articlesViewModel)
                .environmentObject(llmSettingsViewModel)
                .onOpenURL { url in
                    handleIncomingURL(url)
                }
                .alert("添加订阅源失败", isPresented: $showError) {
                    Button("确定", role: .cancel) {}
                } message: {
                    Text(errorMessage)
                }
        }
    }
    
    /// 处理传入的URL
    private func handleIncomingURL(_ url: URL) {
        logger.info("收到URL Scheme调用: \(url.absoluteString)")
        
        guard url.scheme == "rllm" else {
            logger.error("未知的URL scheme: \(url.scheme ?? "nil")")
            showError(message: "无效的URL格式")
            return
        }
        
        // 解析URL中的参数
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let queryItems = components.queryItems else {
            logger.error("无法解析URL参数")
            showError(message: "无法解析URL参数")
            return
        }
        
        // 提取feed_url参数（必需）和feed_title参数（可选）
        guard let feedURL = queryItems.first(where: { $0.name == "feed_url" })?.value else {
            logger.error("缺少feed_url参数")
            showError(message: "缺少RSS源地址")
            return
        }
        
        let providedTitle = queryItems.first(where: { $0.name == "feed_title" })?.value
        logger.info("解析到RSS源: \(providedTitle ?? "未提供标题") - \(feedURL)")
        
        // 检查URL格式
        guard let _ = URL(string: feedURL) else {
            logger.error("无效的RSS源URL: \(feedURL)")
            showError(message: "无效的RSS源地址")
            return
        }
        
        // 检查是否已经订阅
        if articlesViewModel.feeds.contains(where: { $0.url == feedURL }) {
            logger.info("RSS源已存在: \(feedURL)")
            showError(message: "该RSS源已经添加过了")
            return
        }
        
        // 添加新的Feed
        Task {
            do {
                // 先验证Feed
                logger.info("正在验证RSS源: \(feedURL)")
                let validatedFeed = try await articlesViewModel.validateFeed(feedURL)
                
                // 使用验证后的Feed信息创建新Feed，优先使用提供的标题
                var feed = Feed(
                    title: providedTitle ?? validatedFeed.title,  // 优先使用提供的标题，否则使用验证获取的标题
                    url: feedURL,
                    description: validatedFeed.description,
                    iconName: validatedFeed.iconName
                )
                
                // 如果标题重复，生成新标题
                if articlesViewModel.feeds.contains(where: { $0.title == feed.title }) {
                    var counter = 1
                    var newTitle = feed.title
                    while articlesViewModel.feeds.contains(where: { $0.title == newTitle }) {
                        newTitle = "\(feed.title) (\(counter))"
                        counter += 1
                    }
                    feed.title = newTitle
                    logger.info("使用新标题: \(newTitle)")
                }
                
                // 添加验证通过的Feed
                try await articlesViewModel.addFeed(feed)
                logger.info("成功添加RSS源: \(feed.title)")
                HapticManager.shared.success()
            } catch {
                logger.error("添加RSS源失败: \(error.localizedDescription)")
                showError(message: "添加RSS源失败：\(error.localizedDescription)")
            }
        }
    }
    
    /// 显示错误信息
    private func showError(message: String) {
        errorMessage = message
        showError = true
        HapticManager.shared.error()
    }
    
    /// 请求网络权限
    private func requestNetworkPermission() {
        // 发起一个简单的网络请求来触发系统网络权限弹窗
        AF.request("https://www.apple.com").response { _ in
            // 不需要处理响应
        }
    }
}
