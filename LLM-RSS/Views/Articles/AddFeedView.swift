import SwiftUI

struct AddFeedView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: ArticlesViewModel
    @State private var url = ""
    @State private var customTitle = ""
    @State private var isLoading = false
    @State private var error: Error?
    @State private var showingError = false
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("RSS源地址", text: $url)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .keyboardType(.URL)
                    
                    TextField("源名称（可选）", text: $customTitle)
                }
                
                Section {
                    Button(action: addFeed) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("添加")
                        }
                    }
                    .disabled(url.isEmpty || isLoading)
                }
            }
            .navigationTitle("添加订阅源")
            .navigationBarItems(trailing: Button("取消") {
                dismiss()
            })
            .alert("错误", isPresented: $showingError) {
                Button("确定", role: .cancel) {}
            } message: {
                Text(error?.localizedDescription ?? "未知错误")
            }
        }
    }
    
    private func addFeed() {
        isLoading = true
        
        Task {
            do {
                var feed = try await viewModel.validateFeed(url)
                if !customTitle.isEmpty {
                    feed.title = customTitle
                }
                try await viewModel.addFeed(feed)
                dismiss()
            } catch {
                self.error = error
                showingError = true
            }
            isLoading = false
        }
    }
} 