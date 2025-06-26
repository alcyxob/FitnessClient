// ClientPlansView.swift
import SwiftUI

struct ClientPlansView: View {
    @StateObject var viewModel: ClientPlansViewModel
    @EnvironmentObject var apiService: APIService // For navigation
    @EnvironmentObject var authService: AuthService // For navigation context if needed

    // Initializer to create the ViewModel, taking APIService from environment
    init(apiService: APIService) {
        _viewModel = StateObject(wrappedValue: ClientPlansViewModel(apiService: apiService))
        print("ClientPlansView: Initialized.")
    }

    var body: some View {
        NavigationView { // Each main tab should have its own NavigationView for independent navigation stacks
            VStack {
                if viewModel.isLoading {
                    ProgressView("Loading Your Plans...")
                } else if let errorMessage = viewModel.errorMessage, viewModel.trainingPlans.isEmpty { // Show error only if no plans to show
                    VStack(spacing: 10) {
                        Image(systemName: "exclamationmark.bubble").font(.largeTitle).foregroundColor(.orange)
                        Text("Could Not Load Plans").font(.headline)
                        Text(errorMessage).font(.caption).foregroundColor(.secondary).multilineTextAlignment(.center)
                        Button("Retry") { Task { await viewModel.fetchMyTrainingPlans() }}
                            .buttonStyle(.bordered)
                    }.padding()
                } else if viewModel.trainingPlans.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "doc.text.magnifyingglass").font(.largeTitle).foregroundColor(.secondary)
                        Text("No Plans Yet").font(.headline)
                        Text("Your trainer hasn't assigned you any training plans yet. Check back soon!").font(.caption).foregroundColor(.secondary).multilineTextAlignment(.center)
                    }.padding()
                } else {
                    List {
                        ForEach(viewModel.trainingPlans) { plan in
                            // TODO: NavigationLink to ClientWorkoutsView for this plan
                            NavigationLink {
                                // Destination: ClientWorkoutsView (To be created)
                                ClientWorkoutsView( // Navigate to the new view
                                    trainingPlan: plan,
                                    apiService: apiService // Pass the APIService from environment
                                )
                            } label: {
                                VStack(alignment: .leading) {
                                    Text(plan.name).font(.headline)
                                    if let desc = plan.description, !desc.isEmpty {
                                        Text(desc).font(.caption).foregroundColor(.gray).lineLimit(1)
                                    }
                                    if plan.isActive {
                                        HStack {
                                            Image(systemName: "flame.fill").foregroundColor(.orange)
                                            Text("Active Plan").font(.caption).fontWeight(.semibold).foregroundColor(.orange)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .refreshable { await viewModel.fetchMyTrainingPlans() }
                }
            }
            .navigationTitle("My Training Plans")
            .onAppear {
                if viewModel.trainingPlans.isEmpty { // Fetch only if list is empty
                     print("ClientPlansView: Appeared. Fetching my plans.")
                     Task { await viewModel.fetchMyTrainingPlans() }
                }
            }
        }
        .navigationViewStyle(.stack) // Consistent navigation style
    }
}

// Preview Provider
struct ClientPlansView_Previews: PreviewProvider {

    // Helper static function to create a configured preview instance
    static func createPreviewInstance() -> some View {
        // 1. Setup mock AuthService and configure it
        let mockAuthService = AuthService()
        mockAuthService.authToken = "fake_client_token"
        mockAuthService.loggedInUser = UserResponse(
            id: "clientPreview1",
            name: "Client Preview User",
            email: "client@preview.com",
            roles: ["client"],
            createdAt: Date(), // Ensure Date() is accessible
            clientIds: nil,
            trainerId: "trainer1"
        )
        
        // 2. Setup mock APIService (depends on the configured mockAuthService)
        let mockAPIService = APIService(authService: mockAuthService)
        
        // 3. Call the ClientPlansView initializer
        //    ClientPlansView creates its own ClientPlansViewModel internally.
        //    If you wanted to test specific states of ClientPlansViewModel in the preview
        //    (e.g., already loaded plans, error state), you would need to:
        //    a) Modify ClientPlansView's init to optionally accept a pre-configured ViewModel, OR
        //    b) Use a mock APIService that returns specific data/errors.
        //    For now, this preview will show the view in its initial loading state.
        return NavigationView { // Wrap in NavigationView for title rendering in preview
            ClientPlansView(apiService: mockAPIService)
        }
        .environmentObject(mockAPIService) // Provide for views it might present
        .environmentObject(mockAuthService)
    }

    static var previews: some View {
        // Call the helper function to get the configured view
        createPreviewInstance()
        // If you want multiple previews (e.g., different states), you would create
        // more helper functions or parameterize createPreviewInstance,
        // and then put them in a Group:
        // Group {
        //     createPreviewInstance(forState: .withData)
        //     createPreviewInstance(forState: .empty)
        // }
    }
}
