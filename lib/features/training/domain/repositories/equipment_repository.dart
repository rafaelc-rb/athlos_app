import '../../../../core/errors/result.dart';
import '../entities/equipment.dart';

/// Contract for equipment data operations.
abstract interface class EquipmentRepository {
  Future<Result<List<Equipment>>> getAll();
  Future<Result<Equipment?>> getById(int id);
  Future<Result<int>> create(Equipment equipment);
  Future<Result<void>> update(Equipment equipment);
  Future<Result<void>> delete(int id);
  Future<Result<List<Equipment>>> getByUser();
  Future<Result<void>> toggleUserEquipment(int equipmentId,
      {required bool isOwned});
}
