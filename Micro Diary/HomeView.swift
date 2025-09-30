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
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                            
                            Button(action: {
                                showingEditView = true
                            }) {
                                Image(systemName: "pencil")
                                    .font(.system(size: 14))
                                    .foregroundColor(.blue)
                                    .padding(6)
                                    .background(Color.white)
                                    .clipShape(Circle())
                                    .shadow(color: .gray.opacity(0.3), radius: 2, x: 0, y: 1)
                            }
                            .offset(x: -8, y: -8)
                        }
                        
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
                    }
                } else {
                    // 今日未入力
                    VStack(spacing: 16) {
                        TextEditor(text: $todayText)
                            .font(.body)
                            .padding(16)
                            .frame(minHeight: 120)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.separator), lineWidth: 1)
                            )
                        
                        Text("\(todayText.count)/100")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        
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
                
                // 去年の今日
                LastYearTodayView()
                
                Spacer()
            }
            .padding(.horizontal, 16)
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

struct LastYearTodayView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest private var lastYearEntry: FetchedResults<Entry>
    
    init() {
        let lastYear = Calendar.current.date(byAdding: .year, value: -1, to: Date())!
        let lastYearToday = Calendar.current.startOfDay(for: lastYear)
        let lastYearTomorrow = Calendar.current.date(byAdding: .day, value: 1, to: lastYearToday)!
        
        _lastYearEntry = FetchRequest(
            sortDescriptors: [],
            predicate: NSPredicate(format: "date >= %@ AND date < %@", lastYearToday as CVarArg, lastYearTomorrow as CVarArg)
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("去年の今日")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if let entry = lastYearEntry.first {
                Text(entry.text ?? "")
                    .font(.body)
                    .foregroundColor(.primary)
            } else {
                Text("去年の今日の記録はありません")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(8)
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
