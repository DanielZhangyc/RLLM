import SwiftUI

extension Date {
    func timeAgoDisplay() -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day], from: self, to: now)
        
        if let day = components.day, day > 0 {
            if day == 1 {
                return "1天前"
            }
            if day < 7 {
                return "\(day)天前"
            }
            // 超过一周就显示具体日期
            let formatter = DateFormatter()
            formatter.dateFormat = "MM-dd"
            return formatter.string(from: self)
        }
        
        if let hour = components.hour, hour > 0 {
            return "\(hour)小时前"
        }
        
        if let minute = components.minute, minute > 0 {
            return "\(minute)分钟前"
        }
        
        return "刚刚"
    }
}

struct FeedCardView: View {
    let feed: Feed
    let articleCount: Int
    let lastUpdateTime: Date?
    let loadingState: ArticlesViewModel.LoadingState
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var articlesViewModel: ArticlesViewModel
    @State private var showingEditSheet = false
    @State private var isDeleting = false
    @State private var isPressed = false
    
    private var cardBackground: some View {
        colorScheme == .dark
            ? Color(UIColor.secondarySystemBackground)
            : Color(UIColor.systemBackground)
    }
    
    private var shadowColor: Color {
        colorScheme == .dark
            ? Color.white
            : Color.black
    }
    
    private var iconColor: Color {
        if feed.iconColor == "AccentColor" || feed.iconColor == nil {
            return .accentColor
        }
        let colorMap: [String: Color] = [
            "red": .red,
            "orange": .orange,
            "yellow": .yellow,
            "green": .green,
            "mint": .mint,
            "blue": .blue,
            "indigo": .indigo,
            "purple": .purple,
            "pink": .pink
        ]
        return colorMap[feed.iconColor!] ?? .accentColor
    }
    
    var body: some View {
        NavigationLink(destination: ArticleListView(feed: feed)) {
            VStack(alignment: .leading, spacing: 12) {
                // 顶部图标和文章数
                HStack(spacing: 12) {
                    Image(systemName: feed.iconName)
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(iconColor)
                        .frame(width: 40, height: 40)
                        .padding(.vertical, 4)
                    
                    Spacer()
                    
                    switch loadingState {
                    case .loading:
                        ProgressView()
                    case .failed(let error):
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.red)
                            .help(error.localizedDescription)
                    default:
                        Text("\(articleCount)篇")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
                
                Spacer()
                
                // 标题和更新时间
                VStack(alignment: .leading, spacing: 6) {
                    Text(feed.title)
                        .font(.title3.weight(.semibold))
                        .lineLimit(2)
                    
                    if let lastUpdate = lastUpdateTime {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption2)
                            Text(lastUpdate.timeAgoDisplay())
                                .font(.caption2)
                        }
                        .foregroundColor(.secondary)
                    }
                }
            }
            .frame(height: 120)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                ZStack {
                    cardBackground
                        .opacity(0.98)
                    
                    // 添加微妙的渐变背景
                    LinearGradient(
                        gradient: Gradient(colors: [
                            iconColor.opacity(0.05),
                            Color.clear
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(
                color: shadowColor.opacity(colorScheme == .dark ? 0.1 : 0.15),
                radius: 10,
                x: 0,
                y: 2
            )
        }
        .buttonStyle(.plain)
        .opacity(loadingState == .loading ? 0.6 : isDeleting ? 0 : 1.0)
        .scaleEffect(isDeleting ? 0.5 : isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isDeleting)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
        .onTapGesture {
            withAnimation {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    isPressed = false
                }
            }
        }
        .contextMenu {
            Button(action: {
                showingEditSheet = true
            }) {
                Label("设置", systemImage: "gear")
            }
            
            Button(role: .destructive, action: {
                withAnimation {
                    isDeleting = true
                }
                // 延迟删除操作，等待动画完成
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    articlesViewModel.deleteFeed(feed)
                }
            }) {
                Label("删除", systemImage: "trash")
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            NavigationStack {
                FeedEditView(feed: feed)
            }
        }
    }
}
