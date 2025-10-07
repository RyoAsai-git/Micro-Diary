//
//  SettingsView.swift
//  Micro Diary
//
//  Created by Ryo Asai on 2025/09/22.
//

import SwiftUI
import UserNotifications
import MessageUI

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
            ZStack {
                GradientBackground()
                
                ScrollView {
                    VStack(spacing: 24) {
                        NotificationSection(
                            notificationsEnabled: $notificationsEnabled,
                            notificationTime: $notificationTime
                        )
                        
                        PremiumSection(
                            isPremium: premiumService.isPremiumUser,
                            onPremiumTapped: { showingPremiumPurchase = true }
                        )
                        
                        CloudSyncSection(
                            iCloudAvailable: cloudKitService.iCloudAvailable,
                            iCloudStatusText: cloudKitService.iCloudStatusText,
                            lastSyncDate: cloudKitService.lastSyncDate,
                            syncDateFormatter: syncDateFormatter,
                            onSyncTapped: { showingSyncConfirmation = true }
                        )
                        
                        ThemeSection(currentTheme: $themeManager.currentTheme)
                        
                        SupportSection()
                        
                        Spacer(minLength: 32)
                        
                        // バナー広告のための余白
                        Spacer(minLength: 120)
                    }
                    .padding(.top, 16)
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
        
        let content = UNMutableNotificationContent()
        content.title = "今日の日記を書きましょう"
        content.body = "今日はどんな一日でしたか？"
        content.sound = .default
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: notificationTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(identifier: "dailyDiary", content: content, trigger: trigger)
        
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

// MARK: - Section Views

struct NotificationSection: View {
    @Binding var notificationsEnabled: Bool
    @Binding var notificationTime: Date
    
    var body: some View {
        VStack(spacing: 12) {
            // セクションタイトル
            HStack {
                Text("通知設定")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal, 16)
            
            // 通知設定カード
            VStack(spacing: 16) {
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
            .padding(16)
            .background(Color.cardBackground)
            .cornerRadius(12)
        }
        .padding(.horizontal, 16)
    }
}

struct PremiumSection: View {
    let isPremium: Bool
    let onPremiumTapped: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // セクションタイトル
            HStack {
                Text("プレミアム")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal, 16)
            
            // プレミアムカード
            if isPremium {
                HStack {
                    Image(systemName: "crown.fill")
                        .foregroundColor(.gold)
                    
                    VStack(alignment: .leading) {
                        Text("プレミアム会員")
                        Text("すべての機能をご利用いただけます")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("✓")
                        .foregroundColor(.gold)
                        .fontWeight(.bold)
                }
                .padding(16)
                .background(Color.cardBackground)
                .cornerRadius(12)
            } else {
                Button(action: onPremiumTapped) {
                    HStack {
                        Image(systemName: "crown")
                            .foregroundColor(.gold)
                        
                        VStack(alignment: .leading) {
                            Text("プレミアムにアップグレード")
                            Text("すべての機能を解放")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(16)
                    .background(Color.cardBackground)
                    .cornerRadius(12)
                }
                .foregroundColor(.primary)
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 16)
    }
}

struct CloudSyncSection: View {
    let iCloudAvailable: Bool
    let iCloudStatusText: String
    let lastSyncDate: Date?
    let syncDateFormatter: DateFormatter
    let onSyncTapped: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // セクションタイトル
            HStack {
                Text("データ同期")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal, 16)
            
            // 同期設定カード
            VStack(spacing: 16) {
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
                        Text(iCloudStatusText)
                            .font(.caption)
                            .foregroundColor(iCloudAvailable ? .green : .red)
                        
                        if let lastSync = lastSyncDate {
                            Text("最終同期: \(syncDateFormatter.string(from: lastSync))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                if iCloudAvailable {
                    Button("今すぐ同期") {
                        onSyncTapped()
                    }
                    .foregroundColor(.blue)
                }
            }
            .padding(16)
            .background(Color.cardBackground)
            .cornerRadius(12)
        }
        .padding(.horizontal, 16)
    }
}

struct ThemeSection: View {
    @Binding var currentTheme: AppTheme
    
    var body: some View {
        VStack(spacing: 12) {
            // セクションタイトル
            HStack {
                Text("表示設定")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal, 16)
            
            // テーマ設定カード
            HStack {
                Image(systemName: "paintbrush")
                    .foregroundColor(.blue)
                
                Text("テーマ")
                
                Spacer()
                
                Picker("テーマ", selection: $currentTheme) {
                    ForEach(AppTheme.allCases, id: \.self) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            .padding(16)
            .background(Color.cardBackground)
            .cornerRadius(12)
        }
        .padding(.horizontal, 16)
    }
}

struct SupportSection: View {
    @State private var showingMailComposer = false
    @State private var showingAppStoreRating = false
    @State private var showingRatingAlert = false
    @State private var showingMailUnavailableAlert = false
    
    var body: some View {
        VStack(spacing: 12) {
            // セクションタイトル
            HStack {
                Text("サポート・情報")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal, 16)
            
            // サポート項目カード
            VStack(spacing: 16) {
                Button(action: {
                    if MFMailComposeViewController.canSendMail() {
                        showingMailComposer = true
                    } else {
                        showingMailUnavailableAlert = true
                    }
                }) {
                    HStack {
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(.blue)
                        
                        Text("ヘルプ・サポート")
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .foregroundColor(.primary)
                .buttonStyle(PlainButtonStyle())
                
                Divider()
                
                Button(action: {
                    showingAppStoreRating = true
                }) {
                    HStack {
                        Image(systemName: "star")
                            .foregroundColor(.blue)
                        
                        Text("アプリを評価")
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .foregroundColor(.primary)
                .buttonStyle(PlainButtonStyle())
                
                Divider()
                
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                    
                    Text("バージョン")
                    
                    Spacer()
                    
                    Text(appVersion)
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .background(Color.cardBackground)
            .cornerRadius(12)
        }
        .padding(.horizontal, 16)
        .sheet(isPresented: $showingMailComposer) {
            MailComposerView()
        }
        .alert("アプリを評価", isPresented: $showingRatingAlert) {
            Button("App Storeで評価") {
                openAppStoreForRating()
            }
            Button("キャンセル", role: .cancel) { }
        } message: {
            Text("App StoreでMicro Diaryを評価していただけますか？\n\n評価は開発の励みになります。")
        }
        .onChange(of: showingAppStoreRating) { showing in
            if showing {
                showingRatingAlert = true
                showingAppStoreRating = false
            }
        }
        .alert("メールが利用できません", isPresented: $showingMailUnavailableAlert) {
            Button("OK") { }
        } message: {
            Text("メールアプリが設定されていません。\n\nサポート: support@microdiary.app")
        }
    }
    
    private var appVersion: String {
        guard let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            return "1.0.0"
        }
        
        // バージョン番号の形式を正規化
        let components = version.split(separator: ".").map(String.init)
        
        switch components.count {
        case 1:
            // "1" -> "1.0.0"
            return "\(components[0]).0.0"
        case 2:
            // "1.0" -> "1.0.0", "2.0" -> "2.0.0"
            return "\(components[0]).\(components[1]).0"
        case 3:
            // "1.0.5" -> "1.0.5"
            return version
        default:
            // その他の場合はそのまま返す
            return version
        }
    }
    
    private func openAppStoreForRating() {
        // App Storeの評価ページを開く
        // リリース前はテスト用のURLを使用
        let appStoreURL = "https://apps.apple.com/app/micro-diary/id1234567890?action=write-review"
        
        if let url = URL(string: appStoreURL) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Mail Composer View
struct MailComposerView: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let mailComposer = MFMailComposeViewController()
        mailComposer.mailComposeDelegate = context.coordinator
        
        // メールの設定
        mailComposer.setToRecipients(["support@microdiary.app"])
        mailComposer.setSubject("Micro Diary サポート")
        
        // デフォルトのメール本文
        let deviceModel = UIDevice.current.model
        let systemVersion = UIDevice.current.systemVersion
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        
        let body = """
        
        
        ---
        デバイス情報:
        デバイス: \(deviceModel)
        iOS: \(systemVersion)
        アプリバージョン: \(appVersion)
        ---
        """
        
        mailComposer.setMessageBody(body, isHTML: false)
        
        return mailComposer
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let parent: MailComposerView
        
        init(_ parent: MailComposerView) {
            self.parent = parent
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// Color.gold extension is defined in PremiumService.swift

#Preview {
    SettingsView()
}