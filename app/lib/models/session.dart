class Session {
  final int id;
  final int workoutId;
  final DateTime startedAt;

  Session({
    required this.id,
    required this.workoutId,
    required this.startedAt,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'],
      workoutId: json['workout_id'],
      startedAt: DateTime.parse(json['date']),
    );
  }
}