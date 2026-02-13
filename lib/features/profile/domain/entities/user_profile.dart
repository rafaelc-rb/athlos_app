import '../enums/body_aesthetic.dart';
import '../enums/selected_module.dart';
import '../enums/training_goal.dart';

/// User profile with personal data and preferences.
class UserProfile {
  final int id;

  /// Weight in kg.
  final double? weight;

  /// Height in cm.
  final double? height;

  final int? age;
  final TrainingGoal? goal;
  final BodyAesthetic? bodyAesthetic;
  final List<SelectedModule> selectedModules;

  const UserProfile({
    required this.id,
    this.weight,
    this.height,
    this.age,
    this.goal,
    this.bodyAesthetic,
    this.selectedModules = const [],
  });
}
