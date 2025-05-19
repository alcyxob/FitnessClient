// WorkoutListView.swift
import SwiftUI

struct WorkoutListView: View {
    // ViewModel is initialized by the parent view (ClientDetailView)
    // and passed into this view's initializer.
    @StateObject var viewModel: WorkoutListViewModel

    // Services obtained from the environment, needed to pass down to
    // views presented by this view (like CreateWorkoutView or AssignmentListView).
    @EnvironmentObject var apiService: APIService
    @EnvironmentObject var authService: AuthService // Though not directly used by THIS view's VM,
                                                  // it's good to have if sub-views need it.

    // State to control the presentation of the "Create Workout" sheet.
    @State private var showingCreateWorkoutSheet = false
    
    @State private var workoutToEdit: Workout? = nil

    // Initializer expects the specific TrainingPlan and the necessary services
    // to create its own ViewModel.
    init(trainingPlan: TrainingPlan, apiService: APIService, authService: AuthService) {
        _viewModel = StateObject(wrappedValue: WorkoutListViewModel(trainingPlan: trainingPlan, apiService: apiService, authService: authService))
    }

    var body: some View {
        // The List view to display workouts.
        // This view assumes it's already within a NavigationView context
        // from ClientDetailView, so it doesn't create its own NavigationView.
        List {
            // --- Loading State ---
            if viewModel.isLoading {
                HStack { // Center ProgressView
                    Spacer()
                    ProgressView("Loading Workouts...")
                    Spacer()
                }
            }
            // --- Error State ---
            else if let errorMessage = viewModel.errorMessage {
                 VStack(alignment: .center, spacing: 10) {
                     Image(systemName: "exclamationmark.bubble.fill")
                         .foregroundColor(.orange)
                         .font(.title)
                     Text("Error Loading Workouts")
                         .font(.headline)
                     Text(errorMessage)
                         .font(.footnote)
                         .foregroundColor(.secondary)
                         .multilineTextAlignment(.center)
                     Button("Retry") {
                         Task { await viewModel.fetchWorkoutsForPlan() }
                     }
                     .buttonStyle(.bordered)
                 }
                 .frame(maxWidth: .infinity)
                 .padding()
            }
            // --- Empty State ---
            else if viewModel.workouts.isEmpty {
                VStack(alignment: .center, spacing: 10) {
                    Image(systemName: "figure.walk.motion") // Example icon
                        .foregroundColor(.secondary)
                        .font(.largeTitle)
                    Text("No workouts in this plan yet.")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Tap the '+' button to add the first workout session.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
            // --- Data Loaded State ---
            else {
                 ForEach(viewModel.workouts) { workout in
                     Button {
                         self.workoutToEdit = workout // Set state to trigger edit sheet
                     }  label: {
                         HStack {
                             // Label: How the workout row looks in the list
                             VStack(alignment: .leading, spacing: 4) {
                                 Text(workout.name)
                                     .font(.headline)
                                 
                                 if let dayIndex = workout.dayOfWeek, dayIndex > 0 && dayIndex < viewModel.daysOfWeek.count {
                                     Text("Day: \(viewModel.daysOfWeek[dayIndex])")
                                         .font(.caption)
                                         .foregroundColor(.blue)
                                 }
                                 Text("Seq: \(workout.sequence)") // Display sequence
                                     .font(.caption)
                                     .foregroundColor(.purple)
                                 
                                 if let notes = workout.notes, !notes.isEmpty {
                                     Text(notes)
                                         .font(.caption)
                                         .foregroundColor(.gray)
                                         .lineLimit(1) // Show a snippet of notes
                                 }
                             }
                         }
                         .padding(.vertical, 5)
                     }
                     .buttonStyle(.plain)// End Label
                 } // End ForEach
                .onDelete(perform: deleteWorkouts)
            } // End Else (Data Loaded)
        } // End List
        .navigationTitle("Workouts: \(viewModel.trainingPlan.name)") // Set title using plan name
        // .navigationBarTitleDisplayMode(.inline) // Optional title display style
        .toolbar {
            // Add a "+" button to the toolbar to present the CreateWorkoutView sheet
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingCreateWorkoutSheet = true
                } label: {
                     Label("Add Workout", systemImage: "plus.circle.fill")
                }
            }
        }
        .sheet(isPresented: $showingCreateWorkoutSheet,
               onDismiss: {
                    // Action when the "Create Workout" sheet is dismissed
                    print("CreateWorkout sheet dismissed. Refreshing workouts for plan \(viewModel.trainingPlan.id).")
                    Task { await viewModel.fetchWorkoutsForPlan() }
               }) {
            // Content of the sheet: CreateWorkoutView
            CreateWorkoutView(
                trainingPlan: viewModel.trainingPlan, // Pass the current plan
                currentWorkoutCount: viewModel.workouts.count, // Pass current count for sequence default
                apiService: apiService // Pass the APIService from environment
            )
            // Pass authService if CreateWorkoutView needs it directly (unlikely for now)
            // .environmentObject(authService)
        }
       .sheet(item: $workoutToEdit, onDismiss: {
           // item-based sheet: when workoutToEdit is non-nil, sheet shows.
           // On dismiss, workoutToEdit automatically becomes nil. Refresh list.
           Task { await viewModel.fetchWorkoutsForPlan() }
       }) { currentWorkoutToEdit in // Receives the non-nil Workout
           EditWorkoutView(
               workoutToEdit: currentWorkoutToEdit,
               apiService: apiService
           )
           // Pass authService if EditWorkoutView's VM needs it, but it shouldn't
           // .environmentObject(authService)
       }
        .onAppear {
            // Action when the view first appears
            // Fetch workouts if the list is currently empty
            if viewModel.workouts.isEmpty {
                 print("WorkoutListView appeared for plan \(viewModel.trainingPlan.id). Fetching workouts.")
                 Task { await viewModel.fetchWorkoutsForPlan() }
            }
        }
        // Add pull-to-refresh capability for the list of workouts
        .refreshable {
             print("Refreshing workouts for plan \(viewModel.trainingPlan.id)...")
             await viewModel.fetchWorkoutsForPlan()
        }
    } // End body
    
