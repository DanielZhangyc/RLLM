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
    @State private var refreshTask: Task<Void, Never>?
    @State private var backgroundTask: Task<Void, Never>?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let summary = viewModel.dailySummary {
                    // 今日总结部分
                    VStack(alignment: .leading, spacing: 20) {
                        // 今日总结
                        VStack(alignment: .leading, spacing: 12) {
                            Label("今日总结", systemImage: "text.justify")
                                .font(.headline)
                                .padding(.bottom, 4)
                            Text(summary)
                                .font(.body)
                            if let readingTime = viewModel.readingTime {
                                Text("阅读时长：\(readingTime)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 4)
                            }
                        }
                        
                        Divider()
                        
                        // 关键观点
                        VStack(alignment: .leading, spacing: 12) {
                            Label("关键观点", systemImage: "list.bullet")
                                .font(.headline)
                                .padding(.bottom, 4)
                            ForEach(viewModel.keyPoints ?? [], id: \.self) { point in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "circle.fill")
                                        .font(.system(size: 6))
                                        .padding(.top, 7)
                                    Text(point)
                                }
                            }
                        }
                        
                        Divider()
                        
                        // 学习建议
                        VStack(alignment: .leading, spacing: 12) {
                            Label("学习建议", systemImage: "lightbulb")
                                .font(.headline)
                                .padding(.bottom, 4)
                            Text(viewModel.learningAdvice ?? "暂无建议")
                                .font(.body)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                } else if viewModel.isAnalyzing {
                    ProgressView("正在分析...")
                        .frame(maxWidth: .infinity, alignment: .center)
                } else if let error = viewModel.error {
                    ErrorView(error: error) {
                        refreshTask?.cancel()
                        refreshTask = Task {
                            await viewModel.refreshInsights()
                        }
                    }
                } else {
                    Text("暂无今日总结")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                
                // 热门话题部分
                VStack(alignment: .leading, spacing: 16) {
                    Label("热门话题", systemImage: "chart.bar.fill")
                        .font(.headline)
                        .padding(.bottom, 8)
                    
                    if viewModel.topTopics.isEmpty {
                        Text("暂无热门话题")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(viewModel.topTopics, id: \.self) { topic in
                            HStack {
                                Text(topic)
                                    .font(.body)
                                Spacer()
                                Text("\(viewModel.topicCounts[topic] ?? 0)篇")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            }
            .padding()
        }
        .navigationTitle("AI洞察")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if backgroundTask == nil {
                backgroundTask = Task(priority: .background) {
                    await viewModel.refreshInsights()
                }
            }
        }
        .onDisappear {
            refreshTask?.cancel()
            refreshTask = nil
        }
        .refreshable {
            refreshTask?.cancel()
            backgroundTask?.cancel()
            backgroundTask = Task(priority: .background) {
                try? await Task.sleep(nanoseconds: 500_000_000) // 等待0.5秒
                await viewModel.refreshInsights(forceRefresh: true)
            }
            await backgroundTask?.value
        }
    }
}