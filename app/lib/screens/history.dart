import 'package:flutter/material.dart';
import '../models/session.dart';
import '../models/set.dart';
import '../services/api_service.dart';

class HistoryScreen extends StatelessWidget {
  final int? workoutId;

  const HistoryScreen({super.key, this.workoutId});

  @override
  Widget build(BuildContext context) {
    if (workoutId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("History")),
        body: const Center(child: Text("No workout selected")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Workout History")),
      body: FutureBuilder<List<Session>>(
        future: ApiService.getSessionsRange(
          DateTime.now().subtract(const Duration(days: 30)),
          DateTime.now(),
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final sessions = snapshot.data ?? [];
          if (sessions.isEmpty) {
            return const Center(child: Text("No sessions yet"));
          }

          return ListView.builder(
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];

              return ExpansionTile(
                title: Text(
                  "Session ${session.id} - ${session.startedAt.toLocal()}",
                ),
                children: [
                  FutureBuilder<List<WorkoutSet>>(
                    future: ApiService.getAllSets(),
                    builder: (context, setSnapshot) {
                      if (setSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator(),
                        );
                      }

                      if (setSnapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text("Error: ${setSnapshot.error}"),
                        );
                      }

                      final allSets = setSnapshot.data ?? [];

                      // ✅ THIS IS THE IMPORTANT PART
                      final sessionSets = allSets
                          .where((s) => s.sessionId == session.id)
                          .toList();

                      if (sessionSets.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(8),
                          child: Text("No sets for this session"),
                        );
                      }

                      return Column(
                        children: sessionSets.map((s) {
                          return ListTile(
                            leading: const Icon(Icons.fitness_center),
                            title: Text(
                              "Set ${s.setNumber}: ${s.weight} kg × ${s.reps}",
                            ),
                            subtitle:
                                Text("Rest: ${s.restSeconds} sec"),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
