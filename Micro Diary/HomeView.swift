//
//  HomeView.swift
//  Micro Diary
//
//  Created by Ryo Asai on 2025/09/22.
//

import SwiftUI
import CoreData

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject private var adService = AdService.shared
    
    @State private var todayText: String = ""
    @State private var satisfactionScore: Double = 50
    @State private var showCompletionAnimation = false
    @State private var hasEntryToday = false
    @State private var showingEditView = false
    
    // 今日の日付（日のみ）
    private var today: Date {
        Calendar.current.startOfDay(for: Date())
    }
    
    // 今日のエントリを取得
    @FetchRequest private var todayEntry: FetchedResults<Entry>
    
    init() {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        _todayEntry = FetchRequest(
            sortDescriptors: [],
            predicate: NSPredicate(format: "date >= %@ AND date < %@", today as CVarArg, tomorrow as CVarArg)
        )
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                GradientBackground()
                
                VStack(spacing: 32) {
                // 日付表示
                VStack(spacing: 8) {
                    Text(today, style: .date)
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Text("今日の気持ちをひとこと残そう")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                .padding(.top, 32)
                
                // 入力フィールドまたは表示フィールド
                if let entry = todayEntry.first {
                    // 今日既に入力済み
                    VStack(spacing: 16) {
                        ZStack(alignment: .bottomTrailing) {
                            Text(entry.text ?? "")
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .padding(16)
                                .frame(maxWidth: .infinity)
                                .frame(minHeight: 120)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.cardBackground)
                                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                                )
                            
                            Button(action: {
                                showingEditView = true
                            }) {
                                Image(systemName: "pencil")
                                    .font(.system(size: 14))
                                    .foregroundColor(.blue)
                                    .padding(8)
                                    .background(
                                        Circle()
                                            .fill(Color.cardBackground)
                                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                                    )
                            }
                            .offset(x: -8, y: -8)
                        }
                        
                        // 満足度表示
                        VStack(spacing: 8) {
                            Text("今日の満足度")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Text("\(Int(entry.satisfactionScore))")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                Text("/ 100")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity)
                        .background(Color.secondaryCardBackground)
                        .cornerRadius(8)
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("今日のひとことを記録しました ✓")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                if entry.isEdited {
                                    Text("編集済み")
                                        .font(.caption2)
                                        .foregroundColor(.orange)
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.secondaryCardBackground)
                        )
                    }
                } else {
                    // 今日未入力
                    VStack(spacing: 16) {
                        TextEditor(text: $todayText)
                            .font(.body)
                            .padding(16)
                            .frame(minHeight: 120)
                            .background(Color.cardBackground)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.separator), lineWidth: 1)
                            )
                        
                        Text("\(todayText.count)/100")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        
                        // 満足度スライダー
                        VStack(spacing: 12) {
                            HStack {
                                Text("今日の満足度")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text("\(Int(satisfactionScore)) / 100")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Slider(value: $satisfactionScore, in: 0...100, step: 1)
                                .accentColor(.blue)
                            
                            HStack {
                                Text("0")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text("50")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text("100")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(16)
                        .background(Color.secondaryCardBackground)
                        .cornerRadius(12)
                        
                        Button(action: saveTodayEntry) {
                            Text("保存")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(width: 160, height: 44)
                                .background(todayText.isEmpty ? Color.gray : Color.blue)
                                .cornerRadius(8)
                        }
                        .disabled(todayText.isEmpty || todayText.count > 100)
                    }
                }
                
                // 過去の記録
                PastRecordView()
                
                Spacer()
                }
                .padding(.horizontal, 16)
                
                // バナー広告（Safe Areaを考慮）
                VStack {
                    Spacer()
                    AdBannerView()
                        .frame(height: 60)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                }
            }
            .navigationTitle("今日のひとこと")
            .navigationBarTitleDisplayMode(.inline)
        }
        .overlay(
            // 完了アニメーション
            Group {
                if showCompletionAnimation {
                    CompletionAnimationView()
                        .transition(.opacity)
                }
            }
        )
        .sheet(isPresented: $adService.isShowingInterstitialAd) {
            InterstitialAdView(isPresented: $adService.isShowingInterstitialAd)
        }
        .sheet(isPresented: $showingEditView) {
            if let entry = todayEntry.first {
                EditEntryView(entry: entry)
                    .environment(\.managedObjectContext, viewContext)
            }
        }
        .onAppear {
            adService.initializeAds()
        }
    }
    
    private func saveTodayEntry() {
        guard !todayText.isEmpty && todayText.count <= 100 else { return }
        
        let entry = Entry(context: viewContext)
        entry.id = UUID()
        entry.date = today
        entry.text = todayText
        entry.satisfactionScore = Int16(satisfactionScore)
        entry.createdAt = Date()
        entry.isEdited = false
        
        do {
            try viewContext.save()
            showCompletionAnimation = true
            
            // インタースティシャル広告を表示するかチェック
            if adService.shouldShowInterstitialAd() {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    adService.showInterstitialAd()
                }
            }
            
            // アニメーション後に非表示
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    showCompletionAnimation = false
                }
            }
        } catch {
            print("Error saving entry: \(error)")
        }
    }
}

