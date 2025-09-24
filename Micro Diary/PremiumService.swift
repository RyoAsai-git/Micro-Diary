//
//  PremiumService.swift
//  Micro Diary
//
//  Created by Ryo Asai on 2025/09/22.
//
//  Note: This file contains StoreKit integration for premium subscriptions.
//  To use this, you need to configure products in App Store Connect.

import Foundation
import StoreKit
import SwiftUI

class PremiumService: NSObject, ObservableObject {
    static let shared = PremiumService()
    
    @Published var isPremiumUser = false
    @Published var products: [SKProduct] = []
    @Published var isLoading = false
    @Published var purchaseError: String?
    
    private let premiumProductID = "com.ryoasai.microdiary.premium.monthly" // 実際のプロダクトIDに変更
    
    override init() {
        super.init()
        SKPaymentQueue.default().add(self)
        loadPremiumStatus()
        requestProducts()
    }
    
    deinit {
        SKPaymentQueue.default().remove(self)
    }
    
    private func loadPremiumStatus() {
        isPremiumUser = UserDefaults.standard.bool(forKey: "isPremiumUser")
        
        // 実際のアプリでは、レシート検証を行う
        validateReceipt()
    }
    
    private func requestProducts() {
        let request = SKProductsRequest(productIdentifiers: Set([premiumProductID]))
        request.delegate = self
        request.start()
    }
    
    func purchasePremium() {
        guard let product = products.first(where: { $0.productIdentifier == premiumProductID }) else {
            purchaseError = "プロダクトが見つかりません"
            return
        }
        
        guard SKPaymentQueue.canMakePayments() else {
            purchaseError = "購入が無効化されています"
            return
        }
        
        isLoading = true
        purchaseError = nil
        
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    func restorePurchases() {
        isLoading = true
        purchaseError = nil
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    private func validateReceipt() {
        // 実際のアプリでは、App Storeレシートの検証を行う
        // ここではテスト用の実装
        #if DEBUG
        print("Receipt validation (test mode)")
        #endif
    }
    
    private func unlockPremiumFeatures() {
        isPremiumUser = true
        UserDefaults.standard.set(true, forKey: "isPremiumUser")
        AdService.shared.setPremiumStatus(true)
        
        // 購入完了の通知
        NotificationCenter.default.post(name: .premiumPurchased, object: nil)
    }
}

// MARK: - SKProductsRequestDelegate
extension PremiumService: SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        DispatchQueue.main.async {
            self.products = response.products
            self.isLoading = false
        }
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.purchaseError = error.localizedDescription
            self.isLoading = false
        }
    }
}

// MARK: - SKPaymentTransactionObserver
extension PremiumService: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                DispatchQueue.main.async {
                    self.unlockPremiumFeatures()
                    self.isLoading = false
                }
                queue.finishTransaction(transaction)
                
            case .failed:
                DispatchQueue.main.async {
                    if let error = transaction.error as? SKError {
                        if error.code != .paymentCancelled {
                            self.purchaseError = error.localizedDescription
                        }
                    }
                    self.isLoading = false
                }
                queue.finishTransaction(transaction)
                
            case .restored:
                DispatchQueue.main.async {
                    self.unlockPremiumFeatures()
                    self.isLoading = false
                }
                queue.finishTransaction(transaction)
                
            case .deferred, .purchasing:
                break
                
            @unknown default:
                break
            }
        }
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        DispatchQueue.main.async {
            self.purchaseError = error.localizedDescription
            self.isLoading = false
        }
    }
    
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        DispatchQueue.main.async {
            self.isLoading = false
        }
    }
}

// MARK: - Premium Features
extension PremiumService {
    func canEditEntry() -> Bool {
        return isPremiumUser
    }
    
    
    func canChangeTheme() -> Bool {
        return isPremiumUser
    }
    
    func showRewardedAdForFeature(completion: @escaping (Bool) -> Void) {
        guard !isPremiumUser else {
            completion(true)
            return
        }
        
        AdService.shared.showRewardedAd { success in
            completion(success)
        }
    }
}

// MARK: - Notifications
extension Notification.Name {
    static let premiumPurchased = Notification.Name("premiumPurchased")
}

// MARK: - Premium Purchase View
struct PremiumPurchaseView: View {
    @ObservedObject private var premiumService = PremiumService.shared
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // ヘッダー
                    VStack(spacing: 16) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gold)
                        
                        Text("プレミアムにアップグレード")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("すべての機能を制限なく使用")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 32)
                    
                    // 機能一覧
                    VStack(spacing: 16) {
                        PremiumFeatureRow(
                            icon: "xmark.circle.fill",
                            title: "広告削除",
                            description: "すべての広告を非表示"
                        )
                        
                        PremiumFeatureRow(
                            icon: "paintbrush.fill",
                            title: "テーマ変更",
                            description: "ライト・ダークテーマの選択"
                        )
                        
                        
                        PremiumFeatureRow(
                            icon: "pencil.circle.fill",
                            title: "無制限編集",
                            description: "過去の日記を自由に編集"
                        )
                    }
                    .padding(.horizontal, 16)
                    
                    // 価格とボタン
                    VStack(spacing: 16) {
                        if let product = premiumService.products.first {
                            VStack {
                                Text("月額 \(formatPrice(product.price))")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text("いつでもキャンセル可能")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Button(action: {
                                premiumService.purchasePremium()
                            }) {
                                if premiumService.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("プレミアムを開始")
                                }
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.blue)
                            .cornerRadius(12)
                            .disabled(premiumService.isLoading)
                        } else {
                            Text("読み込み中...")
                                .foregroundColor(.secondary)
                        }
                        
                        Button("購入を復元") {
                            premiumService.restorePurchases()
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 16)
                    
                    Spacer(minLength: 32)
                }
            }
            .navigationTitle("プレミアム")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .alert("エラー", isPresented: .constant(premiumService.purchaseError != nil)) {
            Button("OK") {
                premiumService.purchaseError = nil
            }
        } message: {
            Text(premiumService.purchaseError ?? "")
        }
    }
    
    private func formatPrice(_ price: NSDecimalNumber) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: price) ?? "¥300"
    }
}

struct PremiumFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

extension Color {
    static let gold = Color(red: 1.0, green: 0.84, blue: 0.0)
}
