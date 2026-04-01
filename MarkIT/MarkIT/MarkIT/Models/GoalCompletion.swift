import Foundation
import SwiftData

@Model
final class GoalCompletion {
    var id: UUID = UUID()
    var completedAt: Date = Date()

    // Optional for CloudKit compatibility (to-one relationships must be optional)
    var goal: Goal?

    init(goal: Goal, completedAt: Date = Date()) {
        self.id = UUID()
        self.completedAt = completedAt
        self.goal = goal
    }
}
