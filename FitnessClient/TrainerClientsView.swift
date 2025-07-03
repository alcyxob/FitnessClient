// TrainerClientsView.swift
import SwiftUI

struct TrainerClientsView: View {
    @StateObject var viewModel: TrainerClientsViewModel
    @EnvironmentObject var apiService: APIService
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var toastManager: ToastManager
    @Environment(\.appTheme) var theme
    @State private var showingAddClientSheet = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Themed header
                RoleHeaderView(
                    "My Clients",
                    subtitle: "Manage and track your clients' progress"
                )
                
                // Main content
                ZStack {
                    theme.background.ignoresSafeArea()
                    
                    if viewModel.isLoading && viewModel.items.isEmpty {
                        ThemedProgressView(message: "Loading clients...")
                    } else if viewModel.items.isEmpty && !viewModel.isLoading {
                        ThemedEmptyState(
                            title: "No Clients Yet",
                            message: "Add your first client to get started with creating personalized training plans and tracking their progress.",
                            icon: "person.2.badge.plus",
                            actionTitle: "Add Client"
                        ) {
                            showingAddClientSheet = true
                        }
                    } else {
                        clientListView
                    }
                }
            }
            .navigationBarHidden(true)
            .refreshable {
                await viewModel.refreshClients()
            }
            .loadingOverlay(
                isLoading: viewModel.isLoading && !viewModel.items.isEmpty,
                message: "Refreshing clients..."
            )
            .errorHandling {
                viewModel.retry()
            }
            .sheet(isPresented: $showingAddClientSheet,
                   onDismiss: {
                        Task { await viewModel.refreshClients() }
                   }) {
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
    
    private var clientListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Add client button at top
                ThemedCard {
                    Button(action: {
                        showingAddClientSheet = true
                    }) {
                        HStack {
                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(theme.primary)
                            
                            Text("Add New Client")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(theme.primary)
                            
                            Spacer()
                            
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(theme.primary)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                // Clients list
                ForEach(viewModel.items, id: \.id) { client in
                    NavigationLink(destination: ClientDetailView(
                        client: client,
                        apiService: apiService,
                        authService: authService
                    )) {
                        ThemedClientRow(client: client)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, 16)
                }
            }
            .padding(.bottom, 20)
        }
    }
}

struct ThemedClientRow: View {
    @Environment(\.appTheme) var theme
    let client: UserResponse
    
    var body: some View {
        ThemedCard {
            HStack(spacing: 16) {
                // Avatar
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
                    
                    HStack(spacing: 4) {
                        Image(systemName: "person.circle")
                            .font(.caption)
                            .foregroundColor(theme.accent)
                        
                        Text("Active Client")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(theme.accent)
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
    TrainerClientsView(viewModel: TrainerClientsViewModel(apiService: APIService(authService: AuthService())))
        .environmentObject(AuthService())
        .environmentObject(ToastManager())
        .environment(\.appTheme, AppTheme.trainer)
}
