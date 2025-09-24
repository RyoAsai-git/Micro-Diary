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
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var cloudKitService = CloudKitService.shared
    @State private var notificationTime = Date()
    @State private var notificationsEnabled = true
    @State private var showingNotificationPermissionAlert = false
    @State private var showingPremiumPurchase = false
    @State private var showingSyncConfirmation = false
    
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
                        
                        Picker("", selection: $themeManager.currentTheme) {
                            ForEach(AppTheme.allCases, id: \.self) { theme in
                                Text(theme.displayName).tag(theme)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }
                
                // データ管理
                Section("データ管理") {
                    VStack(spacing: 12) {
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
                            
                            VStack(alignment: .trailing) {
                                Text(cloudKitService.iCloudStatusText)
                                    .font(.caption)
                                    .foregroundColor(cloudKitService.iCloudStatusColor)
                                
                                if cloudKitService.isSyncing {
                                    HStack {
                                        ProgressView()
                                            .scaleEffect(0.7)
                                        Text("同期中")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                } else if let lastSync = cloudKitService.lastSyncDate {
                                    Text("最終同期: \(lastSync, formatter: syncDateFormatter)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        
                        if let error = cloudKitService.syncError {
                            Text("同期エラー: \(error)")
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.leading)
                        }
                        
                        if cloudKitService.iCloudStatus == .available {
                            Button(action: {
                                showingSyncConfirmation = true
                            }) {
                                HStack {
                                    Image(systemName: "arrow.clockwise.icloud")
                                        .foregroundColor(.blue)
                                    
                                    Text("手動同期")
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    if cloudKitService.isSyncing {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            .disabled(cloudKitService.isSyncing)
                        }
                    }
                    .padding(.vertical, 4)
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
                                    Text("広告削除・テーマ変更・無制限編集")
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
        .alert("iCloud同期", isPresented: $showingSyncConfirmation) {
            Button("はい") {
                cloudKitService.forceSyncWithCloudKit()
            }
            Button("いいえ", role: .cancel) { }
        } message: {
            Text("いますぐ同期しますか？\n\nデータがiCloudと同期されます。")
        }
        .onAppear {
            loadNotificationSettings()
            cloudKitService.checkiCloudAccountStatus()
        }
    }
    
    private var syncDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
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
