/// Training equipment (e.g. barbell, dumbbell, pull-up bar).
class Equipment {
  final int id;
  final String name;
  final String? description;
  final bool isCustom;

  const Equipment({
    required this.id,
    required this.name,
    this.description,
    this.isCustom = false,
  });
}
