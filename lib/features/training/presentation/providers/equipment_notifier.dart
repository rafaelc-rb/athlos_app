import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/training_providers.dart';
import '../../domain/entities/equipment.dart';
import '../../domain/enums/equipment_category.dart';

part 'equipment_notifier.g.dart';

/// Loads all equipment from the repository.
@riverpod
class EquipmentList extends _$EquipmentList {
  @override
  Future<List<Equipment>> build() async {
    final repo = ref.watch(equipmentRepositoryProvider);
    return repo.getAll();
  }

  /// Adds a user-created equipment and refreshes the list.
  Future<void> addUserEquipment({
    required String name,
    required EquipmentCategory category,
  }) async {
    final repo = ref.read(equipmentRepositoryProvider);
    final equipment = Equipment(
      id: 0,
      name: name,
      category: category,
    );
    final id = await repo.create(equipment);

    // Also mark as owned immediately
    await repo.toggleUserEquipment(id, owns: true);

    ref.invalidateSelf();
  }
}

/// Manages the set of equipment IDs the user owns.
@riverpod
class UserEquipmentIds extends _$UserEquipmentIds {
  @override
  Future<Set<int>> build() async {
    final repo = ref.watch(equipmentRepositoryProvider);
    final userEquipments = await repo.getByUser();
    return userEquipments.map((e) => e.id).toSet();
  }

  /// Toggles ownership of an equipment item.
  Future<void> toggle(int equipmentId) async {
    final current = state.value ?? {};
    final owns = !current.contains(equipmentId);

    final repo = ref.read(equipmentRepositoryProvider);
    await repo.toggleUserEquipment(equipmentId, owns: owns);

    if (owns) {
      state = AsyncData({...current, equipmentId});
    } else {
      state = AsyncData({...current}..remove(equipmentId));
    }
  }
}
