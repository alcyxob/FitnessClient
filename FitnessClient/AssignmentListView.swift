// AssignmentListView.swift
import SwiftUI
import AVKit // For VideoPlayer

struct AssignmentListView: View {
    // ViewModel is initialized by this view's init.
    @StateObject var viewModel: AssignmentListViewModel
    @State private var isVideoURLReadyForPlayer = false
    //@State private var selectedAssignmentForVideo: Assignment? = nil
    @State private var assignmentForVideoSheet: Assignment? = nil
    
    // Services obtained from the environment, can be passed to sheets/modals.
    @EnvironmentObject var apiService: APIService
    @EnvironmentObject var authService: AuthService // For passing to AddExerciseToWorkoutView if its VM needs it

    // State for presenting the "Add Exercise to Workout" sheet
    @State private var showingAddExerciseSheet = false
        
    // State for Video Player (Trainer views client's video)
    @State private var videoURLToPlay: URL? = nil
    @State private var showingVideoPlayer = false
    @State private var videoLoadingErrorMessage: String? = nil
    
    @State private var showingProvideFeedbackSheet = false
    @State private var assignmentForFeedback: Assignment? = nil // To pass to the sheet
    
    @State private var assignmentToEdit: Assignment? = nil

    // THIS INITIALIZER IS KEY: It takes workout, apiService, AND authService
    // It then creates its AssignmentListViewModel, passing authService to it.
    init(workout: Workout, apiService: APIService, authService: AuthService) {
        _viewModel = StateObject(wrappedValue: AssignmentListViewModel(
            workout: workout,
            apiService: apiService,
            authService: authService // <<< Pass authService to the ViewModel
        ))
        print("AssignmentListView (Trainer): Initialized for workout: \(workout.name)")
    }

