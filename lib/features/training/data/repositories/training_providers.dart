import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/repositories/equipment_repository.dart';
import '../../domain/repositories/exercise_repository.dart';
import '../../domain/repositories/workout_execution_repository.dart';
import '../../domain/repositories/workout_repository.dart';
import '../datasources/daos/equipment_dao.dart';
import '../datasources/daos/exercise_dao.dart';
import '../datasources/daos/workout_dao.dart';
import '../datasources/daos/workout_execution_dao.dart';
import 'equipment_repository_impl.dart';
import 'exercise_repository_impl.dart';
import 'workout_execution_repository_impl.dart';
import 'workout_repository_impl.dart';

part 'training_providers.g.dart';

// --- DAOs ---

@riverpod
EquipmentDao equipmentDao(Ref ref) =>
    EquipmentDao(ref.watch(appDatabaseProvider));

@riverpod
ExerciseDao exerciseDao(Ref ref) =>
    ExerciseDao(ref.watch(appDatabaseProvider));

@riverpod
WorkoutDao workoutDao(Ref ref) =>
    WorkoutDao(ref.watch(appDatabaseProvider));

@riverpod
WorkoutExecutionDao workoutExecutionDao(Ref ref) =>
    WorkoutExecutionDao(ref.watch(appDatabaseProvider));

// --- Repositories ---

@riverpod
EquipmentRepository equipmentRepository(Ref ref) =>
    EquipmentRepositoryImpl(ref.watch(equipmentDaoProvider));

@riverpod
ExerciseRepository exerciseRepository(Ref ref) =>
    ExerciseRepositoryImpl(ref.watch(exerciseDaoProvider));

@riverpod
WorkoutRepository workoutRepository(Ref ref) =>
    WorkoutRepositoryImpl(ref.watch(workoutDaoProvider));

@riverpod
WorkoutExecutionRepository workoutExecutionRepository(Ref ref) =>
    WorkoutExecutionRepositoryImpl(ref.watch(workoutExecutionDaoProvider));
