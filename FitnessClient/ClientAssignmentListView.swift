// ClientAssignmentListView.swift
import SwiftUI
import PhotosUI // Import PhotosUI for PhotosPicker
import UniformTypeIdentifiers

// --- Struct for upload information to make it Equatable ---
struct UploadInfo: Equatable {
    let url: URL
    let assignmentId: String
    let contentType: String
    let fileName: String
}
// --- End UploadInfo Struct ---

struct ClientAssignmentListView: View {
    // ViewModel is initialized by the parent (ClientWorkoutsView)
    @StateObject var viewModel: ClientAssignmentListViewModel
    
    // Services from environment, if needed for any actions from this view later
    @EnvironmentObject var apiService: APIService
    // @EnvironmentObject var authService: AuthService // Less likely needed directly here
    @EnvironmentObject var toastManager: ToastManager

    // State for PhotosPicker
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    // State to trigger upload process after video is selected, using the new struct
    @State private var videoToUploadLocally: UploadInfo? = nil

    // For showing upload progress/status for a specific assignment
    @State private var uploadingAssignmentId: String? = nil
    @State private var uploadProgress: Double = 0.0
    @State private var uploadMessage: String? = nil // General message for upload status
    
    // State to manage which assignment's performance logging UI is expanded
    @State private var loggingPerformanceForAssignmentId: String? = nil

    // Initializer that receives the specific workout and APIService
    init(workout: Workout, apiService: APIService, toastManager: ToastManager) {
        _viewModel = StateObject(wrappedValue: ClientAssignmentListViewModel(
            workout: workout,
            apiService: apiService,
            toastManager: toastManager // Pass it to the VM
        ))
        print("ClientAssignmentListView: Initialized for workout: \(workout.name)")
    }

