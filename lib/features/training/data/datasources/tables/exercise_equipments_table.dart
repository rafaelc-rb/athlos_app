import 'package:drift/drift.dart';

import 'equipments_table.dart';
import 'exercises_table.dart';

/// Junction table: Exercise ↔ Equipment (many-to-many).
class ExerciseEquipments extends Table {
  IntColumn get exerciseId => integer().references(Exercises, #id)();
  IntColumn get equipmentId => integer().references(Equipments, #id)();

  @override
  Set<Column> get primaryKey => {exerciseId, equipmentId};
}
