import 'package:flutter/material.dart';
import '../services/api_service.dart';

class StartWorkoutScreen extends StatelessWidget {
  final int workoutId;
  final String workoutName;

  const StartWorkoutScreen({
    super.key,
    required this.workoutId,
    required this.workoutName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(workoutName)),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            try {
              // ✅ Start session
              final session = await ApiService.startSession(workoutId);

              // ✅ Navigate to Add Set screen
              Navigator.pushNamed(
                context,
                '/add_set',
                arguments: {
                  'sessionId': session.id,
                },
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Failed to start session: $e"),
                ),
              );
            }
          },
          child: const Text("Start Workout"),
        ),
      ),
    );
  }
}
