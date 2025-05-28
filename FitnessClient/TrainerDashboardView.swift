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
                    VStack(spacing: 10) { /* ... Error View ... */ }
                        .padding().frame(maxWidth: .infinity)
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
                                // TODO: Navigate to a specific client's submitted assignments view or ClientDetailView
                                // For now, let's go to ClientDetailView.
                                // We need the full UserResponse object for the client.
                                // The dashboard only returns ClientReviewStatusItem.
                                // We might need to fetch UserResponse or pass enough info.
                                // For simplicity, let's assume we have a way to construct a UserResponse or just pass ID.
                                // A better approach: dashboard endpoint returns enough User info or ID to fetch.
                                
                                // Assuming ClientDetailView can be initialized with just clientID
                                // and fetch details, OR modify dashboard DTO to include more.
                                // Let's just show a placeholder for now.
                                Text("Detail for \(item.clientName) (ID: \(item.clientId)) - TODO: Navigate to their submissions")
                                    .onAppear {
                                        print("Navigating to details for client: \(item.clientName)")
                                    }
                                
                                // Ideal (if ClientDetailView had an init(clientId: ...)):
                                // ClientDetailView(clientId: item.clientId, apiService: apiService, authService: authService)

                            } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(item.clientName).font(.headline)
                                        Text("\(item.pendingReviewCount) item(s) to review")
                                            .font(.caption).foregroundColor(.orange)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary.opacity(0.5))
                                }
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
    static func createPreviewInstance() -> some View {
        let mockAuth = AuthService()
        mockAuth.authToken = "trainer_token_preview"
        mockAuth.loggedInUser = UserResponse(id: "t_dash_prev", name: "Dr. Train", email: "trainer@example.com", role: "trainer", createdAt: Date(), clientIds: nil, trainerId: nil)
        let mockAPI = APIService(authService: mockAuth)
        
        let vm = TrainerDashboardViewModel(apiService: mockAPI, authService: mockAuth)
        // vm.clientsWithPendingReviews = [
        //    ClientReviewStatusItem(clientId: "c1", clientName: "Client Alpha", pendingReviewCount: 3),
        //    ClientReviewStatusItem(clientId: "c2", clientName: "Client Beta", pendingReviewCount: 1)
        // ]
        // vm.isLoading = true
        // vm.errorMessage = "Preview: Error loading dashboard"

        // As the view creates its own VM, this preview will show loading.
        // To show data, use a mock APIService.
        return TrainerDashboardView(apiService: mockAPI, authService: mockAuth)
            .environmentObject(mockAPI)
            .environmentObject(mockAuth)
    }
    static var previews: some View {
        createPreviewInstance()
    }
}
