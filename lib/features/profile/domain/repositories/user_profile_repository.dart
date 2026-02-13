import '../entities/user_profile.dart';
import '../enums/selected_module.dart';

/// Contract for user profile data operations.
abstract interface class UserProfileRepository {
  Future<UserProfile?> get();
  Future<int> create(UserProfile profile);
  Future<void> update(UserProfile profile);
  Future<void> updateLastActiveModule(AppModule module);
  Future<bool> hasProfile();
}
