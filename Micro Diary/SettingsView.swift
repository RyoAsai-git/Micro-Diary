//
//  SettingsView.swift
//  Micro Diary
//
//  Created by Ryo Asai on 2025/09/22.
//

import SwiftUI
import UserNotifications

struct SettingsView: View {
    @ObservedObject private var premiumService = PremiumService.shared
    @State private var notificationTime = Date()
    @State private var notificationsEnabled = true
    @State private var selectedTheme = 0 // 0: システム, 1: ライト, 2: ダーク
    @State private var showingNotificationPermissionAlert = false
    @State private var showingPremiumPurchase = false
    
    private let themes = ["システム", "ライト", "ダーク"]
    
    var body: some View {
        NavigationView {
            List {
                // 通知設定
                Section("通知設定") {
                    HStack {
                        Image(systemName: "bell")
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading) {
                            Text("毎日の通知")
                            Text("日記を書く時間をお知らせします")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $notificationsEnabled)
                    }
                    
                    if notificationsEnabled {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(.blue)
                            
                            Text("通知時間")
                            
                            Spacer()
                            
                            DatePicker("", selection: $notificationTime, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                        }
                    }
                }
                
                // 外観設定
                Section("外観") {
                    HStack {
                        Image(systemName: "paintbrush")
                            .foregroundColor(.purple)
                        
                        Text("テーマ")
                        
                        Spacer()
                        
                        Picker("テーマ", selection: $selectedTheme) {
                            ForEach(0..<themes.count, id: \.self) { index in
                                Text(themes[index]).tag(index)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }
                
                // データ管理
                Section("データ管理") {
                    HStack {
                        Image(systemName: "icloud")
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading) {
                            Text("iCloud同期")
                            Text("すべてのデバイスで日記を同期")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("有効")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    
                    Button(action: {}) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.orange)
                            
                            Text("データエクスポート")
                            
                            Spacer()
                            
                            Text("プレミアム")
                                .font(.caption)
                                .foregroundColor(.orange)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                    .foregroundColor(.primary)
                }
                
                // プレミアム
                Section("プレミアム") {
                    if premiumService.isPremiumUser {
                        HStack {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.gold)
                            
                            VStack(alignment: .leading) {
                                Text("プレミアムユーザー")
                                    .foregroundColor(.primary)
                                    .fontWeight(.medium)
                                Text("すべての機能をご利用いただけます")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                    } else {
                        Button(action: {
                            showingPremiumPurchase = true
                        }) {
                            HStack {
                                Image(systemName: "crown")
                                    .foregroundColor(.gold)
                                
                                VStack(alignment: .leading) {
                                    Text("プレミアムにアップグレード")
                                        .foregroundColor(.primary)
                                    Text("広告削除・テーマ変更・エクスポート機能")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                        }
                    }
                }
                
                // サポート・情報
                Section("サポート・情報") {
                    NavigationLink(destination: EmptyView()) {
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundColor(.gray)
                            Text("利用規約")
                        }
                    }
                    
                    NavigationLink(destination: EmptyView()) {
                        HStack {
                            Image(systemName: "hand.raised")
                                .foregroundColor(.gray)
                            Text("プライバシーポリシー")
                        }
                    }
                    
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.gray)
                        
                        Text("バージョン")
                        
                        Spacer()
                        
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            loadNotificationSettings()
        }
        .onChange(of: notificationsEnabled) { enabled in
            if enabled {
                requestNotificationPermission()
            } else {
                cancelNotifications()
            }
        }
        .onChange(of: notificationTime) { _ in
            if notificationsEnabled {
                scheduleNotification()
            }
        }
        .alert("通知許可が必要です", isPresented: $showingNotificationPermissionAlert) {
            Button("設定を開く") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("キャンセル", role: .cancel) {
                notificationsEnabled = false
            }
        } message: {
            Text("日記の通知を受け取るには、設定アプリで通知を許可してください。")
        }
        .sheet(isPresented: $showingPremiumPurchase) {
            PremiumPurchaseView()
        }
    }
    
    private func loadNotificationSettings() {
        // UserDefaultsから設定を読み込み
        let savedTime = UserDefaults.standard.object(forKey: "notificationTime") as? Date ?? {
            let calendar = Calendar.current
            var components = calendar.dateComponents([.year, .month, .day], from: Date())
            components.hour = 21
            components.minute = 0
            return calendar.date(from: components) ?? Date()
        }()
        
        notificationTime = savedTime
        notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        selectedTheme = UserDefaults.standard.integer(forKey: "selectedTheme")
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    UserDefaults.standard.set(true, forKey: "notificationsEnabled")
                    scheduleNotification()
                } else {
                    showingNotificationPermissionAlert = true
                }
            }
        }
    }
    
    private func scheduleNotification() {
        // 既存の通知をキャンセル
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // 新しい通知をスケジュール
        let content = UNMutableNotificationContent()
        content.title = "今日のひとこと"
        content.body = "今日の気持ちをひとこと残そう 🌙"
        content.sound = .default
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: notificationTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(identifier: "dailyReminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            } else {
                DispatchQueue.main.async {
                    UserDefaults.standard.set(notificationTime, forKey: "notificationTime")
                }
            }
        }
    }
    
    private func cancelNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UserDefaults.standard.set(false, forKey: "notificationsEnabled")
    }
}

// Color.gold extension is defined in PremiumService.swift

#Preview {
    SettingsView()
}