    var body: some View {
        let _ = print("AssignmentListView (Trainer) BODY re-eval. isLoading: \(viewModel.isLoading), assignmentCount: \(viewModel.assignmentsWithExercises.count), videoError: \(videoLoadingErrorMessage ?? "nil")")

        // The List content is refactored into a computed property to help with compiler performance.
        List {
            content
        }
        .navigationTitle("Exercises for: \(viewModel.workout.name)")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddExerciseSheet = true
                } label: {
                    Label("Add Exercise", systemImage: "plus.circle.fill")
                }
            }
        }
        .sheet(isPresented: $showingAddExerciseSheet,
               onDismiss: {
                    print("Add Exercise To Workout sheet dismissed. Refreshing assignments for workout \(viewModel.workout.id).")
                    Task { await viewModel.fetchAssignmentsForWorkout() }
               }) {
            // Present AddExerciseToWorkoutView
            AddExerciseToWorkoutView( // This view's init takes workout, currentAssignmentCount, apiService
                workout: viewModel.workout,
                currentAssignmentCount: viewModel.assignmentsWithExercises.count,
                apiService: apiService // APIService from environment
            )
            // If AddExerciseToWorkoutView needed authService directly (it doesn't currently)
            // .environmentObject(authService)
        }
       .sheet(item: $assignmentForVideoSheet, onDismiss: { // <<< USE .sheet(item:)
           // Item is the assignmentForVideoSheet. When it becomes non-nil, sheet shows.
           // When sheet dismisses, assignmentForVideoSheet becomes nil.
           self.videoURLToPlay = nil
           self.videoLoadingErrorMessage = nil
           print("VideoPlayer sheet (item-based) dismissed.")
       }) { currentAssignmentInSheet in // This closure receives the non-nil assignment
           // Now, VideoPlayerSheetContentView is created with a GUARANTEED non-nil assignment
           VideoPlayerSheetContentView(
               assignmentToPlay: currentAssignmentInSheet, // Pass the item
               viewModel: viewModel,
               videoURL: $videoURLToPlay,
               errorMessage: $videoLoadingErrorMessage,
               isPresented: $showingVideoPlayer // This binding is still useful for the content view to dismiss itself
           )
       }      // Alert for videoLoadingErrorMessage (can be kept or removed if sheet handles error display)
        .sheet(item: $assignmentForFeedback, onDismiss: { // <<< Use .sheet(item:...)
            print("ProvideFeedback sheet dismissed. Refreshing assignments.")
            Task { await viewModel.fetchAssignmentsForWorkout() }
        }) { currentAssignmentForFeedback in
            ProvideFeedbackView(
                assignment: currentAssignmentForFeedback,
                apiService: apiService
            )
        }
       // .alert("Video Error", isPresented: .constant(videoLoadingErrorMessage != nil && !showingVideoPlayer), actions: { ... })
       .onAppear {
           if viewModel.assignmentsWithExercises.isEmpty {
               print("AssignmentListView (Trainer): Appeared. Fetching assignments.")
               Task { await viewModel.fetchAssignmentsForWorkout() }
           }
       }
       .refreshable {
           print("AssignmentListView (Trainer): Refreshing assignments...")
           await viewModel.fetchAssignmentsForWorkout()
       }
   }

    // --- Computed Property for List Content (Helps with Error 2) ---
    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            HStack { Spacer(); ProgressView("Loading Exercises..."); Spacer() }
        } else if let errorMessage = viewModel.errorMessage {
            VStack(alignment: .center, spacing: 10) {
                Image(systemName: "exclamationmark.bubble.fill").foregroundColor(.orange).font(.title)
                Text("Error Loading Exercises").font(.headline)
                Text(errorMessage).font(.caption).foregroundColor(.secondary).multilineTextAlignment(.center)
                Button("Retry") { Task { await viewModel.fetchAssignmentsForWorkout() } }
                    .buttonStyle(.bordered)
            }
            .frame(maxWidth: .infinity).padding()
        } else if viewModel.assignmentsWithExercises.isEmpty {
            VStack(alignment: .center, spacing: 10) {
                Image(systemName: "figure.strengthtraining.traditional").foregroundColor(.secondary).font(.largeTitle)
                Text("No exercises assigned.").font(.headline).foregroundColor(.secondary)
                Text("Tap '+' to add exercises.").font(.subheadline).foregroundColor(.gray).multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity).padding()
        } else {
            ForEach(viewModel.assignmentsWithExercises) { assignment in
                assignmentRow(for: assignment) // Extracted row to a helper
            }
        }
    }

    // --- Helper View for Each Assignment Row ---
    @ViewBuilder
    private func assignmentRow(for assignment: Assignment) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(assignment.exercise?.name ?? "Exercise ID: \(assignment.exerciseId)")
                    .font(.headline)
                    .foregroundColor(assignment.exercise == nil ? .orange : .primary)
                Spacer()
                // Trainer actions for assignment status/video
                if assignment.status == "submitted" && assignment.uploadId != nil {
                    Button {
                        Task { // This is a new Task context
                            self.videoLoadingErrorMessage = nil
                            self.videoURLToPlay = nil       // Reset URL from parent
                            self.assignmentForVideoSheet = assignment

                            print("Button Tapped: Will show video player sheet for assignment \(assignment.id)")
                            // THESE ARE THE KEY STATE CHANGES IN THE PARENT (AssignmentListView)
                            //self.selectedAssignmentForVideo = assignment // (1)
                            self.showingVideoPlayer = true      // (2)

                            // The fetchVideoDownloadURL is NO LONGER CALLED HERE.
                            // It's now supposed to be called by VideoPlayerSheetContentView's .task
                        }
                    } label: {
                        Label("View Video", systemImage: "play.tv.fill")
                    }
                    .buttonStyle(.bordered).tint(.orange)
                    
                    Button { // Provide Feedback Button
                         self.assignmentForFeedback = assignment
                         self.showingProvideFeedbackSheet = true
                     } label: { Label("Feedback", systemImage: "pencil.and.ellipsis.rectangle")}
                     .buttonStyle(.bordered).tint(.cyan)
                } else if assignment.status == "reviewed" {
                     HStack {
                        Image(systemName: "checkmark.seal.fill").foregroundColor(.green)
                        Text("Reviewed").font(.caption).foregroundColor(.green)
                        // Optionally, show a button to view/edit feedback if needed
                    }
                
                } else {
                    Text("Status: \(assignment.status.capitalized)")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(statusColor(for: assignment.status))
                }
            }

            ParameterRow(label: "Sets", value: assignment.sets.map { String($0) })
            ParameterRow(label: "Reps", value: assignment.reps)
            ParameterRow(label: "Weight", value: assignment.weight)
            // ... (other ParameterRow calls)

            if let notes = assignment.trainerNotes, !notes.isEmpty { /* ... */ }
            if let clientNotes = assignment.clientNotes, !clientNotes.isEmpty { /* ... */ }
            if let trainerFeedback = assignment.feedback, !trainerFeedback.isEmpty { /* ... */ }
        }
        .padding(.vertical, 5)
    }
    
    func statusColor(for status: String) -> Color {
        switch status.lowercased() { // Use lowercased for case-insensitive matching
        case "assigned":
            return .gray
        case "completed":
            return .blue // Client marked as done, awaiting video or trainer review
        case "submitted":
            return .purple // Video uploaded, awaiting trainer review
        case "reviewed":
            return .green // Trainer has reviewed
        // Add other statuses if you define them (e.g., "skipped", "needs revision")
        // case "skipped":
        //     return .orange
        default:
            return .black // Default color for unknown statuses
        }
    }

} // End struct AssignmentListView


