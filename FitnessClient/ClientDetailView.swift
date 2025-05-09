// ClientDetailView.swift
import SwiftUI

struct ClientDetailView: View {
    // Use @StateObject because this view OWNS this specific ViewModel instance
    // based on the client passed to it.
    @StateObject var viewModel: ClientDetailViewModel

    // EnvironmentObjects are passed down from parent views (like TrainerClientsView via MainTabView)
    // and will be passed further to views navigated to or presented by this view.
    @EnvironmentObject var apiService: APIService
    @EnvironmentObject var authService: AuthService

    // State to control the presentation of the "Create Training Plan" sheet.
    @State private var showingCreatePlanSheet = false

    // Initializer receives the specific client and the services needed by the ViewModel.
    // The services (apiService, authService) are typically received from the parent
    // view via @EnvironmentObject and then passed explicitly here.
    init(client: UserResponse, apiService: APIService, authService: AuthService) {
        // Create the ViewModel instance specific to this client
        _viewModel = StateObject(wrappedValue: ClientDetailViewModel(client: client, apiService: apiService, authService: authService))
    }

    var body: some View {
        // List provides a good structure for sections of details.
        List {
            // --- Section for Client Information ---
            Section(header: Text("Client Info")) {
                HStack {
                    Text("Name:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(viewModel.client.name)
                }
                HStack {
                    Text("Email:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(viewModel.client.email)
                }
                // TODO: Add other relevant client details here if they exist in UserResponse
                // e.g., phone number, registration date, etc.
            }

            // --- Section for Training Plans ---
            Section(header: Text("Training Plans")) {
                // Loading State for Plans
                if viewModel.isLoadingPlans {
                    HStack { // Center the ProgressView
                        Spacer()
                        ProgressView("Loading plans...")
                        Spacer()
                    }
                }
                // Error State for Plans
                else if let errorMessage = viewModel.errorMessage {
                    VStack(alignment: .center, spacing: 10) {
                        Image(systemName: "exclamationmark.bubble.fill")
                            .foregroundColor(.orange)
                            .font(.title)
                        Text("Error: \(errorMessage)")
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                        Button("Retry Fetching Plans") {
                            Task { await viewModel.fetchTrainingPlans() }
                        }
                        .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity) // Ensure VStack takes width for centering
                    .padding()
                }
                // Empty State for Plans
                else if viewModel.trainingPlans.isEmpty {
                    VStack(alignment: .center, spacing: 10) {
                        Image(systemName: "doc.text.magnifyingglass")
                             .foregroundColor(.secondary)
                             .font(.largeTitle)
                        Text("No training plans found for this client yet.")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Button("Create First Plan") {
                            showingCreatePlanSheet = true
                        }
                        .buttonStyle(.borderedProminent) // Make it stand out
                        .padding(.top)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                // Data Loaded State for Plans
                else {
                    ForEach(viewModel.trainingPlans) { plan in
                        // Wrap each plan row in a NavigationLink
                        NavigationLink {
                            // Destination: WorkoutListView for the selected plan
                            WorkoutListView(
                                trainingPlan: plan,
                                apiService: apiService,   // Pass down from environment
                                authService: authService  // Pass down from environment
                            )
                        } label: {
                            // Label: How the plan row looks in the list
                            VStack(alignment: .leading) {
                                Text(plan.name)
                                    .font(.headline)
                                if let desc = plan.description, !desc.isEmpty {
                                    Text(desc)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .lineLimit(1) // Show a snippet
                                }
                                HStack {
                                    if plan.isActive {
                                        Text("Active")
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                            .padding(.horizontal, 5)
                                            .padding(.vertical, 2)
                                            .background(Color.green.opacity(0.2))
                                            .foregroundColor(.green)
                                            .cornerRadius(4)
                                    }
                                    // TODO: Add start/end dates if available and meaningful for display
                                    // if let startDate = plan.startDate { Text("Starts: \(startDate, style: .date))").font(.caption2) }
                                }
                            }
                            .padding(.vertical, 3) // Add a bit of padding to list items
                        }
                        // TODO: Add .onDelete for plans later if needed
                    }
                }
            } // End Training Plans Section
        } // End List
        .navigationTitle(viewModel.client.name) // Set navigation bar title to client's name
        // .navigationBarTitleDisplayMode(.inline) // Optional: for a smaller title
        .toolbar {
            // Add a "+" button to the toolbar to create a new training plan
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingCreatePlanSheet = true // Trigger the sheet presentation
                } label: {
                    Label("New Plan", systemImage: "plus.circle.fill")
                }
            }
        }
        .sheet(isPresented: $showingCreatePlanSheet,
               onDismiss: {
                    // Action to perform when the "Create Training Plan" sheet is dismissed
                    print("Create Training Plan sheet dismissed. Refreshing plans for client \(viewModel.client.id).")
                    Task { await viewModel.fetchTrainingPlans() }
               }) {
            // The View to present as a sheet
            CreateTrainingPlanView(
                client: viewModel.client, // Pass the current client
                apiService: apiService    // Pass the APIService from environment
            )
            // Pass authService if CreateTrainingPlanView or its ViewModel needs it directly
            // .environmentObject(authService)
        }
        .onAppear {
            // Fetch training plans when the view first appears
            print("ClientDetailView appeared for \(viewModel.client.email). Fetching plans.")
            Task { await viewModel.fetchTrainingPlans() }
        }
        // Add pull-to-refresh for the list of plans
        .refreshable {
             print("Refreshing training plans for client \(viewModel.client.id)...")
             await viewModel.fetchTrainingPlans()
        }
    } // End body
} // End struct ClientDetailView


// Updated Preview Provider
struct ClientDetailView_Previews: PreviewProvider {

    // --- Define the MINIMAL Helper Wrapper View ---
    struct PreviewWrapper: View {
        let client: UserResponse
        let authService: AuthService
        let apiService: APIService

        var body: some View {
            ClientDetailView(
                client: client,
                apiService: apiService,
                authService: authService
            )
            .environmentObject(authService)
            .environmentObject(apiService)
        }
    }
    // --- End Minimal Helper Wrapper View ---

    static var previews: some View {
        // --- SETUP PHASE ---
        // 1. Create mock AuthService and configure it
        let configuredAuthService = AuthService() // Use a different variable name
        configuredAuthService.authToken = "fake_preview_token"
        configuredAuthService.loggedInUser = UserResponse(
            id: "trainerPreview456",
            name: "Preview Trainer",
            email: "trainer@preview.com",
            role: "trainer",
            createdAt: Date(), // This should be fine
            clientIds: nil,
            trainerId: nil
        )
        
        // 2. Create mock APIService using the configured AuthService
        let configuredAPIService = APIService(authService: configuredAuthService)

        // 3. Create a mock Client (UserResponse) to display
        let previewClient = UserResponse(
            id: "clientPreview123",
            name: "Alice Johnson (Preview)",
            email: "alice.preview@example.com",
            role: "client",
            createdAt: Date(),
            clientIds: nil,
            trainerId: "trainerPreview456"
        )
        
        // --- RETURN PHASE ---
        // Return the view hierarchy. All setup is done above.
        return NavigationView { // Ensure NavigationView is here for title/toolbar
            PreviewWrapper(
                client: previewClient,
                authService: configuredAuthService, // Use the configured instance
                apiService: configuredAPIService    // Use the configured instance
            )
            // It's generally better to apply environmentObjects inside the wrapper
            // or to the direct view if not using a wrapper, but since the wrapper
            // itself is simple, applying them to NavigationView containing the wrapper
            // might also work, though the previous way (inside wrapper) is cleaner.
            // Let's stick to the wrapper applying them for now.
        }
    }
}
