import 'package:drift/drift.dart';

import '../../../../../core/database/app_database.dart';
import '../tables/equipments_table.dart';
import '../tables/user_equipments_table.dart';

part 'equipment_dao.g.dart';

@DriftAccessor(tables: [Equipments, UserEquipments])
class EquipmentDao extends DatabaseAccessor<AppDatabase>
    with _$EquipmentDaoMixin {
  EquipmentDao(super.db);

  Future<List<Equipment>> getAll() => select(equipments).get();

  Future<Equipment?> getById(int id) =>
      (select(equipments)..where((e) => e.id.equals(id))).getSingleOrNull();

  Future<int> create(EquipmentsCompanion entry) =>
      into(equipments).insert(entry);

  Future<void> updateById(int id, EquipmentsCompanion entry) =>
      (update(equipments)..where((e) => e.id.equals(id))).write(entry);

  Future<void> deleteById(int id) =>
      (delete(equipments)..where((e) => e.id.equals(id))).go();

  Future<List<Equipment>> getByUser() {
    final query = select(equipments).join([
      innerJoin(
        userEquipments,
        userEquipments.equipmentId.equalsExp(equipments.id),
      ),
    ]);
    return query.map((row) => row.readTable(equipments)).get();
  }

  Future<void> addUserEquipment(int equipmentId) =>
      into(userEquipments).insert(
        UserEquipmentsCompanion(equipmentId: Value(equipmentId)),
      );

  Future<void> removeUserEquipment(int equipmentId) =>
      (delete(userEquipments)
            ..where((e) => e.equipmentId.equals(equipmentId)))
          .go();
}
