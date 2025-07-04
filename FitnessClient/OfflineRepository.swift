// OfflineRepository.swift
import Foundation
import CoreData
import SwiftUI

// MARK: - Repository Protocol
protocol OfflineRepositoryProtocol {
    associatedtype APIModel
    associatedtype CoreDataModel: OfflineDataModel
    
    func fetch() async -> [APIModel]
    func fetchByID(_ id: String) async -> APIModel?
    func create(_ model: APIModel) async -> APIModel?
    func update(_ model: APIModel) async -> APIModel?
    func delete(_ id: String) async -> Bool
    
    // Offline-specific methods
    func fetchOffline() -> [APIModel]
    func syncWithServer() async
}

// MARK: - Base Offline Repository
@MainActor
class BaseOfflineRepository<APIModel, CoreDataModel: OfflineDataModel>: ObservableObject {
    
    let apiService: APIService
    let coreDataManager = CoreDataManager.shared
    let networkMonitor = NetworkMonitor.shared
    
    init(apiService: APIService) {
        self.apiService = apiService
    }
    
    // MARK: - Core Data Helpers
    
    func fetchFromCoreData<T: NSManagedObject>(_ request: NSFetchRequest<T>) -> [T] {
        return coreDataManager.fetch(request)
    }
    
    func saveContext() {
        coreDataManager.save()
    }
    
    // MARK: - Sync Helpers
    
    func markForUpload(_ object: CoreDataModel) {
        object.setSyncStatus(SyncStatus.pendingUpload.rawValue)
        object.setLastModified(Date())
        saveContext()
    }
    
    func markAsSynced(_ object: CoreDataModel) {
        object.setSyncStatus(SyncStatus.synced.rawValue)
        saveContext()
    }
    
    func markAsDeleted(_ object: CoreDataModel) {
        object.setIsDeleted(true)
        object.setSyncStatus(SyncStatus.pendingUpload.rawValue)
        object.setLastModified(Date())
        saveContext()
    }
}

// MARK: - User Repository
@MainActor
class OfflineUserRepository: BaseOfflineRepository<UserResponse, CDUser> {
    
    // MARK: - Fetch Operations
    
    func fetchUsers() async -> [UserResponse] {
        if networkMonitor.isConnected {
            do {
                let users: [UserResponse] = try await apiService.GET(endpoint: "/users")
                await syncUsersToLocal(users)
                return users
            } catch {
                print("Failed to fetch users from API, falling back to offline: \(error)")
                return fetchUsersOffline()
            }
        } else {
            return fetchUsersOffline()
        }
    }
    
    func fetchUserByID(_ id: String) async -> UserResponse? {
        if networkMonitor.isConnected {
            do {
                let user: UserResponse = try await apiService.GET(endpoint: "/users/\(id)")
                await syncUserToLocal(user)
                return user
            } catch {
                print("Failed to fetch user from API, falling back to offline: \(error)")
                return fetchUserOffline(id)
            }
        } else {
            return fetchUserOffline(id)
        }
    }
    
    func fetchTrainerClients() async -> [UserResponse] {
        if networkMonitor.isConnected {
            do {
                let clients: [UserResponse] = try await apiService.GET(endpoint: "/trainer/clients")
                await syncUsersToLocal(clients)
                return clients
            } catch {
                print("Failed to fetch trainer clients from API, falling back to offline: \(error)")
                return fetchTrainerClientsOffline()
            }
        } else {
            return fetchTrainerClientsOffline()
        }
    }
    
    // MARK: - Offline Fetch Operations
    
