import SwiftUI

struct SettingsView: View {
    @AppStorage("fontSize") private var fontSize: Double = 17
    @StateObject private var viewModel: SettingsViewModel
    @StateObject private var llmViewModel = LLMSettingsViewModel()
    @EnvironmentObject var articlesViewModel: ArticlesViewModel
    @State private var showingClearSummaryCacheAlert = false
    @State private var showingClearInsightCacheAlert = false
    
    init() {
        _viewModel = StateObject(wrappedValue: SettingsViewModel(articlesViewModel: ArticlesViewModel()))
    }
    
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
                } else if !llmViewModel.availableModels.isEmpty {
                    Picker("模型", selection: $llmViewModel.config.model) {
                        ForEach(llmViewModel.availableModels, id: \.self) { model in
                            Text(model).tag(model)
                        }
                    }
                } else if llmViewModel.error == nil && !llmViewModel.config.apiKey.isEmpty {
                    Button("获取模型列表") {
                        Task {
                            await llmViewModel.fetchModels()
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
                
                Toggle("自动生成摘要", isOn: $viewModel.autoGenerateSummary)
            }
            
            Section(header: Text("阅读设置")) {
                HStack {
                    Text("A").font(.footnote)
                    Slider(value: $fontSize, in: 14...24, step: 1)
                    Text("A").font(.title)
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
                
                Link(destination: URL(string: "https://github.com/yourusername/LLM-RSS")!) {
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
                Text("LLM-RSS 是一个开源的RSS阅读器，结合了AI的智能分析功能。")
            }
            
            Section {
                Button(role: .destructive) {
                    showingClearSummaryCacheAlert = true
                } label: {
                    HStack {
                        Text("清除AI概括缓存")
                        Spacer()
                        Image(systemName: "trash")
                    }
                }
                
                Button(role: .destructive) {
                    showingClearInsightCacheAlert = true
                } label: {
                    HStack {
                        Text("清除AI洞察缓存")
                        Spacer()
                        Image(systemName: "trash")
                    }
                }
            } header: {
                Text("缓存管理")
            } footer: {
                VStack(alignment: .leading, spacing: 8) {
                    let summaryStats = SummaryCache.shared.getStats()
                    let insightStats = InsightCache.shared.getStats()
                    
                    Text("AI概括缓存：")
                        .font(.footnote)
                    + Text("\(summaryStats.entryCount)个条目")
                        .font(.footnote)
                    + Text(" • ")
                        .font(.footnote)
                    + Text(ByteCountFormatter.string(fromByteCount: summaryStats.totalSize, countStyle: .file))
                        .font(.footnote)
                    
                    Text("AI洞察缓存：")
                        .font(.footnote)
                    + Text("\(insightStats.entryCount)个条目")
                        .font(.footnote)
                    + Text(" • ")
                        .font(.footnote)
                    + Text(ByteCountFormatter.string(fromByteCount: insightStats.totalSize, countStyle: .file))
                        .font(.footnote)
                    
                    if summaryStats.expiredCount > 0 || insightStats.expiredCount > 0 {
                        Text("已过期：\(summaryStats.expiredCount + insightStats.expiredCount)个条目")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("设置")
        .onAppear {
            viewModel.updateFeedCount()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("FeedsUpdated"))) { _ in
            viewModel.updateFeedCount()
        }
        .onChange(of: llmViewModel.config) { _, _ in
            llmViewModel.saveConfig()
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
    }
}

#Preview {
    NavigationView {
        SettingsView()
    }
} 
