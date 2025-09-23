//
//  MicroDiaryWidget.swift
//  Micro Diary
//
//  Created by Ryo Asai on 2025/09/22.
//
//  Note: This file contains the Widget implementation.
//  To use this, you need to create a Widget Extension target in Xcode.

import WidgetKit
import SwiftUI
import CoreData

struct MicroDiaryWidget: Widget {
    let kind: String = "MicroDiaryWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            MicroDiaryWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("マイクロ日記")
        .description("今日のひとことを確認・入力できます")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), todayEntry: nil, lastYearEntry: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), todayEntry: nil, lastYearEntry: nil)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        let currentDate = Date()
        let todayEntry = fetchTodayEntry()
        let lastYearEntry = fetchLastYearEntry()
        
        let entry = SimpleEntry(
            date: currentDate,
            todayEntry: todayEntry,
            lastYearEntry: lastYearEntry
        )

        // 1時間後に更新
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func fetchTodayEntry() -> String? {
        let container = NSPersistentCloudKitContainer(name: "Micro_Diary")
        container.loadPersistentStores { _, error in
            if let error = error {
                print("Core Data error: \(error)")
            }
        }
        
        let context = container.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: "Entry")
        
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", today as CVarArg, tomorrow as CVarArg)
        request.fetchLimit = 1
        
        do {
            let entries = try context.fetch(request)
            return entries.first?.value(forKey: "text") as? String
        } catch {
            print("Error fetching today's entry: \(error)")
            return nil
        }
    }
    
    private func fetchLastYearEntry() -> String? {
        let container = NSPersistentCloudKitContainer(name: "Micro_Diary")
        container.loadPersistentStores { _, error in
            if let error = error {
                print("Core Data error: \(error)")
            }
        }
        
        let context = container.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: "Entry")
        
        let lastYear = Calendar.current.date(byAdding: .year, value: -1, to: Date())!
        let lastYearToday = Calendar.current.startOfDay(for: lastYear)
        let lastYearTomorrow = Calendar.current.date(byAdding: .day, value: 1, to: lastYearToday)!
        
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", lastYearToday as CVarArg, lastYearTomorrow as CVarArg)
        request.fetchLimit = 1
        
        do {
            let entries = try context.fetch(request)
            return entries.first?.value(forKey: "text") as? String
        } catch {
            print("Error fetching last year's entry: \(error)")
            return nil
        }
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let todayEntry: String?
    let lastYearEntry: String?
}

struct MicroDiaryWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

struct SmallWidgetView: View {
    let entry: SimpleEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("📒")
                    .font(.title2)
                Spacer()
                Text(entry.date, style: .date)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let todayEntry = entry.todayEntry {
                Text(todayEntry)
                    .font(.caption)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            } else {
                Text("今日のひとことを書こう！")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
            
            Spacer()
        }
        .padding(12)
        .background(Color(.systemBackground))
    }
}

struct MediumWidgetView: View {
    let entry: SimpleEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("📒 マイクロ日記")
                    .font(.headline)
                    .fontWeight(.medium)
                Spacer()
                Text(entry.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("今日")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                
                if let todayEntry = entry.todayEntry {
                    Text(todayEntry)
                        .font(.body)
                        .lineLimit(2)
                } else {
                    Text("今日のひとことを書こう！")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
            
            if let lastYearEntry = entry.lastYearEntry {
                VStack(alignment: .leading, spacing: 4) {
                    Text("去年の今日")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                    
                    Text(lastYearEntry)
                        .font(.caption)
                        .lineLimit(2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color(.systemBackground))
    }
}

#Preview("Small", as: .systemSmall) {
    MicroDiaryWidget()
} timeline: {
    SimpleEntry(date: .now, todayEntry: "今日は良い天気でした", lastYearEntry: nil)
}

#Preview("Medium", as: .systemMedium) {
    MicroDiaryWidget()
} timeline: {
    SimpleEntry(date: .now, todayEntry: "今日は良い天気でした", lastYearEntry: "去年は雨でした")
}
