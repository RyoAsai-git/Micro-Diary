//
//  BadgeView.swift
//  Micro Diary
//
//  Created by Ryo Asai on 2025/09/22.
//

import SwiftUI
import CoreData

struct BadgeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Entry.date, ascending: false)],
        animation: .default
    ) private var entries: FetchedResults<Entry>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Badge.earnedAt, ascending: false)],
        animation: .default
    ) private var badges: FetchedResults<Badge>
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 統計情報
                    StatsCardView(entries: entries)
                    
                    // バッジ一覧
                    BadgeGridView(badges: badges, entries: entries)
                    
                    Spacer(minLength: 32)
                }
                .padding(16)
            }
            .navigationTitle("バッジ")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            checkAndAwardBadges()
        }
    }
    
    private func checkAndAwardBadges() {
        let streakCount = calculateCurrentStreak()
        let totalCount = entries.count
        
        // 連続記録バッジ
        awardBadgeIfNeeded(type: "7days", condition: streakCount >= 7)
        awardBadgeIfNeeded(type: "30days", condition: streakCount >= 30)
        awardBadgeIfNeeded(type: "100days", condition: streakCount >= 100)
        
        // 累計記録バッジ
        awardBadgeIfNeeded(type: "total50", condition: totalCount >= 50)
        awardBadgeIfNeeded(type: "total100", condition: totalCount >= 100)
        awardBadgeIfNeeded(type: "total365", condition: totalCount >= 365)
    }
    
    private func awardBadgeIfNeeded(type: String, condition: Bool) {
        guard condition else { return }
        
        // 既に獲得済みかチェック
        let existingBadge = badges.first { $0.type == type }
        guard existingBadge == nil else { return }
        
        // バッジを作成
        let badge = Badge(context: viewContext)
        badge.id = UUID()
        badge.type = type
        badge.earnedAt = Date()
        
        do {
            try viewContext.save()
        } catch {
            print("Error saving badge: \(error)")
        }
    }
    
    private func calculateCurrentStreak() -> Int {
        guard !entries.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())
        
        // 今日のエントリがあるかチェック
        let todayEntry = entries.first { entry in
            guard let entryDate = entry.date else { return false }
            return calendar.isDate(entryDate, inSameDayAs: currentDate)
        }
        
        if todayEntry == nil {
            // 今日のエントリがない場合は昨日から開始
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
        }
        
        // 連続記録をカウント
        while true {
            let entryForDate = entries.first { entry in
                guard let entryDate = entry.date else { return false }
                return calendar.isDate(entryDate, inSameDayAs: currentDate)
            }
            
            if entryForDate != nil {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else {
                break
            }
        }
        
        return streak
    }
}

struct StatsCardView: View {
    let entries: FetchedResults<Entry>
    
    private var currentStreak: Int {
        // BadgeViewの計算ロジックを再利用（簡略化）
        guard !entries.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())
        
        let todayEntry = entries.first { entry in
            guard let entryDate = entry.date else { return false }
            return calendar.isDate(entryDate, inSameDayAs: currentDate)
        }
        
        if todayEntry == nil {
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
        }
        
        while true {
            let entryForDate = entries.first { entry in
                guard let entryDate = entry.date else { return false }
                return calendar.isDate(entryDate, inSameDayAs: currentDate)
            }
            
            if entryForDate != nil {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else {
                break
            }
        }
        
        return streak
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("記録統計")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 16) {
                StatItemView(
                    title: "連続記録",
                    value: "\(currentStreak)",
                    unit: "日",
                    icon: "flame.fill",
                    color: .orange
                )
                
                StatItemView(
                    title: "総記録数",
                    value: "\(entries.count)",
                    unit: "日",
                    icon: "calendar.badge.plus",
                    color: .blue
                )
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct StatItemView: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(alignment: .bottom, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(8)
    }
}

struct BadgeGridView: View {
    let badges: FetchedResults<Badge>
    let entries: FetchedResults<Entry>
    
    private let badgeTypes: [(type: String, title: String, description: String, icon: String, color: Color)] = [
        ("7days", "1週間", "7日連続記録", "7.circle.fill", .green),
        ("30days", "1ヶ月", "30日連続記録", "30.circle.fill", .blue),
        ("100days", "100日", "100日連続記録", "100.circle.fill", .purple),
        ("total50", "50日達成", "累計50日記録", "50.square.fill", .orange),
        ("total100", "100日達成", "累計100日記録", "100.square.fill", .red),
        ("total365", "1年達成", "累計365日記録", "365.square.fill", .gold)
    ]
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(spacing: 16) {
            Text("獲得バッジ")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(badgeTypes, id: \.type) { badgeType in
                    BadgeItemView(
                        badgeType: badgeType,
                        isEarned: badges.contains { $0.type == badgeType.type }
                    )
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct BadgeItemView: View {
    let badgeType: (type: String, title: String, description: String, icon: String, color: Color)
    let isEarned: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: badgeType.icon)
                .font(.title)
                .foregroundColor(isEarned ? badgeType.color : .gray)
                .scaleEffect(isEarned ? 1.0 : 0.8)
            
            Text(badgeType.title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isEarned ? .primary : .secondary)
            
            Text(badgeType.description)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(8)
        .opacity(isEarned ? 1.0 : 0.6)
    }
}

// Color.gold extension moved to PremiumService.swift to avoid duplication

#Preview {
    BadgeView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
