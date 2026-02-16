import 'package:drift/drift.dart';

import '../../../domain/enums/body_aesthetic.dart';
import '../../../domain/enums/selected_module.dart';
import '../../../domain/enums/training_goal.dart';
import '../../../domain/enums/training_style.dart';

class UserProfiles extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Weight in kg.
  RealColumn get weight => real().nullable()();

  /// Height in cm.
  RealColumn get height => real().nullable()();

  IntColumn get age => integer().nullable()();
  TextColumn get goal => textEnum<TrainingGoal>().nullable()();
  TextColumn get bodyAesthetic => textEnum<BodyAesthetic>().nullable()();
  TextColumn get trainingStyle => textEnum<TrainingStyle>().nullable()();

  /// Last module the user was in.
  TextColumn get lastActiveModule =>
      textEnum<AppModule>().withDefault(Constant(AppModule.training.name))();
}