// --- NEW: Helper View for the Video Player Sheet's Content ---
struct VideoPlayerSheetContentView: View {
    let assignmentToPlay: Assignment
    @ObservedObject var viewModel: AssignmentListViewModel
    
    @Binding var videoURL: URL?
    @Binding var errorMessage: String?
    @Binding var isPresented: Bool

    // Local state for this view to manage its own loading process
    @State private var isCurrentlyFetchingURL: Bool = false // Start false, set true by fetchURLData

    init(assignmentToPlay: Assignment,
         viewModel: AssignmentListViewModel,
         videoURL: Binding<URL?>,
         errorMessage: Binding<String?>,
         isPresented: Binding<Bool>) {
        self.assignmentToPlay = assignmentToPlay
        self.viewModel = viewModel
        self._videoURL = videoURL
        self._errorMessage = errorMessage
        self._isPresented = isPresented
        
        // We don't set isCurrentlyFetchingURL to true here anymore.
        // The .task will trigger the fetch if needed.
        print("VideoPlayerSheetContentView: Initialized for assignment: \(self.assignmentToPlay.id). videoURL binding initially: \(String(describing: videoURL.wrappedValue))")
    }

    var body: some View {
        let _ = print("VideoPlayerSheetContentView BODY re-eval. isCurrentlyFetchingURL: \(isCurrentlyFetchingURL), videoURL: \(String(describing: videoURL)), error: \(errorMessage ?? "nil")")
        VStack {
            if isCurrentlyFetchingURL {
                ProgressView("Loading Video URL...")
                    .padding()
            } else if let url = videoURL {
                VideoPlayerView(videoURL: url, isPresented: $isPresented)
            } else if let err = errorMessage {
                VStack(spacing: 15) {
                    Image(systemName: "video.slash.fill").font(.largeTitle).foregroundColor(.red)
                    Text("Could Not Load Video").font(.headline)
                    Text(err).font(.callout).foregroundColor(.secondary).multilineTextAlignment(.center)
                    Button("Try Again") {
                         // Explicitly call fetchURLData, it will handle isLoadingURL
                         Task { await fetchURLData(for: assignmentToPlay) }
                    }
                    .buttonStyle(.bordered).padding(.top)
                    Button("Close") {
                        print("VideoPlayerView: Close button tapped. Current isPresented: \(isPresented). Setting to false.")
                        isPresented = false
                        print("VideoPlayerView: After setting, isPresented: \(isPresented).")
                    }.buttonStyle(.bordered)
                }.padding()
            } else {
                // This state: not fetching, no URL, no error.
                // Usually means .task hasn't completed or initial state before .task runs.
                Text("Preparing video...")
                    .onAppear{
                        print("VideoPlayerSheetContentView: Body in 'Preparing video...' state.")
                    }
            }
        }
        .task(id: assignmentToPlay.id) {
            print("VideoPlayerSheetContentView .task: Fired for assignment \(assignmentToPlay.id). Current videoURL (binding): \(String(describing: videoURL))")
            // Fetch only if the videoURL binding is currently nil.
            // fetchURLData will set and manage isCurrentlyFetchingURL.
            if videoURL == nil {
                print("VideoPlayerSheetContentView .task: videoURL is nil, calling fetchURLData.")
                await fetchURLData(for: assignmentToPlay)
            } else {
                print("VideoPlayerSheetContentView .task: videoURL is already set. No fetch needed. isCurrentlyFetchingURL: \(isCurrentlyFetchingURL)")
                // If URL is set, ensure loading flag is false.
                if isCurrentlyFetchingURL { isCurrentlyFetchingURL = false }
            }
        }
    }

