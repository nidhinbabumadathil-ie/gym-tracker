import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../data/workout_plan.dart';

class DayDetailScreen extends StatefulWidget {
  final int baseDay;

  const DayDetailScreen({super.key, required this.baseDay});

  @override
  State<DayDetailScreen> createState() => _DayDetailScreenState();
}

class _DayDetailScreenState extends State<DayDetailScreen> {
  int? sessionId;
  bool workoutStarted = false;
  bool startingWorkout = false;
  final Set<String> completedExercises = {};

  // Each weekday is now its own distinct workout (1-6), so there is no
  // 3-day repeating cycle any more.
  int get actualDay => widget.baseDay;

  Map<String, List<String>> get dayWorkouts => workoutPlan[actualDay] ?? const {};

  int get totalExercises =>
      dayWorkouts.values.expand((e) => e).length;

  Future<void> startWorkout() async {
    if (startingWorkout) return;

    setState(() => startingWorkout = true);

    try {
      final session = await ApiService.startSession(widget.baseDay);
      if (!mounted) return;
      setState(() {
        sessionId = session.id;
        workoutStarted = true;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to start workout")),
      );
    } finally {
      if (mounted) setState(() => startingWorkout = false);
    }
  }

  void finishWorkout() {
    Navigator.pushNamed(
      context,
      '/workout_summary',
      arguments: {
        'sessionId': sessionId,
        'dayLabel': "Day ${widget.baseDay} · ${splitNames[actualDay] ?? ''}",
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final groups = dayWorkouts;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Day ${widget.baseDay}"),
            Text(
              splitNames[actualDay] ?? '',
              style: const TextStyle(fontSize: 13, color: Colors.white70),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),

          SizedBox(
            width: 220,
            height: 50,
            child: ElevatedButton(
              onPressed: startingWorkout
                  ? null
                  : (workoutStarted ? finishWorkout : startWorkout),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    workoutStarted ? Colors.green : Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: startingWorkout
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      workoutStarted ? "Finish Workout" : "Start Workout",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),

          if (startingWorkout)
            const Padding(
              padding: EdgeInsets.only(top: 14, left: 30, right: 30),
              child: Text(
                "Waking up the server… the first start after a while can take up to a minute.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),

          const SizedBox(height: 30),

          if (workoutStarted)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                "Exercises completed: ${completedExercises.length} / $totalExercises",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.greenAccent,
                ),
              ),
            ),

          Expanded(
            child: ListView(
              children: groups.entries.map((entry) {
                final muscle = entry.key;
                final exercises = entry.value;

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(
                      muscle,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: workoutStarted ? Colors.white : Colors.grey,
                      ),
                    ),
                    subtitle: Text(
                      "${exercises.length} exercises",
                      style: TextStyle(
                        color: workoutStarted ? Colors.white54 : Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    trailing: Icon(
                      Icons.fitness_center,
                      color: workoutStarted ? Colors.redAccent : Colors.grey,
                    ),
                    onTap: workoutStarted
                        ? () async {
                            final result = await Navigator.pushNamed(
                              context,
                              '/exercise_list',
                              arguments: {
                                'muscle': muscle,
                                'exercises': exercises,
                                'sessionId': sessionId,
                              },
                            );

                            if (result is String && mounted) {
                              setState(() {
                                completedExercises.add(result);
                              });
                            }
                          }
                        : null,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
