import SwiftUI
import SwiftData

struct GoalsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme

    @Query(sort: \Goal.order) private var allGoals: [Goal]

    @State private var selectedPeriod: GoalPeriod = .day
    @State private var showAddGoal = false
    @State private var today = Date()

    // Goals filtered to the selected period
    private var goals: [Goal] {
        allGoals.filter { $0.goalPeriod == selectedPeriod }
    }

    private var completedCount: Int {
        goals.filter { $0.isCompleted(on: today) }.count
    }

    private var progress: Double {
        goals.isEmpty ? 0 : Double(completedCount) / Double(goals.count)
    }

    // Highest streak among all goals for the selected period
    private var topStreak: Int {
        goals.map { $0.streak(on: today) }.max() ?? 0
    }

    var body: some View {
        ScrollView {
            VStack(spacing: DSSpacing.xl) {
                // Period selector
                DSSegmentedPicker(
                    options: GoalPeriod.allCases,
                    selection: $selectedPeriod
                ) { period in
                    Text(period.label)
                }

                // Bento progress row
                bentoRow

                // Goal list
                goalListSection

                // Insight card
                if !goals.isEmpty {
                    insightCard
                }
            }
            .padding(.horizontal, DSSpacing.lg)
            .padding(.top, DSSpacing.lg)
            .padding(.bottom, 120) // clear tab bar
        }
        .navigationTitle("Goals")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showAddGoal = true
                } label: {
                    Image(systemName: "plus").fontWeight(.semibold)
                }
            }
        }
        .sheet(isPresented: $showAddGoal) {
            AddGoalSheet()
        }
    }

    // MARK: - Bento Row

    private var bentoRow: some View {
        HStack(spacing: DSSpacing.md) {
            progressCard
            streakCard
        }
        .frame(height: 160)
    }

    // "Current Progress" card
    private var progressCard: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Current Progress")
                    .font(DSFont.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(DSColors.accent)
                    .textCase(.uppercase)
                    .tracking(0.5)

                Text(goals.isEmpty ? "–" : "\(Int(progress * 100))%")
                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                    .foregroundStyle(DSColors.primary)
                    .contentTransition(.numericText())
                    .animation(DSAnimation.spring, value: completedCount)

                Text(goals.isEmpty
                     ? "No goals yet"
                     : "\(completedCount) of \(goals.count) \(goals.count == 1 ? "goal" : "goals") completed")
                    .font(DSFont.caption)
                    .foregroundStyle(DSColors.secondary)
            }

            Spacer()

            // Gradient progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(DSColors.secondaryBackground)
                        .frame(height: 10)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [DSColors.accent, DSColors.accent.opacity(0.6)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * progress, height: 10)
                        .animation(DSAnimation.spring, value: progress)
                }
            }
            .frame(height: 10)
        }
        .padding(DSSpacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(DSColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DSRadius.lg, style: .continuous))
        .shadow(color: .black.opacity(DSShadow.card.color), radius: DSShadow.card.radius,
                x: DSShadow.card.x, y: DSShadow.card.y)
    }

    // "Streak" card
    private var streakCard: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            Text("Streak")
                .font(DSFont.caption)
                .fontWeight(.bold)
                .foregroundStyle(.white.opacity(0.8))
                .textCase(.uppercase)
                .tracking(0.5)

            Text("\(topStreak)")
                .font(.system(size: 36, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
                .animation(DSAnimation.spring, value: topStreak)

            Text(selectedPeriod == .day ? "Day\(topStreak == 1 ? "" : "s")"
                 : selectedPeriod == .week ? "Week\(topStreak == 1 ? "" : "s")"
                 : "Month\(topStreak == 1 ? "" : "s")")
                .font(DSFont.caption)
                .foregroundStyle(.white.opacity(0.75))

            Spacer()

            Image(systemName: "flame.fill")
                .font(.system(size: 32))
                .foregroundStyle(.white.opacity(0.9))
        }
        .padding(DSSpacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(DSColors.accent)
        .clipShape(RoundedRectangle(cornerRadius: DSRadius.lg, style: .continuous))
        .shadow(color: DSColors.accent.opacity(0.35), radius: DSShadow.card.radius,
                x: DSShadow.card.x, y: DSShadow.card.y)
    }

    // MARK: - Goal List

    @ViewBuilder
    private var goalListSection: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            HStack {
                Text("\(selectedPeriod.label) Goals")
                    .font(DSFont.headline)
                    .foregroundStyle(DSColors.primary)
                Spacer()
            }

            if goals.isEmpty {
                DSEmptyState(
                    systemImage: "checkmark.circle",
                    title: "No \(selectedPeriod.label) Goals",
                    message: "Tap + to add your first \(selectedPeriod.rawValue) goal.",
                    actionTitle: "Add Goal",
                    action: { showAddGoal = true }
                )
                .frame(minHeight: 220)
            } else {
                VStack(spacing: DSSpacing.sm) {
                    ForEach(goals) { goal in
                        GoalRow(goal: goal, date: today)
                            .transition(DSTransition.scaleAndFade)
                    }
                }
                .animation(DSAnimation.spring, value: goals.count)

                // Add more button
                Button {
                    showAddGoal = true
                } label: {
                    HStack(spacing: DSSpacing.sm) {
                        Image(systemName: "plus.circle")
                            .foregroundStyle(DSColors.secondary)
                        Text("Add new \(selectedPeriod.rawValue) goal")
                            .font(DSFont.subheadline)
                            .foregroundStyle(DSColors.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(DSSpacing.lg)
                    .overlay(
                        RoundedRectangle(cornerRadius: DSRadius.md, style: .continuous)
                            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6]))
                            .foregroundStyle(DSColors.separator)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Insight Card

    private var insightCard: some View {
        HStack(alignment: .top, spacing: DSSpacing.lg) {
            ZStack {
                Circle()
                    .fill(DSColors.accent.opacity(0.1))
                    .frame(width: 44, height: 44)
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(DSColors.accent)
                    .font(.system(size: 18))
            }

            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text("Curator Insight")
                    .font(DSFont.headline)
                    .foregroundStyle(DSColors.primary)

                Text(insightText)
                    .font(DSFont.subheadline)
                    .foregroundStyle(DSColors.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(DSSpacing.lg)
        .background(
            LinearGradient(
                colors: [DSColors.secondaryBackground, DSColors.tertiaryBackground],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: DSRadius.lg, style: .continuous))
    }

    private var insightText: String {
        switch progress {
        case 1.0:
            return "Perfect \(selectedPeriod.rawValue)! All goals completed. Keep the streak going tomorrow."
        case 0.8...:
            return "Great work — you're nearly there! Just \(goals.count - completedCount) goal\(goals.count - completedCount == 1 ? "" : "s") left to wrap up today."
        case 0.5...:
            return "Halfway through your \(selectedPeriod.rawValue) goals. Momentum is building — keep going!"
        case 0.01...:
            return "Good start! Every completed goal builds the habit. Try finishing one more before the day ends."
        default:
            return "Your \(selectedPeriod.rawValue) goals are waiting. Tap any goal to mark it complete and start your streak."
        }
    }
}
