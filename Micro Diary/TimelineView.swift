//
//  TimelineView.swift
//  Micro Diary
//
//  Created by Ryo Asai on 2025/09/22.
//

import SwiftUI
import CoreData

struct TimelineView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject private var adService = AdService.shared
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Entry.date, ascending: false)],
        animation: .default
    ) private var entries: FetchedResults<Entry>
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                List {
                    ForEach(groupedEntries, id: \.key) { month, monthEntries in
                        Section(header: Text(monthHeaderText(for: month))) {
                            ForEach(monthEntries) { entry in
                                NavigationLink(destination: EntryDetailView(entry: entry)) {
                                    TimelineEntryRow(entry: entry)
                                }
                            }
                        }
                    }
                }
                .navigationTitle("タイムライン")
                .navigationBarTitleDisplayMode(.large)
                
                // バナー広告（プレミアムユーザーでない場合のみ表示）
                if !adService.isPremiumUser {
                    BannerAdView()
                }
            }
        }
    }
    
    private var groupedEntries: [(key: String, value: [Entry])] {
        let grouped = Dictionary(grouping: entries) { entry in
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM"
            return formatter.string(from: entry.date ?? Date())
        }
        return grouped.sorted { $0.key > $1.key }
    }
    
    private func monthHeaderText(for monthKey: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        guard let date = formatter.date(from: monthKey) else { return monthKey }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "yyyy年M月"
        return displayFormatter.string(from: date)
    }
}

struct TimelineEntryRow: View {
    let entry: Entry
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d (E)"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(dateFormatter.string(from: entry.date ?? Date()))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if entry.isEdited {
                    Image(systemName: "pencil")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            Text(entry.text ?? "")
                .font(.body)
                .foregroundColor(.primary)
                .lineLimit(3)
        }
        .padding(.vertical, 4)
    }
}

struct EntryDetailView: View {
    let entry: Entry
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    @FetchRequest private var lastYearEntry: FetchedResults<Entry>
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日 (E)"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }
    
    init(entry: Entry) {
        self.entry = entry
        
        // 去年の同じ日のエントリを取得
        let entryDate = entry.date ?? Date()
        let lastYear = Calendar.current.date(byAdding: .year, value: -1, to: entryDate)!
        let lastYearDay = Calendar.current.startOfDay(for: lastYear)
        let lastYearNextDay = Calendar.current.date(byAdding: .day, value: 1, to: lastYearDay)!
        
        _lastYearEntry = FetchRequest(
            sortDescriptors: [],
            predicate: NSPredicate(format: "date >= %@ AND date < %@", lastYearDay as CVarArg, lastYearNextDay as CVarArg)
        )
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 日付
                Text(dateFormatter.string(from: entry.date ?? Date()))
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                // メインテキスト
                Text(entry.text ?? "")
                    .font(.title3)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .padding(20)
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                
                // 去年の今日
                if let lastYearEntry = lastYearEntry.first {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("去年の今日")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text(lastYearEntry.text ?? "")
                            .font(.body)
                            .foregroundColor(.primary)
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.tertiarySystemBackground))
                            .cornerRadius(8)
                    }
                }
                
                Spacer(minLength: 32)
            }
            .padding(16)
        }
        .navigationTitle("日記")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    TimelineView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
