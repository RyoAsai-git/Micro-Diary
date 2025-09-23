# Tech Stack and Dependencies

## Core Technologies
- **Language**: Swift 5.0
- **UI Framework**: SwiftUI
- **Data Layer**: Core Data + CloudKit
- **Platform**: iOS 17+ (current deployment target: iOS 18.5)
- **Development Tools**: Xcode 16.4

## Required Dependencies
1. **Google Mobile Ads SDK** - AdMobバナー・インタースティシャル・報酬型広告
2. **UserNotifications.framework** - ローカル通知（毎日21:00デフォルト）
3. **WidgetKit** - ホーム画面Widget（Small/Medium）
4. **StoreKit** - プレミアム課金（サブスクリプション）

## Apple Frameworks
- SwiftUI - UI構築
- Core Data - ローカルデータ永続化
- CloudKit - iCloud同期
- UserNotifications - 通知機能
- WidgetKit - Widget機能
- StoreKit - アプリ内課金

## Project Configuration
- Bundle Identifier: ryoasai.Micro-Diary
- CloudKit Container設定済み
- Background Modes: remote-notification
- Code Signing: Automatic
- Asset Catalog: AppIcon, AccentColor設定済み

## Data Model Requirements
- Entry entity（日記エントリ）
- Badge entity（実績バッジ）
- Settings entity（ユーザー設定）