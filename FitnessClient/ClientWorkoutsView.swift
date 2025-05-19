// ClientWorkoutsView.swift
import SwiftUI

struct ClientWorkoutsView: View {
    // ViewModel is initialized by the parent view (ClientPlansView)
    @StateObject var viewModel: ClientWorkoutsViewModel
    
    // Services from environment, if needed to pass to further navigated views
    @EnvironmentObject var apiService: APIService
    // @EnvironmentObject var authService: AuthService

    // Initializer that receives the specific trainingPlan and APIService
    init(trainingPlan: TrainingPlan, apiService: APIService) {
        _viewModel = StateObject(wrappedValue: ClientWorkoutsViewModel(trainingPlan: trainingPlan, apiService: apiService))
        print("ClientWorkoutsView: Initialized for plan: \(trainingPlan.name)")
    }

    var body: some View {
        // This view assumes it's already within a NavigationView from ClientPlansView
        List {
            // --- Loading State ---
            if viewModel.isLoading {
                HStack { Spacer(); ProgressView("Loading Workouts..."); Spacer() }
            }
            // --- Error State ---
            else if let errorMessage = viewModel.errorMessage, viewModel.workouts.isEmpty {
                VStack(alignment: .center, spacing: 10) {
                    Image(systemName: "exclamationmark.bubble").font(.largeTitle).foregroundColor(.orange)
                    Text("Could Not Load Workouts").font(.headline)
                    Text(errorMessage).font(.caption).foregroundColor(.secondary).multilineTextAlignment(.center)
                    Button("Retry") { Task { await viewModel.fetchMyWorkoutsForPlan() } }
                        .buttonStyle(.bordered)
                }.frame(maxWidth: .infinity).padding()
            }
            // --- Empty State ---
            else if viewModel.workouts.isEmpty {
                 VStack(alignment: .center, spacing: 10) {
                    Image(systemName: "figure.cooldown").font(.largeTitle).foregroundColor(.secondary)
                    Text("No Workouts Yet").font(.headline)
                    Text("This training plan doesn't have specific workouts scheduled yet.").font(.caption).foregroundColor(.secondary).multilineTextAlignment(.center)
                }.frame(maxWidth: .infinity).padding()
            }
            // --- Data Loaded State ---
            else {
                ForEach(viewModel.workouts) { workout in
                    NavigationLink {
                        ClientAssignmentListView( // Navigate to the new view
                           workout: workout,
                           apiService: apiService // Pass APIService from environment
                        )
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(workout.name).font(.headline)
                            HStack {
                                 if let dayIndex = workout.dayOfWeek, dayIndex > 0 && dayIndex < viewModel.daysOfWeek.count {
                                     Text("Day: \(viewModel.daysOfWeek[dayIndex])")
                                         .font(.caption).foregroundColor(.blue)
                                 }
                                 Text("Order: \(workout.sequence + 1)") // Display 1-based sequence
                                    .font(.caption).foregroundColor(.purple)
                            }
                            if let notes = workout.notes, !notes.isEmpty {
                                Text(notes).font(.caption).foregroundColor(.gray).lineLimit(2)
                            }
                        }
                        .padding(.vertical, 5)
                    }
                }
            }
        } // End List
        .navigationTitle("Workouts: \(viewModel.trainingPlan.name)")
        .onAppear {
            if viewModel.workouts.isEmpty { // Fetch only if needed
                print("ClientWorkoutsView: Appeared. Fetching workouts for plan \(viewModel.trainingPlan.id).")
                Task { await viewModel.fetchMyWorkoutsForPlan() }
            }
        }
        .refreshable {
            print("ClientWorkoutsView: Refreshing workouts...")
            await viewModel.fetchMyWorkoutsForPlan()
        }
    } // End body
} // End struct ClientWorkoutsView

// Preview Provider
struct ClientWorkoutsView_Previews: PreviewProvider {
    static func createPreviewInstance() -> some View {
        let mockAuth = AuthService()
        mockAuth.authToken = "fake_client_token"
        mockAuth.loggedInUser = UserResponse(id: "clientPrev", name: "Client Preview", email: "c@p.com", role: "client", createdAt: Date(), clientIds: nil, trainerId: "tPrev")
        let mockAPI = APIService(authService: mockAuth)
        
        let previewPlan = TrainingPlan(
            id: "planPrev1",
            trainerId: "tPrev",
            clientId: "clientPrev",
            name: "My Awesome Plan (Preview)",
            description: "A fantastic plan for preview purposes.", // Or nil
            startDate: nil, // Provide nil for optional Date
            endDate: nil,   // Provide nil for optional Date
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        )

        // To see data in preview, you'd pre-populate the ViewModel:
        // let vm = ClientWorkoutsViewModel(trainingPlan: previewPlan, apiService: mockAPI)
        // vm.workouts = [Workout(id: "w1", trainingPlanId: "planPrev1", trainerId: "tPrev", clientId: "clientPrev", name: "Full Body A", dayOfWeek: 1, notes: "Focus on form.", sequence: 0, createdAt: Date(), updatedAt: Date())]
        // return NavigationView { ClientWorkoutsView(viewModel: vm) } ...

        return NavigationView { // For title
            ClientWorkoutsView(trainingPlan: previewPlan, apiService: mockAPI)
        }
        .environmentObject(mockAPI)
        .environmentObject(mockAuth)
    }

    static var previews: some View {
        createPreviewInstance()
    }
}
