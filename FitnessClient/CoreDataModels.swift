// CoreDataModels.swift
import Foundation
import CoreData

// MARK: - CDUser (Core Data User Model)
@objc(CDUser)
public class CDUser: NSManagedObject {
    
    @NSManaged public var userID: String
    @NSManaged public var name: String
    @NSManaged public var email: String
    @NSManaged public var roles: [String]
    @NSManaged public var createdAt: Date
    @NSManaged public var trainerID: String?
    @NSManaged public var lastModifiedDate: Date
    @NSManaged public var syncStatusValue: String
    @NSManaged public var isDeletedFlag: Bool
    
    // Relationships
    @NSManaged public var trainer: CDUser?
    @NSManaged public var managedClients: Set<CDUser>
    @NSManaged public var createdExercises: Set<CDExercise>
    @NSManaged public var workouts: Set<CDWorkout>
    @NSManaged public var assignedExercises: Set<CDAssignment>
    
    // MARK: - Convenience Methods
    
    var isTrainer: Bool {
        return roles.contains("trainer")
    }
    
    var isClient: Bool {
        return roles.contains("client")
    }
    
    var clientsArray: [CDUser] {
        return Array(managedClients).sorted { $0.name < $1.name }
    }
    
    var exercisesArray: [CDExercise] {
        return Array(createdExercises).sorted { $0.name < $1.name }
    }
    
    var workoutsArray: [CDWorkout] {
        return Array(workouts).sorted { $0.createdAt > $1.createdAt }
    }
}

// MARK: - CDUser OfflineDataModel Conformance
extension CDUser: OfflineDataModel {
    func getID() -> String {
        return userID
    }
    
    func setID(_ id: String) {
        userID = id
    }
    
    func getLastModified() -> Date {
        return lastModifiedDate
    }
    
    func setLastModified(_ date: Date) {
        lastModifiedDate = date
    }
    
    func getSyncStatus() -> String {
        return syncStatusValue
    }
    
    func setSyncStatus(_ status: String) {
        syncStatusValue = status
    }
    
    func getIsDeleted() -> Bool {
        return isDeletedFlag
    }
    
    func setIsDeleted(_ deleted: Bool) {
        isDeletedFlag = deleted
    }
    
    func updateFromAPI(_ apiModel: Any) {
        guard let userResponse = apiModel as? UserResponse else { return }
        
        setID(userResponse.id)
        self.name = userResponse.name
        self.email = userResponse.email
        self.roles = userResponse.roles
        self.createdAt = userResponse.createdAt
        self.trainerID = userResponse.trainerId
        setLastModified(Date())
        setSyncStatus(SyncStatus.synced.rawValue)
        setIsDeleted(false)
    }
    
    func toAPIModel() -> Any? {
        return UserResponse(
            id: getID(),
            name: name,
            email: email,
            roles: roles,
            createdAt: createdAt,
            clientIds: nil, // This would need to be computed from relationships
            trainerId: trainerID
        )
    }
}

// MARK: - CDExercise (Core Data Exercise Model)
@objc(CDExercise)
public class CDExercise: NSManagedObject {
    
    @NSManaged public var exerciseID: String
    @NSManaged public var name: String
    @NSManaged public var exerciseDescription: String
    @NSManaged public var instructions: String
    @NSManaged public var videoURL: String?
    @NSManaged public var createdAt: Date
    @NSManaged public var lastModifiedDate: Date
    @NSManaged public var syncStatusValue: String
    @NSManaged public var isDeletedFlag: Bool
    
    // Relationships
    @NSManaged public var creator: CDUser?
    @NSManaged public var assignments: Set<CDAssignment>
    @NSManaged public var workoutExercises: Set<CDWorkoutExercise>
    
    // MARK: - Convenience Methods
    
    var assignmentsArray: [CDAssignment] {
        return Array(assignments).sorted { $0.assignedAt > $1.assignedAt }
    }
}

