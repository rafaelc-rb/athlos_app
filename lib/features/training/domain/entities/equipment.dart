import '../enums/equipment_category.dart';

/// Training equipment (e.g. barbell, dumbbell, pull-up bar).
///
/// [isVerified] indicates whether this item has been curated by the app team.
/// Verified items have an English key in [name] with ARB translations.
/// Unverified items were created by the user and [name] contains raw user input.
class Equipment {
  final int id;
  final String name;
  final String? description;
  final EquipmentCategory category;
  final bool isVerified;

  const Equipment({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    this.isVerified = false,
  });
}
