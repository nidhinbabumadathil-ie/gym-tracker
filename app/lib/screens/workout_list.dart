import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/workout.dart';
import 'package:shared_preferences/shared_preferences.dart';


class WorkoutListScreen extends StatefulWidget {
  @override
  _WorkoutListScreenState createState() => _WorkoutListScreenState();
}

class _WorkoutListScreenState extends State<WorkoutListScreen> {
  late Future<List<Workout>> workouts;

  final List<String> categories = [
    "Chest",
    "Back",
    "Shoulders",
    "Legs",
    "Biceps",
    "Triceps",
    "Core"
  ];

  @override
  void initState() {
    super.initState();
    workouts = ApiService.getWorkouts();
  }

  void refreshWorkouts() {
    setState(() {
      workouts = ApiService.getWorkouts();
    });
  }

  void showAddWorkoutDialog() {
    final _formKey = GlobalKey<FormState>();
    String workoutName = "";
    String selectedCategory = categories[0];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Workout"),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: "Workout Name"),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? "Enter workout name" : null,
                  onSaved: (v) => workoutName = v!,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  items: categories
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c),
                          ))
                      .toList(),
                  onChanged: (v) => selectedCategory = v!,
                  decoration: const InputDecoration(labelText: "Category"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  try {
                    await ApiService.createWorkout(
                        workoutName, selectedCategory);
                    Navigator.pop(context);
                    refreshWorkouts();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Failed to add workout: $e")),
                    );
                  }
                }
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  title: const Text("Workouts"),
  actions: [
    // Analytics Button
    IconButton(
      icon: Icon(Icons.bar_chart, color: Colors.redAccent),
      onPressed: () {
        Navigator.pushNamed(context, '/analytics');
      },
    ),

    // Sign Out Button
    IconButton(
      icon: Icon(Icons.logout, color: Colors.redAccent),
      onPressed: () async {
        // Clear saved login
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('loggedIn');

        // Go back to Sign In
        Navigator.pushReplacementNamed(context, '/sign_in');
      },
    ),
  ],
),

      body: FutureBuilder<List<Workout>>(
        future: workouts,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final list = snapshot.data;
          if (list == null || list.isEmpty) {
            return const Center(
              child: Text(
                "No workouts added yet",
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, index) {
              final w = list[index];
              return ListTile(
                title: Text(w.name),
                subtitle: Text(w.category),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/start_workout',
                    arguments: {
                      'workoutId': w.id,
                      'workoutName': w.name,
                    },
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddWorkoutDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
