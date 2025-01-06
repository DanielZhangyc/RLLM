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
                if viewModel.isAnalyzing {
                    VStack {
                        Spacer()
                        ProgressView("正在分析...")
                            .frame(maxWidth: .infinity, alignment: .center)
                        Spacer()
                    }
                    .frame(minHeight: 300)
                } else if let error = viewModel.error {
                    VStack {
                        Spacer()
                        ContentUnavailableView {
                            Label("配置错误", systemImage: "exclamationmark.triangle")
                                .font(.title2)
                        } description: {
                            if let configError = error as? AIAnalysisError {
                                Text(configError.localizedDescription)
                            } else {
                                Text(error.localizedDescription)
                            }
                        } actions: {
                            Button(action: {
                                refreshTask?.cancel()
                                refreshTask = Task {
                                    await viewModel.refreshInsights(forceRefresh: true)
                                }
                            }) {
                                Text("重试")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(Color.accentColor)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                        Spacer()
                    }
                    .frame(minHeight: 300)
                } else if viewModel.hasNoReadingRecords {
                    VStack {
                        Spacer()
                        ContentUnavailableView {
                            Label("暂无阅读记录", systemImage: "book.closed")
                                .font(.title2)
                        } description: {
                            Text("开始阅读一些文章，AI将为你生成今日阅读总结")
                        } actions: {
                            Button(action: {
                                refreshTask?.cancel()
                                refreshTask = Task {
                                    await viewModel.refreshInsights(forceRefresh: true)
                                }
                            }) {
                                Text("刷新")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(Color.accentColor)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                        Spacer()
                    }
                    .frame(minHeight: 300)
                } else {
                    // 今日总结部分
                    if let summary = viewModel.dailySummary, !summary.isEmpty {
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
                            
                            // 只有当有关键观点时才显示分隔线和关键观点部分
                            if let points = viewModel.keyPoints, !points.isEmpty {
                                Divider()
                                
                                VStack(alignment: .leading, spacing: 12) {
                                    Label("关键观点", systemImage: "list.bullet")
                                        .font(.headline)
                                        .padding(.bottom, 4)
                                    ForEach(points, id: \.self) { point in
                                        HStack(alignment: .top, spacing: 8) {
                                            Image(systemName: "circle.fill")
                                                .font(.system(size: 6))
                                                .padding(.top, 7)
                                            Text(point)
                                        }
                                    }
                                }
                            }
                            
                            // 只有当有学习建议时才显示分隔线和学习建议部分
                            if let advice = viewModel.learningAdvice, !advice.isEmpty {
                                Divider()
                                
                                VStack(alignment: .leading, spacing: 12) {
                                    Label("学习建议", systemImage: "lightbulb")
                                        .font(.headline)
                                        .padding(.bottom, 4)
                                    Text(advice)
                                        .font(.body)
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemBackground))
                                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        )
                    }
                    
                    // 热门话题部分
                    if !viewModel.topTopics.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Label("热门话题", systemImage: "chart.bar.fill")
                                .font(.headline)
                                .padding(.bottom, 8)
                            
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
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemBackground))
                                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        )
                    }
                }
            }
            .padding()
            .safeAreaInset(edge: .top) {
                Color.clear.frame(height: 1)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("AI总结")
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
