import SwiftUI

/// AI 洞察视图
/// 提供基于用户阅读内容的智能分析和洞察
///
/// 未来功能:
/// - 阅读兴趣分析
/// - 热点话题追踪
/// - 个性化阅读建议
/// - 文章关联分析
/// - 知识图谱构建
struct AIInsightsView: View {
    @StateObject private var viewModel = AIInsightsViewModel()
    
    var body: some View {
        List {
            Section("今日总结") {
                if let summary = viewModel.dailySummary {
                    Text(summary)
                        .font(.body)
                } else {
                    Text("暂无总结")
                        .foregroundColor(.secondary)
                }
            }
            
            Section("热门话题") {
                if viewModel.topTopics.isEmpty {
                    Text("暂无热门话题")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(viewModel.topTopics, id: \.self) { topic in
                        HStack {
                            Text(topic)
                            Spacer()
                            Text("\(viewModel.topicCounts[topic] ?? 0)篇")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("AI总结")
        .onAppear {
            Task {
                await viewModel.refreshInsights()
            }
        }
    }
}