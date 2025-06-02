// AssignmentListView.swift
import SwiftUI
import AVKit // For VideoPlayer

struct AssignmentListView: View {
    // ViewModel is initialized by this view's init.
    @StateObject var viewModel: AssignmentListViewModel
    
    // Services obtained from the environment, passed to presented sheets/views.
    @EnvironmentObject var apiService: APIService
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var toastManager: ToastManager

    // State for presenting sheets
    @State private var showingAddExerciseSheet = false
    @State private var assignmentToEdit: Assignment? = nil      // For EditAssignmentView sheet
    @State private var assignmentForVideo: Assignment? = nil   // For VideoPlayerSheetContentView sheet
    @State private var assignmentForFeedback: Assignment? = nil // For ProvideFeedbackView sheet
    
    // State specifically for the VideoPlayerSheetContentView's internal bindings
    // These are reset each time the sheet for video is presented.
    @State private var videoURLForSheetContent: URL? = nil
    @State private var videoErrorForSheetContent: String? = nil
    // Note: The actual showing/hiding of the video player sheet will be controlled by 'assignmentForVideo'

    init(workout: Workout, apiService: APIService, authService: AuthService) {
        _viewModel = StateObject(wrappedValue: AssignmentListViewModel(
            workout: workout,
            apiService: apiService,
            authService: authService // ViewModel needs authService for trainer actions
        ))
        print("AssignmentListView (Trainer): Initialized for workout: \(workout.name)")
    }