    var body: some View {
        // Debug print to trace body re-evaluation
        let _ = print("ClientAssignmentListView BODY re-evaluating. isLoading: \(viewModel.isLoading), assignmentCount: \(viewModel.assignmentsWithExercises.count), uploadMsg: \(uploadMessage ?? "nil")")

        List {
            // --- Loading State ---
            if viewModel.isLoading {
                HStack { Spacer(); ProgressView("Loading Exercises..."); Spacer() }
            }
            // --- Error State ---
            else if let errorMessage = viewModel.errorMessage, viewModel.assignmentsWithExercises.isEmpty {
                VStack(alignment: .center, spacing: 10) {
                    Image(systemName: "exclamationmark.bubble.fill").foregroundColor(.orange).font(.title)
                    Text("Could Not Load Exercises").font(.headline)
                    Text(errorMessage).font(.caption).foregroundColor(.secondary).multilineTextAlignment(.center)
                    Button("Retry") { Task { await viewModel.fetchMyAssignmentsForWorkout() } }
                        .buttonStyle(.bordered)
                }.frame(maxWidth: .infinity).padding()
            }
            // --- Empty State ---
            else if viewModel.assignmentsWithExercises.isEmpty {
                 VStack(alignment: .center, spacing: 10) {
                    Image(systemName: "list.bullet.indent").font(.largeTitle).foregroundColor(.secondary)
                    Text("No Exercises Yet").font(.headline)
                    Text("This workout doesn't have any exercises assigned to it yet.").font(.caption).foregroundColor(.secondary).multilineTextAlignment(.center)
                }.frame(maxWidth: .infinity).padding()
            }
            // --- Data Loaded State ---
            else {
                ForEach($viewModel.assignmentsWithExercises) { $assignment in
                    VStack(alignment: .leading, spacing: 8) {
                        // Exercise Name and Action Buttons Row
                        HStack {
                            Text(assignment.exercise?.name ?? "Exercise ID: \(assignment.exerciseId)")
                                .font(.title3).fontWeight(.semibold)
                                .foregroundColor(assignment.exercise == nil ? .orange : .primary)
                            Spacer()
                            
                            // Status and Action Buttons
                            statusAndActionButtons(for: assignment) // Extracted to helper
                        }

                        // Display Parameters
                        ParameterRow(label: "Sets", value: assignment.sets.map { String($0) })
                        ParameterRow(label: "Reps", value: assignment.reps)
                        ParameterRow(label: "Weight", value: assignment.weight)
                        ParameterRow(label: "Rest", value: assignment.rest)
                        ParameterRow(label: "Tempo", value: assignment.tempo)
                        ParameterRow(label: "Duration", value: assignment.duration)

                        if let notes = assignment.trainerNotes, !notes.isEmpty {
                            Text("Trainer Notes:")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.gray)
                                .padding(.top, 4)
                            Text(notes)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        // --- Display Logged Performance (if any) ---
                        if assignment.achievedSets != nil || assignment.achievedReps != nil || assignment.achievedWeight != nil || assignment.achievedDuration != nil || (assignment.clientPerformanceNotes != nil && !assignment.clientPerformanceNotes!.isEmpty) {
                            Divider().padding(.vertical, 2)
                            Text("Logged Performance:")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.green)
                            ParameterRow(label: "Achieved Sets", value: assignment.achievedSets.map { String($0) })
                            ParameterRow(label: "Achieved Reps", value: assignment.achievedReps)
                            ParameterRow(label: "Achieved Weight", value: assignment.achievedWeight)
                            ParameterRow(label: "Achieved Duration", value: assignment.achievedDuration)
                            if let clientNotes = assignment.clientPerformanceNotes, !clientNotes.isEmpty {
                                Text("Your Notes:").font(.caption.weight(.medium)).padding(.top, 2)
                                Text(clientNotes).font(.caption).foregroundColor(.secondary)
                            }
                        }
                        // --- Display Trainer Feedback ---
                        if assignment.status.lowercased() == domain.AssignmentStatus.reviewed.rawValue,
                           let feedback = assignment.feedback, !feedback.isEmpty {
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Image(systemName: "text.bubble.fill") // Feedback icon
                                        .foregroundColor(.accentColor) // Use app's accent color
                                    Text("Trainer Feedback:")
                                        .font(.caption.weight(.bold)) // Bolder label
                                        .foregroundColor(.accentColor)
                                }
                                Text(feedback)
                                    .font(.footnote) // Slightly larger than caption for readability
                                    .foregroundColor(.secondary) // Good contrast for readability
                                    .padding(.leading, 5) // Indent feedback text slightly
                            }
                            .padding(10) // Padding inside the feedback block
                            .background(Color.accentColor.opacity(0.1)) // Subtle background highlight
                            .cornerRadius(8)
                            .padding(.top, 6) // Space above the feedback block
                        }
                        // --- Toggle Button for Logging Performance ---
                        // Show if assignment is not yet fully reviewed by trainer and performance not yet logged extensively, or allow re-logging
                        if assignment.status == "completed" || assignment.status == "assigned" || assignment.status == "submitted" {
                            Button {
                                withAnimation {
                                    if loggingPerformanceForAssignmentId == assignment.id {
                                        loggingPerformanceForAssignmentId = nil // Collapse
                                    } else {
                                        loggingPerformanceForAssignmentId = assignment.id // Expand
                                        // Pre-fill with target if not yet logged
                                        if assignment.achievedSets == nil && assignment.sets != nil { $assignment.achievedSets.wrappedValue = assignment.sets }
                                        if assignment.achievedReps == nil && assignment.reps != nil { $assignment.achievedReps.wrappedValue = assignment.reps }
                                        if assignment.achievedWeight == nil && assignment.weight != nil { $assignment.achievedWeight.wrappedValue = assignment.weight }
                                        if assignment.achievedDuration == nil && assignment.duration != nil { $assignment.achievedDuration.wrappedValue = assignment.duration }
                                    }
                                }
                            } label: {
                                Label(loggingPerformanceForAssignmentId == assignment.id ? "Hide Log Form" : "Log Performance",
                                      systemImage: loggingPerformanceForAssignmentId == assignment.id ? "chevron.up.square" : "square.and.pencil")
                            }
                            .font(.caption)
                            .padding(.top, 5)
                        }

                        // --- Performance Logging Form (Conditional) ---
                        if loggingPerformanceForAssignmentId == assignment.id {
                            performanceLoggingForm(for: $assignment) // Pass binding to assignment
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        } // End List
        .navigationTitle("Exercises for: \(viewModel.workout.name)")
        .onAppear {
            if viewModel.assignmentsWithExercises.isEmpty {
                print("ClientAssignmentListView: Appeared for workout \(viewModel.workout.id). Fetching assignments.")
                Task { await viewModel.fetchMyAssignmentsForWorkout() }
            }
        }
        .refreshable {
            print("ClientAssignmentListView: Refreshing assignments...")
            await viewModel.fetchMyAssignmentsForWorkout()
        }
        // --- .onChange for videoToUploadLocally (now using UploadInfo?) ---
        .onChange(of: videoToUploadLocally) { newValue in // For iOS 17+: { oldValue, newValue in
            guard let uploadInfo = newValue else { return } // newValue is UploadInfo?
            
            let videoFileSize = getFileSize(at: uploadInfo.url) ?? 0

            print("ClientAssignmentListView .onChange(videoToUploadLocally): Processing \(uploadInfo.fileName)")
            
            Task {
                uploadingAssignmentId = uploadInfo.assignmentId
                uploadProgress = 0.01
                uploadMessage = "Preparing upload for \(uploadInfo.fileName)..."

                await viewModel.handleVideoUpload(
                    forAssignmentId: uploadInfo.assignmentId,
                    videoFileURL: uploadInfo.url,
                    contentType: uploadInfo.contentType,
                    fileName: uploadInfo.fileName,
                    fileSize: videoFileSize,
                    progressHandler: { progressFraction in
                        self.uploadProgress = progressFraction
                    }
                )
                
                // Clear states AFTER the async task completes
                self.videoToUploadLocally = nil
                self.selectedPhotoItem = nil // Ensure picker selection is also reset
                self.uploadingAssignmentId = nil
                self.uploadProgress = 0.0
                
                if viewModel.errorMessage == nil { // Check general VM error first
                    uploadMessage = "Upload for \(uploadInfo.fileName) complete!"
                } else {
                    uploadMessage = viewModel.errorMessage // Show VM's specific error
                }
                // Auto-clear message
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) { // Increased delay
                    if self.uploadMessage != nil { self.uploadMessage = nil }
                }
            }
        }
        // Display overall upload message at the bottom of the view or list
        if let message = uploadMessage {
             Text(message)
                .font(.caption)
                .foregroundColor(viewModel.errorMessage == nil && !message.lowercased().contains("error") && !message.lowercased().contains("failed") ? .green : .red)
                .padding(.horizontal)
                .frame(maxWidth: .infinity, alignment: .center)
                .transition(.opacity.animation(.easeInOut)) // Add a small animation
        }
    } // End body

