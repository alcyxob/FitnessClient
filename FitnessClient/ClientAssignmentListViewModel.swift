// ClientAssignmentListViewModel.swift
import Foundation
import SwiftUI

@MainActor
class ClientAssignmentListViewModel: ObservableObject {
    // Store assignments with populated exercise details
    @Published var assignmentsWithExercises: [Assignment] = []
    @Published var isLoading = false // General loading for the list
    @Published var errorMessage: String? = nil // General error for the list

    let workout: Workout // The workout these assignments belong to
    private let apiService: APIService
    // No direct need for AuthService here if client ID for auth is handled by APIService token

    init(workout: Workout, apiService: APIService) {
        self.workout = workout
        self.apiService = apiService
        print("ClientAssignListVM: Initialized for workout: \(workout.name) (\(workout.id))")
    }

    // Method to fetch assignments for the client's workout
    func fetchMyAssignmentsForWorkout() async {
        print("ClientAssignListVM: Fetching my assignments for workout ID: \(workout.id)")
        isLoading = true
        errorMessage = nil
        // assignmentsWithExercises = [] // Optional: clear or show stale

        // Client ID is implicit in the token used by APIService
        let endpoint = "/client/workouts/\(workout.id)/assignments"

        do {
            // 1. Fetch the raw assignments
            let rawAssignments: [Assignment] = try await apiService.GET(endpoint: endpoint)
            print("ClientAssignListVM: Fetched \(rawAssignments.count) raw assignments.")

            // 2. Fetch exercise details for each assignment
            var populatedAssignments: [Assignment] = []
            for var assignment in rawAssignments { // Make 'assignment' mutable
                if !assignment.exerciseId.isEmpty {
                    print("ClientAssignListVM: Fetching exercise detail for ID: \(assignment.exerciseId)")
                    do {
                        let exerciseDetail: Exercise = try await apiService.GET(endpoint: "/exercises/\(assignment.exerciseId)")
                        assignment.exercise = exerciseDetail
                        print("ClientAssignListVM: Successfully fetched exercise: \(exerciseDetail.name)")
                    } catch {
                        print("ClientAssignListVM: WARN - Failed to fetch exercise detail for \(assignment.exerciseId): \(error.localizedDescription)")
                        // Assignment will be added without full exercise detail
                    }
                }
                populatedAssignments.append(assignment)
            }
            
            self.assignmentsWithExercises = populatedAssignments.sorted { $0.sequence < $1.sequence }
            
            print("ClientAssignListVM: Successfully processed \(self.assignmentsWithExercises.count) assignments with attempted exercise population.")
            if self.assignmentsWithExercises.isEmpty && rawAssignments.isEmpty {
                // self.errorMessage = "This workout doesn't have any exercises assigned yet." // Set only if truly empty without error
            }

        } catch let error as APINetworkError {
            self.errorMessage = error.localizedDescription
            print("ClientAssignListVM: Error fetching assignments (APINetworkError): \(error.localizedDescription)")
            self.assignmentsWithExercises = [] // Clear on error
        } catch {
            self.errorMessage = "An unexpected error occurred fetching assignments."
            print("ClientAssignListVM: Unexpected error fetching assignments: \(error.localizedDescription)")
            self.assignmentsWithExercises = [] // Clear on error
        }
        isLoading = false
        print("ClientAssignListVM: fetchMyAssignmentsForWorkout finished. isLoading: \(isLoading), Count: \(assignmentsWithExercises.count), Error: \(errorMessage ?? "None")")
    }


