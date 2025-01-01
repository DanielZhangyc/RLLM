import Foundation

/// 缓存管理器错误类型
enum CacheError: LocalizedError {
    /// 创建缓存目录失败
    case directoryCreationFailed(Error)
    /// 写入缓存失败
    case writeFailed(Error)
    /// 读取缓存失败
    case readFailed(Error)
    /// 缓存已满
    case cacheFull
    /// 文件过大
    case fileTooLarge
    
    var errorDescription: String? {
        switch self {
        case .directoryCreationFailed(let error):
            return "创建缓存目录失败：\(error.localizedDescription)"
        case .writeFailed(let error):
            return "写入缓存失败：\(error.localizedDescription)"
        case .readFailed(let error):
            return "读取缓存失败：\(error.localizedDescription)"
        case .cacheFull:
            return "缓存空间已满"
        case .fileTooLarge:
            return "文件超过大小限制"
        }
    }
}

/// 通用缓存管理器
class CacheManager {
    /// 缓存目录名称
    private let directoryName: String
    
    /// 缓存目录URL
    private var cacheDirectory: URL {
        let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent(directoryName)
    }
    
    /// 缓存条目信息文件名
    private let infoFileName = "cache_info.json"
    
    /// 缓存条目信息
    private var entryInfos: [String: CacheEntryInfo] = [:]
    
    /// 缓存统计信息
    private var stats = CacheStats(
        entryCount: 0,
        totalSize: 0,
        expiredCount: 0,
        oldestEntryDate: nil,
        newestEntryDate: nil,
        averageAge: nil,
        hitRate: 0
    )
    
    /// 缓存命中次数
    private var hits: Int = 0
    
    /// 缓存访问总次数
    private var totalAccesses: Int = 0
    
    /// 初始化缓存管理器
    /// - Parameter directoryName: 缓存目录名称
    init(directoryName: String) {
        self.directoryName = directoryName
        createCacheDirectoryIfNeeded()
        loadCacheInfo()
    }
    
