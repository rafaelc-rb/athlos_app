/// A workout is a named collection of exercises with their configurations.
class Workout {
  final int id;
  final String name;
  final String? description;
  final DateTime createdAt;

  const Workout({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
  });
}
