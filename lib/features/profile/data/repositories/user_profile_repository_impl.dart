import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/user_profile.dart' as domain;
import '../../domain/enums/body_aesthetic.dart';
import '../../domain/enums/selected_module.dart';
import '../../domain/enums/training_goal.dart';
import '../../domain/enums/training_style.dart';
import '../../domain/repositories/user_profile_repository.dart';
import '../datasources/daos/user_profile_dao.dart';

class UserProfileRepositoryImpl implements UserProfileRepository {
  final UserProfileDao _dao;

  UserProfileRepositoryImpl(this._dao);

  @override
  Future<domain.UserProfile?> get() async {
    final row = await _dao.get();
    return row != null ? _toDomain(row) : null;
  }

  @override
  Future<int> create(domain.UserProfile profile) => _dao.create(
        UserProfilesCompanion.insert(
          weight: Value(profile.weight),
          height: Value(profile.height),
          age: Value(profile.age),
          goal: Value(profile.goal),
          bodyAesthetic: Value(profile.bodyAesthetic),
          trainingStyle: Value(profile.trainingStyle),
          lastActiveModule: Value(profile.lastActiveModule),
        ),
      );

  @override
  Future<void> update(domain.UserProfile profile) => _dao.updateById(
        profile.id,
        UserProfilesCompanion(
          weight: Value(profile.weight),
          height: Value(profile.height),
          age: Value(profile.age),
          goal: Value(profile.goal),
          bodyAesthetic: Value(profile.bodyAesthetic),
          trainingStyle: Value(profile.trainingStyle),
          lastActiveModule: Value(profile.lastActiveModule),
        ),
      );

  @override
  Future<void> updateLastActiveModule(AppModule module) async {
    final profile = await _dao.get();
    if (profile == null) return;
    await _dao.updateById(
      profile.id,
      UserProfilesCompanion(lastActiveModule: Value(module)),
    );
  }

  @override
  Future<bool> hasProfile() => _dao.hasProfile();

  domain.UserProfile _toDomain(dynamic row) => domain.UserProfile(
        id: row.id as int,
        weight: row.weight as double?,
        height: row.height as double?,
        age: row.age as int?,
        goal: row.goal as TrainingGoal?,
        bodyAesthetic: row.bodyAesthetic as BodyAesthetic?,
        trainingStyle: row.trainingStyle as TrainingStyle?,
        lastActiveModule: row.lastActiveModule as AppModule,
      );
}
