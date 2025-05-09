// AssignmentListView.swift
import SwiftUI

struct AssignmentListView: View {
    @StateObject var viewModel: AssignmentListViewModel
    @EnvironmentObject var apiService: APIService // For AddExerciseToWorkoutView

    @State private var showingAddExerciseSheet = false

    init(workout: Workout, apiService: APIService) {
        _viewModel = StateObject(wrappedValue: AssignmentListViewModel(workout: workout, apiService: apiService))
    }

    var body: some View {
        List {
            if viewModel.isLoading {
                ProgressView("Loading Assigned Exercises...")
            } else if let errorMessage = viewModel.errorMessage {
                VStack(alignment: .leading) {
                    Text("Error: \(errorMessage)").foregroundColor(.red)
                    Button("Retry") { Task { await viewModel.fetchAssignmentsForWorkout() } }
                        .buttonStyle(.bordered)
                }
            } else if viewModel.assignmentsWithExercises.isEmpty {
                Text("No exercises assigned to this workout yet. Tap '+' to add.")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(viewModel.assignmentsWithExercises) { assignment in
                    VStack(alignment: .leading, spacing: 5) {
                        Text(assignment.exercise?.name ?? "Unknown Exercise")
                            .font(.headline)
                        
                        HStack(spacing: 10) {
                            if let sets = assignment.sets { Text("Sets: \(sets)") }
                            if let reps = assignment.reps, !reps.isEmpty { Text("Reps: \(reps)") }
                        }
                        .font(.caption)
                        
                        if let weight = assignment.weight, !weight.isEmpty {
                            Text("Weight: \(weight)").font(.caption)
                        }
                        if let rest = assignment.rest, !rest.isEmpty {
                            Text("Rest: \(rest)").font(.caption)
                        }
                        if let notes = assignment.trainerNotes, !notes.isEmpty {
                            Text("Notes: \(notes)").font(.caption).foregroundColor(.gray).lineLimit(1)
                        }
                        // TODO: Add more details (tempo, duration)
                        // TODO: Tap to edit assignment?
                    }
                    .padding(.vertical, 4)
                }
                // TODO: .onDelete, .onMove
            }
        }
        .navigationTitle("Workout: \(viewModel.workout.name)")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showingAddExerciseSheet = true } label: {
                    Label("Add Exercise", systemImage: "plus.circle.fill")
                }
            }
        }
        .sheet(isPresented: $showingAddExerciseSheet, onDismiss: {
            print("Add Exercise to Workout sheet dismissed. Refreshing assignments.")
            Task { await viewModel.fetchAssignmentsForWorkout() }
        }) {
            AddExerciseToWorkoutView(
                workout: viewModel.workout,
                currentAssignmentCount: viewModel.assignmentsWithExercises.count,
                apiService: apiService
            )
        }
        .onAppear {
            print("AssignmentListView appeared for workout \(viewModel.workout.id). Fetching assignments.")
            Task { await viewModel.fetchAssignmentsForWorkout() }
        }
        .refreshable {
            print("Refreshing assignments...")
            await viewModel.fetchAssignmentsForWorkout()
        }
    }
}

// Preview Provider
struct AssignmentListView_Previews: PreviewProvider {
    static var previews: some View {
        let mockAuth = AuthService()
        // mockAuth.authToken = "fake"
        let mockAPI = APIService(authService: mockAuth)
        let previewWorkout = Workout(id: "w1", trainingPlanId: "p1", trainerId: "t1", clientId: "c1", name: "Full Body A (Preview)", dayOfWeek: 1, notes: "Main lifts", sequence: 0, createdAt: Date(), updatedAt: Date())
        
        // For a better preview, you'd configure the vm with mock assignments
        // let vm = AssignmentListViewModel(workout: previewWorkout, apiService: mockAPI)
        // vm.assignmentsWithExercises = [ Assignment(..., exercise: Exercise(...)) ]

        NavigationView { // Wrap in NavigationView for the title/toolbar
            AssignmentListView(workout: previewWorkout, apiService: mockAPI)
        }
        .environmentObject(mockAPI)
        .environmentObject(mockAuth) // If any sub-views need it
    }
}
