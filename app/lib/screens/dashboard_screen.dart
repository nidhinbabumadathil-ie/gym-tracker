import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/set.dart';
import '../models/session.dart';
import '../data/workout_plan.dart';
import '../data/stats.dart';
import 'exercise_search_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<GymStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _loadStats();
  }

  Future<GymStats> _loadStats() async {
    final now = DateTime.now();
    final sets = await ApiService.getAllSets();
    List<Session> sessions = [];
    try {
      sessions = await ApiService.getSessionsRange(
        now.subtract(const Duration(days: 365)),
        now.add(const Duration(days: 1)),
      );
    } catch (_) {
      // Dashboard still works off sets alone if sessions fail.
    }
    return GymStats.from(sets, sessions);
  }

  Future<void> _refresh() async {
    setState(() => _statsFuture = _loadStats());
    await _statsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gym Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.redAccent),
            tooltip: 'Search exercises',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ExerciseSearchScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart, color: Colors.redAccent),
            tooltip: 'Analytics',
            onPressed: () => Navigator.pushNamed(context, '/analytics'),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Sign out',
            onPressed: () => Navigator.pushReplacementNamed(context, '/sign_in'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: Colors.redAccent,
        child: FutureBuilder<GymStats>(
          future: _statsFuture,
          builder: (context, snapshot) {
            final loading =
                snapshot.connectionState == ConnectionState.waiting;
            final stats = snapshot.data;

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                _StreakHero(
                  streak: stats?.currentStreak ?? 0,
                  loading: loading,
                ),
                const SizedBox(height: 16),
                _StatsRow(stats: stats, loading: loading),
                const SizedBox(height: 24),
                const _SectionTitle('Achievements'),
                const SizedBox(height: 12),
                _BadgeWrap(stats: stats, loading: loading),
                const SizedBox(height: 28),
                const _SectionTitle('Your Split'),
                const SizedBox(height: 12),
                ..._buildDayTiles(),
                const SizedBox(height: 20),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildDayTiles() {
    final days = [1, 2, 3, 4, 5, 6];
    return [
      for (var i = 0; i < days.length; i++)
        _AnimatedInTile(
          delayMs: 60 * i,
          child: _DayTile(day: days[i]),
        ),
    ];
  }
}

// ---------------------------------------------------------------------------
// Streak hero card
// ---------------------------------------------------------------------------
class _StreakHero extends StatelessWidget {
  final int streak;
  final bool loading;
  const _StreakHero({required this.streak, required this.loading});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFFFF5252), Color(0xFFB71C1C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: Text(
              loading ? '—' : '$streak',
              key: ValueKey(loading ? -1 : streak),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 44,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            streak == 1 ? 'day streak' : 'day streak',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stats row (workouts / sets / volume)
// ---------------------------------------------------------------------------
class _StatsRow extends StatelessWidget {
  final GymStats? stats;
  final bool loading;
  const _StatsRow({required this.stats, required this.loading});

  @override
  Widget build(BuildContext context) {
    String v(num? n, {bool volume = false}) {
      if (loading || n == null) return '—';
      if (volume) {
        if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
        return n.toStringAsFixed(0);
      }
      return '$n';
    }

    return Row(
      children: [
        _MiniStat(label: 'Workouts', value: v(stats?.totalWorkouts)),
        const SizedBox(width: 12),
        _MiniStat(label: 'Sets', value: v(stats?.totalSets)),
        const SizedBox(width: 12),
        _MiniStat(
            label: 'Volume kg',
            value: v(stats?.totalVolume, volume: true)),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Badges
// ---------------------------------------------------------------------------
class _BadgeWrap extends StatelessWidget {
  final GymStats? stats;
  final bool loading;
  const _BadgeWrap({required this.stats, required this.loading});

  @override
  Widget build(BuildContext context) {
    final badges = stats?.badges ?? const [];
    if (loading) {
      return const Text('Loading achievements…',
          style: TextStyle(color: Colors.white38));
    }
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (var i = 0; i < badges.length; i++)
          _AnimatedInTile(
            delayMs: 40 * i,
            child: _BadgeChip(badge: badges[i]),
          ),
      ],
    );
  }
}

class _BadgeChip extends StatelessWidget {
  final GymBadge badge;
  const _BadgeChip({required this.badge});

  @override
  Widget build(BuildContext context) {
    final unlocked = badge.unlocked;
    return Tooltip(
      message: '${badge.title} · ${badge.description}',
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: unlocked ? 1 : 0.35,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          decoration: BoxDecoration(
            color: unlocked
                ? const Color(0xFF2A1414)
                : const Color(0xFF161616),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: unlocked ? Colors.redAccent : Colors.white12,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(unlocked ? badge.emoji : '🔒',
                  style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                badge.title,
                style: TextStyle(
                  color: unlocked ? Colors.white : Colors.white38,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Day tiles
// ---------------------------------------------------------------------------
class _DayTile extends StatelessWidget {
  final int day;
  const _DayTile({required this.day});

  @override
  Widget build(BuildContext context) {
    final groups = workoutPlan[day] ?? const {};
    final count = groups.values.expand((e) => e).length;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: const Color(0xFF161616),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: Colors.redAccent.withValues(alpha: 0.15),
          child: Text('$day',
              style: const TextStyle(
                  color: Colors.redAccent, fontWeight: FontWeight.bold)),
        ),
        title: Text(splitNames[day] ?? 'Day $day',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600)),
        subtitle: Text('$count exercises',
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
        trailing:
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white38),
        onTap: () =>
            Navigator.pushNamed(context, '/day_detail', arguments: day),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold));
  }
}

/// Fades + slides a child in, with an optional start delay, for a staggered
/// entrance effect. Pure built-in animation — no packages.
class _AnimatedInTile extends StatefulWidget {
  final Widget child;
  final int delayMs;
  const _AnimatedInTile({required this.child, this.delayMs = 0});

  @override
  State<_AnimatedInTile> createState() => _AnimatedInTileState();
}

class _AnimatedInTileState extends State<_AnimatedInTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late final Animation<double> _fade =
      CurvedAnimation(parent: _c, curve: Curves.easeOut);
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.12),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