    var body: some View {
        let _ = print("AssignmentListView (Trainer) BODY re-eval. isLoading: \(viewModel.isLoading), assignmentCount: \(viewModel.assignmentsWithExercises.count), assignmentForVideo: \(assignmentForVideo?.id ?? "nil")")

        List {
            content // @ViewBuilder computed property for list content
        }
        .navigationTitle("Exercises for: \(viewModel.workout.name)")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) { EditButton() } // Enables swipe-to-delete
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddExerciseSheet = true
                } label: {
                    Label("Add Exercise", systemImage: "plus.circle.fill")
                }
            }
        }
        // Sheet for Adding a new exercise assignment
        .sheet(isPresented: $showingAddExerciseSheet, onDismiss: refreshDataAfterSheet) {
            AddExerciseToWorkoutView(
                workout: viewModel.workout,
                currentAssignmentCount: viewModel.assignmentsWithExercises.count,
                apiService: apiService
            )
        }
        // Sheet for Editing an existing assignment
        .sheet(item: $assignmentToEdit, onDismiss: refreshDataAfterSheet) { currentAssignmentToEdit in
            EditAssignmentView(
                assignmentToEdit: currentAssignmentToEdit,
                apiService: apiService
            )
        }
        // Sheet for Viewing Client's Video
        .sheet(item: $assignmentForVideo, onDismiss: {
            self.videoURLForSheetContent = nil // Reset for next time
            self.videoErrorForSheetContent = nil
            print("VideoPlayer sheet (item-based) dismissed.")
        }) { currentAssignmentForVideo in
            VideoPlayerSheetContentView( // Assumes this view is defined elsewhere
                assignmentToPlay: currentAssignmentForVideo,
                viewModel: viewModel, // Pass the AssignmentListViewModel
                videoURL: $videoURLForSheetContent,
                errorMessage: $videoErrorForSheetContent,
                isPresented: Binding( // Custom binding to allow VideoPlayerSheetContentView to dismiss
                    get: { self.assignmentForVideo != nil },
                    set: { if !$0 { self.assignmentForVideo = nil } }
                )
            )
        }
        // Sheet for Providing Feedback
        .sheet(item: $assignmentForFeedback, onDismiss: refreshDataAfterSheet) { currentAssignmentForFeedback in
            ProvideFeedbackView( // Assumes this view is defined elsewhere
                assignment: currentAssignmentForFeedback,
                apiService: apiService,
                toastManager: toastManager
            )
        }
        .onAppear {
            if viewModel.assignmentsWithExercises.isEmpty {
                print("AssignmentListView (Trainer): Appeared. Fetching assignments.")
                refreshData()
            }
        }
        .refreshable {
            print("AssignmentListView (Trainer): Refreshing assignments...")
            refreshData()
        }
    } // End body

    // --- Helper function to refresh data ---
    private func refreshDataAfterSheet() {
        print("Sheet dismissed. Refreshing assignments for workout \(viewModel.workout.id).")
        Task {
            await viewModel.fetchAssignmentsForWorkout()
        }
    }
    
    private func refreshData() { // Overload for onAppear/refreshable
        Task {
            await viewModel.fetchAssignmentsForWorkout()
        }
    }

    // --- Computed Property for List Content ---
    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            HStack { Spacer(); ProgressView("Loading Exercises..."); Spacer() }.padding()
        } else if let errorMessage = viewModel.errorMessage {
            VStack(alignment: .center, spacing: 10) {
                Image(systemName: "exclamationmark.bubble.fill").foregroundColor(.orange).font(.title)
                Text("Error Loading Exercises").font(.headline)
                Text(errorMessage).font(.caption).foregroundColor(.secondary).multilineTextAlignment(.center)
                Button("Retry") { refreshData() }
                    .buttonStyle(.bordered)
            }
            .frame(maxWidth: .infinity).padding()
        } else if viewModel.assignmentsWithExercises.isEmpty {
            VStack(alignment: .center, spacing: 10) {
                Image(systemName: "figure.strengthtraining.traditional").foregroundColor(.secondary).font(.largeTitle)
                Text("No exercises assigned.").font(.headline).foregroundColor(.secondary)
                Text("Tap '+' in the toolbar to add exercises to this workout.")
                    .font(.subheadline).foregroundColor(.gray).multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity).padding()
        } else {
            ForEach(viewModel.assignmentsWithExercises) { assignment in
                // Use a Button to make the whole row tappable for editing,
                // and a contextMenu for other actions.
                Button {
                    print("Assignment row main tap action: Edit for \(assignment.exercise?.name ?? assignment.id)")
                    self.assignmentToEdit = assignment
                } label: {
                    assignmentRowContent(for: assignment)
                }
                .buttonStyle(.plain) // Makes it look like a list row
                .contextMenu {
                    Button {
                        print("Context Menu: Edit for \(assignment.id)")
                        self.assignmentToEdit = assignment
                    } label: { Label("Edit Assignment", systemImage: "pencil") }

                    if assignment.status == "submitted" && assignment.uploadId != nil {
                        Button {
                            print("Context Menu: View Video for \(assignment.id)")
                            self.videoURLForSheetContent = nil // Reset before fetch attempt
                            self.videoErrorForSheetContent = nil
                            self.assignmentForVideo = assignment // Trigger video sheet
                        } label: { Label("View Client Video", systemImage: "play.tv.fill") }
                        
                        Button {
                            print("Context Menu: Provide Feedback for \(assignment.id)")
                            self.assignmentForFeedback = assignment // Trigger feedback sheet
                        } label: { Label("Provide Feedback", systemImage: "pencil.and.ellipsis.rectangle")}
                    }
                    // You could add a delete option here too, or rely on swipe-to-delete
                }
            }
            .onDelete(perform: deleteAssignments) // Swipe to delete
        }
    }

    // --- Helper View for Each Assignment Row Content ---
    @ViewBuilder
    private func assignmentRowContent(for assignment: Assignment) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(assignment.exercise?.name ?? "Exercise ID: \(assignment.exerciseId)")
                    .font(.headline)
                    .foregroundColor(assignment.exercise == nil ? .orange : .primary)
                Spacer()
                // Status indicators (buttons are now in context menu or main tap action)
                if assignment.status == "submitted" && assignment.uploadId != nil {
                    Image(systemName: "video.fill.badge.checkmark")
                        .foregroundColor(.purple)
                        .help("Video Submitted")
                } else if assignment.status == "reviewed" {
                     Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                        .help("Reviewed by Trainer")
                } else {
                    Text(assignment.status.capitalized)
                        .font(.caption)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(statusColor(for: assignment.status).opacity(0.2))
                        .foregroundColor(statusColor(for: assignment.status))
                        .cornerRadius(4)
                }
            }

            ParameterRow(label: "Seq", value: String(assignment.sequence + 1)) // 1-based for display
            ParameterRow(label: "Sets", value: assignment.sets.map { String($0) })
            ParameterRow(label: "Reps", value: assignment.reps)
            ParameterRow(label: "Weight", value: assignment.weight)
            if let rest = assignment.rest, !rest.isEmpty { ParameterRow(label: "Rest", value: rest) }
            if let tempo = assignment.tempo, !tempo.isEmpty { ParameterRow(label: "Tempo", value: tempo) }
            if let duration = assignment.duration, !duration.isEmpty { ParameterRow(label: "Duration", value: duration) }


            if let notes = assignment.trainerNotes, !notes.isEmpty {
                Text("Trainer Notes:").font(.caption.weight(.semibold)).padding(.top, 2)
                Text(notes).font(.caption).foregroundColor(.secondary)
            }
            if let clientNotes = assignment.clientNotes, !clientNotes.isEmpty {
                Text("Client Notes:").font(.caption.weight(.semibold)).padding(.top, 2)
                Text(clientNotes).font(.caption).foregroundColor(.gray)
            }
            if let trainerFeedback = assignment.feedback, !trainerFeedback.isEmpty {
                Text("Your Feedback:").font(.caption.weight(.semibold)).foregroundColor(.blue).padding(.top, 2)
                Text(trainerFeedback).font(.caption).foregroundColor(.blue.opacity(0.9))
            }
        }
        .padding(.vertical, 5)
    }
    
    // --- Delete Function for .onDelete ---
    private func deleteAssignments(at offsets: IndexSet) {
        let assignmentsToDelete = offsets.map { viewModel.assignmentsWithExercises[$0] }
        Task {
            for assignment in assignmentsToDelete {
                print("AssignmentListView: Requesting delete for assignment ID: \(assignment.id)")
                let success = await viewModel.deleteAssignment(assignmentId: assignment.id)
                if !success {
                    print("AssignmentListView: Failed to delete assignment \(assignment.id). Error: \(viewModel.errorMessage ?? "Unknown")")
                    break
                }
            }
            // ViewModel should handle optimistic removal, or refresh is triggered by sheet dismiss
        }
    }
    
    func statusColor(for status: String) -> Color {
        switch status.lowercased() {
        case "assigned": return .gray
        case "completed": return .blue
        case "submitted": return .purple
        case "reviewed": return .green
        default: return .black
        }
    }

} // End struct AssignmentListView


