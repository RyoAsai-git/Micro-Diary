//
//  CloudKitService.swift
//  Micro Diary
//
//  Created by Ryo Asai on 2025/09/23.
//

import Foundation
import CoreData
import CloudKit

class CloudKitService: ObservableObject {
    static let shared = CloudKitService()
    
    @Published var iCloudStatus: CKAccountStatus = .couldNotDetermine
    @Published var isSyncing: Bool = false
    @Published var lastSyncDate: Date?
    @Published var syncError: String?
    
    private let container = CKContainer(identifier: "iCloud.ryoasai.Micro-Diary")
    private var persistentContainer: NSPersistentCloudKitContainer?
    
    private init() {
        checkiCloudAccountStatus()
        setupRemoteChangeNotifications()
    }
    
    func setPersistentContainer(_ container: NSPersistentCloudKitContainer) {
        self.persistentContainer = container
    }
    
    func checkiCloudAccountStatus() {
        container.accountStatus { [weak self] status, error in
            DispatchQueue.main.async {
                self?.iCloudStatus = status
                if let error = error {
                    self?.syncError = error.localizedDescription
                }
            }
        }
    }
    
    private func setupRemoteChangeNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(storeRemoteChange(_:)),
            name: .NSPersistentStoreRemoteChange,
            object: nil
        )
    }
    
    @objc private func storeRemoteChange(_ notification: Notification) {
        DispatchQueue.main.async {
            self.lastSyncDate = Date()
            self.isSyncing = false
        }
    }
    
    func forceSyncWithCloudKit() {
        guard let container = persistentContainer else { return }
        
        isSyncing = true
        syncError = nil
        
        // CloudKitとの同期を強制実行
        let context = container.newBackgroundContext()
        context.perform {
            do {
                try context.save()
                DispatchQueue.main.async {
                    self.lastSyncDate = Date()
                    self.isSyncing = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.syncError = error.localizedDescription
                    self.isSyncing = false
                }
            }
        }
    }
    
    var iCloudStatusText: String {
        switch iCloudStatus {
        case .available:
            return "有効"
        case .noAccount:
            return "アカウントなし"
        case .restricted:
            return "制限中"
        case .couldNotDetermine:
            return "確認中"
        case .temporarilyUnavailable:
            return "一時的に利用不可"
        @unknown default:
            return "不明"
        }
    }
    
    var iCloudStatusColor: Color {
        switch iCloudStatus {
        case .available:
            return .green
        case .noAccount, .restricted:
            return .red
        case .couldNotDetermine, .temporarilyUnavailable:
            return .orange
        @unknown default:
            return .gray
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - SwiftUI Color Extension
extension Color {
    static let cloudKitGreen = Color.green
    static let cloudKitRed = Color.red
    static let cloudKitOrange = Color.orange
}
