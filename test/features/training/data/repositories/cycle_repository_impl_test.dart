import 'package:athlos_app/core/database/app_database.dart';
import 'package:athlos_app/core/errors/result.dart';
import 'package:athlos_app/features/training/data/datasources/daos/cycle_step_dao.dart';
import 'package:athlos_app/features/training/data/repositories/cycle_repository_impl.dart';
import 'package:athlos_app/features/training/domain/entities/cycle_step.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CycleRepositoryImpl', () {
    late AppDatabase db;
    late CycleRepositoryImpl repository;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repository = CycleRepositoryImpl(CycleStepDao(db));
      await db.customSelect('SELECT 1').get();
    });

    tearDown(() async {
      await db.close();
    });

    test('setSteps/getSteps preserva ordem', () async {
      final result = await repository.setSteps(
        const [
          TrainingCycleStep(id: 0, orderIndex: 0, workoutId: 10),
          TrainingCycleStep(id: 0, orderIndex: 1, workoutId: 20),
        ],
      );
      expect(result.isSuccess, isTrue);

      final loaded = (await repository.getSteps()).getOrThrow();
      expect(loaded.length, 2);
      expect(loaded[0].workoutId, 10);
      expect(loaded[1].workoutId, 20);
    });

    test('appendWorkoutToCycle adiciona no final', () async {
      await repository.setSteps(const []);

      expect((await repository.appendWorkoutToCycle(1)).isSuccess, isTrue);
      expect((await repository.appendWorkoutToCycle(2)).isSuccess, isTrue);

      final loaded = (await repository.getSteps()).getOrThrow();
      expect(loaded.length, 2);
      expect(loaded[0].workoutId, 1);
      expect(loaded[0].orderIndex, 0);
      expect(loaded[1].workoutId, 2);
      expect(loaded[1].orderIndex, 1);
    });

    test('removeWorkoutFromCycle remove e reindexa', () async {
      await repository.setSteps(
        const [
          TrainingCycleStep(id: 0, orderIndex: 0, workoutId: 1),
          TrainingCycleStep(id: 0, orderIndex: 1, workoutId: 2),
          TrainingCycleStep(id: 0, orderIndex: 2, workoutId: 3),
        ],
      );

      expect((await repository.removeWorkoutFromCycle(1)).isSuccess, isTrue);
      final loaded = (await repository.getSteps()).getOrThrow();

      expect(loaded.length, 2);
      expect(loaded[0].orderIndex, 0);
      expect(loaded[0].workoutId, 2);
      expect(loaded[1].orderIndex, 1);
      expect(loaded[1].workoutId, 3);
    });

    test('syncWithActiveWorkoutIds adiciona faltantes no final', () async {
      await repository.setSteps(
        const [
          TrainingCycleStep(id: 0, orderIndex: 0, workoutId: 1),
        ],
      );

      expect(
        (await repository.syncWithActiveWorkoutIds(const [1, 2, 3])).isSuccess,
        isTrue,
      );
      final loaded = (await repository.getSteps()).getOrThrow();

      final workoutIds = loaded.map((s) => s.workoutId).toList();
      expect(workoutIds, containsAll([1, 2, 3]));
      expect(loaded.last.workoutId, 3);
    });
  });
}
