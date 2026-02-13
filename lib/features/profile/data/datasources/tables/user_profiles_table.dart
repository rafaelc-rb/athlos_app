import 'package:drift/drift.dart';

import '../../../domain/enums/body_aesthetic.dart';
import '../../../domain/enums/training_goal.dart';

class UserProfiles extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Weight in kg.
  RealColumn get weight => real().nullable()();

  /// Height in cm.
  RealColumn get height => real().nullable()();

  IntColumn get age => integer().nullable()();
  TextColumn get goal => textEnum<TrainingGoal>().nullable()();
  TextColumn get bodyAesthetic => textEnum<BodyAesthetic>().nullable()();

  /// Comma-separated module names (e.g. "training,diet").
  TextColumn get selectedModules => text().withDefault(const Constant(''))();
}