struct PastRecordView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedPeriod: TimePeriod = .year
    
    enum TimePeriod: String, CaseIterable {
        case yesterday = "昨日"
        case threeDays = "3日前"
        case week = "1週間前"
        case month = "1ヶ月前"
        case threeMonths = "3ヶ月前"
        case halfYear = "半年前"
        case year = "1年前"
        
        var days: Int {
            switch self {
            case .yesterday: return 1
            case .threeDays: return 3
            case .week: return 7
            case .month: return 30
            case .threeMonths: return 90
            case .halfYear: return 180
            case .year: return 365
            }
        }
        
        var displayTitle: String {
            switch self {
            case .yesterday: return "昨日の記録"
            case .threeDays: return "3日前の記録"
            case .week: return "1週間前の記録"
            case .month: return "1ヶ月前の記録"
            case .threeMonths: return "3ヶ月前の記録"
            case .halfYear: return "半年前の記録"
            case .year: return "1年前の記録"
            }
        }
    }
    
    @FetchRequest private var pastEntries: FetchedResults<Entry>
    
    init() {
        // 初期値として1年前のエントリを取得
        let pastDate = Calendar.current.date(byAdding: .day, value: -365, to: Date())!
        let pastDay = Calendar.current.startOfDay(for: pastDate)
        let pastNextDay = Calendar.current.date(byAdding: .day, value: 1, to: pastDay)!
        
        _pastEntries = FetchRequest(
            sortDescriptors: [],
            predicate: NSPredicate(format: "date >= %@ AND date < %@", pastDay as CVarArg, pastNextDay as CVarArg)
        )
    }
    
    private func updateFetchRequest() {
        let pastDate = Calendar.current.date(byAdding: .day, value: -selectedPeriod.days, to: Date())!
        let pastDay = Calendar.current.startOfDay(for: pastDate)
        let pastNextDay = Calendar.current.date(byAdding: .day, value: 1, to: pastDay)!
        
        pastEntries.nsPredicate = NSPredicate(format: "date >= %@ AND date < %@", pastDay as CVarArg, pastNextDay as CVarArg)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // セクションタイトル
            Text("過去の記録")
                .font(.headline)
                .foregroundColor(.primary)
            
            // 期間選択タブ（スクロール可能）
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(TimePeriod.allCases, id: \.self) { period in
                        Button(action: {
                            selectedPeriod = period
                            updateFetchRequest()
                        }) {
                            Text(period.rawValue)
                                .font(.caption)
                                .fontWeight(selectedPeriod == period ? .semibold : .regular)
                                .foregroundColor(selectedPeriod == period ? .white : .primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(selectedPeriod == period ? Color.blue : Color(.secondarySystemBackground))
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 2)
            }
            
            // 記録表示エリア
            VStack(alignment: .leading, spacing: 8) {
                Text(selectedPeriod.displayTitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let entry = pastEntries.first {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(entry.text ?? "")
                            .font(.body)
                            .foregroundColor(.primary)
                        
                        // 満足度表示
                        HStack {
                            Text("満足度:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("\(Int(entry.satisfactionScore))/100")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if entry.isEdited {
                                Text("編集済み")
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                } else {
                    Text("\(selectedPeriod.displayTitle.replacingOccurrences(of: "の記録", with: ""))の記録はありません")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.8))
            .cornerRadius(8)
        }
        .onAppear {
            updateFetchRequest()
        }
    }
}

struct CompletionAnimationView: View {
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                    .scaleEffect(scale)
                    .opacity(opacity)
                
                Text("保存しました！")
                    .font(.headline)
                    .foregroundColor(.white)
                    .opacity(opacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}

#Preview {
    HomeView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
