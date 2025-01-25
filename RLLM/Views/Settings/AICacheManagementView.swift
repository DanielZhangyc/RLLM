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
                        Text(NSLocalizedString("ai_cache.clear_all", comment: "Clear all AI cache"))
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
                        Text(NSLocalizedString("ai_cache.summary_cache", comment: "AI summary cache"))
                        Spacer()
                        Text(String(format: NSLocalizedString("ai_cache.entry_count_size", comment: "Entry count and size"), summaryStats.entryCount, ByteCountFormatter.string(fromByteCount: summaryStats.totalSize, countStyle: .file)))
                            .foregroundColor(.secondary)
                    }
                }
                
                Button(role: .destructive) {
                    showingClearInsightCacheAlert = true
                } label: {
                    HStack {
                        Text(NSLocalizedString("ai_cache.insight_cache", comment: "AI insight cache"))
                        Spacer()
                        Text(String(format: NSLocalizedString("ai_cache.entry_count_size", comment: "Entry count and size"), insightStats.entryCount, ByteCountFormatter.string(fromByteCount: insightStats.totalSize, countStyle: .file)))
                            .foregroundColor(.secondary)
                    }
                }
                
                Button(role: .destructive) {
                    showingClearDailySummaryCacheAlert = true
                } label: {
                    HStack {
                        Text(NSLocalizedString("ai_cache.daily_summary_cache", comment: "Daily summary cache"))
                        Spacer()
                        Text(String(format: NSLocalizedString("ai_cache.entry_count_size", comment: "Entry count and size"), dailySummaryStats.entryCount, ByteCountFormatter.string(fromByteCount: dailySummaryStats.totalSize, countStyle: .file)))
                            .foregroundColor(.secondary)
                    }
                }
            } footer: {
                if summaryStats.expiredCount > 0 || insightStats.expiredCount > 0 {
                    Text(String(format: NSLocalizedString("ai_cache.expired_entries", comment: "Expired entries"), summaryStats.expiredCount + insightStats.expiredCount))
                }
            }
        }
        .navigationTitle(NSLocalizedString("ai_cache.title", comment: "AI cache management"))
        .alert(NSLocalizedString("ai_cache.clear_all_title", comment: "Clear all AI cache confirmation"), isPresented: $showingClearAllAlert) {
            Button(NSLocalizedString("ai_cache.cancel", comment: "Cancel button"), role: .cancel) { }
            Button(NSLocalizedString("ai_cache.clear", comment: "Clear button"), role: .destructive) {
                SummaryCache.shared.clear()
                InsightCache.shared.clear()
                DailySummaryCache.shared.clear()
            }
        } message: {
            Text(NSLocalizedString("ai_cache.clear_all_message", comment: "Clear all AI cache message"))
        }
        .alert(NSLocalizedString("ai_cache.clear_summary_title", comment: "Clear summary cache confirmation"), isPresented: $showingClearSummaryCacheAlert) {
            Button(NSLocalizedString("ai_cache.cancel", comment: "Cancel button"), role: .cancel) { }
            Button(NSLocalizedString("ai_cache.clear", comment: "Clear button"), role: .destructive) {
                SummaryCache.shared.clear()
            }
        } message: {
            Text(NSLocalizedString("ai_cache.clear_summary_message", comment: "Clear summary cache message"))
        }
        .alert(NSLocalizedString("ai_cache.clear_insight_title", comment: "Clear insight cache confirmation"), isPresented: $showingClearInsightCacheAlert) {
            Button(NSLocalizedString("ai_cache.cancel", comment: "Cancel button"), role: .cancel) { }
            Button(NSLocalizedString("ai_cache.clear", comment: "Clear button"), role: .destructive) {
                InsightCache.shared.clear()
            }
        } message: {
            Text(NSLocalizedString("ai_cache.clear_insight_message", comment: "Clear insight cache message"))
        }
        .alert(NSLocalizedString("ai_cache.clear_daily_summary_title", comment: "Clear daily summary cache confirmation"), isPresented: $showingClearDailySummaryCacheAlert) {
            Button(NSLocalizedString("ai_cache.cancel", comment: "Cancel button"), role: .cancel) { }
            Button(NSLocalizedString("ai_cache.clear", comment: "Clear button"), role: .destructive) {
                DailySummaryCache.shared.clear()
            }
        } message: {
            Text(NSLocalizedString("ai_cache.clear_daily_summary_message", comment: "Clear daily summary cache message"))
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