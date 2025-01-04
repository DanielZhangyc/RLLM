import SwiftUI
import Alamofire

@main
struct RLLMApp: App {
    @StateObject private var articlesViewModel = ArticlesViewModel()
    
    init() {
        // 在应用启动时主动请求网络权限
        requestNetworkPermission()
    }
    
    var body: some Scene { 
        WindowGroup {
            ContentView()
                .environmentObject(articlesViewModel)
        }
    }
    
    /// 请求网络权限
    private func requestNetworkPermission() {
        // 发起一个简单的网络请求来触发系统网络权限弹窗
        AF.request("https://www.apple.com").response { _ in
            // 不需要处理响应
        }
    }
} 
