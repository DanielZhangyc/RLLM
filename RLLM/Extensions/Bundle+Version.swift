import Foundation

extension Bundle {
    var appVersion: String {
        if let version = infoDictionary?["CFBundleShortVersionString"] as? String {
            return version
        }
        return "1.0.0"
    }
    
    var buildNumber: String {
        if let build = infoDictionary?["CFBundleVersion"] as? String {
            return build
        }
        return "1"
    }
    
    var versionAndBuild: String {
        return "\(appVersion) (\(buildNumber))"
    }
} 