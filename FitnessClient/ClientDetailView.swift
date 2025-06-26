// ClientDetailView.swift
import SwiftUI

struct ClientDetailView: View {
    // ViewModel is owned by this view. Its initialization path determines
    // whether it starts with full client data or needs to fetch it.
    @StateObject var viewModel: ClientDetailViewModel
    
    // Services obtained from the environment, passed to sub-views.
    @EnvironmentObject var apiService: APIService
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var toastManager: ToastManager

    // State for presenting the "Create Training Plan" sheet.
    @State private var showingCreatePlanSheet = false

    // Initializer for when a full UserResponse object for the client is already available
    // (e.g., when navigating from TrainerClientsView where the full list was fetched).
    init(client: UserResponse, apiService: APIService, authService: AuthService) {
        _viewModel = StateObject(wrappedValue: ClientDetailViewModel(client: client, apiService: apiService, authService: authService))
        print("ClientDetailView: Initialized with full client object: \(client.email)")
    }

    // Initializer for when only the clientID is available
    // (e.g., when navigating from TrainerDashboardView).
    init(clientId: String, apiService: APIService, authService: AuthService) {
        _viewModel = StateObject(wrappedValue: ClientDetailViewModel(clientId: clientId, apiService: apiService, authService: authService))
        print("ClientDetailView: Initialized with clientID: \(clientId). Will fetch details.")
    }

    var body: some View {
        // Use a Group to manage the display based on whether client details are loaded.
        Group {
            if viewModel.isLoadingClientDetails {
                // Shown if initialized with clientId and details are being fetched.
                ProgressView("Loading Client Details...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity) // Center it
            } else if let client = viewModel.client {
                // --- Main content once client details are available ---
                List {
                    // Section for basic client information
                    Section(header: Text("Client Info")) {
                        HStack {
                            Text("Name:")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(client.name)
                        }
                        HStack {
                            Text("Email:")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(client.email)
                        }
                        // TODO: Add other client details here if they exist in UserResponse
                    }

                    // Section for the client's training plans
                    Section(header: Text("Training Plans")) {
                        if viewModel.isLoadingPlans {
                            HStack { Spacer(); ProgressView("Loading plans..."); Spacer() }
                        } else if let errorMessage = viewModel.errorMessage, viewModel.trainingPlans.isEmpty {
                            // Show specific error for plan loading if plans list is also empty
                            VStack(alignment: .center, spacing: 10) {
                                Image(systemName: "exclamationmark.bubble.fill").foregroundColor(.orange).font(.title)
                                Text("Could Not Load Plans").font(.headline)
                                Text(errorMessage).font(.caption).foregroundColor(.secondary).multilineTextAlignment(.center)
                                Button("Retry Fetching Plans") {
                                    Task { await viewModel.fetchTrainingPlans() }
                                }
                                .buttonStyle(.bordered)
                            }
                            .frame(maxWidth: .infinity).padding()
                        } else if viewModel.trainingPlans.isEmpty {
                            VStack(alignment: .center, spacing: 10) {
                                Image(systemName: "doc.text.magnifyingglass").foregroundColor(.secondary).font(.largeTitle)
                                Text("No training plans assigned yet.")
                                    .font(.headline).foregroundColor(.secondary)
                                Button("Create First Plan for \(client.name.components(separatedBy: " ").first ?? "Client")") {
                                    showingCreatePlanSheet = true
                                }
                                .buttonStyle(.borderedProminent)
                                .padding(.top)
                            }
                            .frame(maxWidth: .infinity).padding()
                        } else {
                            ForEach(viewModel.trainingPlans) { plan in
                                NavigationLink {
                                    // Navigate to WorkoutListView for the selected plan
                                    WorkoutListView(
                                        trainingPlan: plan,
                                        apiService: apiService,
                                        authService: authService // Pass down necessary services
                                    )
                                } label: {
                                    // How each plan row looks in the list
                                    VStack(alignment: .leading) {
                                        Text(plan.name).font(.headline)
                                        if let desc = plan.description, !desc.isEmpty {
                                            Text(desc).font(.caption).foregroundColor(.gray).lineLimit(1)
                                        }
                                        HStack {
                                            if plan.isActive {
                                                Text("Active")
                                                    .font(.caption2).fontWeight(.bold)
                                                    .padding(.horizontal, 5).padding(.vertical, 2)
                                                    .background(Color.green.opacity(0.2))
                                                    .foregroundColor(.green).cornerRadius(4)
                                            }
                                            // TODO: Display start/end dates if useful
                                        }
                                    }
                                    .padding(.vertical, 3)
                                }
                            }
                            .onDelete(perform: deletePlans) // Swipe-to-delete for plans
                        }
                    } // End Training Plans Section
                } // End List
                .navigationTitle(client.name) // Use the fetched client's name
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) { EditButton() } // For list editing (delete)
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showingCreatePlanSheet = true
                        } label: {
                            Label("New Plan", systemImage: "plus.circle.fill")
                        }
                    }
                }
                .sheet(isPresented: $showingCreatePlanSheet, onDismiss: {
                    print("Create Training Plan sheet dismissed. Refreshing plans for client \(client.id).")
                    Task { await viewModel.fetchTrainingPlans() } // Refresh plans list
                }) {
                    // Ensure client object is available before presenting sheet that needs it
                    CreateTrainingPlanView(
                        client: client, // Pass the fully loaded client object
                        apiService: apiService,
                        toastManager: toastManager
                    )
                }
                .refreshable { // Pull to refresh for the list of plans
                     print("ClientDetailView: Refreshing training plans for client \(client.id)...")
                     await viewModel.fetchTrainingPlans()
                }
                .onAppear {
                    // This onAppear is for the List content, fetch plans if client details are loaded
                    print("ClientDetailView: List content appeared for \(client.email). Fetching plans if needed.")
                    if viewModel.trainingPlans.isEmpty { // Fetch plans only if not already loaded
                        Task { await viewModel.fetchTrainingPlans() }
                    }
                }

            } else if let errorMessage = viewModel.errorMessage {
                // Error state specifically for failing to load client details
                VStack(spacing: 15) {
                    Image(systemName: "person.crop.circle.badge.exclamationmark.fill").font(.largeTitle).foregroundColor(.red)
                    Text("Error Loading Client Details").font(.headline)
                    Text(errorMessage).font(.callout).foregroundColor(.secondary).multilineTextAlignment(.center)
                    Button("Retry") { Task { await viewModel.fetchClientDetailsIfNeeded() }}
                        .buttonStyle(.borderedProminent)
                }
                .padding()
                .navigationTitle("Error") // Or some generic title
            } else {
                // Fallback if somehow no client and no error, should be brief
                Text("Loading client information...")
                    .navigationTitle("Loading...")
            }
        } // End Group
        .onAppear {
            // This onAppear is for the entire ClientDetailView (the Group)
            // Trigger initial client detail fetch if it was initialized with only an ID
            print("ClientDetailView (Outer Group): Appeared. Triggering fetchClientDetailsIfNeeded.")
            Task { await viewModel.fetchClientDetailsIfNeeded() }
        }
    } // End body
    
    // --- Function to handle deletion of training plans ---
    private func deletePlans(at offsets: IndexSet) {
        guard let client = viewModel.client else { return } // Should always have client by this point
        let plansToDelete = offsets.map { viewModel.trainingPlans[$0] }
        
        Task {
            for plan in plansToDelete {
                print("ClientDetailView: Requesting delete for plan ID: \(plan.id) by trainer \(viewModel.trainerId ?? "N/A") for client \(client.id)")
                let success = await viewModel.deleteTrainingPlan(planId: plan.id) // ViewModel handles passing trainerId from authService
                if !success {
                    print("ClientDetailView: Failed to delete plan \(plan.id). Error: \(viewModel.errorMessage ?? "Unknown error")")
                    break
                }
            }
            // ViewModel's deleteTrainingPlan should optimistically update the trainingPlans array
            // or fetchTrainingPlans could be called again if needed.
        }
    }
} // End struct ClientDetailView


