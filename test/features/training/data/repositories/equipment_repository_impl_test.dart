import 'package:athlos_app/core/database/app_database.dart';
import 'package:athlos_app/core/errors/result.dart';
import 'package:athlos_app/features/training/data/datasources/daos/equipment_dao.dart';
import 'package:athlos_app/features/training/data/repositories/equipment_repository_impl.dart';
import 'package:athlos_app/features/training/domain/entities/equipment.dart'
    as domain;
import 'package:athlos_app/features/training/domain/enums/equipment_category.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EquipmentRepositoryImpl', () {
    late AppDatabase db;
    late EquipmentRepositoryImpl repository;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repository = EquipmentRepositoryImpl(EquipmentDao(db));
      await db.customSelect('SELECT 1').get();
    });

    tearDown(() async {
      await db.close();
    });

    test('create/getById/update/delete', () async {
      final createResult = await repository.create(
        const domain.Equipment(
          id: 0,
          name: 'My Bench',
          description: 'Test bench',
          category: EquipmentCategory.accessories,
          isVerified: false,
        ),
      );
      final id = createResult.getOrThrow();

      final loaded = (await repository.getById(id)).getOrThrow();
      expect(loaded, isNotNull);
      expect(loaded!.name, 'My Bench');

      final updateResult = await repository.update(
        domain.Equipment(
          id: id,
          name: 'My Bench V2',
          description: 'Updated',
          category: EquipmentCategory.accessories,
          isVerified: false,
        ),
      );
      expect(updateResult.isSuccess, isTrue);
      expect((await repository.getById(id)).getOrThrow()!.name, 'My Bench V2');

      final deleteResult = await repository.delete(id);
      expect(deleteResult.isSuccess, isTrue);
      expect((await repository.getById(id)).getOrThrow(), isNull);
    });

    test('toggleUserEquipment e add/remove por nome', () async {
      final id = (await repository.create(
        const domain.Equipment(
          id: 0,
          name: 'Toggle EQ',
          category: EquipmentCategory.freeWeights,
        ),
      ))
          .getOrThrow();

      await repository.toggleUserEquipment(id, isOwned: true);
      final userOwned1 = (await repository.getByUser()).getOrThrow();
      expect(userOwned1.any((e) => e.id == id), isTrue);

      await repository.toggleUserEquipment(id, isOwned: false);
      final userOwned2 = (await repository.getByUser()).getOrThrow();
      expect(userOwned2.any((e) => e.id == id), isFalse);

      await repository.addByName('Nome Unico Equipamento Teste');
      final userOwned3 = (await repository.getByUser()).getOrThrow();
      expect(
        userOwned3.any((e) => e.name.contains('Nome Unico Equipamento Teste')),
        isTrue,
      );

      await repository.removeByName('Nome Unico Equipamento Teste');
      final userOwned4 = (await repository.getByUser()).getOrThrow();
      expect(
        userOwned4.any((e) => e.name.contains('Nome Unico Equipamento Teste')),
        isFalse,
      );
    });
  });
}
