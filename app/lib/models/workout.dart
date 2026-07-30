class Workout {
  final int id;
  final String name;
  final DateTime? createdAt; // optional, in case you need it
  final String category;

  Workout({
    required this.id,
    required this.name,
    this.createdAt,
    required this.category,
  });

  factory Workout.fromJson(Map<String, dynamic> json) {
    return Workout(
      id: json['id'],
      name: json['name'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      category: json['category'],    
    );
  }
}
