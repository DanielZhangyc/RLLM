@preconcurrency import SwiftUI
@preconcurrency import WebKit

// 添加自定义WKWebView子类
@available(iOS 13.0, *)
class CustomWKWebView: WKWebView {
    var selectedText: String?
    
    override init(frame: CGRect, configuration: WKWebViewConfiguration) {
        super.init(frame: frame, configuration: configuration)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        // 只允许以下操作：
        // 1. 我们的自定义收藏操作
        // 2. 复制
        // 3. 选择
        // 4. 全选
        let allowedActions: [Selector] = [
            #selector(saveQuote(_:)),
            #selector(UIResponderStandardEditActions.copy(_:)),
            #selector(UIResponderStandardEditActions.select(_:)),
            #selector(UIResponderStandardEditActions.selectAll(_:))
        ]
        
        return allowedActions.contains(action)
    }
    
    @objc func saveQuote(_ sender: Any?) {
        evaluateJavaScript("window.getSelection().toString()") { [weak self] result, error in
            if let text = result as? String, !text.isEmpty {
                NotificationCenter.default.post(
                    name: Notification.Name("SaveQuote"),
                    object: nil,
                    userInfo: ["content": text]
                )
            }
        }
    }
}

@available(iOS 13.0, *)
struct RichTextView: UIViewRepresentable {
    let html: String
    let baseURL: URL?
    @Binding var contentHeight: CGFloat
    let fontSize: Double
    @Environment(\.colorScheme) var colorScheme
    
