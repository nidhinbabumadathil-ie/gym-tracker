import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import '../models/session.dart';
import '../data/workout_plan.dart';

/// Result of joining sets to their sessions.
class _Analytics {
  final Map<DateTime, double> volumeByDate;
  final Map<int, double> volumeBySplit; // day number -> volume
  final Map<int, int> sessionsBySplit; // day number -> session count
  final int totalSets;

  _Analytics({
    required this.volumeByDate,
    required this.volumeBySplit,
    required this.sessionsBySplit,
    required this.totalSets,
  });
}

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  static const _accent = Color(0xFFFF5252); // redAccent
  static const _accentFaint = Color(0x26FF5252); // redAccent @ ~15%

  Future<_Analytics> _load() async {
    // Sets carry the numbers; sessions carry the real date and which training
    // day (1-6) they belong to. Joining them gives accurate dates even if the
    // backend does not send a created_at on each set.
    final sets = await ApiService.getAllSets();

    final now = DateTime.now();
    final sessions = await ApiService.getSessionsRange(
      now.subtract(const Duration(days: 365)),
      now.add(const Duration(days: 1)),
    );

    final Map<int, Session> byId = {for (final s in sessions) s.id: s};

    final Map<DateTime, double> volumeByDate = {};
    final Map<int, double> volumeBySplit = {};
    final Map<int, Set<int>> sessionIdsBySplit = {};

    for (final s in sets) {
      final session = byId[s.sessionId];
      final when = session?.startedAt ?? s.createdAt;
      final day = DateTime(when.year, when.month, when.day);
      final volume = (s.weight * s.reps).toDouble();

      volumeByDate[day] = (volumeByDate[day] ?? 0) + volume;

      final split = session?.workoutId;
      if (split != null) {
        volumeBySplit[split] = (volumeBySplit[split] ?? 0) + volume;
        (sessionIdsBySplit[split] ??= <int>{}).add(session!.id);
      }
    }

    return _Analytics(
      volumeByDate: volumeByDate,
      volumeBySplit: volumeBySplit,
      sessionsBySplit: {
        for (final e in sessionIdsBySplit.entries) e.key: e.value.length
      },
      totalSets: sets.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      appBar: AppBar(
        title: const Text('Analytics'),
        backgroundColor: const Color(0xFF0E0E0E),
        elevation: 0,
      ),
      body: FutureBuilder<_Analytics>(
        future: _load(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text('Failed to load analytics',
                  style: TextStyle(color: Colors.white70)),
            );
          }

          final data = snapshot.data!;
          if (data.volumeByDate.isEmpty) {
            return const Center(
              child: Text('No data yet — log a few sets first.',
                  style: TextStyle(color: Colors.white70)),
            );
          }

          final sortedDates = data.volumeByDate.keys.toList()..sort();
          final spots = <FlSpot>[
            for (var i = 0; i < sortedDates.length; i++)
              FlSpot(i.toDouble(), data.volumeByDate[sortedDates[i]]!)
          ];

          final totalVolume =
              data.volumeByDate.values.fold<double>(0, (a, b) => a + b);
          final maxVolume =
              data.volumeByDate.values.fold<double>(0, (a, b) => a > b ? a : b);
          final maxY = maxVolume <= 0 ? 10.0 : maxVolume * 1.2;
          final leftInterval = maxY / 4;

          final maxSplitVolume =
              data.volumeBySplit.values.fold<double>(0, (a, b) => a > b ? a : b);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Workout Volume Progress',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Total weight lifted (weight × reps) per day',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    _StatCard(
                        label: 'Total volume', value: _compact(totalVolume)),
                    const SizedBox(width: 12),
                    _StatCard(label: 'Sets logged', value: '${data.totalSets}'),
                    const SizedBox(width: 12),
                    _StatCard(
                        label: 'Days trained', value: '${sortedDates.length}'),
                  ],
                ),
                const SizedBox(height: 28),

                SizedBox(
                  height: 280,
                  child: LineChart(
                    LineChartData(
                      minX: -0.5,
                      maxX: (sortedDates.length - 1) + 0.5,
                      minY: 0,
                      maxY: maxY,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: leftInterval,
                        getDrawingHorizontalLine: (value) =>
                            const FlLine(color: Colors.white10, strokeWidth: 1),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 44,
                            interval: leftInterval,
                            getTitlesWidget: (value, meta) => Text(
                              _compact(value),
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 11),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            reservedSize: 32,
                            getTitlesWidget: (value, meta) {
                              final i = value.round();
                              if (i < 0 ||
                                  i >= sortedDates.length ||
                                  (value - i).abs() > 0.01) {
                                return const SizedBox.shrink();
                              }
                              final d = sortedDates[i];
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  '${d.day} ${_months[d.month - 1]}',
                                  style: const TextStyle(
                                      color: Colors.white54, fontSize: 11),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: _accent,
                          barWidth: 3,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: _accentFaint,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 34),

                // ---- Per split-day breakdown ----
                const Text(
                  'Volume by training day',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Which days you are putting the most work into',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
                const SizedBox(height: 16),

                ...List.generate(6, (i) {
                  final day = i + 1;
                  final vol = data.volumeBySplit[day] ?? 0;
                  final count = data.sessionsBySplit[day] ?? 0;
                  final fraction =
                      maxSplitVolume <= 0 ? 0.0 : (vol / maxSplitVolume);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Day $day · ${splitNames[day] ?? ''}',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 14),
                              ),
                            ),
                            Text(
                              _compact(vol),
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: fraction,
                            minHeight: 8,
                            backgroundColor: Colors.white10,
                            valueColor:
                                const AlwaysStoppedAnimation<Color>(_accent),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          count == 0
                              ? 'not trained yet'
                              : '$count session${count == 1 ? '' : 's'}',
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 11),
                        ),
                      ],
                    ),
                  );
                }),

                if (sortedDates.length == 1)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text(
                      'Log workouts on more days to see your progress trend.',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  static String _compact(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
