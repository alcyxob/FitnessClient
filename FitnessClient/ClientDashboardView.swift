// ClientDashboardView.swift
import SwiftUI

struct ClientDashboardView: View {
    @StateObject var viewModel: ClientDashboardViewModel
    @EnvironmentObject var apiService: APIService
    @EnvironmentObject var toastManager: ToastManager
    // authService is accessed via viewModel

    init(apiService: APIService, authService: AuthService) {
        _viewModel = StateObject(wrappedValue: ClientDashboardViewModel(apiService: apiService, authService: authService))
        print("ClientDashboardView: Initialized.")
    }

    var body: some View {
        NavigationView { // Each tab content often has its own NavigationView
            ScrollView { // Use ScrollView if content might exceed screen height
                VStack(alignment: .leading, spacing: 16) { // Added more spacing
                    // --- Greeting Header ---
                    Text(viewModel.greeting)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                        .padding(.top, 20) // More top padding if no nav bar title

                    // --- Main Content Area ---
                    if viewModel.isLoading {
                        VStack { // Center ProgressView
                            Spacer(minLength: 50) // Push down a bit
                            ProgressView("Loading your day...")
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                    } else if let errorMessage = viewModel.errorMessage, viewModel.todaysWorkouts.isEmpty {
                        VStack(spacing: 15) { // Center Error Message
                            Spacer(minLength: 50)
                            Image(systemName: "exclamationmark.icloud.fill").font(.system(size: 50)).foregroundColor(.orange)
                            Text("Could Not Load Schedule").font(.title3).fontWeight(.semibold)
                            Text(errorMessage).font(.callout).foregroundColor(.secondary).multilineTextAlignment(.center).padding(.horizontal)
                            Button("Retry") { Task { await viewModel.fetchTodaysWorkouts() }}
                                .buttonStyle(.borderedProminent)
                                .padding(.top)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    } else if viewModel.todaysWorkouts.isEmpty {
                        VStack(spacing: 15) { // Center Rest Day Message
                            Spacer(minLength: 50)
                            Image(systemName: "moon.zzz.fill").font(.system(size: 60)).foregroundColor(.blue.opacity(0.7))
                            Text("Rest Day!")
                                .font(.title).fontWeight(.bold)
                            Text("No workouts scheduled for today. Enjoy your recovery!")
                                .font(.callout)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    } else {
                        // --- Today's Workout(s) List ---
                        Text("Today's Workout(s):")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                            .padding(.top, 10) // Add some space above the list
                        
                        // Using a ForEach directly within VStack if List styling is not desired,
                        // or keep List for standard row appearance and swipe actions (if any later).
                        // For now, List is fine.
                        List { // Consider removing List if you want more custom card layout
                            ForEach(viewModel.todaysWorkouts) { workout in
                                NavigationLink {
                                    ClientAssignmentListView(
                                        workout: workout,
                                        apiService: apiService,
                                        toastManager: toastManager
                                    )
                                } label: {
                                    WorkoutRowView(workout: workout, daysOfWeek: viewModel.daysOfWeek)
                                }
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)) // Custom padding for rows
                            }
                        }
                        .listStyle(.plain) // Or .insetGrouped
                        .frame(height: CGFloat(viewModel.todaysWorkouts.count) * 90) // Approximate height; adjust as needed or use dynamic sizing
                        // Be cautious with fixed frame heights for lists. It's often better to let them size naturally.
                        // If inside a ScrollView, this fixed height for List can be problematic.
                        // Let's remove fixed height and rely on ScrollView if content overflows.
                        // .frame(height: ...) REMOVED
                    }
                } // End Main VStack
            } // End ScrollView
            .navigationBarHidden(true) // Keep if custom greeting acts as title
            .onAppear {
                print("ClientDashboardView: Appeared. Fetching today's workouts.")
                Task {
                    viewModel.updateGreeting()
                    await viewModel.fetchTodaysWorkouts()
                }
            }
            .refreshable { // Pull to refresh on the ScrollView
                print("ClientDashboardView: Refreshing today's workouts.")
                await viewModel.fetchTodaysWorkouts()
            }
        } // End NavigationView
        .navigationViewStyle(.stack)
    }
}

// WorkoutRowView helper (ensure this is defined, e.g., at the bottom of this file or in HelperViews.swift)
struct WorkoutRowView: View {
    let workout: Workout
    let daysOfWeek: [String] // From ClientDashboardViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(workout.name)
                .font(.headline)
                .foregroundColor(.primary)
                .lineLimit(1)
            
            HStack(spacing: 10) {
                if let dayIndex = workout.dayOfWeek, dayIndex > 0 && dayIndex < daysOfWeek.count {
                    Text("Day: \(daysOfWeek[dayIndex])")
                        .font(.caption)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(5)
                }
                Text("Order: \(workout.sequence + 1)")
                   .font(.caption)
                   .padding(.horizontal, 8).padding(.vertical, 3)
                   .background(Color.purple.opacity(0.1))
                   .foregroundColor(.purple)
                   .cornerRadius(5)
            }
            
            if let notes = workout.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .padding(.top, 2)
            }
        }
        .padding(.vertical, 8) // Add padding to the row itself
    }
}

// Preview Provider
struct ClientDashboardView_Previews: PreviewProvider {
    static func createPreviewWithServiceInit(isLoading: Bool = false, errorMessage: String? = nil, workouts: [Workout]? = nil) -> some View {
         let mockAuthService = AuthService()
         mockAuthService.authToken = "client_token_preview"
         mockAuthService.loggedInUser = UserResponse(id: "c_dash_prev", name: "Jane Client", email: "jane@example.com", roles: ["client"], createdAt: Date(), clientIds: nil, trainerId: "t_dash_prev")
         
        // To effectively preview different states, you'd need a MockAPIService
        // that can be configured to return specific data or errors for the
        // "/client/workouts/today" endpoint.
        let mockAPIService = APIService(authService: mockAuthService)

        // The view creates its own ViewModel.
        // For previewing specific states of the ViewModel (isLoading, error, data),
        // you'd typically need to either:
        // 1. Modify ClientDashboardView to accept an optional pre-configured ViewModel in its init.
        // 2. Use a MockAPIService that the ViewModel will call.
        // For now, this preview will show the view making a live call (if APIService points to real URL)
        // or failing if mockAPIService doesn't handle /client/workouts/today.

        let view = ClientDashboardView(apiService: mockAPIService, authService: mockAuthService)
        
        // If you modify ClientDashboardView to take an optional VM, you could do:
        // let vm = ClientDashboardViewModel(apiService: mockAPIService, authService: mockAuthService)
        // if isLoading { vm.isLoading = true }
        // if let err = errorMessage { vm.errorMessage = err }
        // if let wos = workouts { vm.todaysWorkouts = wos }
        // let view = ClientDashboardView(viewModel: vm) // Assuming init(viewModel:)

        return view
            .environmentObject(mockAPIService)
            .environmentObject(mockAuthService)
    }

    static var previews: some View {
        // This will show the loading sequence for now, as the default mockAPIService
        // won't return data for /client/workouts/today.
        createPreviewWithServiceInit().previewDisplayName("Default Load")

        // To see a data-filled preview, you'd need to adjust createPreviewWithServiceInit
        // to use a MockAPIService that returns canned workout data.
    }
}
