import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/user_profile.dart' as domain;
import '../../domain/enums/body_aesthetic.dart';
import '../../domain/enums/selected_module.dart';
import '../../domain/enums/training_goal.dart';
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
          selectedModules:
              Value(profile.selectedModules.map((m) => m.name).join(',')),
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
          selectedModules:
              Value(profile.selectedModules.map((m) => m.name).join(',')),
        ),
      );

  @override
  Future<void> updateSelectedModules(List<SelectedModule> modules) async {
    final profile = await _dao.get();
    if (profile == null) return;
    await _dao.updateById(
      profile.id,
      UserProfilesCompanion(
        selectedModules: Value(modules.map((m) => m.name).join(',')),
      ),
    );
  }

  @override
  Future<bool> hasProfile() => _dao.hasProfile();

  domain.UserProfile _toDomain(dynamic row) {
    final modulesStr = row.selectedModules as String;
    final modules = modulesStr.isEmpty
        ? <SelectedModule>[]
        : modulesStr.split(',').map((s) => SelectedModule.values.byName(s)).toList();

    return domain.UserProfile(
      id: row.id as int,
      weight: row.weight as double?,
      height: row.height as double?,
      age: row.age as int?,
      goal: row.goal as TrainingGoal?,
      bodyAesthetic: row.bodyAesthetic as BodyAesthetic?,
      selectedModules: modules,
    );
  }
}
