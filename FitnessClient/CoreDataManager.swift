// CoreDataManager.swift
import Foundation
import CoreData
import SwiftUI

// MARK: - Core Data Manager
@MainActor
class CoreDataManager: ObservableObject {
    static let shared = CoreDataManager()
    
    // MARK: - Core Data Stack
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "FitnessApp")
        
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                // In production, you should handle this error appropriately
                print("Core Data error: \(error), \(error.userInfo)")
            }
        }
        
        // Enable automatic merging of changes
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // Background context for sync operations
    lazy var backgroundContext: NSManagedObjectContext = {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }()
    
    private init() {}
    
    // MARK: - Core Data Operations
    
    func save() {
        guard context.hasChanges else { return }
        
        do {
            try context.save()
        } catch {
            print("Failed to save Core Data context: \(error)")
        }
    }
    
    func saveBackground(_ context: NSManagedObjectContext) {
        guard context.hasChanges else { return }
        
        context.perform {
            do {
                try context.save()
            } catch {
                print("Failed to save background context: \(error)")
            }
        }
    }
    
    // MARK: - Fetch Operations
    
    func fetch<T: NSManagedObject>(_ request: NSFetchRequest<T>) -> [T] {
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch \(T.self): \(error)")
            return []
        }
    }
    
    func fetchFirst<T: NSManagedObject>(_ request: NSFetchRequest<T>) -> T? {
        request.fetchLimit = 1
        return fetch(request).first
    }
    
    // MARK: - Delete Operations
    
    func delete(_ object: NSManagedObject) {
        context.delete(object)
        save()
    }
    
    func deleteAll<T: NSManagedObject>(_ type: T.Type) {
        let request = NSFetchRequest<T>(entityName: String(describing: type))
        let objects = fetch(request)
        objects.forEach { context.delete($0) }
        save()
    }
    
    // MARK: - Batch Operations
    
    func batchDelete<T: NSManagedObject>(_ type: T.Type, predicate: NSPredicate? = nil) {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: type))
        request.predicate = predicate
        
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        batchDeleteRequest.resultType = .resultTypeObjectIDs
        
        do {
            let result = try context.execute(batchDeleteRequest) as? NSBatchDeleteResult
            if let objectIDs = result?.result as? [NSManagedObjectID] {
                let changes = [NSDeletedObjectsKey: objectIDs]
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [context])
            }
        } catch {
            print("Failed to batch delete \(type): \(error)")
        }
    }
}

// MARK: - Sync Status Tracking
enum SyncStatus: String, CaseIterable {
    case synced = "synced"
    case pendingUpload = "pending_upload"
    case pendingDownload = "pending_download"
    case conflict = "conflict"
    case error = "error"
}

// MARK: - Offline Data Protocol
protocol OfflineDataModel: NSManagedObject {
    func getID() -> String
    func setID(_ id: String)
    func getLastModified() -> Date
    func setLastModified(_ date: Date)
    func getSyncStatus() -> String
    func setSyncStatus(_ status: String)
    func getIsDeleted() -> Bool
    func setIsDeleted(_ deleted: Bool)
    
    func updateFromAPI(_ apiModel: Any)
    func toAPIModel() -> Any?
}

// MARK: - Sync Manager
@MainActor
class SyncManager: ObservableObject {
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncErrors: [String] = []
    
    private let coreDataManager = CoreDataManager.shared
    private let networkMonitor = NetworkMonitor.shared
    
    static let shared = SyncManager()
    
    private init() {
        // Load last sync date
        lastSyncDate = UserDefaults.standard.object(forKey: "lastSyncDate") as? Date
        
        // Start monitoring network changes
        startNetworkMonitoring()
    }
    
    private func startNetworkMonitoring() {
        // Sync when network becomes available
        networkMonitor.$isConnected
            .dropFirst() // Skip initial value
            .sink { [weak self] isConnected in
                if isConnected {
                    Task {
                        await self?.syncAll()
                    }
                }
            }
            .store(in: &networkMonitor.cancellables)
    }
    
    // MARK: - Sync Operations
    
    func syncAll() async {
        guard networkMonitor.isConnected else {
            print("SyncManager: No network connection, skipping sync")
            return
        }
        
        guard !isSyncing else {
            print("SyncManager: Sync already in progress")
            return
        }
        
        isSyncing = true
        syncErrors.removeAll()
        
        do {
            // Sync different data types
            await syncUsers()
            await syncExercises()
            await syncWorkouts()
            await syncAssignments()
            
            // Update last sync date
            lastSyncDate = Date()
            UserDefaults.standard.set(lastSyncDate, forKey: "lastSyncDate")
            
            print("SyncManager: Sync completed successfully")
        } catch {
            syncErrors.append("Sync failed: \(error.localizedDescription)")
            print("SyncManager: Sync failed: \(error)")
        }
        
        isSyncing = false
    }
    
    private func syncUsers() async {
        // Implementation will be added when we create User Core Data model
        print("SyncManager: Syncing users...")
    }
    
    private func syncExercises() async {
        // Implementation will be added when we create Exercise Core Data model
        print("SyncManager: Syncing exercises...")
    }
    
    private func syncWorkouts() async {
        // Implementation will be added when we create Workout Core Data model
        print("SyncManager: Syncing workouts...")
    }
    
    private func syncAssignments() async {
        // Implementation will be added when we create Assignment Core Data model
        print("SyncManager: Syncing assignments...")
    }
    
    // MARK: - Manual Sync Trigger
    
    func forcSync() async {
        await syncAll()
    }
}

// MARK: - Network Monitor
import Network

@MainActor
class NetworkMonitor: ObservableObject {
    @Published var isConnected = false
    @Published var connectionType: NWInterface.InterfaceType?
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    var cancellables = Set<AnyCancellable>()
    
    static let shared = NetworkMonitor()
    
    private init() {
        startMonitoring()
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.connectionType = path.availableInterfaces.first?.type
                
                print("NetworkMonitor: Connection status: \(path.status)")
                if let type = self?.connectionType {
                    print("NetworkMonitor: Connection type: \(type)")
                }
            }
        }
        
        monitor.start(queue: queue)
    }
    
    deinit {
        monitor.cancel()
    }
}

// MARK: - Import Combine for NetworkMonitor
import Combine
