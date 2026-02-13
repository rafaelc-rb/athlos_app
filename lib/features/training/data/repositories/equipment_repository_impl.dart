import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/equipment.dart' as domain;
import '../../domain/repositories/equipment_repository.dart';
import '../datasources/daos/equipment_dao.dart';

class EquipmentRepositoryImpl implements EquipmentRepository {
  final EquipmentDao _dao;

  EquipmentRepositoryImpl(this._dao);

  @override
  Future<List<domain.Equipment>> getAll() async {
    final rows = await _dao.getAll();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<domain.Equipment?> getById(int id) async {
    final row = await _dao.getById(id);
    return row != null ? _toDomain(row) : null;
  }

  @override
  Future<int> create(domain.Equipment equipment) => _dao.create(
        EquipmentsCompanion.insert(
          name: equipment.name,
          description: Value(equipment.description),
          isCustom: Value(equipment.isCustom),
        ),
      );

  @override
  Future<void> update(domain.Equipment equipment) => _dao.updateById(
        equipment.id,
        EquipmentsCompanion(
          name: Value(equipment.name),
          description: Value(equipment.description),
          isCustom: Value(equipment.isCustom),
        ),
      );

  @override
  Future<void> delete(int id) => _dao.deleteById(id);

  @override
  Future<List<domain.Equipment>> getByUser() async {
    final rows = await _dao.getByUser();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<void> toggleUserEquipment(
    int equipmentId, {
    required bool owns,
  }) async {
    if (owns) {
      await _dao.addUserEquipment(equipmentId);
    } else {
      await _dao.removeUserEquipment(equipmentId);
    }
  }

  domain.Equipment _toDomain(dynamic row) => domain.Equipment(
        id: row.id as int,
        name: row.name as String,
        description: row.description as String?,
        isCustom: row.isCustom as bool,
      );
}
