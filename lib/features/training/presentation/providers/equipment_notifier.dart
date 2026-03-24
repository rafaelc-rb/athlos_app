import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart';

import '../../../../core/errors/result.dart';
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
    final result = await repo.getAll();
    return result.getOrThrow();
  }

  /// Adds a user-created equipment and refreshes the list.
  Future<void> addUserEquipment({
    required String name,
    required EquipmentCategory category,
  }) async {
    await addUserEquipmentAndReturnId(
      name: name,
      category: category,
    );
  }

  /// Adds a user-created equipment, marks it as owned, and returns its ID.
  Future<int> addUserEquipmentAndReturnId({
    required String name,
    required EquipmentCategory category,
  }) async {
    final repo = ref.read(equipmentRepositoryProvider);
    final equipment = Equipment(
      id: 0,
      name: name,
      category: category,
    );
    final createResult = await repo.create(equipment);
    final id = createResult.getOrThrow();

    final toggleResult = await repo.toggleUserEquipment(id, isOwned: true);
    toggleResult.getOrThrow();

    ref.invalidateSelf();
    ref.invalidate(userEquipmentIdsProvider);
    return id;
  }

  /// Updates a user-created equipment.
  Future<void> updateEquipment(Equipment equipment) async {
    final repo = ref.read(equipmentRepositoryProvider);
    final result = await repo.update(equipment);
    result.getOrThrow();
    ref.invalidateSelf();
  }

  /// Deletes a user-created equipment.
  Future<void> deleteEquipment(int id) async {
    final repo = ref.read(equipmentRepositoryProvider);
    final result = await repo.delete(id);
    result.getOrThrow();
    ref.invalidateSelf();
  }
}

/// Manages the set of equipment IDs the user owns.
@riverpod
class UserEquipmentIds extends _$UserEquipmentIds {
  @override
  Future<Set<int>> build() async {
    final repo = ref.watch(equipmentRepositoryProvider);
    final result = await repo.getByUser();
    final equipments = result.getOrThrow();
    return equipments.map((e) => e.id).toSet();
  }

  /// Toggles ownership of an equipment item.
  Future<void> toggle(int equipmentId) async {
    final current = state.value ?? {};
    final isOwned = !current.contains(equipmentId);

    final repo = ref.read(equipmentRepositoryProvider);
    final result = await repo.toggleUserEquipment(equipmentId, isOwned: isOwned);
    result.getOrThrow();

    if (!ref.mounted) return;

    if (isOwned) {
      state = AsyncData({...current, equipmentId});
    } else {
      state = AsyncData({...current}..remove(equipmentId));
    }
  }

  /// Marks multiple equipment IDs as owned in a single batch.
  Future<void> addAll(Iterable<int> equipmentIds) async {
    final current = state.value ?? {};
    final toAdd = equipmentIds.where((id) => !current.contains(id)).toList();
    if (toAdd.isEmpty) return;

    final repo = ref.read(equipmentRepositoryProvider);
    for (final id in toAdd) {
      final result = await repo.toggleUserEquipment(id, isOwned: true);
      result.getOrThrow();
    }

    if (!ref.mounted) return;

    state = AsyncData({...current, ...toAdd});
  }
}

final equipmentByIdProvider = FutureProvider.family<Equipment?, int>(
  (ref, equipmentId) async {
    final equipments = await ref.watch(equipmentListProvider.future);
    for (final equipment in equipments) {
      if (equipment.id == equipmentId) return equipment;
    }
    return null;
  },
);