    // --- Delete Function for .onDelete ---
    private func deleteWorkouts(at offsets: IndexSet) {
        let workoutsToDelete = offsets.map { viewModel.workouts[$0] }
        Task {
            for workout in workoutsToDelete {
                print("WorkoutListView: Requesting delete for workout ID: \(workout.id)")
                let success = await viewModel.deleteWorkout(workoutId: workout.id)
                if !success {
                    print("WorkoutListView: Failed to delete workout \(workout.id). Error: \(viewModel.errorMessage ?? "Unknown")")
                    break // Stop on first error
                }
            }
            // ViewModel handles optimistic removal or you can refresh here if needed
        }
    }
} // End struct WorkoutListView


// Updated Preview Provider
struct WorkoutListView_Previews: PreviewProvider {
    static var previews: some View {
        let mockAuthService = AuthService()
        mockAuthService.authToken = "fake_token_for_preview"
        mockAuthService.loggedInUser = UserResponse(id: "trainerPreview123", name: "Preview Trainer", email: "trainer@preview.com", role: "trainer", createdAt: Date(), clientIds: nil, trainerId: nil)

        let mockAPIService = APIService(authService: mockAuthService)

        let previewPlan = TrainingPlan(
            id: "planPreview1",
            trainerId: "trainerPreview123",
            clientId: "clientPreview789",
            name: "Strength Phase Alpha (Preview)",
            description: "Focus on building base strength.",
            startDate: nil,
            endDate: nil,
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // This is the line that was likely incorrect before, but your LAST provided code for this was:
        // let vm = WorkoutListViewModel(trainingPlan: previewPlan, apiService: mockAPIService, authService: mockAuthService)
        // And then it was called like: WorkoutListView(viewModel: vm)
        //
        // Let's ensure we call the correct init directly:

        return NavigationView {
            WorkoutListView( // Call the init defined in WorkoutListView
                trainingPlan: previewPlan,
                apiService: mockAPIService,
                authService: mockAuthService
            )
        }
        .environmentObject(mockAPIService)
        .environmentObject(mockAuthService)
    }
}
