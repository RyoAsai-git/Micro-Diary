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
    
    var body: some View {
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
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
