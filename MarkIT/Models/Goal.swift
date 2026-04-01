import Foundation
import SwiftData

@Model
final class Goal {
    var id: UUID = UUID()
    var title: String = ""
    var emoji: String = "🎯"
    /// Short descriptor shown below the title, e.g. "15 Minutes • Habit"
    var subtitle: String = ""
    /// Hex colour for the icon tile background tint
    var colorHex: String = "#4A90E2"
    /// Raw value of GoalPeriod — "day" | "week" | "month"
    var period: String = GoalPeriod.day.rawValue
    var order: Int = 0
    var createdAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \GoalCompletion.goal)
    var completions: [GoalCompletion] = []

    init(
        title: String,
        emoji: String = "🎯",
        subtitle: String = "",
        colorHex: String = "#4A90E2",
        period: GoalPeriod = .day
    ) {
        self.id = UUID()
        self.title = title
        self.emoji = emoji
        self.subtitle = subtitle
        self.colorHex = colorHex
        self.period = period.rawValue
        self.createdAt = Date()
    }

    var goalPeriod: GoalPeriod {
        GoalPeriod(rawValue: period) ?? .day
    }

    // MARK: - Completion helpers

    /// Whether this goal has been completed in the period that contains `date`.
    func isCompleted(on date: Date = Date()) -> Bool {
        let p = goalPeriod
        return completions.contains { p.same($0.completedAt, date) }
    }

    /// Toggle completion for today's period.
    /// Returns the new completion object if one was added, nil if one was removed.
    @discardableResult
    func toggleCompletion(on date: Date = Date()) -> GoalCompletion? {
        let p = goalPeriod
        if let existing = completions.first(where: { p.same($0.completedAt, date) }) {
            completions.removeAll { $0.id == existing.id }
            return nil
        } else {
            let c = GoalCompletion(goal: self, completedAt: date)
            completions.append(c)
            return c
        }
    }

    // MARK: - Streak

    /// Number of consecutive periods (ending at current period) that contain at least one completion.
    func streak(on date: Date = Date()) -> Int {
        let p = goalPeriod
        var count = 0
        var cursor = date
        while true {
            if completions.contains(where: { p.same($0.completedAt, cursor) }) {
                count += 1
                cursor = p.previous(from: cursor)
            } else {
                break
            }
        }
        return count
    }
}