    // --- Helper View for Performance Logging Form ---
    @ViewBuilder
    private func performanceLoggingForm(for assignmentBinding: Binding<Assignment>) -> some View {
        // Use assignmentBinding.wrappedValue to access properties, $assignmentBinding.achievedSets for TextFields
        let assignment = assignmentBinding.wrappedValue
        
        VStack(alignment: .leading, spacing: 8) {
            Divider()
            Text("Log Your Performance").font(.headline).padding(.top)
            
            HStack {
                Text("Achieved Sets:")
                TextField("Sets", text: Binding(
                    get: { assignmentBinding.achievedSets.wrappedValue.map { String($0) } ?? "" },
                    set: { assignmentBinding.achievedSets.wrappedValue = Int($0) }
                ))
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            HStack {
                Text("Achieved Reps:")
                TextField("Reps", text: Binding(
                    get: { assignmentBinding.achievedReps.wrappedValue ?? "" },
                    set: { assignmentBinding.achievedReps.wrappedValue = $0.isEmpty ? nil : $0 }
                ))
                .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            HStack {
                Text("Achieved Weight:")
                TextField("Weight", text: Binding(
                    get: { assignmentBinding.achievedWeight.wrappedValue ?? "" },
                    set: { assignmentBinding.achievedWeight.wrappedValue = $0.isEmpty ? nil : $0 }
                ))
                .textFieldStyle(RoundedBorderTextFieldStyle())
            }
             HStack {
                Text("Achieved Duration:")
                TextField("Duration", text: Binding(
                    get: { assignmentBinding.achievedDuration.wrappedValue ?? "" },
                    set: { assignmentBinding.achievedDuration.wrappedValue = $0.isEmpty ? nil : $0 }
                ))
                .textFieldStyle(RoundedBorderTextFieldStyle())
            }

            Text("Your Notes (Optional):")
            TextEditor(text: Binding(
                get: { assignmentBinding.clientPerformanceNotes.wrappedValue ?? ""},
                set: { assignmentBinding.clientPerformanceNotes.wrappedValue = $0.isEmpty ? nil : $0 }
            ))
            .frame(height: 80)
            .border(Color.gray.opacity(0.5))

            Button("Save Performance Log") {
                Task {
                    let payload = LogPerformancePayload(
                        achievedSets: assignment.achievedSets, // Use current values from bound assignment
                        achievedReps: assignment.achievedReps,
                        achievedWeight: assignment.achievedWeight,
                        achievedDuration: assignment.achievedDuration,
                        clientPerformanceNotes: assignment.clientPerformanceNotes
                    )
                    let success = await viewModel.logPerformance(for: assignment.id, achievedData: payload)
                    if success {
                        loggingPerformanceForAssignmentId = nil // Collapse form on success
                        // Optionally also mark as completed if not already
                        if assignment.status == "assigned" {
                             await viewModel.markAssignmentStatus(assignmentId: assignment.id, newStatus: "completed")
                        }
                    }
                    // Error is handled by viewModel.errorMessage and displayed in main list error area
                }
            }
            .padding(.top)
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isLoading) // Disable if another general list load is happening
        }
        .padding(.vertical)
        .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity)) // Nice animation
    }
    
    // --- Helper ViewBuilder function for status and action buttons ---
    @ViewBuilder
    private func statusAndActionButtons(for assignment: Assignment) -> some View {
        if uploadingAssignmentId == assignment.id {
            ProgressView(value: uploadProgress, total: 1.0) {
                Text("Uploading...").font(.caption2)
            } currentValueLabel: {
                Text(String(format: "%.0f%%", uploadProgress * 100)).font(.caption2)
            }
            .progressViewStyle(.linear)
            .frame(width: 100)
        } else if assignment.status == "assigned" {
            Button {
                Task { await viewModel.markAssignmentStatus(assignmentId: assignment.id, newStatus: "completed") }
            } label: {
                Label("Mark Done", systemImage: "checkmark.circle")
            }
            .buttonStyle(.bordered)
            .tint(.green)
        } else if assignment.status == "completed" && assignment.uploadId == nil {
            PhotosPicker(
                selection: $selectedPhotoItem,
                matching: .videos, // Can also use .any(of: [.videos, .livePhotos]) etc.
                photoLibrary: .shared()
            ) {
                Label("Upload Video", systemImage: "video.badge.plus")
            }
            .tint(.blue)
            .buttonStyle(.bordered)
            // This onChange should ideally be specific to THIS assignment's picker.
            // The current setup uses a single $selectedPhotoItem for the whole view.
            // For multiple pickers, more complex state management might be needed.
            // The current processSelectedVideo takes `forAssignment` to link it.
            .onChange(of: selectedPhotoItem) { newItem in // For iOS 17+: { oldValue, newValue in
                 Task { await processSelectedVideo(item: newItem, forAssignment: assignment) }
            }
        } else if assignment.status == "submitted" || (assignment.status == "completed" && assignment.uploadId != nil) {
            HStack {
                Image(systemName: "video.fill.badge.checkmark").foregroundColor(.purple)
                Text("Submitted").font(.caption).foregroundColor(.purple)
            }
        } else if assignment.status == "reviewed" {
             HStack {
                Image(systemName: "checkmark.seal.fill").foregroundColor(.blue)
                Text("Reviewed").font(.caption).foregroundColor(.blue)
            }
        } else {
            Text("Status: \(assignment.status.capitalized)")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }


    // Helper to process selected video from PhotosPicker
    private func processSelectedVideo(item: PhotosPickerItem?, forAssignment assignment: Assignment) async {
        guard let item = item else {
            print("processSelectedVideo: No item selected for assignment \(assignment.id).")
            return
        }
        
        // Prevent reprocessing if already working on an upload for a different assignment
        // or if videoToUploadLocally is already set (meaning one is pending upload trigger)
        if self.videoToUploadLocally != nil && self.videoToUploadLocally?.assignmentId != assignment.id {
            print("processSelectedVideo: Another video selection is already pending processing.")
            self.selectedPhotoItem = nil // Reset picker if we ignore this selection
            return
        }
        
        print("processSelectedVideo: Processing item for assignment \(assignment.id)")
        var fileNameToUse: String
        fileNameToUse = "\(UUID().uuidString).mp4"
        
        self.uploadMessage = "Loading video: \(fileNameToUse ?? "selected video")..."

        do {
            if let data = try await item.loadTransferable(type: Data.self) {

                
                
                let utTypeIdentifier = item.supportedContentTypes.first?.identifier ?? "public.mpeg-4"// Default if type unknown
                print("----->>>>> Selected Video Content Type (UTType Identifier): \(utTypeIdentifier)")
                
                var mimeType = "video/mp4"
                
                if let utType = UTType(utTypeIdentifier) { // Requires import UniformTypeIdentifiers
                    if let preferredMimeType = utType.preferredMIMEType {
                        mimeType = preferredMimeType
                        print("----->>>>> Converted to MIME Type: \(mimeType)")
                    } else {
                        print("----->>>>> WARN: Could not get preferred MIME type for \(utTypeIdentifier), using default \(mimeType)")
                    }
                }

                let tempDir = FileManager.default.temporaryDirectory
                // Ensure unique temp file name even if suggestedFileName is the same for multiple picks
                let uniqueTempFileName = "\(UUID().uuidString)-\(fileNameToUse)"
                let tempURL = tempDir.appendingPathComponent(uniqueTempFileName)
                
                try data.write(to: tempURL)
                print("processSelectedVideo: Video saved to temporary URL: \(tempURL.path) for assignment \(assignment.id)")
                
                // Set the state to trigger the full upload process via .onChange(of: videoToUploadLocally)
                self.videoToUploadLocally = UploadInfo(
                    url: tempURL,
                    assignmentId: assignment.id,
                    contentType: mimeType,
                    fileName: fileNameToUse // Use original suggested filename for backend, not unique temp name
                )
                self.uploadMessage = nil // Clear "Loading video..."

            } else {
                print("processSelectedVideo: Failed to load video data from PhotosPickerItem for assignment \(assignment.id).")
                self.uploadMessage = "Could not load video data."
                self.selectedPhotoItem = nil // Reset picker on failure to load data
            }
        } catch {
            print("processSelectedVideo: Error loading video transferable for assignment \(assignment.id): \(error)")
            self.uploadMessage = "Error preparing video: \(error.localizedDescription)"
            self.selectedPhotoItem = nil // Reset picker on error
        }
        // Do not reset selectedPhotoItem here if data loading started successfully,
        // let the .onChange(of: videoToUploadLocally) handler do it after processing.
    }

    // Helper function to get file size
    private func getFileSize(at url: URL) -> Int64? {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            return attributes[.size] as? Int64
        } catch {
            print("Error getting file size for \(url.path): \(error)")
            return nil
        }
    }
} // End struct ClientAssignmentListView

