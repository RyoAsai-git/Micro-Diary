//
//  Persistence.swift
//  Micro Diary
//
//  Created by Ryo Asai on 2025/09/22.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Create sample entries for preview
        let sampleTexts = ["今日は良い天気でした", "新しいプロジェクトを始めた", "友人と楽しい時間を過ごした", "読書の時間を作れた", "散歩で気分転換"]
        for i in 0..<5 {
            let entry = Entry(context: viewContext)
            entry.id = UUID()
            entry.date = Calendar.current.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            entry.text = sampleTexts[i]
            entry.createdAt = entry.date
            entry.isEdited = false
        }
        
        // Create sample badges
        let badge = Badge(context: viewContext)
        badge.id = UUID()
        badge.type = "7days"
        badge.earnedAt = Date()
        
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "Micro_Diary")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // CloudKit設定
            guard let description = container.persistentStoreDescriptions.first else {
                fatalError("Failed to retrieve a persistent store description.")
            }
            
            // CloudKitコンテナIDを設定
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            description.setOption("iCloud.ryoasai.Micro-Diary" as NSString, forKey: NSPersistentCloudKitContainerOptionsKey)
        }
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                print("Core Data error: \(error), \(error.userInfo)")
                print("Store description: \(storeDescription)")
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 * CloudKit container is not properly configured.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            } else {
                print("Core Data store loaded successfully")
                print("Store description: \(storeDescription)")
                
                // CloudKitServiceにコンテナを設定
                if !inMemory {
                    CloudKitService.shared.setPersistentContainer(self.container)
                }
            }
        })
        
        // CloudKit同期の設定
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        do {
            // リモート通知の設定
            try container.viewContext.setQueryGenerationFrom(.current)
        } catch {
            print("Failed to pin viewContext to the current generation: \(error)")
        }
    }
}
