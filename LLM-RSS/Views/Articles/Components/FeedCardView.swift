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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: feed.iconName)
                    .font(.title)
                    .foregroundColor(.accentColor)
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
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 4) {
                Text(feed.title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .lineLimit(2)
                
                if let lastUpdate = lastUpdateTime {
                    Text("更新于 \(lastUpdate.timeAgoDisplay())")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(height: 120)
        .padding()
        .background(
            colorScheme == .dark 
                ? Color(UIColor.secondarySystemBackground)
                : Color(UIColor.systemBackground)
        )
        .cornerRadius(12)
        .shadow(
            color: colorScheme == .dark 
                ? Color.white.opacity(0.05)
                : Color.black.opacity(0.1),
            radius: 5, 
            x: 0, 
            y: 2
        )
        .opacity(loadingState == .loading ? 0.6 : 1.0)
    }
}
