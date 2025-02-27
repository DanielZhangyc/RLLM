import Foundation
import SwiftUI
import Toast

/// Toast管理器
final class ToastManager: ObservableObject {
    static let shared = ToastManager()
    private init() {}
    
    /// 显示一个Toast
    /// - Parameters:
    ///   - type: Toast类型
    ///   - title: 标题（可选，如果为nil则使用默认标题）
    ///   - message: 消息内容（可选）
    ///   - duration: 显示时长（默认2秒）
    func show(type: ToastType, title: String? = nil, message: String? = nil, duration: TimeInterval = 2.0) {
        let config = ToastConfiguration(
            direction: .top,
            dismissBy: [.time(time: duration), .swipe(direction: .natural)],
            animationTime: 0.2
        )
        
        let displayTitle = title ?? type.localizedTitle
        
        // 创建带图标的toast
        if let image = UIImage(systemName: type.systemImage)?.withTintColor(type.uiColor, renderingMode: .alwaysOriginal) {
            Toast.default(
                image: image,
                title: displayTitle,
                subtitle: message,
                config: config
            ).show()
        } else {
            // 如果无法创建图标，则使用纯文本toast
            Toast.text(
                displayTitle,
                subtitle: message,
                config: config
            ).show()
        }
    }
    
    /// 显示成功Toast
    func showSuccess(_ title: String? = nil, message: String? = nil) {
        show(type: .success, title: title, message: message)
    }
    
    /// 显示错误Toast
    func showError(_ title: String? = nil, message: String? = nil) {
        show(type: .error, title: title, message: message)
    }
    
    /// 显示警告Toast
    func showWarning(_ title: String? = nil, message: String? = nil) {
        show(type: .warning, title: title, message: message)
    }
    
    /// 显示信息Toast
    func showInfo(_ title: String? = nil, message: String? = nil) {
        show(type: .info, title: title, message: message)
    }
}

/// Toast消息的类型
enum ToastType {
    case success
    case error
    case warning
    case info
    
    /// 获取对应的系统图标名称
    var systemImage: String {
        switch self {
        case .success:
            return "checkmark.circle.fill"
        case .error:
            return "xmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .info:
            return "info.circle.fill"
        }
    }
    
    /// 获取对应的UIColor
    var uiColor: UIColor {
        switch self {
        case .success:
            return .systemGreen
        case .error:
            return .systemRed
        case .warning:
            return .systemOrange
        case .info:
            return .systemBlue
        }
    }
    
    /// 获取本地化的标题
    var localizedTitle: String {
        switch self {
        case .success:
            return NSLocalizedString("toast.success", comment: "Toast success")
        case .error:
            return NSLocalizedString("toast.error", comment: "Toast error")
        case .warning:
            return NSLocalizedString("toast.warning", comment: "Toast warning")
        case .info:
            return NSLocalizedString("toast.info", comment: "Toast info")
        }
    }
} 