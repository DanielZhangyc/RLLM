import SwiftUI

struct ReadingHistoryView: View {
    @StateObject private var historyManager = ReadingHistoryManager.shared
    @State private var selectedTimeRange: TimeRange = .week
    
    enum TimeRange {
        case day, week, month
        
        var title: String {
            switch self {
            case .day: return NSLocalizedString("reading_history.today", comment: "Today")
            case .week: return NSLocalizedString("reading_history.this_week", comment: "This week")
            case .month: return NSLocalizedString("reading_history.this_month", comment: "This month")
            }
        }
    }
    
    var body: some View {
        List {
            Section {
                Picker(NSLocalizedString("reading_history.time_range", comment: "Time range"), selection: $selectedTimeRange) {
                    Text(NSLocalizedString("reading_history.today", comment: "Today")).tag(TimeRange.day)
                    Text(NSLocalizedString("reading_history.this_week", comment: "This week")).tag(TimeRange.week)
                    Text(NSLocalizedString("reading_history.this_month", comment: "This month")).tag(TimeRange.month)
                }
                .pickerStyle(.segmented)
                .padding(.vertical, 8)
            }
            
            Section(NSLocalizedString("reading_history.statistics", comment: "Reading statistics")) {
                VStack(spacing: 16) {
                    HStack {
                        StatCard(
                            title: NSLocalizedString("reading_history.reading_time", comment: "Reading time"),
                            value: formattedReadingTime,
                            icon: "clock.fill"
                        )
                        
                        StatCard(
                            title: NSLocalizedString("reading_history.articles_read", comment: "Articles read"),
                            value: formattedArticleCount,
                            icon: "doc.text.fill"
                        )
                    }
                    
                    if selectedTimeRange != .day {
                        HStack {
                            StatCard(
                                title: NSLocalizedString("reading_history.daily_average", comment: "Daily average"),
                                value: formattedAverageTime,
                                icon: "chart.bar.fill"
                            )
                            
                            StatCard(
                                title: NSLocalizedString("reading_history.average_per_article", comment: "Average per article"),
                                value: formattedAveragePerArticle,
                                icon: "book.fill"
                            )
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            
            Section(NSLocalizedString("reading_history.records", comment: "Reading records")) {
                if records.isEmpty {
                    Text(NSLocalizedString("reading_history.no_records", comment: "No reading records"))
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
        .navigationTitle(NSLocalizedString("reading_history.title", comment: "Reading history"))
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
            let key = minutes == 1 ? "reading_history.minute" : "reading_history.minutes"
            return String(format: NSLocalizedString(key, comment: "Minutes"), Int(minutes))
        } else {
            let hours = Int(minutes / 60)
            let remainingMinutes = Int(minutes.truncatingRemainder(dividingBy: 60))
            return String(format: NSLocalizedString("reading_history.hours_minutes", comment: "Hours and minutes"), hours, remainingMinutes)
        }
    }
    
    private var articleCount: Int {
        records.count
    }
    
    private var formattedArticleCount: String {
        let count = records.count
        let key = count == 1 ? "reading_history.article_read" : "reading_history.articles_read"
        return String(format: NSLocalizedString(key, comment: "Articles read"), count)
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
                let key = "reading_history.minute"
                return String(format: NSLocalizedString(key, comment: "Minutes"), 0)
            }
            startDate = weekStart
        case .month:
            guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) else {
                let key = "reading_history.minute"
                return String(format: NSLocalizedString(key, comment: "Minutes"), 0)
            }
            startDate = monthStart
        }
        
        guard let days = calendar.dateComponents([.day], from: startDate, to: now).day,
              days > 0 else {
            let key = "reading_history.minute"
            return String(format: NSLocalizedString(key, comment: "Minutes"), 0)
        }
        
        let averageMinutes = totalMinutes / Double(days)
        if averageMinutes < 60 {
            let key = averageMinutes == 1 ? "reading_history.minute" : "reading_history.minutes"
            return String(format: NSLocalizedString(key, comment: "Minutes"), Int(averageMinutes))
        } else {
            let hours = Int(averageMinutes / 60)
            let remainingMinutes = Int(averageMinutes.truncatingRemainder(dividingBy: 60))
            return String(format: NSLocalizedString("reading_history.hours_minutes", comment: "Hours and minutes"), hours, remainingMinutes)
        }
    }
    
    private var formattedAveragePerArticle: String {
        guard !records.isEmpty else { 
            let key = "reading_history.minute"
            return String(format: NSLocalizedString(key, comment: "Minutes"), 0)
        }
        let averageMinutes = records.reduce(0) { $0 + $1.duration / 60 } / Double(records.count)
        if averageMinutes < 60 {
            let key = averageMinutes == 1 ? "reading_history.minute" : "reading_history.minutes"
            return String(format: NSLocalizedString(key, comment: "Minutes"), Int(averageMinutes))
        } else {
            let hours = Int(averageMinutes / 60)
            let remainingMinutes = Int(averageMinutes.truncatingRemainder(dividingBy: 60))
            return String(format: NSLocalizedString("reading_history.hours_minutes", comment: "Hours and minutes"), hours, remainingMinutes)
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
                let minutes = Int(record.duration / 60)
                let key = minutes == 1 ? "reading_history.minute" : "reading_history.minutes"
                Label(String(format: NSLocalizedString(key, comment: "Minutes"), minutes), systemImage: "clock")
                
                Spacer()
                
                Text(record.startTime.formatted(.relative(presentation: .named)))
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
} 