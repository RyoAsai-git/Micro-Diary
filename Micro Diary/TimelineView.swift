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
            ZStack {
                GradientBackground()
                
                VStack(spacing: 0) {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            if groupedEntries.isEmpty {
                                // 投稿がない場合の表示
                                VStack(spacing: 16) {
                                    Spacer(minLength: 100)
                                    
                                    Image(systemName: "book.closed")
                                        .font(.system(size: 60))
                                        .foregroundColor(.secondary)
                                    
                                    Text("投稿がありません")
                                        .font(.title2)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                    
                                    Text("今日の気持ちを記録してみましょう")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                    
                                    Spacer(minLength: 100)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            } else {
                                ForEach(groupedEntries, id: \.key) { month, monthEntries in
                                    VStack(spacing: 0) {
                                        // セクションヘッダー
                                        HStack {
                                            Text(monthHeaderText(for: month))
                                                .font(.title2)
                                                .fontWeight(.bold)
                                                .foregroundColor(.primary)
                                            Spacer()
                                            Text("\(monthEntries.count)件")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(
                                                    Capsule()
                                                        .fill(Color.secondaryCardBackground)
                                                )
                                        }
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 12)
                                        
                                        // エントリー一覧
                                        LazyVStack(spacing: 12) {
                                            ForEach(monthEntries) { entry in
                                                NavigationLink(destination: EntryDetailView(entry: entry)) {
                                                    TimelineEntryRow(entry: entry)
                                                }
                                                .buttonStyle(PlainButtonStyle())
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.bottom, 24)
                                    }
                                }
                                
                            // バナー広告のための余白
                            Spacer(minLength: 120)
                            }
                        }
                        .padding(.top, 8)
                    }
                    .navigationTitle("タイムライン")
                    .navigationBarTitleDisplayMode(.large)
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
        VStack(alignment: .leading, spacing: 0) {
            // ヘッダー部分
            HStack(alignment: .center, spacing: 8) {
                // 日付
                Text(dateFormatter.string(from: entry.date ?? Date()))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // 満足度バッジ
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.caption2)
                        .foregroundColor(.white)
                    Text("\(entry.satisfactionScore)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(satisfactionColor)
                )
                
                // 編集済みインジケーター
                if entry.isEdited {
                    Image(systemName: "pencil.circle.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            .padding(.bottom, 8)
            
            // 本文
            Text(entry.text ?? "")
                .font(.body)
                .foregroundColor(.primary)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    private var satisfactionColor: Color {
        let score = Int(entry.satisfactionScore)
        switch score {
        case 0..<30:
            return Color.red.opacity(0.8)
        case 30..<50:
            return Color.orange.opacity(0.8)
        case 50..<70:
            return Color.yellow.opacity(0.8)
        case 70..<85:
            return Color.green.opacity(0.8)
        default:
            return Color.blue.opacity(0.8)
        }
    }
}

struct EntryDetailView: View {
    let entry: Entry
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    @ObservedObject private var premiumService = PremiumService.shared
    @State private var showingEditView = false
    @State private var showingPremiumPrompt = false
    @FetchRequest private var lastYearEntry: FetchedResults<Entry>
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日 (E)"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }
    
    // 今日の日付（日のみ）
    private var today: Date {
        Calendar.current.startOfDay(for: Date())
    }
    
    // 当日投稿かどうかを判定
    private var isToday: Bool {
        guard let entryDate = entry.date else { return false }
        return Calendar.current.isDate(entryDate, inSameDayAs: today)
    }
    
    // 編集可能かどうかを判定
    private var canEdit: Bool {
        return isToday || premiumService.canEditPastEntries()
    }
    
    private var satisfactionColor: Color {
        let score = Int(entry.satisfactionScore)
        switch score {
        case 0..<30:
            return Color.red.opacity(0.8)
        case 30..<50:
            return Color.orange.opacity(0.8)
        case 50..<70:
            return Color.yellow.opacity(0.8)
        case 70..<85:
            return Color.green.opacity(0.8)
        default:
            return Color.blue.opacity(0.8)
        }
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
        ZStack {
            GradientBackground()
            
            ScrollView {
                VStack(spacing: 24) {
                    // ヘッダーカード
                    VStack(spacing: 16) {
                        // 日付
                        Text(dateFormatter.string(from: entry.date ?? Date()))
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        // 満足度バッジ
                        HStack(spacing: 8) {
                            Image(systemName: "heart.fill")
                                .font(.title3)
                                .foregroundColor(.white)
                            Text("\(Int(entry.satisfactionScore))")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            Text("/ 100")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(satisfactionColor)
                        )
                        
                        // 編集済みバッジ
                        if entry.isEdited {
                            HStack(spacing: 4) {
                                Image(systemName: "pencil.circle.fill")
                                    .font(.caption)
                                Text("編集済み")
                                    .font(.caption)
                            }
                            .foregroundColor(.orange)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.orange.opacity(0.1))
                            )
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.cardBackground)
                            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                    )
                    
                    // メインテキストカード
                    VStack(alignment: .leading, spacing: 0) {
                        Text(entry.text ?? "")
                            .font(.body)
                            .lineSpacing(4)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.cardBackground)
                            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                    )
                    
                    // 去年の今日カード
                    if let lastYearEntry = lastYearEntry.first {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.title3)
                                    .foregroundColor(.purple)
                                Text("去年の今日")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            
                            Text(lastYearEntry.text ?? "")
                                .font(.body)
                                .lineSpacing(4)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.purple.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
            }
        }
        .navigationTitle("日記")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            VStack {
                Divider()
                
                if canEdit {
                    Button(action: {
                        showingEditView = true
                    }) {
                        HStack {
                            Image(systemName: "pencil")
                                .font(.system(size: 16))
                            Text("編集")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                } else if !isToday {
                    Button(action: {
                        showingPremiumPrompt = true
                    }) {
                        HStack {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 16))
                            Text("プレミアムで編集")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.orange)
                        .cornerRadius(12)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .sheet(isPresented: $showingEditView) {
            EditEntryView(entry: entry)
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(isPresented: $showingPremiumPrompt) {
            PremiumPurchaseView()
        }
    }
}

#Preview {
    TimelineView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

#Preview("TimelineEntryRow") {
    let context = PersistenceController.preview.container.viewContext
    let entry = Entry(context: context)
    entry.id = UUID()
    entry.date = Date()
    entry.text = "今日は良い天気でした"
    entry.createdAt = Date()
    entry.isEdited = false
    
    return TimelineEntryRow(entry: entry)
        .padding()
}
