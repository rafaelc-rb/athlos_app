import 'package:drift/drift.dart';

import 'equipments_table.dart';

/// Junction table: UserProfile ↔ Equipment (equipment the user owns).
class UserEquipments extends Table {
  IntColumn get equipmentId => integer().references(Equipments, #id)();

  @override
  Set<Column> get primaryKey => {equipmentId};
}
