// TrainerClientsView.swift
import SwiftUI

struct TrainerClientsView: View {
    @StateObject var viewModel: TrainerClientsViewModel
    @EnvironmentObject var apiService: APIService
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var toastManager: ToastManager
    @State private var showingAddClientSheet = false

    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading && viewModel.items.isEmpty {
                    // Show loading for initial load
                    ProgressView("Loading clients...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.items.isEmpty && !viewModel.isLoading {
                    // Show empty state
                    EmptyStateView(
                        title: "No Clients Yet",
                        message: "Add your first client to get started with training plans and workouts.",
                        systemImage: "person.2",
                        actionTitle: "Add Client"
                    ) {
                        showingAddClientSheet = true
                    }
                } else {
                    // Show client list
                    clientListView
                }
            }
            .navigationTitle("My Clients")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddClientSheet = true
                    } label: {
                        Label("Add Client", systemImage: "plus.circle.fill")
                    }
                }
            }
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
        List {
            ForEach(viewModel.items) { client in
                NavigationLink {
                    ClientDetailView(
                        client: client,
                        apiService: apiService,
                        authService: authService
                    )
                } label: {
                    ClientRowView(client: client)
                }
            }
        }
        .listStyle(.plain)
    }
}

struct ClientRowView: View {
    let client: UserResponse
    
    var body: some View {
        HStack {
            // Avatar placeholder
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(client.name.prefix(1).uppercased())
                        .font(.headline)
                        .foregroundColor(.blue)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(client.name)
                    .font(.headline)
                
                Text(client.email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding(.vertical, 4)
    }
}

// Updated Preview Provider
struct TrainerClientsView_Previews: PreviewProvider {
    struct MinimalPreviewWrapper: View {
        @StateObject var viewModel: TrainerClientsViewModel

        var body: some View {
            TrainerClientsView(viewModel: viewModel)
        }
    }

    static var previews: some View {
        let mockAuthService = AuthService()
        mockAuthService.authToken = "fake_token_for_preview"
        mockAuthService.loggedInUser = UserResponse(id: "previewTrainer", name: "Preview Trainer", email: "preview@trainer.com", roles: ["trainer"], createdAt: Date(), clientIds: nil, trainerId: nil)
        let mockAPIService = APIService(authService: mockAuthService)

        let vmData: TrainerClientsViewModel = {
             let vm = TrainerClientsViewModel(apiService: mockAPIService)
             vm.updateItems([
                UserResponse(id: "client1", name: "Alice Example", email: "alice@example.com", roles: ["client"], createdAt: Date(), clientIds: nil, trainerId: "previewTrainer"),
                UserResponse(id: "client2", name: "Bob Sample", email: "bob@sample.com", roles: ["client"], createdAt: Date(), clientIds: nil, trainerId: "previewTrainer")
             ])
             return vm
        }()

        return MinimalPreviewWrapper(viewModel: vmData)
            .environmentObject(mockAuthService)
            .environmentObject(mockAPIService)
            .environmentObject(ToastManager())
    }
}