    private func fetchUsersOffline() -> [UserResponse] {
        let request: NSFetchRequest<CDUser> = CDUser.fetchRequest()
        request.predicate = NSPredicate(format: "isDeletedFlag == NO")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDUser.name, ascending: true)]
        
        let cdUsers = fetchFromCoreData(request)
        return cdUsers.compactMap { $0.toAPIModel() as? UserResponse }
    }
    
    private func fetchUserOffline(_ id: String) -> UserResponse? {
        guard let cdUser = CDUser.fetchByID(id, context: coreDataManager.context) else {
            return nil
        }
        return cdUser.toAPIModel() as? UserResponse
    }
    
    private func fetchTrainerClientsOffline() -> [UserResponse] {
        let request: NSFetchRequest<CDUser> = CDUser.fetchRequest()
        request.predicate = NSPredicate(format: "ANY roles == %@ AND isDeletedFlag == NO", "client")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDUser.name, ascending: true)]
        
        let cdUsers = fetchFromCoreData(request)
        return cdUsers.compactMap { $0.toAPIModel() as? UserResponse }
    }
    
    // MARK: - Sync Operations
    
    private func syncUsersToLocal(_ users: [UserResponse]) async {
        await coreDataManager.backgroundContext.perform {
            for user in users {
                let cdUser = CDUser.fetchByID(user.id, context: self.coreDataManager.backgroundContext) ??
                            CDUser(context: self.coreDataManager.backgroundContext)
                cdUser.updateFromAPI(user)
            }
            self.coreDataManager.saveBackground(self.coreDataManager.backgroundContext)
        }
    }
    
    private func syncUserToLocal(_ user: UserResponse) async {
        await coreDataManager.backgroundContext.perform {
            let cdUser = CDUser.fetchByID(user.id, context: self.coreDataManager.backgroundContext) ??
                        CDUser(context: self.coreDataManager.backgroundContext)
            cdUser.updateFromAPI(user)
            self.coreDataManager.saveBackground(self.coreDataManager.backgroundContext)
        }
    }
    
    // MARK: - Create/Update Operations
    
    func createUser(_ user: UserResponse) async -> UserResponse? {
        // Store locally first
        let cdUser = CDUser(context: coreDataManager.context)
        cdUser.updateFromAPI(user)
        cdUser.setID(UUID().uuidString) // Generate local ID
        markForUpload(cdUser)
        
        if networkMonitor.isConnected {
            // Try to sync to server
            do {
                let createdUser: UserResponse = try await apiService.POST(endpoint: "/users", body: user)
                cdUser.updateFromAPI(createdUser)
                markAsSynced(cdUser)
                return createdUser
            } catch {
                print("Failed to create user on server, will sync later: \(error)")
                return cdUser.toAPIModel() as? UserResponse
            }
        } else {
            return cdUser.toAPIModel() as? UserResponse
        }
    }
    
    // MARK: - Sync with Server
    
    func syncWithServer() async {
        guard networkMonitor.isConnected else { return }
        
        // Upload pending changes
        await uploadPendingChanges()
        
        // Download latest data
        await downloadLatestData()
    }
    
    private func uploadPendingChanges() async {
        let request: NSFetchRequest<CDUser> = CDUser.fetchRequest()
        request.predicate = NSPredicate(format: "syncStatusValue == %@", SyncStatus.pendingUpload.rawValue)
        
        let pendingUsers = fetchFromCoreData(request)
        
        for cdUser in pendingUsers {
            do {
                if cdUser.getIsDeleted() {
                    // Delete on server
                    try await apiService.DELETE(endpoint: "/users/\(cdUser.getID())")
                    coreDataManager.delete(cdUser)
                } else if let userResponse = cdUser.toAPIModel() as? UserResponse {
                    // Update on server
                    let updatedUser: UserResponse = try await apiService.PUT(endpoint: "/users/\(cdUser.getID())", body: userResponse)
                    cdUser.updateFromAPI(updatedUser)
                    markAsSynced(cdUser)
                }
            } catch {
                print("Failed to sync user \(cdUser.getID()): \(error)")
                cdUser.setSyncStatus(SyncStatus.error.rawValue)
                saveContext()
            }
        }
    }
    
    private func downloadLatestData() async {
        do {
            let users: [UserResponse] = try await apiService.GET(endpoint: "/users")
            await syncUsersToLocal(users)
        } catch {
            print("Failed to download latest users: \(error)")
        }
    }
}

// MARK: - Exercise Repository
@MainActor
class OfflineExerciseRepository: BaseOfflineRepository<Exercise, CDExercise> {
    
