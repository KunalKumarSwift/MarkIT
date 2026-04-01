import Foundation

enum GoalPeriod: String, CaseIterable, Identifiable, Codable {
    case day   = "day"
    case week  = "week"
    case month = "month"

    var id: String { rawValue }
    var label: String { rawValue.capitalized }

    /// The calendar component that defines one unit of this period
    var calendarComponent: Calendar.Component {
        switch self {
        case .day:   return .day
        case .week:  return .weekOfYear
        case .month: return .month
        }
    }

    /// Returns the start of the period containing `date`
    func start(for date: Date, calendar: Calendar = .current) -> Date {
        calendar.dateInterval(of: calendarComponent, for: date)?.start ?? date
    }

    /// Returns true if two dates fall in the same period
    func same(_ a: Date, _ b: Date, calendar: Calendar = .current) -> Bool {
        start(for: a, calendar: calendar) == start(for: b, calendar: calendar)
    }

    /// Returns the start of the period immediately before `date`'s period
    func previous(from date: Date, calendar: Calendar = .current) -> Date {
        let s = start(for: date, calendar: calendar)
        return calendar.date(byAdding: calendarComponent, value: -1, to: s) ?? s
    }
}
