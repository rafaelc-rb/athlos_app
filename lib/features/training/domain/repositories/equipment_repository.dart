import '../entities/equipment.dart';

/// Contract for equipment data operations.
abstract interface class EquipmentRepository {
  Future<List<Equipment>> getAll();
  Future<Equipment?> getById(int id);
  Future<int> create(Equipment equipment);
  Future<void> update(Equipment equipment);
  Future<void> delete(int id);
  Future<List<Equipment>> getByUser();
  Future<void> toggleUserEquipment(int equipmentId, {required bool owns});
}
