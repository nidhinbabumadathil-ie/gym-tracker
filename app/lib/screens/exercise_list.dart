import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'exercise_demo_screen.dart';

class ExerciseListScreen extends StatelessWidget {
  const ExerciseListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    final String muscle = args['muscle'];
    final int? sessionId = args['sessionId'];

    final dynamic rawExercises = args['exercises'];

    final List<String> exercises = rawExercises is List
        ? rawExercises.map((e) => e.toString()).toList()
        : [];

    // 🔒 SAFETY CHECK
    if (sessionId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Error")),
        body: const Center(
          child: Text(
            "Workout session missing.\nPlease start workout again.",
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(muscle)),
      body: ListView.builder(
        itemCount: exercises.length,
        itemBuilder: (context, index) {
          final exerciseName = exercises[index];

          return ListTile(
            title: Text(exerciseName),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.info_outline, color: Colors.white54),
                  tooltip: 'How to do it',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ExerciseDemoScreen(exerciseName: exerciseName),
                      ),
                    );
                  },
                ),
                const Icon(Icons.play_arrow, color: Colors.redAccent),
              ],
            ),
            onTap: () async {
              try {
                // ✅ Create or fetch workout
                final workout =
                    await ApiService.createWorkout(exerciseName, muscle);

                final result = await Navigator.pushNamed(
                  context,
                  '/add_set',
                  arguments: {
                    'sessionId': sessionId,
                    'workoutName': workout.name,
                  },
                );

                if (result is String) {
                  Navigator.pop(context, result); // ✅ return completed exercise
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error: $e")),
                );
              }
            },
          );
        },
      ),
    );
  }
}
