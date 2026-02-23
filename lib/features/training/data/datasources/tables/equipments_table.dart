import 'package:drift/drift.dart';

import '../../../domain/enums/equipment_category.dart';

class Equipments extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get description => text().nullable()();
  TextColumn get category => textEnum<EquipmentCategory>()();
  BoolColumn get isVerified =>
      boolean().withDefault(const Constant(false))();
}