    /// 创建缓存目录（如果不存在）
    private func createCacheDirectoryIfNeeded() {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            do {
                try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
            } catch {
                print("Error creating cache directory: \(error)")
            }
        }
    }
    
    /// 加载缓存信息
    private func loadCacheInfo() {
        let infoURL = cacheDirectory.appendingPathComponent(infoFileName)
        if let data = try? Data(contentsOf: infoURL) {
            entryInfos = (try? JSONDecoder().decode([String: CacheEntryInfo].self, from: data)) ?? [:]
            updateStats()
        }
    }
    
    /// 保存缓存信息
    private func saveCacheInfo() {
        let infoURL = cacheDirectory.appendingPathComponent(infoFileName)
        if let data = try? JSONEncoder().encode(entryInfos) {
            try? data.write(to: infoURL)
        }
    }
    
    /// 更新缓存统计信息
    private func updateStats() {
        let now = Date()
        var totalSize: Int64 = 0
        var expiredCount = 0
        var oldestDate: Date?
        var newestDate: Date?
        var totalAge: TimeInterval = 0
        
        for (_, info) in entryInfos {
            totalSize += info.fileSize
            if info.isExpired {
                expiredCount += 1
            }
            
            if let oldest = oldestDate {
                oldestDate = info.createdAt < oldest ? info.createdAt : oldest
            } else {
                oldestDate = info.createdAt
            }
            
            if let newest = newestDate {
                newestDate = info.createdAt > newest ? info.createdAt : newest
            } else {
                newestDate = info.createdAt
            }
            
            totalAge += now.timeIntervalSince(info.createdAt)
        }
        
        let entryCount = entryInfos.count
        let averageAge = entryCount > 0 ? totalAge / Double(entryCount) : nil
        let hitRate = totalAccesses > 0 ? Double(hits) / Double(totalAccesses) : 0
        
        stats = CacheStats(
            entryCount: entryCount,
            totalSize: totalSize,
            expiredCount: expiredCount,
            oldestEntryDate: oldestDate,
            newestEntryDate: newestDate,
            averageAge: averageAge,
            hitRate: hitRate
        )
    }
    
    /// 清理过期和超量的缓存
    private func cleanup() {
        // 清理过期缓存
        let expiredKeys = entryInfos.filter { $0.value.isExpired }.map { $0.key }
        for key in expiredKeys {
            removeEntry(for: key)
        }
        
        // 如果仍然超过大小限制，按最后访问时间清理
        if stats.totalSize > CacheConfig.maxTotalSize {
            let sortedEntries = entryInfos.sorted { $0.value.lastAccessedAt < $1.value.lastAccessedAt }
            for entry in sortedEntries {
                if stats.totalSize <= CacheConfig.maxTotalSize {
                    break
                }
                removeEntry(for: entry.key)
            }
        }
        
        // 如果超过数量限制，继续清理
        if stats.entryCount > CacheConfig.maxEntries {
            let sortedEntries = entryInfos.sorted { $0.value.lastAccessedAt < $1.value.lastAccessedAt }
            let excessCount = stats.entryCount - CacheConfig.maxEntries
            for i in 0..<excessCount {
                removeEntry(for: sortedEntries[i].key)
            }
        }
        
        saveCacheInfo()
    }
    
    /// 移除指定key的缓存条目
    /// - Parameter key: 缓存key
    private func removeEntry(for key: String) {
        let fileURL = cacheDirectory.appendingPathComponent(key)
        try? FileManager.default.removeItem(at: fileURL)
        entryInfos.removeValue(forKey: key)
        updateStats()
    }
    
    /// 获取缓存统计信息
    /// - Returns: 缓存统计信息
    func getStats() -> CacheStats {
        updateStats()
        return stats
    }
    
    /// 清除所有缓存
    func clearAll() {
        let fileManager = FileManager.default
        try? fileManager.removeItem(at: cacheDirectory)
        createCacheDirectoryIfNeeded()
        entryInfos.removeAll()
        updateStats()
        saveCacheInfo()
    }
    
    /// 写入缓存
    /// - Parameters:
    ///   - data: 要缓存的数据
    ///   - key: 缓存key
    /// - Throws: CacheError
    func write(_ data: Data, for key: String) throws {
        // 检查文件大小
        let fileSize = Int64(data.count)
        if fileSize > CacheConfig.maxFileSize {
            throw CacheError.fileTooLarge
        }
        
        // 检查总缓存大小
        if stats.totalSize + fileSize > CacheConfig.maxTotalSize {
            cleanup()
            if stats.totalSize + fileSize > CacheConfig.maxTotalSize {
                throw CacheError.cacheFull
            }
        }
        
        // 写入文件
        let fileURL = cacheDirectory.appendingPathComponent(key)
        do {
            try data.write(to: fileURL)
            let now = Date()
            entryInfos[key] = CacheEntryInfo(
                createdAt: now,
                lastAccessedAt: now,
                fileSize: fileSize
            )
            updateStats()
            saveCacheInfo()
        } catch {
            throw CacheError.writeFailed(error)
        }
    }
    
    /// 读取缓存
    /// - Parameter key: 缓存key
    /// - Returns: 缓存的数据
    /// - Throws: CacheError
    func read(for key: String) throws -> Data {
        totalAccesses += 1
        
        guard let info = entryInfos[key], !info.isExpired else {
            if entryInfos[key] != nil {
                removeEntry(for: key)
            }
            return Data()
        }
        
        let fileURL = cacheDirectory.appendingPathComponent(key)
        do {
            let data = try Data(contentsOf: fileURL)
            hits += 1
            
            // 更新访问时间
            entryInfos[key]?.lastAccessedAt = Date()
            updateStats()
            saveCacheInfo()
            
            return data
        } catch {
            throw CacheError.readFailed(error)
        }
    }
    
    /// 检查是否存在缓存
    /// - Parameter key: 缓存key
    /// - Returns: 是否存在有效缓存
    func has(for key: String) -> Bool {
        guard let info = entryInfos[key], !info.isExpired else {
            if entryInfos[key] != nil {
                removeEntry(for: key)
            }
            return false
        }
        return true
    }
} 