    // Method for client to mark their assignment status
    func markAssignmentStatus(assignmentId: String, newStatus: String) async {
        print("ClientAssignListVM: Marking assignment \(assignmentId) as \(newStatus)")
        self.errorMessage = nil // Clear previous errors specific to this action

        let endpoint = "/client/assignments/\(assignmentId)/status"
        let payload = UpdateAssignmentStatusPayload(status: newStatus)

        do {
            let updatedAssignment: Assignment = try await apiService.PATCH(endpoint: endpoint, body: payload)

            if let index = assignmentsWithExercises.firstIndex(where: { $0.id == updatedAssignment.id }) {
                var assignmentToUpdate = updatedAssignment
                if let existingExercise = assignmentsWithExercises[index].exercise {
                     assignmentToUpdate.exercise = existingExercise
                } else if !updatedAssignment.exerciseId.isEmpty {
                    do {
                        let exerciseDetail: Exercise = try await apiService.GET(endpoint: "/exercises/\(updatedAssignment.exerciseId)")
                        assignmentToUpdate.exercise = exerciseDetail
                    } catch {
                        print("ClientAssignListVM: WARN - Failed to re-fetch exercise detail for updated assignment \(updatedAssignment.exerciseId) after status change.")
                    }
                }
                assignmentsWithExercises[index] = assignmentToUpdate
            } else {
                print("ClientAssignListVM: Updated assignment not found in local list after status change, refreshing all.")
                await self.fetchMyAssignmentsForWorkout() // <<< CORRECTED
            }
            print("ClientAssignListVM: Assignment \(assignmentId) status updated to \(newStatus) successfully.")

        } catch let error as APINetworkError {
            self.errorMessage = "Failed to update status: \(error.localizedDescription)"
            print("ClientAssignListVM: Error updating assignment status (APINetworkError): \(error.localizedDescription)")
            // Optionally refresh to revert optimistic UI or get server state
            // await self.fetchMyAssignmentsForWorkout() // <<< CORRECTED
        } catch {
            self.errorMessage = "An unexpected error occurred while updating status."
            print("ClientAssignListVM: Unexpected error updating status: \(error.localizedDescription)")
            // await self.fetchMyAssignmentsForWorkout() // <<< CORRECTED
        }
    }


