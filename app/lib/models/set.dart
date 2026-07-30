class WorkoutSet {
  final int id;
  final int sessionId;
  final int setNumber;
  final double weight;
  final int reps;
  final int restSeconds;
  final DateTime createdAt;

  WorkoutSet({
    required this.id,
    required this.sessionId,
    required this.setNumber,
    required this.weight,
    required this.reps,
    required this.restSeconds,
    required this.createdAt,
  });

  factory WorkoutSet.fromJson(Map<String, dynamic> json) {
    return WorkoutSet(
      id: json['id'] ?? 0,
      sessionId: json['session_id'] ?? 0,
      setNumber: json['set_number'] ?? 0,
      // Accepts whole numbers or decimals (e.g. 40 or 2.5).
      weight: (json['weight'] ?? 0).toDouble(),
      reps: json['reps'] ?? 0,
      restSeconds: json['rest_seconds'] ?? 0,
      // Fall back to "now" so a missing/null date can never crash the app.
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}