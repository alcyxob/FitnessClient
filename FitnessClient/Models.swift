// Models.swift (or UserResponse.swift)
import Foundation

// Matches the Go API's UserResponse DTO
struct UserResponse: Codable, Identifiable, Hashable, Equatable {
    let id: String // Use String for the hex ObjectID from Go/Mongo
    let name: String
    let email: String
    let roles: [String]
    let createdAt: Date // Assuming Go API sends RFC3339 or ISO8601 format
    let clientIds: [String]? // Optional array of client ID strings
    let trainerId: String?   // Optional trainer ID string

    // Helper methods for easy role checking
    func hasRole(_ role: domain.Role) -> Bool {
        return roles.contains(role.rawValue)
    }

    // Add CodingKeys if your backend JSON keys differ from these property names
//    enum CodingKeys: String, CodingKey {
//        case id, name, email, roles, createdAt // Use 'roles'
//        case clientIds, trainerId, appleUserID, googleUserID
//    }
}

// Matches the Go API's LoginResponse DTO
struct LoginResponse: Codable {
    let token: String
    let user: UserResponse
}

// Needed for sending the request body
struct LoginRequest: Codable {
    let email: String
    let password: String
}

// A simple error structure if your Go API returns {"error": "message"}
struct APIErrorResponse: Codable, Error {
    let error: String
}

// Matches the Go API's domain.Exercise struct
struct Exercise: Codable, Identifiable, Hashable, Equatable { // Added Equatable
    let id: String
    let trainerId: String
    var name: String
    var description: String?
    var muscleGroup: String?
    var executionTechnic: String?
    var applicability: String?
    var difficulty: String?
    var videoUrl: String?
    let createdAt: Date
    let updatedAt: Date

    // Add CodingKeys ONLY if your JSON keys from Go API differ from these property names
    // enum CodingKeys: String, CodingKey {
    //     case id, trainerId, name, description, muscleGroup, executionTechnic, applicability, difficulty, videoUrl, createdAt, updatedAt
    // }

    // Example init if needed for previews or other manual creation
    init(id: String = UUID().uuidString, trainerId: String = "", name: String = "", description: String? = nil, muscleGroup: String? = nil, executionTechnic: String? = nil, applicability: String? = nil, difficulty: String? = nil, videoUrl: String? = nil, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.trainerId = trainerId
        self.name = name
        self.description = description
        self.muscleGroup = muscleGroup
        self.executionTechnic = executionTechnic
        self.applicability = applicability
        self.difficulty = difficulty
        self.videoUrl = videoUrl
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}


// DTO for sending create exercise request (matches Go's CreateExerciseRequest)
struct CreateExercisePayload: Codable {
    let name: String
    var description: String?
    var muscleGroup: String?
    var executionTechnic: String?
    var applicability: String?
    var difficulty: String?
    var videoUrl: String? // Optional
}

// Payload for the "Add Client by Email" API request
struct AddClientPayload: Codable {
    let clientEmail: String
}

// Matches Go API's AssignmentResponse DTO
struct Assignment: Codable, Identifiable, Hashable, Equatable { // Added Equatable
    let id: String
    let workoutId: String
    let exerciseId: String // The ID of the base Exercise
    let assignedAt: Date
    let status: String // Consider making this an enum later
    
    // Exercise Execution Details specific to this assignment instance
    var sets: Int?
    var reps: String?
    var rest: String?
    var tempo: String?
    var weight: String?
    var duration: String?
    var sequence: Int
    var trainerNotes: String?
    
    var achievedSets: Int?                // 'var' and optional
    var achievedReps: String?             // 'var' and optional
    var achievedWeight: String?           // 'var' and optional
    var achievedDuration: String?         // 'var' and optional
    var clientPerformanceNotes: String?   // 'var' and optional
    
    // Client Tracking
    let clientNotes: String?
    let uploadId: String? // String representation of ObjectID
    let feedback: String?
    let updatedAt: Date

    // This property is for client-side convenience to hold fetched Exercise details.
    // It should NOT be part of the direct Codable process from the raw assignment API response
    // unless your API explicitly nests the full exercise object within each assignment.
    // If it's populated manually after fetching, it needs to be handled for Codable conformance.
    var exercise: Exercise?

    // To make `Assignment` Codable when `exercise` is populated client-side
    // and not part of the JSON for Assignment itself:
    enum CodingKeys: String, CodingKey {
        case id, workoutId, exerciseId, assignedAt, status
        case sets, reps, rest, tempo, weight, duration, sequence, trainerNotes
        case clientNotes, uploadId, feedback, updatedAt
        // Notice 'exercise' is NOT listed here if it's not in the JSON for Assignment
    }

    // Manual Equatable conformance if exercise is included
    static func == (lhs: Assignment, rhs: Assignment) -> Bool {
        return lhs.id == rhs.id &&
               lhs.workoutId == rhs.workoutId &&
               lhs.exerciseId == rhs.exerciseId &&
               // ... compare all other stored properties EXCEPT exercise initially ...
               lhs.exercise == rhs.exercise // Add this if Exercise is Equatable
    }

    // Manual Hashable conformance if exercise is included
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(workoutId)
        hasher.combine(exerciseId)
        // ... combine all other stored properties EXCEPT exercise initially ...
        hasher.combine(exercise) // Add this if Exercise is Hashable
    }
    
