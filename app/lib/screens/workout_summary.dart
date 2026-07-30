import 'package:flutter/material.dart';
import '../models/set.dart';
import '../services/api_service.dart';

class WorkoutSummaryScreen extends StatelessWidget {
  final int sessionId;
  final String dayLabel; // e.g. "Monday", "Day 1"

  const WorkoutSummaryScreen({
    super.key,
    required this.sessionId,
    this.dayLabel = "Workout",
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("$dayLabel Summary")),
      body: FutureBuilder<List<WorkoutSet>>(
        future: ApiService.getAllSets(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final allSets = snapshot.data ?? [];

          // ✅ ONLY sets for this session
          final sessionSets =
              allSets.where((s) => s.sessionId == sessionId).toList();

          if (sessionSets.isEmpty) {
            return const Center(child: Text("No sets logged"));
          }

          int totalSets = sessionSets.length;
          int totalReps =
              sessionSets.fold(0, (sum, s) => sum + s.reps);
          double totalVolume =
              sessionSets.fold(0.0, (sum, s) => sum + (s.weight * s.reps));

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Workout Summary",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),

                Text("Total Sets: $totalSets"),
                Text("Total Reps: $totalReps"),
                Text("Total Volume: ${totalVolume.toStringAsFixed(1)} kg"),

                const SizedBox(height: 24),
                const Divider(),

                Expanded(
                  child: ListView.builder(
                    itemCount: sessionSets.length,
                    itemBuilder: (context, index) {
                      final s = sessionSets[index];
                      return ListTile(
                        title: Text(
                            "Set ${s.setNumber}: ${s.weight}kg × ${s.reps}"),
                        subtitle:
                            Text("Rest: ${s.restSeconds} sec"),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.popUntil(
                      context,
                      ModalRoute.withName('/workout_plan'),
                    );
                  },
                  child: const Text("Finish Workout"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
