import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/repositories/user_profile_repository.dart';
import '../datasources/daos/user_profile_dao.dart';
import 'user_profile_repository_impl.dart';

part 'profile_providers.g.dart';

@riverpod
UserProfileDao userProfileDao(Ref ref) =>
    UserProfileDao(ref.watch(appDatabaseProvider));

@riverpod
UserProfileRepository userProfileRepository(Ref ref) =>
    UserProfileRepositoryImpl(ref.watch(userProfileDaoProvider));
