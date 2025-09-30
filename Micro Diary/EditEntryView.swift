//
//  EditEntryView.swift
//  Micro Diary
//
//  Created by Ryo Asai on 2025/09/29.
//

import SwiftUI
import CoreData

struct EditEntryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    let entry: Entry
    @State private var editedText: String = ""
    @State private var showingSaveConfirmation = false
    @State private var isLoading = false
    
    // 今日の日付（日のみ）
    private var today: Date {
        Calendar.current.startOfDay(for: Date())
    }
    
    // 当日投稿かどうかを判定
    private var isToday: Bool {
        guard let entryDate = entry.date else { return false }
        return Calendar.current.isDate(entryDate, inSameDayAs: today)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 日付表示
                VStack(spacing: 8) {
                    if let entryDate = entry.date {
                        Text(entryDate, style: .date)
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(isToday ? "今日の一言を編集" : "過去の投稿")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                .padding(.top, 16)
                
                // 編集フィールド
                if isToday {
                    VStack(spacing: 16) {
                        TextEditor(text: $editedText)
                            .font(.body)
                            .padding(16)
                            .frame(minHeight: 120)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.separator), lineWidth: 1)
                            )
                        
                        HStack {
                            Text("\(editedText.count)/100")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            if entry.isEdited {
                                Text("編集済み")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                        
                        Button(action: saveEntry) {
                            if isLoading {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("保存中...")
                                }
                            } else {
                                Text("保存")
                            }
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 160, height: 44)
                        .background(editedText.isEmpty || editedText.count > 100 || isLoading ? Color.gray : Color.blue)
                        .cornerRadius(8)
                        .disabled(editedText.isEmpty || editedText.count > 100 || isLoading)
                    }
                } else {
                    // 過去の投稿は編集不可
                    VStack(spacing: 16) {
                        Text(entry.text ?? "")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .padding(16)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 120)
                            .background(Color(.tertiarySystemBackground))
                            .cornerRadius(12)
                        
                        Text("過去の投稿は編集できません")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .navigationTitle("編集")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("キャンセル") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: EmptyView()
            )
        }
        .alert("保存しました", isPresented: $showingSaveConfirmation) {
            Button("OK") {
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("変更内容が保存されました。")
        }
        .onAppear {
            editedText = entry.text ?? ""
        }
    }
    
    private func saveEntry() {
        guard !editedText.isEmpty && editedText.count <= 100 && isToday else { return }
        
        isLoading = true
        
        // エントリを更新
        entry.text = editedText
        entry.isEdited = true
        entry.updatedAt = Date()
        
        do {
            try viewContext.save()
            showingSaveConfirmation = true
        } catch {
            print("Error saving entry: \(error)")
        }
        
        isLoading = false
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    
    // サンプルエントリを作成
    let entry = Entry(context: context)
    entry.id = UUID()
    entry.date = Date()
    entry.text = "今日は良い天気でした"
    entry.createdAt = Date()
    entry.isEdited = false
    
    return EditEntryView(entry: entry)
        .environment(\.managedObjectContext, context)
}