    func fetchExercises() async -> [Exercise] {
        if networkMonitor.isConnected {
            do {
                let exercises: [Exercise] = try await apiService.GET(endpoint: "/exercises")
                await syncExercisesToLocal(exercises)
                return exercises
            } catch {
                print("Failed to fetch exercises from API, falling back to offline: \(error)")
                return fetchExercisesOffline()
            }
        } else {
            return fetchExercisesOffline()
        }
    }
    
    func fetchTrainerExercises() async -> [Exercise] {
        if networkMonitor.isConnected {
            do {
                let exercises: [Exercise] = try await apiService.GET(endpoint: "/exercises")
                await syncExercisesToLocal(exercises)
                return exercises
            } catch {
                print("Failed to fetch trainer exercises from API, falling back to offline: \(error)")
                return fetchTrainerExercisesOffline()
            }
        } else {
            return fetchTrainerExercisesOffline()
        }
    }
    
    private func fetchExercisesOffline() -> [Exercise] {
        let request: NSFetchRequest<CDExercise> = CDExercise.fetchRequest()
        request.predicate = NSPredicate(format: "isDeletedFlag == NO")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDExercise.name, ascending: true)]
        
        let cdExercises = fetchFromCoreData(request)
        return cdExercises.compactMap { $0.toAPIModel() as? Exercise }
    }
    
    private func fetchTrainerExercisesOffline() -> [Exercise] {
        // For now, return all exercises. In a real app, you'd filter by creator
        return fetchExercisesOffline()
    }
    
    private func syncExercisesToLocal(_ exercises: [Exercise]) async {
        await coreDataManager.backgroundContext.perform {
            for exercise in exercises {
                let cdExercise = CDExercise.fetchByID(exercise.id, context: self.coreDataManager.backgroundContext) ??
                                CDExercise(context: self.coreDataManager.backgroundContext)
                cdExercise.updateFromAPI(exercise)
            }
            self.coreDataManager.saveBackground(self.coreDataManager.backgroundContext)
        }
    }
    
    func syncWithServer() async {
        guard networkMonitor.isConnected else { return }
        
        do {
            let exercises: [Exercise] = try await apiService.GET(endpoint: "/exercises")
            await syncExercisesToLocal(exercises)
        } catch {
            print("Failed to sync exercises: \(error)")
        }
    }
}

// MARK: - Assignment Repository
@MainActor
class OfflineAssignmentRepository: BaseOfflineRepository<Assignment, CDAssignment> {
    
    func fetchClientAssignments() async -> [Assignment] {
        if networkMonitor.isConnected {
            do {
                let assignments: [Assignment] = try await apiService.GET(endpoint: "/client/assignments")
                await syncAssignmentsToLocal(assignments)
                return assignments
            } catch {
                print("Failed to fetch client assignments from API, falling back to offline: \(error)")
                return fetchClientAssignmentsOffline()
            }
        } else {
            return fetchClientAssignmentsOffline()
        }
    }
    
    private func fetchClientAssignmentsOffline() -> [Assignment] {
        let request: NSFetchRequest<CDAssignment> = CDAssignment.fetchRequest()
        request.predicate = NSPredicate(format: "isDeletedFlag == NO")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDAssignment.assignedAt, ascending: false)]
        
        let cdAssignments = fetchFromCoreData(request)
        return cdAssignments.compactMap { $0.toAPIModel() as? Assignment }
    }
    
    private func syncAssignmentsToLocal(_ assignments: [Assignment]) async {
        await coreDataManager.backgroundContext.perform {
            for assignment in assignments {
                let cdAssignment = CDAssignment.fetchByID(assignment.id, context: self.coreDataManager.backgroundContext) ??
                                 CDAssignment(context: self.coreDataManager.backgroundContext)
                cdAssignment.updateFromAPI(assignment)
            }
            self.coreDataManager.saveBackground(self.coreDataManager.backgroundContext)
        }
    }
    
    func syncWithServer() async {
        guard networkMonitor.isConnected else { return }
        
        do {
            let assignments: [Assignment] = try await apiService.GET(endpoint: "/client/assignments")
            await syncAssignmentsToLocal(assignments)
        } catch {
            print("Failed to sync assignments: \(error)")
        }
    }
}