// MARK: - CDExercise OfflineDataModel Conformance
extension CDExercise: OfflineDataModel {
    func getID() -> String {
        return exerciseID
    }
    
    func setID(_ id: String) {
        exerciseID = id
    }
    
    func getLastModified() -> Date {
        return lastModifiedDate
    }
    
    func setLastModified(_ date: Date) {
        lastModifiedDate = date
    }
    
    func getSyncStatus() -> String {
        return syncStatusValue
    }
    
    func setSyncStatus(_ status: String) {
        syncStatusValue = status
    }
    
    func getIsDeleted() -> Bool {
        return isDeletedFlag
    }
    
    func setIsDeleted(_ deleted: Bool) {
        isDeletedFlag = deleted
    }
    
    func updateFromAPI(_ apiModel: Any) {
        guard let exerciseModel = apiModel as? Exercise else { return }
        
        setID(exerciseModel.id)
        self.name = exerciseModel.name
        self.exerciseDescription = exerciseModel.description ?? ""
        self.instructions = exerciseModel.executionTechnic ?? ""
        self.videoURL = exerciseModel.videoUrl
        self.createdAt = exerciseModel.createdAt
        setLastModified(Date())
        setSyncStatus(SyncStatus.synced.rawValue)
        setIsDeleted(false)
    }
    
    func toAPIModel() -> Any? {
        return Exercise(
            id: getID(),
            trainerId: creator?.getID() ?? "",
            name: name,
            description: exerciseDescription.isEmpty ? nil : exerciseDescription,
            muscleGroup: nil,
            executionTechnic: instructions.isEmpty ? nil : instructions,
            applicability: nil,
            difficulty: nil,
            videoUrl: videoURL,
            createdAt: createdAt,
            updatedAt: getLastModified()
        )
    }
}

// MARK: - CDWorkout (Core Data Workout Model)
@objc(CDWorkout)
public class CDWorkout: NSManagedObject {
    
    @NSManaged public var workoutID: String
    @NSManaged public var name: String
    @NSManaged public var notes: String?
    @NSManaged public var createdAt: Date
    @NSManaged public var completedAt: Date?
    @NSManaged public var lastModifiedDate: Date
    @NSManaged public var syncStatusValue: String
    @NSManaged public var isDeletedFlag: Bool
    
    // Relationships
    @NSManaged public var user: CDUser?
    @NSManaged public var exercises: Set<CDWorkoutExercise>
    
    // MARK: - Convenience Methods
    
    var exercisesArray: [CDWorkoutExercise] {
        return Array(exercises).sorted { $0.exercise?.name ?? "" < $1.exercise?.name ?? "" }
    }
    
    var isCompleted: Bool {
        return completedAt != nil
    }
    
    var duration: TimeInterval? {
        guard let completedAt = completedAt else { return nil }
        return completedAt.timeIntervalSince(createdAt)
    }
}

// MARK: - CDWorkout OfflineDataModel Conformance
extension CDWorkout: OfflineDataModel {
    func getID() -> String {
        return workoutID
    }
    
    func setID(_ id: String) {
        workoutID = id
    }
    
    func getLastModified() -> Date {
        return lastModifiedDate
    }
    
    func setLastModified(_ date: Date) {
        lastModifiedDate = date
    }
    
    func getSyncStatus() -> String {
        return syncStatusValue
    }
    
    func setSyncStatus(_ status: String) {
        syncStatusValue = status
    }
    
    func getIsDeleted() -> Bool {
        return isDeletedFlag
    }
    
    func setIsDeleted(_ deleted: Bool) {
        isDeletedFlag = deleted
    }
    
    func updateFromAPI(_ apiModel: Any) {
        guard let workoutModel = apiModel as? Workout else { return }
        
        setID(workoutModel.id)
        self.name = workoutModel.name
        self.notes = workoutModel.notes
        self.createdAt = workoutModel.createdAt
        self.completedAt = nil
        setLastModified(Date())
        setSyncStatus(SyncStatus.synced.rawValue)
        setIsDeleted(false)
    }
    
