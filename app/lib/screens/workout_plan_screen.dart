import 'package:flutter/material.dart';
import '../data/workout_plan.dart';

class WorkoutPlanScreen extends StatelessWidget {
  const WorkoutPlanScreen({super.key});

  final List<int> weekdays = const [1, 2, 3, 4, 5, 6];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Weekly Workout Plan"),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart, color: Colors.redAccent),
            onPressed: () {
              Navigator.pushNamed(context, '/analytics');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () async {
              Navigator.pushReplacementNamed(context, '/sign_in');
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: weekdays.length,
        itemBuilder: (context, index) {
          final day = weekdays[index];
          final groups = workoutPlan[day] ?? const {};
          final exerciseCount = groups.values.expand((e) => e).length;

          return Card(
            margin: const EdgeInsets.all(12),
            child: ListTile(
              title: Text(
                "Day $day",
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  "${splitNames[day] ?? ''}  ·  $exerciseCount exercises",
                  style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/day_detail',
                  arguments: day,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
