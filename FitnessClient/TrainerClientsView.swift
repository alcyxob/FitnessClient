// TrainerClientsView.swift
import SwiftUI

struct TrainerClientsView: View {
    // ViewModel instance is created by the parent view (MainTabView)
    // and passed into this view's initializer.
    @StateObject var viewModel: TrainerClientsViewModel

    // Services obtained from the environment, needed to pass down
    // to presented sheets or navigated views.
    @EnvironmentObject var apiService: APIService
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var toastManager: ToastManager

    // State to control the presentation of the "Add Client" sheet.
    @State private var showingAddClientSheet = false

    var body: some View {
        // Embed in a NavigationView to get a navigation bar for title and toolbar items
        // specific to this screen. If the parent TabView setup already provides one
        // per tab, this might technically be redundant but often helps clarity.
        
        NavigationView {
            
            VStack { // Use a VStack to structure content within the NavigationView body
                // --- Loading State ---
                // Show ProgressView only if loading AND the list is currently empty
                if viewModel.isLoading && viewModel.clients.isEmpty {
                    ProgressView("Loading Clients...")
                        .padding()
                    Spacer() // Push loader to center if desired
                }
                // --- Error State ---
                else if let errorMessage = viewModel.errorMessage {
                    VStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.orange)
                        Text("Error Loading Clients")
                            .font(.headline)
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            Task { await viewModel.fetchManagedClients() }
                        }
                        .padding(.top)
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    Spacer() // Push error message to center
                }
                // --- Empty State ---
                else if viewModel.clients.isEmpty {
                    VStack(spacing: 10) {
                         Image(systemName: "person.2.slash")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.secondary)
                         Text("No Clients Yet")
                            .font(.headline)
                         Text("Tap the '+' button to add your first client by email.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    Spacer() // Push empty state message to center
                }
                // --- Data Loaded State ---
                else {
                    // Display the list of clients
                    List {
                        ForEach(viewModel.clients) { client in
                            // Wrap the row content in NavigationLink
                            NavigationLink {
                                // Destination: Create the detail view when tapped
                                ClientDetailView(
                                    client: client,
                                    apiService: apiService, // Pass needed services
                                    authService: authService
                                )
                            } label: {
                                // Label: How the row looks in the list
                                VStack(alignment: .leading) {
                                    Text(client.name)
                                        .font(.headline)
                                    Text(client.email)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 4) // Add slight padding inside the row
                            }
                        }
                        // TODO: Add .onDelete modifier here later if needed
                        // .onDelete(perform: removeClient)
                    }
                    .listStyle(.plain) // Use plain style for edge-to-edge look
                    // Add pull-to-refresh capability
                    .refreshable {
                        print("Refreshing client list...")
                        await viewModel.fetchManagedClients()
                    }
                } // End of conditional content display (Loading/Error/Empty/List)

            } // End VStack
            .navigationTitle("My Clients") // Title for the navigation bar
            // .navigationBarTitleDisplayMode(.inline) // Optional: smaller title style
            .toolbar {
                // Add the "+" button to the top-right corner
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddClientSheet = true // Set state to present the sheet
                    } label: {
                        Label("Add Client", systemImage: "plus.circle.fill") // Use Label for icon+text or just Image
                    }
                }
                // Optional: Add an EditButton if you implement list editing/deleting
                // ToolbarItem(placement: .navigationBarLeading) { EditButton() }
            }
            .sheet(isPresented: $showingAddClientSheet,
                   onDismiss: {
                        // Action to perform when the sheet is dismissed
                        print("Add Client sheet dismissed. Refreshing client list.")
                        Task { await viewModel.fetchManagedClients() }
                   }) {
                // The View to present as a sheet
                // Pass the required APIService from the environment
                AddClientByEmailView(apiService: apiService, toastManager: toastManager)
            }
            .onAppear {
                // Action when the view first appears
                // Fetch clients only if the list is currently empty to avoid
                // unnecessary reloads every time the tab is selected.
                if viewModel.clients.isEmpty {
                    print("TrainerClientsView appeared. Fetching clients.")
                    Task { await viewModel.fetchManagedClients() }
                }
            }
         
        } // End NavigationView
        // Use .stack navigation style for typical phone push/pop behavior
        .navigationViewStyle(.stack)
    } // End body

    // TODO: Implement removeClient function if needed
    // func removeClient(at offsets: IndexSet) {
    //     print("Attempting to remove clients at: \(offsets)")
    //     // Call a method on the viewModel to handle deletion via API
    //     // viewModel.removeClients(at: offsets)
    // }
} // End struct TrainerClientsView

// Updated Preview Provider
struct TrainerClientsView_Previews: PreviewProvider {

    // --- Define the MINIMAL Helper Wrapper View ---
    struct MinimalPreviewWrapper: View {
        @StateObject var viewModel: TrainerClientsViewModel

        var body: some View {
            TrainerClientsView(viewModel: viewModel)
        }
    }
    // --- End Minimal Helper Wrapper View ---

    static var previews: some View {
        // --- Setup Mock Services ONCE ---
        let mockAuthService = AuthService()
        mockAuthService.authToken = "fake_token_for_preview"
        mockAuthService.loggedInUser = UserResponse(id: "previewTrainer", name: "Preview Trainer", email: "preview@trainer.com", roles: ["trainer"], createdAt: Date(), clientIds: nil, trainerId: nil)
        let mockAPIService = APIService(authService: mockAuthService)

        // --- Create and configure ONE ViewModel for the single preview ---
        let vmData: TrainerClientsViewModel = {
             let vm = TrainerClientsViewModel(apiService: mockAPIService)
             vm.clients = [
                UserResponse(id: "client1", name: "Alice Example", email: "alice@example.com", roles: ["client"], createdAt: Date(), clientIds: nil, trainerId: "previewTrainer"),
                UserResponse(id: "client2", name: "Bob Sample", email: "bob@sample.com", roles: ["client"], createdAt: Date(), clientIds: nil, trainerId: "previewTrainer")
             ]
             return vm
        }()

        // --- Return JUST the Wrapper for the single preview ---
        return MinimalPreviewWrapper(viewModel: vmData) // Return the wrapper directly
            // Apply EnvironmentObjects to this single wrapper instance
            .environmentObject(mockAuthService)
            .environmentObject(mockAPIService)

        /* // --- COMMENT OUT THE GROUP ---
        Group {
            MinimalPreviewWrapper(viewModel: { ... }())
                .previewDisplayName("With Data")
            // ... other wrappers ...
        }
        .environmentObject(mockAuthService)
        .environmentObject(mockAPIService)
        */
    }
}