    func toAPIModel() -> Any? {
        return Workout(
            id: getID(),
            trainingPlanId: "",
            trainerId: "",
            clientId: user?.getID() ?? "",
            name: name,
            dayOfWeek: nil,
            notes: notes,
            sequence: 0,
            createdAt: createdAt,
            updatedAt: getLastModified()
        )
    }
}

// MARK: - CDWorkoutExercise (Core Data Workout Exercise Model)
@objc(CDWorkoutExercise)
public class CDWorkoutExercise: NSManagedObject {
    
    @NSManaged public var workoutExerciseID: String
    @NSManaged public var sets: Int32
    @NSManaged public var reps: Int32
    @NSManaged public var weight: Double
    @NSManaged public var lastModifiedDate: Date
    @NSManaged public var syncStatusValue: String
    @NSManaged public var isDeletedFlag: Bool
    
    // Relationships
    @NSManaged public var workout: CDWorkout?
    @NSManaged public var exercise: CDExercise?
}

// MARK: - CDWorkoutExercise OfflineDataModel Conformance
extension CDWorkoutExercise: OfflineDataModel {
    func getID() -> String {
        return workoutExerciseID
    }
    
    func setID(_ id: String) {
        workoutExerciseID = id
    }
    
    func getLastModified() -> Date {
        return lastModifiedDate
    }
    
    func setLastModified(_ date: Date) {
        lastModifiedDate = date
    }
    
    func getSyncStatus() -> String {
        return syncStatusValue
    }
    
    func setSyncStatus(_ status: String) {
        syncStatusValue = status
    }
    
    func getIsDeleted() -> Bool {
        return isDeletedFlag
    }
    
    func setIsDeleted(_ deleted: Bool) {
        isDeletedFlag = deleted
    }
    
    func updateFromAPI(_ apiModel: Any) {
        setLastModified(Date())
        setSyncStatus(SyncStatus.synced.rawValue)
        setIsDeleted(false)
    }
    
    func toAPIModel() -> Any? {
        return [
            "id": getID(),
            "exerciseId": exercise?.getID() ?? "",
            "sets": Int(sets),
            "reps": Int(reps),
            "weight": weight
        ]
    }
}

// MARK: - CDAssignment (Core Data Assignment Model)
@objc(CDAssignment)
public class CDAssignment: NSManagedObject {
    
    @NSManaged public var assignmentID: String
    @NSManaged public var sets: Int32
    @NSManaged public var reps: Int32
    @NSManaged public var weight: Double
    @NSManaged public var status: String
    @NSManaged public var feedback: String?
    @NSManaged public var assignedAt: Date
    @NSManaged public var dueDate: Date?
    @NSManaged public var completedAt: Date?
    @NSManaged public var lastModifiedDate: Date
    @NSManaged public var syncStatusValue: String
    @NSManaged public var isDeletedFlag: Bool
    
    // Relationships
    @NSManaged public var client: CDUser?
    @NSManaged public var exercise: CDExercise?
    
    // MARK: - Convenience Methods
    
    var isCompleted: Bool {
        return status == "completed" || completedAt != nil
    }
    
    var isPending: Bool {
        return status == "pending"
    }
    
    var isOverdue: Bool {
        guard let dueDate = dueDate else { return false }
        return !isCompleted && Date() > dueDate
    }
}

// MARK: - CDAssignment OfflineDataModel Conformance
extension CDAssignment: OfflineDataModel {
    func getID() -> String {
        return assignmentID
    }
    
    func setID(_ id: String) {
        assignmentID = id
    }
    
    func getLastModified() -> Date {
        return lastModifiedDate
    }
    
    func setLastModified(_ date: Date) {
        lastModifiedDate = date
    }
    
    func getSyncStatus() -> String {
        return syncStatusValue
    }
    
    func setSyncStatus(_ status: String) {
        syncStatusValue = status
    }
    
