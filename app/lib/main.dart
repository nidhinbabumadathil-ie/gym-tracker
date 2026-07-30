import 'package:flutter/material.dart';
import 'screens/workout_list.dart';
import 'screens/start_workout.dart';
import 'screens/add_set.dart';
import 'screens/history.dart';
import 'screens/analytics.dart';
import 'screens/sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/day_detail.dart';
import 'screens/exercise_list.dart';
import 'screens/workout_plan_screen.dart';
import 'screens/workout_summary.dart';
import 'screens/dashboard_screen.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Needed for SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final loggedIn = prefs.getBool('loggedIn') ?? false;

 runApp(GymApp(
    startScreen: loggedIn ? const DashboardScreen() : SignInScreen(),
  ));

}


class GymApp extends StatelessWidget {
  final Widget startScreen;
  GymApp({required this.startScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Gym App",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Color(0xFF0D0D0D),
        primaryColor: Colors.redAccent,
        colorScheme: ColorScheme.dark(
          primary: Colors.redAccent,
          secondary: Colors.redAccent,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF0D0D0D),
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        textTheme: TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
          bodyLarge: TextStyle(color: Colors.white),
        ),
      ),
      home: startScreen,
      routes: {
        '/sign_in': (context) => SignInScreen(),

        // NEW HOME
        '/workout_plan': (context) => const DashboardScreen(),

        // Day → Muscle
        '/day_detail': (context) {
          final baseDay = ModalRoute.of(context)!.settings.arguments as int;
          return DayDetailScreen(baseDay: baseDay);
        },

        // Muscle → Exercises
        '/exercise_list': (context) => ExerciseListScreen(),

        // Existing flows (UNCHANGED)
        '/workouts': (context) => WorkoutListScreen(),

        '/start_workout': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map;
          return StartWorkoutScreen(
            workoutId: args['workoutId'],
            workoutName: args['workoutName'],
          );
        },

        '/add_set': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map;
          return AddSetScreen(
            sessionId: args['sessionId'],
          );
        },

        '/history': (context) => HistoryScreen(),
        '/analytics': (context) => AnalyticsScreen(),
        '/workout_summary': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;

          return WorkoutSummaryScreen(
            sessionId: args?['sessionId'],
            dayLabel: args?['dayLabel'] ?? "Workout",
          );
        },
      },

    );
  }
}
