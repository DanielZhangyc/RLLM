import Foundation

extension Bundle {
    /// 获取应用版本号和构建号
    var versionAndBuild: String {
        let version = infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
    
    /// 获取应用版本号
    var version: String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    /// 获取应用构建号
    var build: String {
        return infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
} 