    private func fetchURLData(for assignment: Assignment) async {
        // Re-entrancy guard for this specific async function
        guard !isCurrentlyFetchingURL else {
            print("VideoPlayerSheetContentView: fetchURLData: Already in progress. Bailing.")
            return
        }

        print("VideoPlayerSheetContentView: fetchURLData STARTED for assignment \(assignment.id)")
        isCurrentlyFetchingURL = true // Set loading TRUE *here* at the start of the actual operation
        self.errorMessage = nil
        // self.videoURL = nil // Parent clears this before presenting. Don't clear it here again during a retry.

        if let url = await viewModel.fetchVideoDownloadURL(for: assignment) {
            print("VideoPlayerSheetContentView: fetchURLData - URL fetched: \(url.absoluteString)")
            self.videoURL = url
            self.errorMessage = nil
        } else {
            print("VideoPlayerSheetContentView: fetchURLData - Failed. VM error: \(String(describing: viewModel.errorMessage))")
            self.errorMessage = viewModel.errorMessage ?? "Failed to load video URL."
            self.videoURL = nil
        }
        isCurrentlyFetchingURL = false // Set loading FALSE at the end of the operation
        print("VideoPlayerSheetContentView: fetchURLData FINISHED. isCurrentlyFetchingURL: \(isCurrentlyFetchingURL), videoURL (binding): \(String(describing: self.videoURL)), error (binding): \(String(describing: self.errorMessage))")
    }
}

// CORRECTED Preview Provider
struct AssignmentListView_Previews: PreviewProvider {
    static func createPreviewInstance() -> some View {
        let mockAuthService = AuthService()
        mockAuthService.authToken = "fake_trainer_token"
        mockAuthService.loggedInUser = UserResponse(
            id: "trainerPrev", name: "Trainer Preview", email: "t@p.com", role: "trainer",
            createdAt: Date(), clientIds: nil, trainerId: nil
        )
        let mockAPIService = APIService(authService: mockAuthService)
        
        let previewWorkout = Workout(
            id: "wPreview1", trainingPlanId: "tpPreview1", trainerId: "trainerPrev",
            clientId: "clientPrev1", name: "Full Body Day A (Preview)", dayOfWeek: 1,
            notes: "Main lifts", sequence: 0, createdAt: Date(), updatedAt: Date()
        )

        // --- Call the correct init for AssignmentListView ---
        return NavigationView {
            AssignmentListView(
                workout: previewWorkout,
                apiService: mockAPIService,
                authService: mockAuthService // <<< Pass authService here
            )
        }
        .environmentObject(mockAPIService) // For views presented by AssignmentListView
        .environmentObject(mockAuthService)
    }

    static var previews: some View {
        createPreviewInstance()
    }
}
