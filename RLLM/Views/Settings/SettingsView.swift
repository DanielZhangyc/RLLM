import SwiftUI
import Foundation

struct SettingsView: View {
    // MARK: - Properties
    
    @AppStorage("fontSize") private var fontSize: Double = 17
    @StateObject private var viewModel = SettingsViewModel()
    @StateObject private var llmViewModel = LLMSettingsViewModel()
    @StateObject private var historyManager = ReadingHistoryManager.shared
    @EnvironmentObject var articlesViewModel: ArticlesViewModel
    @State private var showingClearReadingHistoryAlert = false
    
    var body: some View {
        Form {
            Section("LLM设置") {
                Picker("服务商", selection: $llmViewModel.config.provider) {
                    ForEach(LLMConnectionManager.getProviders(), id: \.self) { provider in
                        Text(provider.rawValue).tag(provider)
                    }
                }
                .onChange(of: llmViewModel.config.provider) { _, newValue in
                    llmViewModel.updateProvider(newValue)
                }
                
                TextField("Base URL", text: $llmViewModel.config.baseURL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                
                SecureField("API Key", text: $llmViewModel.config.apiKey)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                
                if llmViewModel.isLoadingModels {
                    ProgressView("加载模型列表...")
                } else {
                    NavigationLink {
                        ModelSelectionView(
                            config: llmViewModel.config,
                            onModelSelected: { modelId in
                                llmViewModel.config.model = modelId
                            }
                        )
                    } label: {
                        HStack {
                            Text("模型")
                            Spacer()
                            Text(llmViewModel.config.model)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                if let error = llmViewModel.error {
                    Text(error.localizedDescription)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Button(action: llmViewModel.testConnection) {
                    if llmViewModel.isTestingConnection {
                        ProgressView()
                    } else {
                        Text("测试连接")
                    }
                }
                .disabled(llmViewModel.config.apiKey.isEmpty)
                
                if let testResult = llmViewModel.testResult {
                    Text(testResult)
                        .foregroundColor(testResult.contains("成功") ? .green : .red)
                }
            }
            
            Section(header: Text("阅读设置")) {
                HStack {
                    Text("A").font(.footnote)
                    Slider(value: $fontSize, in: 14...24, step: 1)
                        .onChange(of: fontSize) { _, _ in
                            HapticManager.shared.selection()
                        }
                    Text("A").font(.title)
                }
                
                NavigationLink {
                    ReadingHistoryView()
                } label: {
                    Label("阅读历史", systemImage: "clock.arrow.circlepath")
                }
            }
            
            Section("订阅源管理") {
                NavigationLink {
                    FeedManagementView()
                } label: {
                    HStack {
                        Text("管理RSS源")
                        Spacer()
                        Text("\(viewModel.feedCount)个订阅")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section {
                HStack {
                    Text("版本")
                    Spacer()
                    Text(Bundle.main.versionAndBuild)
                        .foregroundColor(.secondary)
                }
                
                Link(destination: URL(string: "https://github.com/DanielZhangyc/RLLM")!) {
                    HStack {
                        Text("源代码")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("关于")
            } footer: {
                Text("RLLM 是一个开源的RSS阅读器，结合了AI的智能分析功能。")
            }
            
            Section {
                NavigationLink {
                    AICacheManagementView()
                } label: {
                    HStack {
                        Text("AI缓存管理")
                        Spacer()
                        let totalSize = summaryStats.totalSize + insightStats.totalSize + dailySummaryStats.totalSize
                        Text(ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file))
                            .foregroundColor(.secondary)
                    }
                }
                
                Button(role: .destructive) {
                    showingClearReadingHistoryAlert = true
                } label: {
                    HStack {
                        Text("清除阅读记录")
                        Spacer()
                        Text("\(historyManager.readingRecords.count)个记录")
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("数据管理")
            } footer: {
                Text("清除阅读记录将删除所有阅读历史和统计数据，此操作无法撤销。")
            }
        }
        .navigationTitle("设置")
        .onAppear {
            viewModel.updateFeedCount(feeds: articlesViewModel.feeds)
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("FeedsUpdated"))) { _ in
            viewModel.updateFeedCount(feeds: articlesViewModel.feeds)
        }
        .onChange(of: llmViewModel.config) { _, _ in
            llmViewModel.saveConfig()
        }
        .alert("确认清除阅读记录", isPresented: $showingClearReadingHistoryAlert) {
            Button("取消", role: .cancel) { }
            Button("清除", role: .destructive) {
                historyManager.clearAllRecords()
            }
        } message: {
            Text("这将删除所有阅读记录和统计数据，此操作无法撤销。")
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

#Preview {
    NavigationView {
        SettingsView()
    }
} 
