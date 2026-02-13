import 'package:drift/drift.dart';

class Equipments extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get description => text().nullable()();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
}
