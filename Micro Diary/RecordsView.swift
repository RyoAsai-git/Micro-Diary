//
//  RecordsView.swift
//  Micro Diary
//
//  Created by Ryo Asai on 2025/09/29.
//

import SwiftUI
import CoreData
import Charts

struct RecordsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject private var premiumService = PremiumService.shared
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Entry.date, ascending: true)],
        animation: .default
    ) private var entries: FetchedResults<Entry>
    
    @State private var selectedPeriod: TimePeriod = .week
    @State private var showingPastRecords = false
    @State private var showingPremiumPrompt = false
    
    enum TimePeriod: String, CaseIterable {
        case week = "1週間"
        case month = "1ヶ月"
        case threeMonths = "3ヶ月"
        case year = "1年"
        
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .threeMonths: return 90
            case .year: return 365
            }
        }
    }
    
    private var filteredEntries: [Entry] {
        let calendar = Calendar.current
        let endDate = calendar.startOfDay(for: Date())
        let startDate = calendar.date(byAdding: .day, value: -selectedPeriod.days + 1, to: endDate) ?? endDate
        
        return entries.filter { entry in
            guard let entryDate = entry.date else { return false }
            return entryDate >= startDate && entryDate <= endDate
        }
    }
    
    private var averageSatisfaction: Double {
        guard !filteredEntries.isEmpty else { return 0 }
        let total = filteredEntries.reduce(0) { $0 + Int($1.satisfactionScore) }
        return Double(total) / Double(filteredEntries.count)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                GradientBackground()
                
                ScrollView {
                VStack(spacing: 24) {
                    // 期間選択
                    Picker("期間", selection: $selectedPeriod) {
                        ForEach(TimePeriod.allCases, id: \.self) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal, 16)
                    
                    // 統計カード
                    StatsOverviewView(
                        entries: filteredEntries,
                        averageSatisfaction: averageSatisfaction
                    )
                    
                    // 満足度グラフ
                    SatisfactionChartView(entries: filteredEntries, period: selectedPeriod)
                    
                    // 過去の記録セクション
                    PastRecordsSection(
                        totalEntries: entries.count,
                        onTapped: {
                            showingPastRecords = true
                        }
                    )
                    
                    Spacer(minLength: 32)
                }
                .padding(.top, 16)
                }
            }
            .navigationTitle("記録")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingPastRecords) {
            PastRecordsDetailView()
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(isPresented: $showingPremiumPrompt) {
            PremiumPurchaseView()
        }
    }
}

struct PastRecordsSection: View {
    let totalEntries: Int
    let onTapped: () -> Void
    
    var body: some View {
        Button(action: onTapped) {
            VStack(spacing: 16) {
                HStack {
                    Text("過去の記録")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("総記録数")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("\(totalEntries)件")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    Text("詳細を見る")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .padding(16)
            .background(Color.cardBackground)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 16)
    }
}

struct StatsOverviewView: View {
    let entries: [Entry]
    let averageSatisfaction: Double
    
    var body: some View {
        VStack(spacing: 16) {
            Text("統計情報")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 16) {
                StatCardView(
                    title: "記録日数",
                    value: "\(entries.count)",
                    unit: "日",
                    icon: "calendar.badge.plus",
                    color: .blue
                )
                
                StatCardView(
                    title: "平均満足度",
                    value: String(format: "%.1f", averageSatisfaction),
                    unit: "点",
                    icon: "heart.fill",
                    color: .red
                )
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal, 16)
    }
}

struct StatCardView: View {
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
        .cornerRadius(8)
    }
}

struct SatisfactionChartView: View {
    let entries: [Entry]
    let period: RecordsView.TimePeriod
    
    private var chartData: [ChartDataPoint] {
        let calendar = Calendar.current
        let endDate = calendar.startOfDay(for: Date())
        let startDate = calendar.date(byAdding: .day, value: -period.days + 1, to: endDate) ?? endDate
        
        var dataPoints: [ChartDataPoint] = []
        var currentDate = startDate
        
        while currentDate <= endDate {
            let entry = entries.first { entry in
                guard let entryDate = entry.date else { return false }
                return calendar.isDate(entryDate, inSameDayAs: currentDate)
            }
            
            let score = entry?.satisfactionScore ?? 0
            dataPoints.append(ChartDataPoint(
                date: currentDate,
                satisfaction: Int(score),
                hasEntry: entry != nil
            ))
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return dataPoints
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("満足度の推移")
                    .font(.headline)
                
                Spacer()
            }
            
            Chart(chartData, id: \.date) { dataPoint in
                if dataPoint.hasEntry {
                    LineMark(
                        x: .value("日付", dataPoint.date),
                        y: .value("満足度", dataPoint.satisfaction)
                    )
                    .foregroundStyle(.blue)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    
                    PointMark(
                        x: .value("日付", dataPoint.date),
                        y: .value("満足度", dataPoint.satisfaction)
                    )
                    .foregroundStyle(.blue)
                    .symbolSize(30)
                }
            }
            .frame(height: 200)
            .chartYScale(domain: 0...100)
            .chartXAxis {
                AxisMarks(values: .stride(by: period == .week ? .day : .weekOfYear)) { value in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                }
            }
            .chartYAxis {
                AxisMarks(values: [0, 25, 50, 75, 100]) { value in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal, 16)
    }
}

struct ChartDataPoint {
    let date: Date
    let satisfaction: Int
    let hasEntry: Bool
}

#Preview {
    RecordsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