    func getIsDeleted() -> Bool {
        return isDeletedFlag
    }
    
    func setIsDeleted(_ deleted: Bool) {
        isDeletedFlag = deleted
    }
    
    func updateFromAPI(_ apiModel: Any) {
        guard let assignmentModel = apiModel as? Assignment else { return }
        
        setID(assignmentModel.id)
        self.sets = Int32(assignmentModel.sets ?? 0)
        self.reps = Int32(Int(assignmentModel.reps ?? "0") ?? 0)
        self.weight = Double(assignmentModel.weight ?? "0") ?? 0.0
        self.status = assignmentModel.status
        self.feedback = assignmentModel.feedback
        self.assignedAt = assignmentModel.assignedAt
        self.dueDate = nil
        self.completedAt = nil
        setLastModified(Date())
        setSyncStatus(SyncStatus.synced.rawValue)
        setIsDeleted(false)
    }
    
    func toAPIModel() -> Any? {
        return Assignment(
            id: getID(),
            workoutId: "",
            exerciseId: exercise?.getID() ?? "",
            assignedAt: assignedAt,
            status: status,
            sets: Int(sets),
            reps: String(reps),
            rest: nil,
            tempo: nil,
            weight: String(weight),
            duration: nil,
            sequence: 0,
            trainerNotes: nil,
            achievedSets: nil,
            achievedReps: nil,
            achievedWeight: nil,
            achievedDuration: nil,
            clientPerformanceNotes: nil,
            clientNotes: feedback,
            uploadId: nil,
            feedback: feedback,
            updatedAt: getLastModified(),
            exercise: nil
        )
    }
}

// MARK: - Fetch Request Extensions
extension CDUser {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDUser> {
        return NSFetchRequest<CDUser>(entityName: "CDUser")
    }
    
    static func fetchByID(_ id: String, context: NSManagedObjectContext) -> CDUser? {
        let request: NSFetchRequest<CDUser> = CDUser.fetchRequest()
        request.predicate = NSPredicate(format: "userID == %@", id)
        request.fetchLimit = 1
        
        do {
            return try context.fetch(request).first
        } catch {
            print("Failed to fetch CDUser by ID: \(error)")
            return nil
        }
    }
}

extension CDExercise {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDExercise> {
        return NSFetchRequest<CDExercise>(entityName: "CDExercise")
    }
    
    static func fetchByID(_ id: String, context: NSManagedObjectContext) -> CDExercise? {
        let request: NSFetchRequest<CDExercise> = CDExercise.fetchRequest()
        request.predicate = NSPredicate(format: "exerciseID == %@", id)
        request.fetchLimit = 1
        
        do {
            return try context.fetch(request).first
        } catch {
            print("Failed to fetch CDExercise by ID: \(error)")
            return nil
        }
    }
}

extension CDWorkout {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDWorkout> {
        return NSFetchRequest<CDWorkout>(entityName: "CDWorkout")
    }
    
    static func fetchByID(_ id: String, context: NSManagedObjectContext) -> CDWorkout? {
        let request: NSFetchRequest<CDWorkout> = CDWorkout.fetchRequest()
        request.predicate = NSPredicate(format: "workoutID == %@", id)
        request.fetchLimit = 1
        
        do {
            return try context.fetch(request).first
        } catch {
            print("Failed to fetch CDWorkout by ID: \(error)")
            return nil
        }
    }
}

extension CDAssignment {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDAssignment> {
        return NSFetchRequest<CDAssignment>(entityName: "CDAssignment")
    }
    
    static func fetchByID(_ id: String, context: NSManagedObjectContext) -> CDAssignment? {
        let request: NSFetchRequest<CDAssignment> = CDAssignment.fetchRequest()
        request.predicate = NSPredicate(format: "assignmentID == %@", id)
        request.fetchLimit = 1
        
        do {
            return try context.fetch(request).first
        } catch {
            print("Failed to fetch CDAssignment by ID: \(error)")
            return nil
        }
    }
}
