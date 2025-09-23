# Micro Diary Project Overview

## Purpose
マイクロ日記アプリ - 1日1行だけ日記を書くシンプルなiOSアプリケーション。続けやすさと振り返り機能に重点を置き、通知・Widget・去年の今日機能でリテンション向上を図る。

## Tech Stack
- **Platform**: iOS 17以上（iPhone対象）
- **UI Framework**: SwiftUI
- **Data Storage**: Core Data + CloudKit（iCloud同期対応）
- **Development**: Xcode 16.4, Swift 5.0
- **Target Deployment**: iOS 18.5
- **Bundle ID**: ryoasai.Micro-Diary

## Current State
- Xcodeプロジェクトは作成済み（テンプレート状態）
- Core Data + CloudKit統合済み
- 基本的なMVCアーキテクチャでItem entityが定義済み
- CloudKit entitlements設定済み
- リモート通知のbackground mode設定済み

## Architecture
- SwiftUIベースのMVVM構造
- Core Dataでローカル永続化
- CloudKitでiCloud同期
- PersistenceController経由でデータ管理

## Features to Implement
1. ホーム画面（今日のひとこと入力）
2. タイムライン画面（過去の日記一覧）
3. バッジ画面（連続記録等の実績）
4. 設定画面（通知時間、テーマ等）
5. Widget（Today Extension）
6. ローカル通知機能
7. AdMob広告統合
8. プレミアム課金機能