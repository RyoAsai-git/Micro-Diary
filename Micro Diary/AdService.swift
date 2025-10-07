//
//  AdService.swift
//  Micro Diary
//
//  Created by Ryo Asai on 2025/09/22.
//
//  Note: This file contains AdMob integration code.
//  To use this, you need to add Google Mobile Ads SDK to your project.
//  1. Add the SDK via Swift Package Manager or CocoaPods
//  2. Add your AdMob App ID to Info.plist
//  3. Configure ad unit IDs

import Foundation
import UIKit
import SwiftUI
// import GoogleMobileAds // Uncomment when Google Mobile Ads SDK is added

class AdService: ObservableObject {
    static let shared = AdService()
    
    @Published var isPremiumUser = false
    @Published var isShowingInterstitialAd = false
    
    private var interstitialAdCounter = 0
    private let interstitialAdFrequency = 2 // 週2回程度
    
    private init() {
        // UserDefaultsからプレミアムステータスを読み込み
        isPremiumUser = UserDefaults.standard.bool(forKey: "isPremiumUser")
    }
    
    func initializeAds() {
        guard !isPremiumUser else { return }
        
        // Google Mobile Ads SDK初期化
        // GADMobileAds.sharedInstance().start(completionHandler: nil)
        print("AdMob initialized")
    }
    
    func shouldShowInterstitialAd() -> Bool {
        guard !isPremiumUser else { return false }
        
        interstitialAdCounter += 1
        
        // 週2回程度の頻度で表示
        if interstitialAdCounter >= interstitialAdFrequency {
            interstitialAdCounter = 0
            return true
        }
        
        return false
    }
    
    func showInterstitialAd() {
        guard !isPremiumUser else { return }
        
        // インタースティシャル広告を表示
        // 実際の実装ではGADInterstitialAdを使用
        print("Showing interstitial ad")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.isShowingInterstitialAd = true
        }
        
        // 3秒後に自動で閉じる（テスト用）
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.isShowingInterstitialAd = false
        }
    }
    
    func showRewardedAd(completion: @escaping (Bool) -> Void) {
        guard !isPremiumUser else {
            completion(true)
            return
        }
        
        // 報酬型広告を表示
        // 実際の実装ではGADRewardedAdを使用
        print("Showing rewarded ad")
        
        // テスト用：3秒後に報酬を与える
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            completion(true)
        }
    }
    
    func setPremiumStatus(_ isPremium: Bool) {
        isPremiumUser = isPremium
        UserDefaults.standard.set(isPremium, forKey: "isPremiumUser")
        
        if isPremium {
            // プレミアムユーザーになった場合、広告を無効化
            print("Premium activated - Ads disabled")
        }
    }
}

// MARK: - Banner Ad View (SwiftUI)
struct BannerAdView: UIViewRepresentable {
    let adUnitID: String
    
    init(adUnitID: String = "ca-app-pub-6760883877695559/4176741351") { // Production Ad Unit ID
        self.adUnitID = adUnitID
    }
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .systemGray6
        
        // プレミアムユーザーの場合は空のViewを返す
        if AdService.shared.isPremiumUser {
            return view
        }
        
        // テスト用のプレースホルダー
        let label = UILabel()
        label.text = "バナー広告エリア"
        label.textAlignment = .center
        label.textColor = .systemGray
        label.font = UIFont.systemFont(ofSize: 12)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            view.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        // 実際の実装では以下のようなコードになる：
        /*
        let bannerView = GADBannerView(adSize: GADAdSizeBanner)
        bannerView.adUnitID = adUnitID
        bannerView.rootViewController = UIApplication.shared.windows.first?.rootViewController
        bannerView.load(GADRequest())
        
        view.addSubview(bannerView)
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bannerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            bannerView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        */
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // 必要に応じて更新処理を実装
    }
}

// MARK: - Interstitial Ad View
struct InterstitialAdView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("広告")
                    .font(.title)
                    .foregroundColor(.white)
                
                Rectangle()
                    .fill(Color.gray)
                    .frame(width: 300, height: 250)
                    .overlay(
                        Text("インタースティシャル広告\nプレースホルダー")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white)
                    )
                
                Button("閉じる") {
                    isPresented = false
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
    }
}
