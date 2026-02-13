import 'package:drift/drift.dart';

import '../../../domain/enums/muscle_group.dart';

class Exercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 150)();
  TextColumn get muscleGroup => textEnum<MuscleGroup>()();

  /// Specific muscles worked (e.g. "biceps brachii, brachialis").
  TextColumn get targetMuscles => text().nullable()();

  /// Portion of the muscle emphasized (e.g. "upper", "mid", "lower").
  TextColumn get muscleRegion => text().nullable()();

  TextColumn get description => text().nullable()();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
}