    // If 'exercise' is truly only for client-side display and NOT part of the JSON payload
    // for an assignment, you might need to provide custom Encodable/Decodable initializers
    // or ensure it's always nil when encoding/decoding if it's not in the JSON.
    // For simplicity, if your GET /assignments endpoint DOESN'T return a nested exercise,
    // then `exercise` should NOT be in CodingKeys.
    // The current `AssignmentListViewModel` fetches exercises separately and populates this.
}

// Payload for the "Assign Exercise" API request
struct AssignExercisePayload: Codable {
    let clientId: String // Client's ObjectID hex string
    let exerciseId: String // Exercise's ObjectID hex string
    var dueDate: Date? = nil // Optional date
}

// Matches Go API's TrainingPlanResponse DTO
struct TrainingPlan: Codable, Identifiable, Hashable { // Add Hashable for ForEach ID
    let id: String
    let trainerId: String
    let clientId: String
    let name: String
    let description: String?
    let startDate: Date? // Optional Date
    let endDate: Date?   // Optional Date
    let isActive: Bool
    let createdAt: Date
    let updatedAt: Date

    // Add CodingKeys only if JSON keys from Go API differ
    // enum CodingKeys: String, CodingKey {
    //    case id, trainerId, clientId, name, description, startDate, endDate, isActive, createdAt, updatedAt
    // }
}

// Matches Go API's WorkoutResponse DTO
struct Workout: Codable, Identifiable, Hashable {
    let id: String
    let trainingPlanId: String
    let trainerId: String
    let clientId: String
    var name: String
    var dayOfWeek: Int? // Optional: 1 (Mon) - 7 (Sun)
    var notes: String?
    var sequence: Int // Order within the plan
    let createdAt: Date
    let updatedAt: Date

    // Add CodingKeys only if Go JSON keys differ
    // enum CodingKeys: String, CodingKey { ... }
}

// --- DTO for Create Workout Request Body ---
// Define this here or in CreateWorkoutViewModel
struct CreateWorkoutPayload: Codable {
    let name: String
    var dayOfWeek: Int?
    var notes: String?
    let sequence: Int
}

struct UploadURLResponse: Codable {
    let uploadUrl: String
    let objectKey: String
}

struct VideoDownloadURLResponse: Codable {
    let downloadUrl: String // Ensure key matches Go JSON: "downloadUrl"
}

// Payload for the Trainer's "Submit Feedback" API request
struct SubmitFeedbackPayload: Codable {
    let feedback: String? // Backend might allow empty feedback if only status changes
    let status: String   // The new status (e.g., "reviewed", "assigned")
}

// Payload for logging performance
struct LogPerformancePayload: Codable {
    var achievedSets: Int?
    var achievedReps: String?
    var achievedWeight: String?
    var achievedDuration: String?
    var clientPerformanceNotes: String?
    // var status: String? // If logging also changes status, add this
}

// Matches Go API's ClientReviewStatusResponse DTO
struct ClientReviewStatusItem: Codable, Identifiable {
    let clientId: String   // Use 'id' for Identifiable conformance on this specific ID
    let clientName: String
    let pendingReviewCount: Int
    // let lastSubmissionDate: Date? // Optional, if you add it to backend DTO

    // Make clientId the identifiable ID for this struct
    var id: String { clientId }

    // CodingKeys if your JSON keys differ (e.g., if backend sends client_id)
    // enum CodingKeys: String, CodingKey {
    //     case clientId = "client_id" // Example
    //     case clientName, pendingReviewCount
    // }
}

// --- DTO for sending Apple Sign-In data to YOUR backend ---
// This MUST match the fields expected by your Go backend's
// api.SignInWithAppleRequest struct.
struct SignInWithAppleRequest: Codable {
    let identityToken: String
    let firstName: String // Send empty string if nil
    let lastName: String  // Send empty string if nil
    let role: String      // Send role as string (e.g., "client", "trainer")

    // Ensure CodingKeys match your Go backend's JSON tags if they differ
    enum CodingKeys: String, CodingKey {
        case identityToken
        case firstName
        case lastName
        case role
    }

    // Convenience initializer to handle optional name parts
    init(identityToken: String, firstName: String?, lastName: String?, role: domain.Role) {
        self.identityToken = identityToken
        self.firstName = firstName ?? ""
        self.lastName = lastName ?? ""
        self.role = role.rawValue // Convert domain.Role enum to its String rawValue
    }
}

struct SocialLoginResponse: Codable { // Matches Go's SocialLoginResponse
    let token: String
    let user: UserResponse
    let isNewUser: Bool
}

enum domain {
    enum Role: String, Codable, CaseIterable, Identifiable {
        case trainer = "trainer"
        case client = "client"
        var id: String { self.rawValue }
    }
    
    enum AssignmentStatus: String, CaseIterable, Identifiable {
        case assigned = "assigned"
        case completed = "completed" // Client sets this
        case submitted = "submitted" // Client sets this after video upload
        case reviewed = "reviewed"   // Trainer sets this
        // case needsRevision = "needs_revision" // Example for trainer

        var id: String { self.rawValue }
    }
 }
