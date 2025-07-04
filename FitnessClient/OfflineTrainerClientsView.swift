// OfflineTrainerClientsView.swift
import SwiftUI

struct OfflineTrainerClientsView: View {
    @StateObject private var viewModel: OfflineTrainerClientsViewModel
    @EnvironmentObject var apiService: APIService
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var toastManager: ToastManager
    @Environment(\.appTheme) var theme
    @State private var showingAddClientSheet = false

    init(apiService: APIService) {
        _viewModel = StateObject(wrappedValue: OfflineTrainerClientsViewModel(apiService: apiService))
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Themed header with offline indicator
                RoleHeaderView(
                    "My Clients",
                    subtitle: viewModel.isOffline ? 
                    "Viewing offline data • \(viewModel.items.count) clients" :
                    "Manage and track your clients' progress"
                )
                
                // Offline-aware list
                OfflineAwareListView(
                    items: viewModel.items,
                    isLoading: viewModel.isLoading,
                    onRefresh: {
                        await viewModel.refreshClients()
                    },
                    onSync: {
                        await viewModel.syncData()
                    },
                    emptyTitle: "No Clients Yet",
                    emptyMessage: "Add your first client to get started with creating personalized training plans.",
                    emptyIcon: "person.2.badge.plus"
                ) { client in
                    NavigationLink(destination: ClientDetailView(
                        client: client,
                        apiService: apiService,
                        authService: authService
                    )) {
                        OfflineClientRow(client: client)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationBarHidden(true)
            .errorHandling {
                viewModel.retry()
            }
            .sheet(isPresented: $showingAddClientSheet) {
                AddClientByEmailView(apiService: apiService, toastManager: toastManager)
            }
            .onAppear {
                if viewModel.items.isEmpty {
                    Task { await viewModel.fetchManagedClients() }
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}

struct OfflineClientRow: View {
    @Environment(\.appTheme) var theme
    @EnvironmentObject var networkMonitor: NetworkMonitor
    let client: UserResponse
    
    var body: some View {
        ThemedCard {
            HStack(spacing: 16) {
                // Avatar with offline indicator
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [theme.primary, theme.secondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    
                    Text(client.name.prefix(1).uppercased())
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    // Offline indicator
                    if !networkMonitor.isConnected {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Circle()
                                    .fill(.orange)
                                    .frame(width: 12, height: 12)
                                    .overlay(
                                        Image(systemName: "wifi.slash")
                                            .font(.system(size: 6, weight: .bold))
                                            .foregroundColor(.white)
                                    )
                            }
                        }
                    }
                }
                
                // Client info
                VStack(alignment: .leading, spacing: 6) {
                    Text(client.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.primaryText)
                    
                    Text(client.email)
                        .font(.subheadline)
                        .foregroundColor(theme.secondaryText)
                    
                    HStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Image(systemName: "person.circle")
                                .font(.caption)
                                .foregroundColor(theme.accent)
                            
                            Text("Active Client")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(theme.accent)
                        }
                        
                        if !networkMonitor.isConnected {
                            HStack(spacing: 4) {
                                Image(systemName: "internaldrive")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                
                                Text("Offline")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.tertiaryText)
            }
        }
    }
}

#Preview {
    OfflineTrainerClientsView(apiService: APIService(authService: AuthService()))
        .environmentObject(AuthService())
        .environmentObject(ToastManager())
        .environmentObject(NetworkMonitor.shared)
        .environmentObject(SyncManager.shared)
        .environment(\.appTheme, AppTheme.trainer)
}