// Preview Provider (ensure it calls the correct init)
struct ClientAssignmentListView_Previews: PreviewProvider {
    static func createPreviewInstance() -> some View {
        let mockAuth = AuthService()
        mockAuth.authToken = "fake_client_token"
        mockAuth.loggedInUser = UserResponse(id: "clientPrev", name: "Client Preview", email: "c@p.com", role: "client", createdAt: Date(), clientIds: nil, trainerId: "tPrev")
        let mockAPI = APIService(authService: mockAuth)
        let mockToast = ToastManager();
        
        let previewWorkout = Workout(id: "wPreview1", trainingPlanId: "tpPreview1", trainerId: "tPrev", clientId: "clientPrev", name: "Leg Day Preview", dayOfWeek: 2, notes: "Remember to stretch!", sequence: 0, createdAt: Date(), updatedAt: Date())

        let vm = ClientAssignmentListViewModel(workout: previewWorkout, apiService: mockAPI, toastManager: mockToast)
        let ex1 = Exercise(id: "ex1", trainerId: "tPrev", name: "Barbell Squats", createdAt: Date(), updatedAt: Date())
        vm.assignmentsWithExercises = [
            Assignment(id: "a1", workoutId: "wPreview1", exerciseId: "ex1", assignedAt: Date(), status: "completed", sets: 4, reps: "8-10", rest: "90s", tempo: "2010", weight: "100kg", duration: nil, sequence: 0, trainerNotes: "Go deep!", clientNotes: nil, uploadId: nil, feedback: nil, updatedAt: Date(), exercise: ex1)
        ]

        // --- MOCK DATA FOR PREVIEW ---
        let mockExercise1 = Exercise(id: "ex1", trainerId: "tPrev", name: "Barbell Squats", createdAt: Date(), updatedAt: Date())
        let mockExercise2 = Exercise(id: "ex2", trainerId: "tPrev", name: "Leg Press", createdAt: Date(), updatedAt: Date())
        let mockExerciseReviewed = Exercise(id: "exReviewed", trainerId: "tPrev", name: "Reviewed Exercise", createdAt: Date(), updatedAt: Date())
        let mockExerciseSubmitted = Exercise(id: "exSubmitted", trainerId: "tPrev", name: "Submitted Exercise", createdAt: Date(), updatedAt: Date())

        vm.assignmentsWithExercises = [
            Assignment(id: "a1_reviewed", workoutId: "wPreview1", exerciseId: "exReviewed", assignedAt: Date(),
                       status: domain.AssignmentStatus.reviewed.rawValue, // Important for preview
                       sets: 3, reps: "10", rest: "60s", tempo: nil, weight: "Bodyweight", duration: nil, sequence: 0,
                       trainerNotes: "Make sure to engage your core.",
                       clientNotes: "This felt pretty good!",
                       uploadId: "fakeUploadIdClient1",
                       feedback: "Great job on maintaining form, Alice! For next time, try to go a bit deeper on the squats. Overall, excellent effort!", // Mock feedback
                       updatedAt: Date(), exercise: mockExerciseReviewed),
            Assignment(id: "a2_submitted", workoutId: "wPreview1", exerciseId: "exSubmitted", assignedAt: Date(),
                       status: domain.AssignmentStatus.submitted.rawValue, // So "Upload Video" button won't show
                       sets: 4, reps: "12", rest: "45s", tempo: nil, weight: "10kg Dumbbells", duration: nil, sequence: 1,
                       trainerNotes: "Keep elbows slightly tucked.", clientNotes: nil, uploadId: "fakeUploadIdClient2", feedback: nil,
                       updatedAt: Date(), exercise: mockExerciseSubmitted),
            Assignment(id: "a1", workoutId: "wPreview1", exerciseId: "ex1", assignedAt: Date(),
                       status: domain.AssignmentStatus.reviewed.rawValue, // <<< For previewing feedback
                       sets: 4, reps: "8-10", rest: "90s", tempo: "2010", weight: "100kg", duration: nil, sequence: 0,
                       trainerNotes: "Go deep on these squats!",
                       clientNotes: "Felt good today, managed all reps.",
                       uploadId: "fakeUploadId1",
                       feedback: "Excellent depth on your squats, Alice! Keep up the great work. Watch your knee tracking on the last set.", // <<< Mock feedback
                       updatedAt: Date(), exercise: mockExercise1),
            Assignment(id: "a2", workoutId: "wPreview1", exerciseId: "ex2", assignedAt: Date(),
                       status: domain.AssignmentStatus.submitted.rawValue, // Before feedback
                       sets: 3, reps: "12-15", rest: "60s", tempo: nil, weight: "150kg", duration: nil, sequence: 1,
                       trainerNotes: "Full range of motion.", clientNotes: nil, uploadId: "fakeUploadId2", feedback: nil,
                       updatedAt: Date(), exercise: mockExercise2),
            Assignment(id: "a3", workoutId: "wPreview1", exerciseId: "ex1", assignedAt: Date(),
                       status: domain.AssignmentStatus.assigned.rawValue, // Not yet done
                       sets: 3, reps: "10", rest: "60s", tempo: nil, weight: "90kg", duration: nil, sequence: 2,
                       trainerNotes: "Control the descent.", clientNotes: nil, uploadId: nil, feedback: nil,
                       updatedAt: Date(), exercise: mockExercise1)
        ]
        // --- END MOCK DATA ---

        return NavigationView {
            ClientAssignmentListView(workout: previewWorkout, apiService: mockAPI, toastManager: mockToast) // Pass the pre-configured VM
        }
        .environmentObject(mockAPI)
        .environmentObject(mockAuth)
        .environmentObject(mockToast);
    }

    static var previews: some View {
        createPreviewInstance()
    }
}
