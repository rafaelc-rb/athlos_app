import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/user_profile.dart';
import '../../domain/enums/body_aesthetic.dart';
import '../../domain/enums/training_goal.dart';
import '../../domain/enums/training_style.dart';
import '../../data/repositories/profile_providers.dart';

part 'profile_notifier.g.dart';

/// Manages the user profile state across the app.
///
/// Loads the profile from the database on init. Exposes methods
/// to create, update, and check if a profile exists.
@Riverpod(keepAlive: true)
class ProfileNotifier extends _$ProfileNotifier {
  @override
  Future<UserProfile?> build() async {
    final repo = ref.watch(userProfileRepositoryProvider);
    return repo.get();
  }

  /// Creates a new user profile and updates the state.
  Future<void> create({
    required double weight,
    required double height,
    required int age,
    required TrainingGoal goal,
    required BodyAesthetic bodyAesthetic,
    required TrainingStyle trainingStyle,
  }) async {
    final repo = ref.read(userProfileRepositoryProvider);
    final profile = UserProfile(
      id: 0,
      weight: weight,
      height: height,
      age: age,
      goal: goal,
      bodyAesthetic: bodyAesthetic,
      trainingStyle: trainingStyle,
    );
    final id = await repo.create(profile);
    state = AsyncData(UserProfile(
      id: id,
      weight: weight,
      height: height,
      age: age,
      goal: goal,
      bodyAesthetic: bodyAesthetic,
      trainingStyle: trainingStyle,
    ));
  }

  /// Updates an existing user profile and refreshes the state.
  Future<void> updateProfile(UserProfile profile) async {
    final repo = ref.read(userProfileRepositoryProvider);
    await repo.update(profile);
    state = AsyncData(profile);
  }
}

/// Simple provider to check if a profile exists.
/// Used by the redirect guard in the router.
@Riverpod(keepAlive: true)
class HasProfile extends _$HasProfile {
  @override
  Future<bool> build() async {
    final repo = ref.watch(userProfileRepositoryProvider);
    return repo.hasProfile();
  }

  /// Force refresh after profile creation.
  void markAsCreated() {
    state = const AsyncData(true);
  }
}
