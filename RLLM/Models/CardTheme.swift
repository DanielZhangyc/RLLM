import SwiftUI

struct CardTheme: Codable, Identifiable {
    let id: Int
    let name: String
    let colors: [String] // Hex colors
    let isGradient: Bool
    
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

extension Color {
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