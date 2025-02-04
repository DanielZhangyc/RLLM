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
            Section(NSLocalizedString("settings.llm", comment: "LLM settings section")) {
                Picker(NSLocalizedString("settings.provider", comment: "Provider picker"), selection: $llmViewModel.config.provider) {
                    ForEach(LLMConnectionManager.getProviders(), id: \.self) { provider in
                        Text(provider.displayName).tag(provider)
                    }
                }
                .onChange(of: llmViewModel.config.provider) { _, newValue in
                    llmViewModel.updateProvider(newValue)
                }
                
                TextField(NSLocalizedString("settings.base_url", comment: "Base URL"), text: $llmViewModel.config.baseURL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                
                SecureField(NSLocalizedString("settings.api_key", comment: "API Key"), text: $llmViewModel.config.apiKey)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                
                if llmViewModel.isLoadingModels {
                    ProgressView(NSLocalizedString("settings.loading_models", comment: "Loading models"))
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
                            Text(NSLocalizedString("settings.model", comment: "Model selection"))
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
                        Text(NSLocalizedString("settings.test_connection", comment: "Test connection button"))
                    }
                }
                .disabled(llmViewModel.config.apiKey.isEmpty)
                
                if let testResult = llmViewModel.testResult {
                    Text(testResult)
                        .foregroundColor(testResult.contains(NSLocalizedString("settings.test_success", comment: "Test success")) ? .green : .red)
                }
            }
            
            Section(header: Text(NSLocalizedString("settings.reading", comment: "Reading settings section"))) {
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
                    Label(NSLocalizedString("settings.reading_history", comment: "Reading history"), systemImage: "clock.arrow.circlepath")
                }
            }
            
            Section(NSLocalizedString("settings.feed_management", comment: "Feed management section")) {
                NavigationLink {
                    FeedManagementView()
                } label: {
                    HStack {
                        Text(NSLocalizedString("settings.manage_feeds", comment: "Manage feeds"))
                        Spacer()
                        Text(String(format: NSLocalizedString("settings.feed_count", comment: "Feed count"), viewModel.feedCount))
                            .foregroundColor(.secondary)
                    }
                }
                
                Button {
                    exportOPML()
                } label: {
                    Label(NSLocalizedString("settings.export_opml", comment: "Export OPML"), systemImage: "square.and.arrow.up")
                }
            }
            
            Section {
                HStack {
                    Text(NSLocalizedString("settings.version", comment: "Version"))
                    Spacer()
                    Text(Bundle.main.versionAndBuild)
                        .foregroundColor(.secondary)
                }
                
                Link(destination: URL(string: "https://github.com/DanielZhangyc/RLLM")!) {
                    HStack {
                        Text(NSLocalizedString("settings.source_code", comment: "Source code"))
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text(NSLocalizedString("settings.about", comment: "About section"))
            } footer: {
                Text(NSLocalizedString("settings.about_description", comment: "About description"))
            }
            
            Section {
                NavigationLink {
                    AICacheManagementView()
                } label: {
                    HStack {
                        Text(NSLocalizedString("settings.ai_cache", comment: "AI cache management"))
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
                        Text(NSLocalizedString("settings.clear_history", comment: "Clear history"))
                        Spacer()
                        Text(String(format: NSLocalizedString("settings.record_count", comment: "Record count"), historyManager.readingRecords.count))
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text(NSLocalizedString("settings.data_management", comment: "Data management section"))
            } footer: {
                Text(NSLocalizedString("settings.clear_history_warning", comment: "Clear history warning"))
            }
        }
        .navigationTitle(NSLocalizedString("settings.title", comment: "Settings title"))
        .onAppear {
            viewModel.updateFeedCount(feeds: articlesViewModel.feeds)
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("FeedsUpdated"))) { _ in
            viewModel.updateFeedCount(feeds: articlesViewModel.feeds)
        }
        .onChange(of: llmViewModel.config) { _, _ in
            llmViewModel.saveConfig()
        }
        .alert(NSLocalizedString("settings.clear_history_title", comment: "Clear history confirmation title"), isPresented: $showingClearReadingHistoryAlert) {
            Button(NSLocalizedString("settings.cancel", comment: "Cancel button"), role: .cancel) { }
            Button(NSLocalizedString("settings.clear", comment: "Clear button"), role: .destructive) {
                // 使用CoreStorage清除阅读记录
                CoreDataManager.shared.clearAllReadingRecords()
                // 更新UI状态
                historyManager.readingRecords = []
            }
        } message: {
            Text(NSLocalizedString("settings.clear_history_message", comment: "Clear history confirmation message"))
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
    
    // MARK: - OPML Export
    
    private func exportOPML() {
        do {
            let url = try ExportManager.shared.exportOPML(articlesViewModel.feeds)
            
            // 显示分享菜单
            let activityVC = UIActivityViewController(
                activityItems: [url],
                applicationActivities: nil
            )
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let viewController = window.rootViewController {
                viewController.present(activityVC, animated: true)
            }
            
            // 显示成功提示
            ToastManager.shared.showSuccess(
                NSLocalizedString("toast.opml.export_success.title", comment: "Export success"),
                message: NSLocalizedString("toast.opml.export_success.message", comment: "OPML file has been generated")
            )
        } catch {
            // 显示错误提示
            ToastManager.shared.showError(
                NSLocalizedString("toast.opml.export_error.title", comment: "Export failed"),
                message: String(format: NSLocalizedString("toast.opml.export_error.message", comment: "Failed to export OPML"), error.localizedDescription)
            )
        }
    }
}

#Preview {
    NavigationView {
        SettingsView()
    }
}
