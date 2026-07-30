import 'package:flutter/material.dart';
import '../models/workout.dart';
import '../services/api_service.dart';

class WorkoutProvider with ChangeNotifier {
  List<Workout> workouts = [];

  Future<void> loadWorkouts() async {
    workouts = await ApiService.getWorkouts();
    notifyListeners();
  }
}
