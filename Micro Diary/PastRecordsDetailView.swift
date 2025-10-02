//
//  PastRecordsDetailView.swift
//  Micro Diary
//
//  Created by Ryo Asai on 2025/09/30.
//

import SwiftUI
import CoreData

struct PastRecordsDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var premiumService = PremiumService.shared
    
    @State private var searchText = ""
    @State private var sortOption: SortOption = .dateDescending
    @State private var showingPremiumPrompt = false
    @State private var selectedEntry: Entry?
    @State private var showingEntryDetail = false
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Entry.date, ascending: false)],
        animation: .default
    ) private var allEntries: FetchedResults<Entry>
    
    enum SortOption: String, CaseIterable {
        case dateAscending = "日付（古い順）"
        case dateDescending = "日付（新しい順）"
        case satisfactionAscending = "満足度（低い順）"
        case satisfactionDescending = "満足度（高い順）"
        
        var sortDescriptors: [NSSortDescriptor] {
            switch self {
            case .dateAscending:
                return [NSSortDescriptor(keyPath: \Entry.date, ascending: true)]
            case .dateDescending:
                return [NSSortDescriptor(keyPath: \Entry.date, ascending: false)]
            case .satisfactionAscending:
                return [NSSortDescriptor(keyPath: \Entry.satisfactionScore, ascending: true)]
            case .satisfactionDescending:
                return [NSSortDescriptor(keyPath: \Entry.satisfactionScore, ascending: false)]
            }
        }
        
        var icon: String {
            switch self {
            case .dateAscending:
                return "calendar.badge.plus"
            case .dateDescending:
                return "calendar.badge.minus"
            case .satisfactionAscending:
                return "arrow.up.heart"
            case .satisfactionDescending:
                return "arrow.down.heart.fill"
            }
        }
    }
    
    private var filteredAndSortedEntries: [Entry] {
        let filtered = searchText.isEmpty ? 
            Array(allEntries) : 
            allEntries.filter { entry in
                entry.text?.localizedCaseInsensitiveContains(searchText) ?? false
            }
        
        return filtered.sorted { entry1, entry2 in
            switch sortOption {
            case .dateAscending:
                return (entry1.date ?? Date()) < (entry2.date ?? Date())
            case .dateDescending:
                return (entry1.date ?? Date()) > (entry2.date ?? Date())
            case .satisfactionAscending:
                return entry1.satisfactionScore < entry2.satisfactionScore
            case .satisfactionDescending:
                return entry1.satisfactionScore > entry2.satisfactionScore
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                GradientBackground()
                
                VStack(spacing: 0) {
                // 検索バー（プレミアム機能）
                if premiumService.canSearchDiary() {
                    SearchBar(text: $searchText)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                } else {
                    Button(action: {
                        showingPremiumPrompt = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.blue)
                                .font(.caption)
                            Text("検索するにはプレミアムが必要です")
                                .foregroundColor(.secondary)
                                .font(.caption)
                            Spacer()
                            HStack(spacing: 2) {
                                Image(systemName: "crown.fill")
                                    .foregroundColor(.orange)
                                    .font(.caption2)
                                Text("Premium")
                                    .foregroundColor(.orange)
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.orange.opacity(0.1))
                            )
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.secondaryCardBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
                
                // ソート選択（プレミアム機能）
                if premiumService.canUseSatisfactionSort() {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(SortOption.allCases, id: \.self) { option in
                                Button(action: {
                                    sortOption = option
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: option.icon)
                                            .font(.caption2)
                                        Text(option.rawValue)
                                            .font(.caption2)
                                            .fontWeight(.medium)
                                    }
                                    .foregroundColor(sortOption == option ? .white : .primary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(sortOption == option ? Color.blue : Color.secondaryCardBackground)
                                            .overlay(
                                                Capsule()
                                                    .stroke(sortOption == option ? Color.clear : Color.blue.opacity(0.3), lineWidth: 1)
                                            )
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.vertical, 8)
                } else {
                    Button(action: {
                        showingPremiumPrompt = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.up.arrow.down")
                                .foregroundColor(.blue)
                                .font(.caption)
                            Text("ソートするにはプレミアムが必要です")
                                .foregroundColor(.secondary)
                                .font(.caption)
                            Spacer()
                            HStack(spacing: 2) {
                                Image(systemName: "crown.fill")
                                    .foregroundColor(.orange)
                                    .font(.caption2)
                                Text("Premium")
                                    .foregroundColor(.orange)
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.orange.opacity(0.1))
                            )
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.secondaryCardBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                
                Divider()
                
                // エントリリスト
                List(filteredAndSortedEntries, id: \.id) { entry in
                    Button(action: {
                        selectedEntry = entry
                        showingEntryDetail = true
                    }) {
                        PastRecordRow(entry: entry)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                }
                .listStyle(PlainListStyle())
                .background(Color.clear)
                .scrollContentBackground(.hidden)
            }
                }
            .navigationTitle("過去の記録")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("閉じる") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .sheet(isPresented: $showingEntryDetail) {
            if let entry = selectedEntry {
                NavigationView {
                    EntryDetailView(entry: entry)
                }
            }
        }
        .sheet(isPresented: $showingPremiumPrompt) {
            PremiumPurchaseView()
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.blue)
                .font(.caption)
            
            TextField("日記を検索...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.caption)
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct PastRecordRow: View {
    let entry: Entry
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/M/d (E)"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(dateFormatter.string(from: entry.date ?? Date()))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                HStack(spacing: 8) {
                    HStack(spacing: 2) {
                        Image(systemName: "heart.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                        Text("\(Int(entry.satisfactionScore))")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.primary)
                    
                    if entry.isEdited {
                        Image(systemName: "pencil")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            Text(entry.text ?? "")
                .font(.body)
                .foregroundColor(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.cardBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

#Preview {
    PastRecordsDetailView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
