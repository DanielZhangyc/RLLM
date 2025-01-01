import SwiftUI

/// 通用错误提示视图
struct ErrorView: View {
    /// 错误信息
    let error: Error
    
    /// 重试回调
    let retryAction: () -> Void
    
    /// 是否显示重试按钮
    var showRetryButton: Bool = true
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.red)
            
            Text(error.localizedDescription)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
            
            if let recoverySuggestion = (error as? LocalizedError)?.recoverySuggestion {
                Text(recoverySuggestion)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
            
            if showRetryButton {
                Button(action: retryAction) {
                    Label("重试", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .tint(.accentColor)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
} 