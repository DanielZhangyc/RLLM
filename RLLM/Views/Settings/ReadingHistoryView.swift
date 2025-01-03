import SwiftUI

struct ReadingHistoryView: View {
    @StateObject private var historyManager = ReadingHistoryManager.shared
    @State private var selectedTimeRange: TimeRange = .week
    
    enum TimeRange {
        case day, week, month
        
        var title: String {
            switch self {
            case .day: return "今日"
            case .week: return "本周"
            case .month: return "本月"
            }
        }
    }
    
    var body: some View {
        List {
            Section {
                Picker("时间范围", selection: $selectedTimeRange) {
                    Text("今日").tag(TimeRange.day)
                    Text("本周").tag(TimeRange.week)
                    Text("本月").tag(TimeRange.month)
                }
                .pickerStyle(.segmented)
                .padding(.vertical, 8)
            }
            
            Section("阅读统计") {
                VStack(spacing: 16) {
                    HStack {
                        StatCard(
                            title: "阅读时长",
                            value: formattedReadingTime,
                            icon: "clock.fill"
                        )
                        
                        StatCard(
                            title: "阅读文章",
                            value: "\(articleCount)篇",
                            icon: "doc.text.fill"
                        )
                    }
                    
                    if selectedTimeRange != .day {
                        HStack {
                            StatCard(
                                title: "平均每日",
                                value: formattedAverageTime,
                                icon: "chart.bar.fill"
                            )
                            
                            StatCard(
                                title: "平均每篇",
                                value: formattedAveragePerArticle,
                                icon: "book.fill"
                            )
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            
            Section("阅读记录") {
                if records.isEmpty {
                    Text("暂无阅读记录")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    ForEach(records) { record in
                        ReadingRecordRow(record: record)
                    }
                }
            }
        }
        .navigationTitle("阅读历史")
    }
    
    private var records: [ReadingRecord] {
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedTimeRange {
        case .day:
            let startOfDay = calendar.startOfDay(for: now)
            return historyManager.getRecords(from: startOfDay, to: now)
            
        case .week:
            guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) else {
                return []
            }
            return historyManager.getRecords(from: weekStart, to: now)
            
        case .month:
            guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) else {
                return []
            }
            return historyManager.getRecords(from: monthStart, to: now)
        }
    }
    
    private var formattedReadingTime: String {
        let minutes = records.reduce(0) { $0 + $1.duration / 60 }
        if minutes < 60 {
            return "\(Int(minutes))分钟"
        } else {
            let hours = Int(minutes / 60)
            let remainingMinutes = Int(minutes.truncatingRemainder(dividingBy: 60))
            return "\(hours)小时\(remainingMinutes)分钟"
        }
    }
    
    private var articleCount: Int {
        records.count
    }
    
    private var formattedAverageTime: String {
        let totalMinutes = records.reduce(0) { $0 + $1.duration / 60 }
        
        // 计算天数
        let calendar = Calendar.current
        let now = Date()
        var startDate: Date
        
        switch selectedTimeRange {
        case .day:
            return ""  // 不显示每日平均
        case .week:
            guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) else {
                return "0分钟"
            }
            startDate = weekStart
        case .month:
            guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) else {
                return "0分钟"
            }
            startDate = monthStart
        }
        
        guard let days = calendar.dateComponents([.day], from: startDate, to: now).day,
              days > 0 else {
            return "0分钟"
        }
        
        let averageMinutes = totalMinutes / Double(days)
        if averageMinutes < 60 {
            return "\(Int(averageMinutes))分钟"
        } else {
            let hours = Int(averageMinutes / 60)
            let remainingMinutes = Int(averageMinutes.truncatingRemainder(dividingBy: 60))
            return "\(hours)小时\(remainingMinutes)分钟"
        }
    }
    
    private var formattedAveragePerArticle: String {
        guard !records.isEmpty else { return "0分钟" }
        let averageMinutes = records.reduce(0) { $0 + $1.duration / 60 } / Double(records.count)
        if averageMinutes < 60 {
            return "\(Int(averageMinutes))分钟"
        } else {
            let hours = Int(averageMinutes / 60)
            let remainingMinutes = Int(averageMinutes.truncatingRemainder(dividingBy: 60))
            return "\(hours)小时\(remainingMinutes)分钟"
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title2.bold())
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

struct ReadingRecordRow: View {
    let record: ReadingRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(record.articleTitle)
                .font(.headline)
                .lineLimit(1)
            
            HStack {
                Label("\(Int(record.duration / 60))分钟", systemImage: "clock")
                
                Spacer()
                
                Text(record.startTime.formatted(.relative(presentation: .named)))
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
} 