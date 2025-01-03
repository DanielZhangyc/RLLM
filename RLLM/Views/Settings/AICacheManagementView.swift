import SwiftUI

struct AICacheManagementView: View {
    @State private var showingClearSummaryCacheAlert = false
    @State private var showingClearInsightCacheAlert = false
    @State private var showingClearDailySummaryCacheAlert = false
    @State private var showingClearAllAlert = false
    
    var body: some View {
        List {
            Section {
                Button(role: .destructive) {
                    showingClearAllAlert = true
                } label: {
                    HStack {
                        Text("清除所有AI缓存")
                        Spacer()
                        let totalSize = summaryStats.totalSize + insightStats.totalSize + dailySummaryStats.totalSize
                        Text(ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section {
                Button(role: .destructive) {
                    showingClearSummaryCacheAlert = true
                } label: {
                    HStack {
                        Text("AI概括缓存")
                        Spacer()
                        Text("\(summaryStats.entryCount)个 • \(ByteCountFormatter.string(fromByteCount: summaryStats.totalSize, countStyle: .file))")
                            .foregroundColor(.secondary)
                    }
                }
                
                Button(role: .destructive) {
                    showingClearInsightCacheAlert = true
                } label: {
                    HStack {
                        Text("AI洞察缓存")
                        Spacer()
                        Text("\(insightStats.entryCount)个 • \(ByteCountFormatter.string(fromByteCount: insightStats.totalSize, countStyle: .file))")
                            .foregroundColor(.secondary)
                    }
                }
                
                Button(role: .destructive) {
                    showingClearDailySummaryCacheAlert = true
                } label: {
                    HStack {
                        Text("每日总结缓存")
                        Spacer()
                        Text("\(dailySummaryStats.entryCount)个 • \(ByteCountFormatter.string(fromByteCount: dailySummaryStats.totalSize, countStyle: .file))")
                            .foregroundColor(.secondary)
                    }
                }
            } footer: {
                if summaryStats.expiredCount > 0 || insightStats.expiredCount > 0 {
                    Text("已过期：\(summaryStats.expiredCount + insightStats.expiredCount)个条目")
                }
            }
        }
        .navigationTitle("AI缓存管理")
        .alert("确认清除所有AI缓存", isPresented: $showingClearAllAlert) {
            Button("取消", role: .cancel) { }
            Button("清除", role: .destructive) {
                SummaryCache.shared.clear()
                InsightCache.shared.clear()
                DailySummaryCache.shared.clear()
            }
        } message: {
            Text("这将删除所有AI生成的内容，包括文章概括、洞察分析和每日总结，需要时会重新生成。")
        }
        .alert("确认清除AI概括缓存", isPresented: $showingClearSummaryCacheAlert) {
            Button("取消", role: .cancel) { }
            Button("清除", role: .destructive) {
                SummaryCache.shared.clear()
            }
        } message: {
            Text("这将删除所有已生成的文章概括，需要时会重新生成。")
        }
        .alert("确认清除AI洞察缓存", isPresented: $showingClearInsightCacheAlert) {
            Button("取消", role: .cancel) { }
            Button("清除", role: .destructive) {
                InsightCache.shared.clear()
            }
        } message: {
            Text("这将删除所有已生成的文章洞察分析，需要时会重新生成。")
        }
        .alert("确认清除每日总结缓存", isPresented: $showingClearDailySummaryCacheAlert) {
            Button("取消", role: .cancel) { }
            Button("清除", role: .destructive) {
                DailySummaryCache.shared.clear()
            }
        } message: {
            Text("这将删除所有已生成的每日总结，需要时会重新生成。")
        }
    }
    
    private var summaryStats: CacheStats {
        SummaryCache.shared.getStats()
    }
    
    private var insightStats: CacheStats {
        InsightCache.shared.getStats()
    }
    
    private var dailySummaryStats: CacheStats {
        DailySummaryCache.shared.getStats()
    }
} 