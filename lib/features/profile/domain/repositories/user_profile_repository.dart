import '../../../../core/errors/result.dart';
import '../entities/user_profile.dart';
import '../enums/selected_module.dart';

/// Contract for user profile data operations.
abstract interface class UserProfileRepository {
  Future<Result<UserProfile?>> get();
  Future<Result<int>> create(UserProfile profile);
  Future<Result<void>> update(UserProfile profile);
  Future<Result<void>> updateLastActiveModule(AppModule module);
  Future<Result<bool>> hasProfile();
}