    // Method to handle the full video upload process
    func handleVideoUpload(
        forAssignmentId assignmentId: String,
        videoFileURL: URL,
        contentType: String,
        fileName: String,
        fileSize: Int64,
        progressHandler: @escaping (Double) -> Void
    ) async {
        print("ClientAssignListVM: Starting video upload process for assignment \(assignmentId)")
        self.errorMessage = nil // Clear previous general errors

        var finalObjectKey: String?

        do {
            // 1. Request Pre-signed URL from our backend
            print("ClientAssignListVM: Requesting S3 upload URL...")
            print("----->>>>> ContentType received by ViewModel: \(contentType)")
            progressHandler(0.05)
            
            let uploadURLRequestPayload = RequestUploadURLPayload(contentType: contentType)
            let endpointUploadURL = "/client/assignments/\(assignmentId)/upload-url"
            let presignedResponse: UploadURLResponse = try await apiService.POST(endpoint: endpointUploadURL, body: uploadURLRequestPayload)
            
            guard let uploadS3URL = URL(string: presignedResponse.uploadUrl) else {
                throw APINetworkError.invalidURL
            }
            finalObjectKey = presignedResponse.objectKey
            print("ClientAssignListVM: Received S3 Upload URL. Object Key: \(finalObjectKey ?? "N/A")")
            progressHandler(0.1)

            // 2. Upload video file directly to S3
            print("ClientAssignListVM: Uploading video to S3...")
            var s3Request = URLRequest(url: uploadS3URL)
            s3Request.httpMethod = "PUT"
            s3Request.setValue(contentType, forHTTPHeaderField: "Content-Type")
            // s3Request.setValue("\(fileSize)", forHTTPHeaderField: "Content-Length") // S3 often infers

            let videoData = try Data(contentsOf: videoFileURL)
            // For actual progress with large files, use URLSessionUploadTask and a delegate.
            // This is a simplified blocking version.
            let (_, s3httpResponse) = try await URLSession.shared.upload(for: s3Request, from: videoData)
            
            guard let s3Response = s3httpResponse as? HTTPURLResponse else {
                throw APINetworkError.unknown(statusCode: -1)
            }
            print("ClientAssignListVM: S3 Upload HTTP Status: \(s3Response.statusCode)")
            progressHandler(0.8)

            if !(200..<300).contains(s3Response.statusCode) {
                throw APINetworkError.serverError(statusCode: s3Response.statusCode, message: "S3 upload failed (status: \(s3Response.statusCode)).")
            }
            print("ClientAssignListVM: Video successfully uploaded to S3.")

            // 3. Confirm Upload with our backend
            print("ClientAssignListVM: Confirming upload with our backend...")
            progressHandler(0.9)
            guard let objectKey = finalObjectKey else {
                // This should not happen if S3 upload was successful and presignedResponse was valid
                throw NSError(domain: "UploadError", code: 1, userInfo: [NSLocalizedDescriptionKey: "S3 Object Key missing."])
            }

            let confirmPayload = ConfirmUploadPayload(
                objectKey: objectKey,
                fileName: fileName,
                fileSize: fileSize,
                contentType: contentType
            )
            let endpointConfirmUpload = "/client/assignments/\(assignmentId)/upload-confirm"
            let updatedAssignment: Assignment = try await apiService.POST(endpoint: endpointConfirmUpload, body: confirmPayload)

            print("ClientAssignListVM: Upload confirmed with backend. Assignment status: \(updatedAssignment.status)")
            progressHandler(1.0)

            // Update the specific assignment in the list
            if let index = assignmentsWithExercises.firstIndex(where: { $0.id == updatedAssignment.id }) {
                var assignmentToUpdate = updatedAssignment
                if let existingExercise = assignmentsWithExercises[index].exercise {
                     assignmentToUpdate.exercise = existingExercise
                } else if !updatedAssignment.exerciseId.isEmpty {
                    do {
                        let exerciseDetail: Exercise = try await apiService.GET(endpoint: "/exercises/\(updatedAssignment.exerciseId)")
                        assignmentToUpdate.exercise = exerciseDetail
                    } catch {
                        print("ClientAssignListVM: WARN - Failed to re-fetch exercise detail for updated assignment \(updatedAssignment.exerciseId) after upload.")
                    }
                }
                assignmentsWithExercises[index] = assignmentToUpdate
            } else {
                print("ClientAssignListVM: Uploaded assignment not found in local list after confirm, refreshing all.")
                await self.fetchMyAssignmentsForWorkout() // <<< CORRECTED
            }
            self.errorMessage = nil // Clear general error on full success

        } catch let error as APINetworkError {
            self.errorMessage = error.localizedDescription // Set general error
            print("ClientAssignListVM: Video Upload Process Error (APINetworkError): \(self.errorMessage ?? "")")
            // Optionally refresh list to ensure UI reflects server state after an error
            // await self.fetchMyAssignmentsForWorkout() // <<< CORRECTED if needed
        } catch {
            self.errorMessage = "Video upload failed: \(error.localizedDescription)" // Set general error
            print("ClientAssignListVM: Video Upload Process Error: \(error.localizedDescription)")
            // await self.fetchMyAssignmentsForWorkout() // <<< CORRECTED if needed
        }
        
        // Clean up temporary file
        if videoFileURL.path.contains(FileManager.default.temporaryDirectory.path) {
            do {
                try FileManager.default.removeItem(at: videoFileURL)
                print("ClientAssignListVM: Removed temporary video file: \(videoFileURL.path)")
            } catch {
                print("ClientAssignListVM: WARN - Failed to remove temporary video file: \(error.localizedDescription)")
            }
        }
    } // End handleVideoUpload
} // End class ClientAssignmentListViewModel

// DTOs used by this ViewModel (ensure they are defined, e.g., in Models.swift or here)
// struct UpdateAssignmentStatusPayload: Codable { let status: String }
// struct RequestUploadURLPayload: Codable { let contentType: String }
// struct ConfirmUploadPayload: Codable { /* ... fields ... */ }
// struct UploadURLResponse: Codable { /* ... fields ... */ }

// DTO for the PATCH request body
struct UpdateAssignmentStatusPayload: Codable {
    let status: String
}

// --- DTOs for Upload Process (can be in Models.swift) ---
struct RequestUploadURLPayload: Codable {
    let contentType: String
}

// UploadURLResponse is already in Models.swift if defined during APIService setup,
// or add it to Models.swift:
// struct UploadURLResponse: Codable {
//     let uploadUrl: String
//     let objectKey: String
// }

struct ConfirmUploadPayload: Codable {
    let objectKey: String
    let fileName: String
    let fileSize: Int64 // Make sure this matches Go backend (int64 vs int)
    let contentType: String
}
