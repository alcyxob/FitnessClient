// TrainerDashboardView.swift
import SwiftUI

struct TrainerDashboardView: View {
    @StateObject var viewModel: TrainerDashboardViewModel
    
    // Services from environment, for navigation destinations
    @EnvironmentObject var apiService: APIService
    @EnvironmentObject var authService: AuthService

    init(apiService: APIService, authService: AuthService) {
        _viewModel = StateObject(wrappedValue: TrainerDashboardViewModel(apiService: apiService, authService: authService))
        print("TrainerDashboardView: Initialized.")
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 0) {
                Text(viewModel.greeting)
                    .font(.largeTitle).fontWeight(.bold)
                    .padding([.top, .horizontal])
                    .padding(.bottom, 10)

                Divider().padding(.bottom)

                if viewModel.isLoading {
                    Spacer()
                    ProgressView("Loading Dashboard...")
                    Spacer()
                } else if let errorMessage = viewModel.errorMessage, viewModel.clientsWithPendingReviews.isEmpty {
                    Spacer()
                    VStack(spacing: 15) {
                        Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 50)).foregroundColor(.orange)
                        Text("Error Loading Dashboard").font(.title3).fontWeight(.semibold)
                        Text(errorMessage).font(.callout).foregroundColor(.secondary).multilineTextAlignment(.center).padding(.horizontal)
                        Button("Retry") { Task { await viewModel.fetchPendingReviews() }}
                            .buttonStyle(.borderedProminent).padding(.top)
                    }.padding()
                    Spacer()
                } else if viewModel.clientsWithPendingReviews.isEmpty {
                    Spacer()
                    VStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.badge.questionmark.fill")
                            .font(.system(size: 60)).foregroundColor(.green)
                        Text("All Caught Up!")
                            .font(.title2).fontWeight(.semibold)
                        Text("No clients currently have submissions awaiting your review.")
                            .font(.callout).foregroundColor(.secondary).multilineTextAlignment(.center)
                    }.padding()
                    Spacer()
                } else {
                    Text("Clients Awaiting Review:")
                        .font(.title2).fontWeight(.semibold)
                        .padding([.horizontal, .top])
                    
                    List {
                        ForEach(viewModel.clientsWithPendingReviews) { item in
                            NavigationLink {
                                ClientDetailView(
                                    clientId: item.clientId, // From ClientReviewStatusItem
                                    apiService: apiService,
                                    authService: authService
                                )
                            } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(item.clientName).font(.headline)
                                        Text("\(item.pendingReviewCount) item(s) to review")
                                            .font(.caption)
                                            .foregroundColor(item.pendingReviewCount > 0 ? .orange : .secondary)
                                            .fontWeight(item.pendingReviewCount > 0 ? .semibold : .regular)
                                    }
                                    Spacer()
                                    if item.pendingReviewCount > 0 {
                                        Image(systemName: "exclamationmark.bubble.fill") // Visual cue
                                            .foregroundColor(.orange)
                                    }
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary.opacity(0.5))
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            } // End Main VStack
            .navigationBarHidden(true) // Using custom greeting as title
            .onAppear {
                print("TrainerDashboardView: Appeared. Fetching pending reviews.")
                Task {
                    viewModel.updateGreeting()
                    await viewModel.fetchPendingReviews()
                }
            }
            .refreshable {
                print("TrainerDashboardView: Refreshing pending reviews.")
                await viewModel.fetchPendingReviews()
            }
        } // End NavigationView
        .navigationViewStyle(.stack)
    }
}

// Preview Provider
struct TrainerDashboardView_Previews: PreviewProvider {
    // This helper function creates an instance of TrainerDashboardView
    // using its standard initializer.
    static func createPreviewInstance() -> some View {
        let mockAuthService = AuthService()
        mockAuthService.authToken = "trainer_token_preview"
        mockAuthService.loggedInUser = UserResponse(
            id: "t_dash_prev",
            name: "Dr. Train",
            email: "trainer@example.com",
            role: "trainer",
            createdAt: Date(),
            clientIds: nil, // Ensure all UserResponse fields are provided
            trainerId: nil  // Ensure all UserResponse fields are provided
        )
        
        let mockAPIService = APIService(authService: mockAuthService)
        
        // When TrainerDashboardView is initialized, its internal ViewModel
        // will use mockAPIService. If mockAPIService is not a true mock
        // that handles "/trainer/dashboard/pending-reviews", the preview
        // will show the loading state, then an error or empty state from the API call.
        
        return TrainerDashboardView(
                apiService: mockAPIService,
                authService: mockAuthService
            )
            .environmentObject(mockAPIService) // For sub-views if needed
            .environmentObject(mockAuthService)
    }

    static var previews: some View {
        createPreviewInstance()
            .previewDisplayName("Default Load Sequence")
        
        // To demonstrate different states in preview *without* live API calls,
        // you would typically:
        // 1. Modify TrainerDashboardView to have an init(viewModel: TrainerDashboardViewModel).
        // 2. Create and configure TrainerDashboardViewModel instances with mock data/states.
        // 3. Pass those ViewModels to TrainerDashboardView in the preview.
        //
        // Example if you add init(viewModel: TrainerDashboardViewModel) to TrainerDashboardView:
        /*
        static func createDataLoadedPreview() -> some View {
            let mockAuth = AuthService(); /* ... */
            let mockAPI = APIService(authService: mockAuth);
            let vm = TrainerDashboardViewModel(apiService: mockAPI, authService: mockAuth)
            vm.clientsWithPendingReviews = [
                ClientReviewStatusItem(clientId: "c1", clientName: "Client Alpha (Preview)", pendingReviewCount: 3),
                ClientReviewStatusItem(clientId: "c2", clientName: "Client Beta (Preview)", pendingReviewCount: 1)
            ]
            vm.isLoading = false
            vm.errorMessage = nil
            return TrainerDashboardView(viewModel: vm) // Assumes init(viewModel:) exists
                .environmentObject(mockAPI)
                .environmentObject(mockAuth)
        }

        static var previews: some View {
            Group {
                createPreviewInstance().previewDisplayName("Default Load") // Shows loading, then API result
                // createDataLoadedPreview().previewDisplayName("With Mock Data") // Shows predefined data
            }
        }
        */
    }
}