    func makeUIView(context: Context) -> CustomWKWebView {
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences = preferences
        configuration.setValue(true, forKey: "allowUniversalAccessFromFileURLs")
        
        // 添加消息处理器
        configuration.userContentController.add(context.coordinator, name: "heightChanged")
        
        let webView = CustomWKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = false
        webView.backgroundColor = .clear
        webView.isOpaque = false
        
        // 添加图片长按手势识别器
        let imageLongPress = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleLongPress(_:)))
        webView.addGestureRecognizer(imageLongPress)
        
        #if compiler(>=5.7)
        // 添加自定义菜单项，并确保它显示在最前面
        let saveQuoteItem = UIMenuItem(title: "收藏", action: #selector(CustomWKWebView.saveQuote(_:)))
        UIMenuController.shared.menuItems = [saveQuoteItem]
        #endif
        
        return webView
    }
    
    func updateUIView(_ webView: CustomWKWebView, context: Context) {
        let cssStyle = """
            <style>
                :root {
                    color-scheme: light dark;
                    -webkit-user-select: text;
                    user-select: text;
                }
                
                body {
                    font-family: -apple-system, system-ui;
                    font-size: \(fontSize)px;
                    line-height: 1.6;
                    margin: 0;
                    padding: 0;
                    color: var(--text-color);
                    background-color: transparent;
                    -webkit-user-select: text;
                    user-select: text;
                }
                
                img, video {
                    max-width: 100%;
                    height: auto;
                    border-radius: 8px;
                    margin: 16px 0;
                    display: block;
                    background-color: transparent;
                }
                
                img.loading {
                    min-height: 200px;
                    position: relative;
                }
                
                img.loading::after {
                    content: '';
                    position: absolute;
                    top: 50%;
                    left: 50%;
                    width: 24px;
                    height: 24px;
                    margin: -12px 0 0 -12px;
                    border: 2px solid transparent;
                    border-top-color: var(--text-color);
                    border-radius: 50%;
                    animation: spinner 1s linear infinite;
                }
                
                @keyframes spinner {
                    to {transform: rotate(360deg);}
                }
                
                a {
                    color: var(--link-color);
                    text-decoration: none;
                }
                
                a:hover {
                    text-decoration: underline;
                }
                
                pre, code {
                    background-color: var(--code-bg);
                    padding: 8px;
                    border-radius: 4px;
                    overflow-x: auto;
                    font-family: ui-monospace, monospace;
                }
                
                blockquote {
                    border-left: 4px solid var(--quote-border);
                    margin: 16px 0;
                    padding: 8px 0 8px 16px;
                    color: var(--quote-text);
                }
                
                p {
                    margin: 16px 0;
                }
                
                @media (prefers-color-scheme: dark) {
                    :root {
                        --text-color: #FFFFFF;
                        --link-color: #0A84FF;
                        --code-bg: #1C1C1E;
                        --quote-border: #48484A;
                        --quote-text: #EBEBF5;
                    }
                }
                
                @media (prefers-color-scheme: light) {
                    :root {
                        --text-color: #000000;
                        --link-color: #007AFF;
                        --code-bg: #F2F2F7;
                        --quote-border: #C7C7CC;
                        --quote-text: #3A3A3C;
                    }
                }
            </style>
        """
        
        let wrappedHTML = """
            <!DOCTYPE html>
            <html>
            <head>
                <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
                <meta http-equiv="Content-Security-Policy" content="default-src * 'unsafe-inline' 'unsafe-eval' data: blob:;">
                \(cssStyle)
            </head>
            <body>
                \(html)
                <script>
                    document.addEventListener('DOMContentLoaded', function() {
                        // 保持原有的图片处理代码
                        var images = document.getElementsByTagName('img');
                        for(var i = 0; i < images.length; i++) {
                            var img = images[i];
                            img.classList.add('loading');
                            img.onerror = function() {
                                this.style.display = 'none';
                                this.classList.remove('loading');
                            };
                            img.onload = function() {
                                this.classList.remove('loading');
                                window.webkit.messageHandlers.heightChanged.postMessage(document.documentElement.scrollHeight);
                            };
                        }
                        window.webkit.messageHandlers.heightChanged.postMessage(document.documentElement.scrollHeight);
                    });
                </script>
            </body>
            </html>
        """
        
        webView.loadHTMLString(wrappedHTML, baseURL: baseURL)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler, @unchecked Sendable {
        var parent: RichTextView
        
        init(_ parent: RichTextView) {
            self.parent = parent
            super.init()
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "heightChanged", let height = message.body as? CGFloat {
                parent.contentHeight = height
            }
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if navigationAction.navigationType == .linkActivated {
                if let url = navigationAction.request.url {
                    UIApplication.shared.open(url)
                }
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.evaluateJavaScript("document.documentElement.scrollHeight") { height, _ in
                if let height = height as? CGFloat {
                    self.parent.contentHeight = height
                }
            }
        }
        
        @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            guard gesture.state == .began else { return }
            
            let point = gesture.location(in: gesture.view)
            let javascript = """
                (function() {
                    var element = document.elementFromPoint(\(point.x), \(point.y));
                    if (element.tagName.toLowerCase() === 'img') {
                        return element.src;
                    }
                    return null;
                })()
            """
            
            if let webView = gesture.view as? WKWebView {
                webView.evaluateJavaScript(javascript) { result, error in
                    if let imageURL = result as? String,
                       let url = URL(string: imageURL) {
                        self.showImageActionSheet(for: url)
                    }
                }
            }
        }
        
        private func showImageActionSheet(for url: URL) {
            let activityVC = UIActivityViewController(
                activityItems: [url],
                applicationActivities: nil
            )
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let viewController = window.rootViewController {
                viewController.present(activityVC, animated: true)
            }
        }
    }
}

// 添加JavaScript处理
extension CustomWKWebView {
    override func didMoveToWindow() {
        super.didMoveToWindow()
        
        // 先移除旧的处理程序和脚本
        configuration.userContentController.removeScriptMessageHandler(forName: "textSelected")
        configuration.userContentController.removeAllUserScripts()
        
        // 添加新的脚本和处理程序
        let script = WKUserScript(source: """
            document.addEventListener('selectionchange', function() {
                const selection = window.getSelection();
                const text = selection.toString();
                if (text) {
                    window.webkit.messageHandlers.textSelected.postMessage(text);
                }
            });
        """, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        
        configuration.userContentController.add(self, name: "textSelected")
        configuration.userContentController.addUserScript(script)
    }
    
    override func removeFromSuperview() {
        super.removeFromSuperview()
        // 清理资源
        configuration.userContentController.removeScriptMessageHandler(forName: "textSelected")
        configuration.userContentController.removeAllUserScripts()
    }
}

extension CustomWKWebView: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "textSelected", let text = message.body as? String {
            selectedText = text
        }
    }
} 