// Make sure ParameterRow is defined (e.g. in HelperViews.swift)
// Make sure VideoPlayerSheetContentView is defined (e.g. in its own file or HelperViews.swift)
// Make sure VideoPlayerView is defined (e.g. in its own file or HelperViews.swift)
// Make sure ProvideFeedbackView is defined
// Make sure EditAssignmentView is defined
// Make sure AddExerciseToWorkoutView is defined

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


// Preview Provider for AssignmentListView
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
        
        // Create the ViewModel instance for the preview
        let previewViewModel = AssignmentListViewModel(
            workout: previewWorkout,
            apiService: mockAPIService,
            authService: mockAuthService // Pass authService here
        )

        // Optionally populate with mock assignments for preview
        let mockEx1 = Exercise(id: "ex1", trainerId: "trainerPrev", name: "Barbell Squats", createdAt: Date(), updatedAt: Date())
        previewViewModel.assignmentsWithExercises = [
             Assignment(id: "a1", workoutId: "wPreview1", exerciseId: "ex1", assignedAt: Date(), status: "submitted", sets: 3, reps: "5", rest: "120s", tempo: "2010", weight: "80kg", duration: nil, sequence: 0, trainerNotes: "Keep core tight.", clientNotes: "Felt good!", uploadId: "fakeUploadId1", feedback: nil, updatedAt: Date(), exercise: mockEx1)
        ]


        return NavigationView {
            // This now uses the init of AssignmentListView that takes the ViewModel
            // If you changed AssignmentListView's init back to only take workout, apiService, authService,
            // then call that init here instead.
            // For this example, I'm assuming we added an init(viewModel: ...) to AssignmentListView
            // for easier previewing of specific states.
            // If not, call:
            // AssignmentListView(workout: previewWorkout, apiService: mockAPIService, authService: mockAuthService)
            
            // Sticking to the init defined in AssignmentListView:
             AssignmentListView(
                 workout: previewWorkout,
                 apiService: mockAPIService,
                 authService: mockAuthService
             )
        }
        .environmentObject(mockAPIService)
        .environmentObject(mockAuthService)
    }

    static var previews: some View {
        createPreviewInstance()
    }
}
