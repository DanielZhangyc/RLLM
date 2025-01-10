import Foundation

/// 缓存配置结构体
/// 定义了缓存的各项参数限制
struct CacheConfig {
    // MARK: - Static Properties
    
    /// 缓存过期时间（秒）
    /// 默认为15天
    static let expirationInterval: TimeInterval = 15 * 24 * 60 * 60  // 15天
    
    /// 最大缓存条目数
    /// 默认为1000条
    static let maxEntries: Int = 1000
    
    /// 单个缓存文件大小限制（字节）
    /// 默认为1MB
    static let maxFileSize: Int64 = 1024 * 1024  // 1MB
    
    /// 总缓存大小限制（字节）
    /// 默认为100MB
    static let maxTotalSize: Int64 = 100 * 1024 * 1024  // 100MB
}

/// 缓存条目信息结构体
/// 记录每个缓存条目的元数据
struct CacheEntryInfo: Codable {
    // MARK: - Properties
    
    /// 缓存条目的创建时间
    let createdAt: Date
    
    /// 缓存条目的最后访问时间
    var lastAccessedAt: Date
    
    /// 缓存文件的大小（字节）
    let fileSize: Int64
    
    // MARK: - Methods
    
    /// 检查缓存条目是否已过期
    /// - Returns: 如果缓存条目已过期则返回true，否则返回false
    func isExpired() -> Bool {
        Date().timeIntervalSince(createdAt) > CacheConfig.expirationInterval
    }
}

/// 缓存统计信息结构体
/// 提供缓存系统的整体统计数据
struct CacheStats {
    // MARK: - Properties
    
    /// 当前缓存条目的总数
    let entryCount: Int
    
    /// 当前总缓存大小（字节）
    let totalSize: Int64
    
    /// 已过期的缓存条目数量
    let expiredCount: Int
    
    /// 最早的缓存条目创建时间
    let oldestEntryDate: Date?
    
    /// 最新的缓存条目创建时间
    let newestEntryDate: Date?
    
    /// 缓存条目的平均存在时间
    let averageAge: TimeInterval?
    
    /// 缓存命中率
    let hitRate: Double
    
    /// 缓存使用率（占最大限制的百分比）
    var usagePercentage: Double {
        Double(totalSize) / Double(CacheConfig.maxTotalSize) * 100
    }
} 