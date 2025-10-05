//
//  BannerView.swift
//  Micro Diary
//
//  Created by Ryo Asai on 2025/09/22.
//

import GoogleMobileAds
import SwiftUI

struct AdBannerView: UIViewControllerRepresentable {
    func makeUIViewController(context _: Context) -> UIViewController {
        let viewController = GADBannerViewController()
        return viewController
    }

    func updateUIViewController(_: UIViewController, context _: Context) {}
}

class GADBannerViewController: UIViewController, BannerViewDelegate {
    var bannerView: BannerView!
    let adUnitID = "ca-app-pub-3940256099942544/2934735716" // テスト用の広告ユニットID

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadBanner()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { [weak self] _ in
            guard let self else { return }
            self.loadBanner()
        }
    }

    private func loadBanner() {
        bannerView = BannerView(adSize: AdSizeBanner)
        bannerView.adUnitID = adUnitID

        bannerView.delegate = self
        bannerView.rootViewController = self

        let bannerWidth = view.frame.size.width
        bannerView.adSize = currentOrientationAnchoredAdaptiveBanner(width: bannerWidth)

        let request = Request()
        request.scene = view.window?.windowScene
        bannerView.load(request)

        setAdView(bannerView)
    }

    func setAdView(_ view: BannerView) {
        bannerView = view
        self.view.addSubview(bannerView)
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        let viewDictionary = ["_bannerView": bannerView!]
        self.view.addConstraints(
            NSLayoutConstraint.constraints(
                withVisualFormat: "H:|[_bannerView]|",
                options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: viewDictionary
            )
        )
        self.view.addConstraints(
            NSLayoutConstraint.constraints(
                withVisualFormat: "V:|[_bannerView]|",
                options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: viewDictionary
            )
        )
    }
    
    // MARK: - GADBannerViewDelegate
    
    func bannerViewDidReceiveAd(_ bannerView: BannerView) {
        print("Banner ad loaded successfully")
    }
    
    func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
        print("Banner ad failed to load: \(error.localizedDescription)")
    }
}
