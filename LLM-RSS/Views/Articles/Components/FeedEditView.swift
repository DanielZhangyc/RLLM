import SwiftUI

struct FeedEditView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var articlesViewModel: ArticlesViewModel
    let feed: Feed
    @State private var title: String
    @State private var selectedIcon: String
    
    private let iconOptions = [
        "newspaper.fill", "book.fill", "text.book.closed.fill",
        "doc.text.fill", "magazine.fill", "bookmark.fill",
        "link", "globe", "network", "antenna.radiowaves.left.and.right"
    ]
    
    init(feed: Feed) {
        self.feed = feed
        _title = State(initialValue: feed.title)
        _selectedIcon = State(initialValue: feed.iconName)
    }
    
    var body: some View {
        Form {
            Section(header: Text("基本信息")) {
                TextField("名称", text: $title)
            }
            
            Section(header: Text("图标")) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(iconOptions, id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.title2)
                                .foregroundColor(selectedIcon == icon ? .accentColor : .primary)
                                .padding(8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(selectedIcon == icon ? Color.accentColor.opacity(0.1) : Color.clear)
                                )
                                .onTapGesture {
                                    selectedIcon = icon
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .navigationTitle("编辑订阅源")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("完成") {
                    articlesViewModel.updateFeed(feed, title: title, icon: selectedIcon)
                    dismiss()
                }
            }
        }
    }
}