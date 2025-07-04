// OfflineViewModels.swift
import Foundation
import SwiftUI

// MARK: - Offline-Aware Trainer Clients ViewModel
@MainActor
class OfflineTrainerClientsViewModel: ListViewModel<UserResponse> {
    @Published var isOffline = false
    @Published var lastSyncDate: Date?
    
    private let offlineUserRepository: OfflineUserRepository
    private let networkMonitor = NetworkMonitor.shared
    private let syncManager = SyncManager.shared
    
    init(apiService: APIService) {
        self.offlineUserRepository = OfflineUserRepository(apiService: apiService)
        super.init()
        
        // Monitor network status
        networkMonitor.$isConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                self?.isOffline = !isConnected
                if isConnected {
                    // Auto-sync when network becomes available
                    Task {
                        await self?.syncData()
                    }
                }
            }
            .store(in: &cancellables)
        
        // Monitor sync status
        syncManager.$lastSyncDate
            .receive(on: DispatchQueue.main)
            .assign(to: \.lastSyncDate, on: self)
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    func fetchManagedClients() async {
        await safeExecute(
            operationId: "fetch_clients_offline",
            loadingMessage: isOffline ? "Loading from offline storage..." : "Loading clients...",
            context: "Fetching managed clients (offline-aware)"
        ) { [weak self] in
            guard let self = self else { return }
            let clients = await self.offlineUserRepository.fetchTrainerClients()
            self.updateItems(clients)
            
            print("OfflineTrainerClientsViewModel: Fetched \(clients.count) clients (offline: \(self.isOffline))")
        }
    }
    
    func refreshClients() async {
        if networkMonitor.isConnected {
            await fetchManagedClients()
        } else {
            // Just reload from local storage
            await fetchManagedClients()
        }
    }
    
    func syncData() async {
        guard networkMonitor.isConnected else {
            print("OfflineTrainerClientsViewModel: Cannot sync - no network connection")
            return
        }
        
        await safeExecute(
            operationId: "sync_clients",
            loadingMessage: "Syncing with server...",
            context: "Syncing client data"
        ) { [weak self] in
            await self?.offlineUserRepository.syncWithServer()
            await self?.fetchManagedClients()
        }
    }
    
    override func retry() {
        Task {
            if networkMonitor.isConnected {
                await fetchManagedClients()
            } else {
                // In offline mode, just try to load from local storage
                await fetchManagedClients()
            }
        }
    }
}

// MARK: - Offline-Aware Exercise List ViewModel
@MainActor
class OfflineExerciseListViewModel: ListViewModel<Exercise> {
    @Published var isOffline = false
    @Published var lastSyncDate: Date?
    
    private let offlineExerciseRepository: OfflineExerciseRepository
    private let networkMonitor = NetworkMonitor.shared
    private let syncManager = SyncManager.shared
    
    init(apiService: APIService) {
        self.offlineExerciseRepository = OfflineExerciseRepository(apiService: apiService)
        super.init()
        
        // Monitor network status
        networkMonitor.$isConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                self?.isOffline = !isConnected
                if isConnected {
                    Task {
                        await self?.syncData()
                    }
                }
            }
            .store(in: &cancellables)
        
        syncManager.$lastSyncDate
            .receive(on: DispatchQueue.main)
            .assign(to: \.lastSyncDate, on: self)
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    func fetchExercises() async {
        await safeExecute(
            operationId: "fetch_exercises_offline",
            loadingMessage: isOffline ? "Loading from offline storage..." : "Loading exercises...",
            context: "Fetching exercises (offline-aware)"
        ) { [weak self] in
            guard let self = self else { return }
            let exercises = await self.offlineExerciseRepository.fetchTrainerExercises()
            self.updateItems(exercises)
            
            print("OfflineExerciseListViewModel: Fetched \(exercises.count) exercises (offline: \(self.isOffline))")
        }
    }
    
    func refreshExercises() async {
        await fetchExercises()
    }
    
    func syncData() async {
        guard networkMonitor.isConnected else { return }
        
        await safeExecute(
            operationId: "sync_exercises",
            loadingMessage: "Syncing with server...",
            context: "Syncing exercise data"
        ) { [weak self] in
            await self?.offlineExerciseRepository.syncWithServer()
            await self?.fetchExercises()
        }
    }
    
    override func retry() {
        Task {
            await fetchExercises()
        }
    }
}

// MARK: - Offline-Aware Assignment List ViewModel
@MainActor
class OfflineAssignmentListViewModel: ListViewModel<Assignment> {
    @Published var isOffline = false
    @Published var lastSyncDate: Date?
    @Published var pendingAssignments: [Assignment] = []
    @Published var completedAssignments: [Assignment] = []
    
    private let offlineAssignmentRepository: OfflineAssignmentRepository
    private let networkMonitor = NetworkMonitor.shared
    private let syncManager = SyncManager.shared
    
    init(apiService: APIService) {
        self.offlineAssignmentRepository = OfflineAssignmentRepository(apiService: apiService)
        super.init()
        
        networkMonitor.$isConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                self?.isOffline = !isConnected
                if isConnected {
                    Task {
                        await self?.syncData()
                    }
                }
            }
            .store(in: &cancellables)
        
        syncManager.$lastSyncDate
            .receive(on: DispatchQueue.main)
            .assign(to: \.lastSyncDate, on: self)
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    func fetchAssignments() async {
        await safeExecute(
            operationId: "fetch_assignments_offline",
            loadingMessage: isOffline ? "Loading from offline storage..." : "Loading assignments...",
            context: "Fetching assignments (offline-aware)"
        ) { [weak self] in
            guard let self = self else { return }
            let assignments = await self.offlineAssignmentRepository.fetchClientAssignments()
            self.updateItems(assignments)
            self.categorizeAssignments(assignments)
            
            print("OfflineAssignmentListViewModel: Fetched \(assignments.count) assignments (offline: \(self.isOffline))")
        }
    }
    
    private func categorizeAssignments(_ assignments: [Assignment]) {
        pendingAssignments = assignments.filter { $0.status != "completed" }
        completedAssignments = assignments.filter { $0.status == "completed" }
    }
    
    func refreshAssignments() async {
        await fetchAssignments()
    }
    
    func syncData() async {
        guard networkMonitor.isConnected else { return }
        
        await safeExecute(
            operationId: "sync_assignments",
            loadingMessage: "Syncing with server...",
            context: "Syncing assignment data"
        ) { [weak self] in
            await self?.offlineAssignmentRepository.syncWithServer()
            await self?.fetchAssignments()
        }
    }
    
    override func retry() {
        Task {
            await fetchAssignments()
        }
    }
}

// MARK: - Import Combine
import Combine
