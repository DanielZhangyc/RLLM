import SwiftUI

struct FeedEditView: View {
    let feed: Feed
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var articlesViewModel: ArticlesViewModel
    @State private var title: String
    @State private var selectedIcon: String
    @State private var selectedColor: String
    
    private let icons = [
        "newspaper.fill",           // 新闻/媒体
        "doc.text.fill",           // 文章/博客
        "terminal.fill",           // 技术/开发
        "person.2.fill",           // 社区/论坛
        "book.fill",               // 杂志/期刊
        "globe.americas.fill",     // 网站
        "quote.bubble.fill",       // 评论/观点
        "chart.bar.fill"           // 数据/分析
    ]
    
    private let colors: [(name: String, color: Color)] = [
        ("AccentColor", .accentColor),
        ("red", .red),
        ("orange", .orange),
        ("yellow", .yellow),
        ("green", .green),
        ("mint", .mint),
        ("blue", .blue),
        ("indigo", .indigo),
        ("purple", .purple),
        ("pink", .pink)
    ]
    
    private var currentColor: Color {
        if selectedColor == "AccentColor" {
            return .accentColor
        }
        return colors.first { $0.name == selectedColor }?.color ?? .accentColor
    }
    
    init(feed: Feed) {
        self.feed = feed
        _title = State(initialValue: feed.title)
        _selectedIcon = State(initialValue: feed.iconName)
        _selectedColor = State(initialValue: feed.iconColor ?? "AccentColor")
    }
    
    var body: some View {
        Form {
            Section {
                TextField("标题", text: $title)
            } header: {
                Text("基本信息")
            }
            
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(icons, id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.title2)
                                .foregroundColor(currentColor)
                                .frame(width: 24, height: 24)
                                .padding(8)
                                .background(currentColor.opacity(0.1))
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .strokeBorder(currentColor, lineWidth: selectedIcon == icon ? 2 : 0)
                                )
                                .onTapGesture {
                                    selectedIcon = icon
                                    HapticManager.shared.selection()
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(colors, id: \.name) { colorOption in
                            Circle()
                                .fill(colorOption.color)
                                .frame(width: 24, height: 24)
                                .padding(8)
                                .background(colorOption.color.opacity(0.1))
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .strokeBorder(colorOption.color, lineWidth: selectedColor == colorOption.name ? 2 : 0)
                                )
                                .onTapGesture {
                                    selectedColor = colorOption.name
                                    HapticManager.shared.selection()
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }
            } header: {
                Text("图标设置")
            }
        }
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("取消") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("完成") {
                    articlesViewModel.updateFeed(
                        feed,
                        title: title,
                        icon: selectedIcon,
                        color: selectedColor
                    )
                    dismiss()
                }
                .disabled(title.isEmpty)
            }
        }
    }
}