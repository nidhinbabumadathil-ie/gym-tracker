import '../models/set.dart';
import '../models/session.dart';

/// A single achievement badge.
class GymBadge {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final bool unlocked;

  const GymBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.unlocked,
  });
}

/// Everything the app derives from raw sets + sessions, computed in one place
/// so the dashboard, analytics, and celebrations all agree.
class GymStats {
  final int currentStreak; // consecutive days up to today/yesterday
  final int longestStreak;
  final int totalWorkouts; // distinct training days
  final int totalSets;
  final double totalVolume;
  final Map<int, double> volumeBySplit; // day 1-6 -> volume
  final List<GymBadge> badges;
  final DateTime? lastWorkout;

  GymStats({
    required this.currentStreak,
    required this.longestStreak,
    required this.totalWorkouts,
    required this.totalSets,
    required this.totalVolume,
    required this.volumeBySplit,
    required this.badges,
    required this.lastWorkout,
  });

  int get unlockedBadgeCount => badges.where((b) => b.unlocked).length;

  /// Build all stats from the full set + session history.
  factory GymStats.from(List<WorkoutSet> sets, List<Session> sessions) {
    final byId = {for (final s in sessions) s.id: s};

    // ---- Distinct training days (by calendar date) ----
    final workoutDays = <DateTime>{};
    double totalVolume = 0;
    final Map<int, double> volumeBySplit = {};

    for (final s in sets) {
      final session = byId[s.sessionId];
      final when = session?.startedAt ?? s.createdAt;
      final day = DateTime(when.year, when.month, when.day);
      workoutDays.add(day);

      final vol = s.weight * s.reps;
      totalVolume += vol;

      final split = session?.workoutId;
      if (split != null) {
        volumeBySplit[split] = (volumeBySplit[split] ?? 0) + vol;
      }
    }

    // Also count sessions that exist even if no sets were logged that day.
    for (final session in sessions) {
      final d = session.startedAt;
      workoutDays.add(DateTime(d.year, d.month, d.day));
    }

    final sortedDays = workoutDays.toList()..sort();

    // ---- Streaks ----
    final streaks = _streaks(sortedDays);

    // ---- Badges ----
    final badges = _badges(
      totalWorkouts: sortedDays.length,
      totalSets: sets.length,
      totalVolume: totalVolume,
      currentStreak: streaks.$1,
      longestStreak: streaks.$2,
      distinctSplits: volumeBySplit.keys.length,
    );

    return GymStats(
      currentStreak: streaks.$1,
      longestStreak: streaks.$2,
      totalWorkouts: sortedDays.length,
      totalSets: sets.length,
      totalVolume: totalVolume,
      volumeBySplit: volumeBySplit,
      badges: badges,
      lastWorkout: sortedDays.isEmpty ? null : sortedDays.last,
    );
  }

  /// Returns (currentStreak, longestStreak) from a sorted list of unique days.
  static (int, int) _streaks(List<DateTime> days) {
    if (days.isEmpty) return (0, 0);

    int longest = 1;
    int run = 1;
    for (var i = 1; i < days.length; i++) {
      final diff = days[i].difference(days[i - 1]).inDays;
      if (diff == 1) {
        run++;
      } else if (diff > 1) {
        run = 1;
      }
      if (run > longest) longest = run;
    }

    // Current streak only counts if the last workout was today or yesterday.
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final last = days.last;
    final gapFromToday = today.difference(last).inDays;

    int current = 0;
    if (gapFromToday <= 1) {
      current = 1;
      for (var i = days.length - 1; i > 0; i--) {
        if (days[i].difference(days[i - 1]).inDays == 1) {
          current++;
        } else {
          break;
        }
      }
    }

    return (current, longest);
  }

  static List<GymBadge> _badges({
    required int totalWorkouts,
    required int totalSets,
    required double totalVolume,
    required int currentStreak,
    required int longestStreak,
    required int distinctSplits,
  }) {
    return [
      GymBadge(
        id: 'first_workout',
        title: 'First Steps',
        description: 'Complete your first workout',
        emoji: '🎯',
        unlocked: totalWorkouts >= 1,
      ),
      GymBadge(
        id: 'streak_3',
        title: 'On a Roll',
        description: '3-day streak',
        emoji: '🔥',
        unlocked: longestStreak >= 3,
      ),
      GymBadge(
        id: 'streak_7',
        title: 'Unstoppable',
        description: '7-day streak',
        emoji: '⚡',
        unlocked: longestStreak >= 7,
      ),
      GymBadge(
        id: 'sets_50',
        title: 'Half Century',
        description: 'Log 50 sets',
        emoji: '💪',
        unlocked: totalSets >= 50,
      ),
      GymBadge(
        id: 'sets_200',
        title: 'Iron Addict',
        description: 'Log 200 sets',
        emoji: '🏋️',
        unlocked: totalSets >= 200,
      ),
      GymBadge(
        id: 'volume_10k',
        title: 'Ten Tonne',
        description: 'Lift 10,000 kg total',
        emoji: '🚛',
        unlocked: totalVolume >= 10000,
      ),
      GymBadge(
        id: 'all_splits',
        title: 'Well Rounded',
        description: 'Train all 6 split days',
        emoji: '🌟',
        unlocked: distinctSplits >= 6,
      ),
      GymBadge(
        id: 'workouts_25',
        title: 'Quarter Ton of Sessions',
        description: 'Complete 25 workouts',
        emoji: '👑',
        unlocked: totalWorkouts >= 25,
      ),
    ];
  }
}

/// Personal-best lookup for a single exercise, computed from that exercise's
/// sets. Used by the logging screen to detect and celebrate new PBs.
class PersonalBest {
  /// Heaviest weight ever logged for [exerciseWorkoutId], or null if none yet.
  static double? heaviestWeight(List<WorkoutSet> setsForExercise) {
    if (setsForExercise.isEmpty) return null;
    return setsForExercise
        .map((s) => s.weight)
        .reduce((a, b) => a > b ? a : b);
  }

  /// True if [weight] beats every previous weight in [previousSets].
  static bool isNewBest(double weight, List<WorkoutSet> previousSets) {
    final best = heaviestWeight(previousSets);
    return best == null ? false : weight > best;
  }
}