// Preview Provider
struct ClientDetailView_Previews: PreviewProvider {
    static func createFullClientPreview() -> some View {
        let mockAuth = AuthService();
        mockAuth.loggedInUser = UserResponse(id: "trainerPrev1", name: "Preview Trainer", email: "trainer@preview.com", roles: ["trainer"], createdAt: Date(), clientIds: nil, trainerId: nil)
        mockAuth.authToken = "fake_token"
        let mockAPI = APIService(authService: mockAuth);
        
        let previewClient = UserResponse(id: "clientFullPrev1", name: "Full Client (Alice)", email: "full_alice@c.com", roles: ["client"], createdAt: Date(), clientIds: nil, trainerId: "trainerPrev1")
        
        // To see plans in preview, the ClientDetailViewModel would need to be pre-populated,
        // or the mockAPIService would need to return mock plans for "/trainer/clients/{id}/plans".
        // For now, it will show "Loading plans..." then likely "No plans..."
        
        return NavigationView {
            ClientDetailView(client: previewClient, apiService: mockAPI, authService: mockAuth)
        }
        .environmentObject(mockAPI)
        .environmentObject(mockAuth)
    }

    static func createIdOnlyPreview() -> some View {
        let mockAuth = AuthService();
        mockAuth.loggedInUser = UserResponse(id: "trainerPrev2", name: "Preview Trainer", email: "trainer@preview.com", roles: ["trainer"], createdAt: Date(), clientIds: nil, trainerId: nil)
        mockAuth.authToken = "fake_token"
        let mockAPI = APIService(authService: mockAuth);
        
        // This preview will initially show "Loading Client Details..."
        // For it to resolve, the mockAPIService would need to handle the
        // GET /trainer/clients endpoint and return a UserResponse matching "clientIdForPreview"
        // when ClientDetailViewModel calls fetchClientDetailsIfNeeded.
        return NavigationView {
            ClientDetailView(clientId: "clientIdForPreview", apiService: mockAPI, authService: mockAuth)
        }
        .environmentObject(mockAPI)
        .environmentObject(mockAuth)
    }

    static var previews: some View {
        Group {
            createFullClientPreview()
                .previewDisplayName("With Full Client Object")

            createIdOnlyPreview()
                .previewDisplayName("With Client ID (Fetches Details)")
        }
    }
}
