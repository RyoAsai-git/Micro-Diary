//
//  ContentView.swift
//  Micro Diary
//
//  Created by Ryo Asai on 2025/09/22.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var adService = AdService.shared
    
    var body: some View {
        ZStack {
            TabView {
                HomeView()
                    .tabItem {
                        Image(systemName: "house")
                        Text("ホーム")
                    }
                
                TimelineView()
                    .tabItem {
                        Image(systemName: "list.bullet")
                        Text("タイムライン")
                    }
                
                RecordsView()
                    .tabItem {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                        Text("記録")
                    }
                
                SettingsView()
                    .tabItem {
                        Image(systemName: "gearshape")
                        Text("設定")
                    }
            }
            
            // バナー広告（フッターメニューの上部に固定配置）
            if !adService.isPremiumUser {
                VStack {
                    Spacer()
                    AdBannerView()
                        .frame(height: 60)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 60) // フッターメニューとの間隔を調整
                        .background(Color.clear)
                }
            }
        }
        .preferredColorScheme(themeManager.currentTheme.colorScheme)
        .onAppear {
            setupTabBarAppearance()
        }
        .onChange(of: themeManager.currentTheme) {
            setupTabBarAppearance()
        }
    }
    
    private func setupTabBarAppearance() {
        // タブバーの設定
        let tabBarAppearance = UITabBarAppearance()
        
        // テーマに応じてタブバーの背景を設定
        switch themeManager.currentTheme {
        case .light:
            tabBarAppearance.configureWithOpaqueBackground()
            tabBarAppearance.backgroundColor = UIColor.white.withAlphaComponent(0.95)
        case .dark:
            tabBarAppearance.configureWithOpaqueBackground()
            tabBarAppearance.backgroundColor = UIColor.black.withAlphaComponent(0.95)
        case .system:
            tabBarAppearance.configureWithDefaultBackground()
        }
        
        // 影を追加してタブバーを際立たせる
        tabBarAppearance.shadowColor = UIColor.black.withAlphaComponent(0.1)
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        
        // ナビゲーションバーの設定 - 完全に透明にして洗練された見た目に
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithTransparentBackground()
        navBarAppearance.backgroundColor = UIColor.clear
        navBarAppearance.shadowColor = UIColor.clear
        
        // タイトルの色を設定
        switch themeManager.currentTheme {
        case .light:
            navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.label]
            navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        case .dark:
            navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.label]
            navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        case .system:
            navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.label]
            navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        }
        
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
