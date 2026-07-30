import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/workout.dart';
import '../models/session.dart';
import '../models/set.dart';

class ApiService {
  static const String baseUrl = "https://gym-app-1-n98u.onrender.com";

  // A cold start on free hosting can take ~50-60s. Give requests room to wait
  // and retry instead of failing on the first miss.
  static const Duration _timeout = Duration(seconds: 20);
  static const int _maxRetries = 4;

  /// Runs an HTTP call with a timeout, and retries a few times if the server
  /// is still waking up (timeouts, connection errors, or 5xx responses).
  /// This is what turns "failed to load" into "waits patiently, then works".
  static Future<http.Response> _send(
    Future<http.Response> Function() request,
  ) async {
    Object? lastError;
    for (var attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        final res = await request().timeout(_timeout);
        // 5xx usually means the app is mid-boot — worth retrying.
        if (res.statusCode >= 500) {
          lastError = 'Server ${res.statusCode}';
        } else {
          return res;
        }
      } on TimeoutException catch (e) {
        lastError = e;
      } catch (e) {
        lastError = e;
      }
      // Wait a moment before trying again (server is likely booting).
      await Future.delayed(Duration(seconds: 2 * (attempt + 1)));
    }
    throw Exception(
        'Server is taking too long to respond. It may be waking up — '
        'please try again in a moment. ($lastError)');
  }

  /// Fire-and-forget wake-up. Call this the instant the app opens so the
  /// server boots while the user is still on the login/home screen.
  static Future<void> warmUp() async {
    try {
      await http
          .get(Uri.parse("$baseUrl/health"))
          .timeout(const Duration(seconds: 90));
    } catch (_) {
      // Ignored on purpose — only a wake-up nudge.
    }
  }

  // -----------------------------
  // WORKOUTS
  // -----------------------------
  static Future<List<Workout>> getWorkouts() async {
    final res = await _send(() => http.get(Uri.parse("$baseUrl/workouts/")));
    final decoded = jsonDecode(res.body);
    if (decoded is List) {
      return decoded.map((e) => Workout.fromJson(e)).toList();
    } else if (decoded is Map) {
      return [Workout.fromJson(Map<String, dynamic>.from(decoded))];
    } else {
      return [];
    }
  }

  static Future<Workout> createWorkout(String name, String category) async {
    final res = await _send(() => http.post(
          Uri.parse("$baseUrl/workouts/"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"name": name, "category": category}),
        ));
    return Workout.fromJson(jsonDecode(res.body));
  }

  // -----------------------------
  // SESSIONS
  // -----------------------------
  static Future<Session> startSession(int workoutId) async {
    final res =
        await _send(() => http.post(Uri.parse("$baseUrl/sessions/$workoutId")));
    return Session.fromJson(jsonDecode(res.body));
  }

  static Future<List<Session>> getSessionsRange(
      DateTime start, DateTime end) async {
    final res = await _send(() => http.get(
          Uri.parse(
            "$baseUrl/sessions/range?start=${start.toIso8601String()}&end=${end.toIso8601String()}",
          ),
        ));
    final data = jsonDecode(res.body) as List;
    return data.map((e) => Session.fromJson(e)).toList();
  }

  // -----------------------------
  // SETS
  // -----------------------------
  static Future<void> addSet({
    required int sessionId,
    required int setNumber,
    required int reps,
    required double weight,
    required int restSeconds,
  }) async {
    final res = await _send(() => http.post(
          Uri.parse("$baseUrl/sets/$sessionId"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "set_number": setNumber,
            "weight": weight,
            "reps": reps,
            "rest_seconds": restSeconds,
          }),
        ));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception("Server rejected the set (${res.statusCode}): ${res.body}");
    }
  }

  static Future<List<WorkoutSet>> getAllSets() async {
    final res = await _send(() => http.get(Uri.parse("$baseUrl/sets/all")));
    final data = jsonDecode(res.body) as List;
    return data.map((e) => WorkoutSet.fromJson(e)).toList();
  }
}