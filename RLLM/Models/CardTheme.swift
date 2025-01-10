import SwiftUI

/// 表示卡片主题的数据模型
/// 用于定义卡片的颜色和渐变样式
struct CardTheme: Codable, Identifiable {
    // MARK: - Properties
    
    /// 主题的唯一标识符
    let id: Int
    
    /// 主题的名称
    let name: String
    
    /// 主题的颜色列表，使用十六进制颜色值
    let colors: [String]
    
    /// 是否使用渐变效果
    let isGradient: Bool
    
    // MARK: - Static Properties
    
    /// 预设的主题列表
    static let presets: [CardTheme] = [
        // 渐变色主题
        CardTheme(id: 1, name: "极光紫", colors: ["#A18CD1", "#FBC2EB"], isGradient: true),
        CardTheme(id: 2, name: "清晨蓝", colors: ["#89f7fe", "#66a6ff"], isGradient: true),
        CardTheme(id: 3, name: "日落橙", colors: ["#fad0c4", "#ffd1ff"], isGradient: true),
        CardTheme(id: 4, name: "薄荷绿", colors: ["#84fab0", "#8fd3f4"], isGradient: true),
        
        // 纯色主题
        CardTheme(id: 5, name: "静谧蓝", colors: ["#5B7CF7"], isGradient: false),
        CardTheme(id: 6, name: "珊瑚粉", colors: ["#FF7B89"], isGradient: false),
        CardTheme(id: 7, name: "薄荷绿", colors: ["#69D0B3"], isGradient: false),
        CardTheme(id: 8, name: "暖阳黄", colors: ["#FFB344"], isGradient: false)
    ]
}

/// Color扩展，添加从十六进制字符串创建颜色的功能
extension Color {
    /// 从十六进制字符串创建Color实例
    /// - Parameter hex: 十六进制颜色字符串，支持3位(RGB)、6位(RGB)和8位(ARGB)格式
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
} 