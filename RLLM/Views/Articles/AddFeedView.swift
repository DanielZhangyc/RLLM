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
                    TextField(NSLocalizedString("add_feed.rss_url", comment: "RSS feed URL"), text: $url)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .keyboardType(.URL)
                    
                    TextField(NSLocalizedString("add_feed.feed_name", comment: "Feed name"), text: $customTitle)
                }
                
                Section {
                    Button(action: addFeed) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text(NSLocalizedString("add_feed.add", comment: "Add feed button"))
                        }
                    }
                    .disabled(url.isEmpty || isLoading)
                }
            }
            .navigationTitle(NSLocalizedString("add_feed.title", comment: "Add feed title"))
            .navigationBarItems(trailing: Button(NSLocalizedString("cancel", comment: "Cancel button")) {
                dismiss()
            })
            .alert(NSLocalizedString("add_feed.error", comment: "Error alert title"), isPresented: $showingError) {
                Button(NSLocalizedString("add_feed.ok", comment: "OK button"), role: .cancel) {}
            } message: {
                Text(error?.localizedDescription ?? NSLocalizedString("add_feed.unknown_error", comment: "Unknown error message"))
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