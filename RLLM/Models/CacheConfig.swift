import Foundation

/// 缓存配置
struct CacheConfig {
    /// 缓存过期时间（秒）
    static let expirationInterval: TimeInterval = 15 * 24 * 60 * 60  // 15天
    
    /// 最大缓存条目数
    static let maxEntries: Int = 1000
    
    /// 单个缓存文件大小限制（字节）
    static let maxFileSize: Int64 = 1024 * 1024  // 1MB
    
    /// 总缓存大小限制（字节）
    static let maxTotalSize: Int64 = 100 * 1024 * 1024  // 100MB
}

/// 缓存条目信息
struct CacheEntryInfo: Codable {
    /// 创建时间
    let createdAt: Date
    
    /// 最后访问时间
    var lastAccessedAt: Date
    
    /// 文件大小（字节）
    let fileSize: Int64
    
    /// 检查是否已过期
    func isExpired() -> Bool {
        Date().timeIntervalSince(createdAt) > CacheConfig.expirationInterval
    }
}

/// 缓存统计信息
struct CacheStats {
    /// 缓存条目数量
    let entryCount: Int
    
    /// 总缓存大小（字节）
    let totalSize: Int64
    
    /// 已过期的条目数量
    let expiredCount: Int
    
    /// 最早的缓存时间
    let oldestEntryDate: Date?
    
    /// 最近的缓存时间
    let newestEntryDate: Date?
    
    /// 平均缓存时间
    let averageAge: TimeInterval?
    
    /// 缓存命中率
    let hitRate: Double
    
    /// 缓存使用率（占最大限制的百分比）
    var usagePercentage: Double {
        Double(totalSize) / Double(CacheConfig.maxTotalSize) * 100
    }
} 