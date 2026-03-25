import 'dart:convert';

import 'package:athlos_app/core/data/repositories/local_backup_repository_impl.dart';
import 'package:athlos_app/core/database/app_database.dart';
import 'package:athlos_app/core/domain/entities/local_backup_models.dart';
import 'package:athlos_app/core/errors/app_exception.dart';
import 'package:athlos_app/core/errors/result.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocalBackupRepositoryImpl', () {
    late AppDatabase db;
    late LocalBackupRepositoryImpl repository;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repository = LocalBackupRepositoryImpl(db);
      await db.customSelect('SELECT 1').get();
    });

    tearDown(() async {
      await db.close();
    });

    test('previewImport gera conflito de perfil por campo diferente', () async {
      await db.customInsert(
        'INSERT INTO "user_profiles" ("name", "weight", "height", "age", "trains_at_gym") VALUES (?, ?, ?, ?, ?)',
        variables: [
          const Variable<String>('Rafa'),
          const Variable<double>(72.0),
          const Variable<double>(181.0),
          const Variable<int>(24),
          const Variable<bool>(false),
        ],
      );

      final jsonContent = jsonEncode(
        _payloadWithTables(
          {
            'user_profiles': [
              {
                'id': 1,
                'name': 'Rafa',
                'weight': 73.0,
                'height': 181.0,
                'age': 24,
                'trains_at_gym': null,
              },
            ],
          },
        ),
      );

      final result = await repository.previewImport(jsonContent);
      final preview = result.getOrThrow();
      final profileConflictIds = preview.conflicts
          .where((c) => c.type == BackupConflictType.profile)
          .map((c) => c.conflictId)
          .toList();

      expect(profileConflictIds, contains('profile:weight'));
      expect(profileConflictIds, isNot(contains('profile:name')));
      expect(profileConflictIds, isNot(contains('profile:trains_at_gym')));
    });

    test('previewImport retorna ValidationException para JSON invalido', () async {
      final result = await repository.previewImport('{invalid');
      expect(result.isFailure, isTrue);
      final failure = result as Failure<BackupImportPreview>;
      expect(failure.exception, isA<ValidationException>());
    });

    test('importBackup retorna ValidationException para versao invalida', () async {
      final payload = _payloadWithTables(const {});
      payload['backupFormatVersion'] = 999;

      final result = await repository.importBackup(
        BackupImportRequest(
          jsonContent: jsonEncode(payload),
          conflictResolutions: const {},
        ),
      );

      expect(result.isFailure, isTrue);
      final failure = result as Failure<BackupImportReport>;
      expect(failure.exception, isA<ValidationException>());
    });

    test('previewImport nao gera conflito com equivalencia de formato', () async {
      await db.customInsert(
        'INSERT INTO "user_profiles" ("name", "weight", "height", "age", "trains_at_gym") VALUES (?, ?, ?, ?, ?)',
        variables: [
          const Variable<String>('Rafa'),
          const Variable<double>(72.0),
          const Variable<double>(181.0),
          const Variable<int>(24),
          const Variable<bool>(false),
        ],
      );

      final jsonContent = jsonEncode(
        _payloadWithTables(
          {
            'user_profiles': [
              {
                'id': 1,
                'name': ' RAFA ',
                'weight': 72,
                'height': 181,
                'age': 24,
                'trains_at_gym': null,
              },
            ],
          },
        ),
      );

      final result = await repository.previewImport(jsonContent);
      final preview = result.getOrThrow();
      final profileConflicts = preview.conflicts
          .where((c) => c.type == BackupConflictType.profile)
          .toList();

      expect(profileConflicts, isEmpty);
    });

    test('importBackup insere perfil quando nao existe local', () async {
      final jsonContent = jsonEncode(
        _payloadWithTables(
          {
            'user_profiles': [
              {
                'id': 1,
                'name': 'Novo',
                'weight': 80.0,
                'height': 180.0,
                'age': 30,
                'trains_at_gym': 1,
              },
            ],
          },
        ),
      );

      final result = await repository.importBackup(
        BackupImportRequest(
          jsonContent: jsonContent,
          conflictResolutions: const {},
        ),
      );
      final report = result.getOrThrow();
      final rows =
          await db.customSelect('SELECT * FROM "user_profiles" LIMIT 1').get();

      expect(report.createdCount, 1);
      expect(rows.first.data['name'], 'Novo');
    });

    test('importBackup com perfil keepExisting incrementa skippedCount', () async {
      await db.customInsert(
        'INSERT INTO "user_profiles" ("name", "weight", "height", "age", "trains_at_gym") VALUES (?, ?, ?, ?, ?)',
        variables: [
          const Variable<String>('Rafa'),
          const Variable<double>(72.0),
          const Variable<double>(181.0),
          const Variable<int>(24),
          const Variable<bool>(false),
        ],
      );

      final jsonContent = jsonEncode(
        _payloadWithTables(
          {
            'user_profiles': [
              {
                'id': 1,
                'name': 'Rafael',
                'weight': 73.5,
                'height': 181.0,
                'age': 24,
                'trains_at_gym': 1,
              },
            ],
          },
        ),
      );

      final result = await repository.importBackup(
        BackupImportRequest(
          jsonContent: jsonContent,
          conflictResolutions: const {
            'profile:name': BackupConflictResolution.keepExisting,
            'profile:weight': BackupConflictResolution.keepExisting,
            'profile:trains_at_gym': BackupConflictResolution.keepExisting,
          },
        ),
      );
      final report = result.getOrThrow();

      expect(report.skippedCount, 1);
      expect(report.updatedCount, 0);
    });

    test('importBackup aplica resolucao de conflito de perfil por campo', () async {
      await db.customInsert(
        'INSERT INTO "user_profiles" ("name", "weight", "height", "age", "trains_at_gym") VALUES (?, ?, ?, ?, ?)',
        variables: [
          const Variable<String>('Rafa'),
          const Variable<double>(72.0),
          const Variable<double>(181.0),
          const Variable<int>(24),
          const Variable<bool>(false),
        ],
      );

      final jsonContent = jsonEncode(
        _payloadWithTables(
          {
            'user_profiles': [
              {
                'id': 1,
                'name': 'Rafael',
                'weight': 73.5,
                'height': 181,
                'age': 24,
                'trains_at_gym': null,
              },
            ],
          },
        ),
      );

      final result = await repository.importBackup(
        BackupImportRequest(
          jsonContent: jsonContent,
          conflictResolutions: const {
            'profile:name': BackupConflictResolution.keepExisting,
            'profile:weight': BackupConflictResolution.overwriteExisting,
          },
        ),
      );
      final report = result.getOrThrow();

      final rows =
          await db.customSelect('SELECT * FROM "user_profiles" LIMIT 1').get();
      final profile = rows.first.data;

      expect(report.updatedCount, 1);
      expect(profile['name'], 'Rafa');
      expect(profile['weight'], 73.5);
    });

    test('importBackup aceita coluna order sem erro SQL', () async {
      final jsonContent = jsonEncode(
        _payloadWithTables(
          {
            'workouts': [
              {
                'id': 1,
                'name': 'Treino A',
                'description': null,
                'sort_order': 0,
                'is_archived': 0,
                'created_at': 1,
              },
            ],
            'workout_exercises': [
              {
                'workout_id': 1,
                'exercise_id': 1,
                'order': 0,
                'sets': 3,
                'reps': 10,
                'rest': 60,
                'duration': null,
                'group_id': null,
                'is_unilateral': 0,
                'notes': null,
              },
            ],
          },
        ),
      );

      final result = await repository.importBackup(
        BackupImportRequest(
          jsonContent: jsonContent,
          conflictResolutions: const {},
        ),
      );
      final report = result.getOrThrow();

      expect(report.failedCount, 0);
      expect(report.createdCount, greaterThan(0));
    });

    test('importBackup suporta resolucao keepBoth para workout duplicado', () async {
      await db.customInsert(
        'INSERT INTO "workouts" ("name", "description", "sort_order", "is_archived", "created_at") VALUES (?, ?, ?, ?, ?)',
        variables: [
          const Variable<String>('Treino A'),
          const Variable<String>('Atual'),
          const Variable<int>(0),
          const Variable<bool>(false),
          const Variable<int>(1),
        ],
      );

      final jsonContent = jsonEncode(
        _payloadWithTables(
          {
            'workouts': [
              {
                'id': 7,
                'name': 'Treino A',
                'description': 'Importado',
                'sort_order': 1,
                'is_archived': 0,
                'created_at': 2,
              },
            ],
          },
        ),
      );

      final result = await repository.importBackup(
        BackupImportRequest(
          jsonContent: jsonContent,
          conflictResolutions: const {
            'workout:7': BackupConflictResolution.keepBoth,
          },
        ),
      );
      final report = result.getOrThrow();
      final rows = await db.customSelect('SELECT "name" FROM "workouts"').get();
      final names = rows.map((r) => r.data['name'] as String).toList();

      expect(report.createdCount, greaterThanOrEqualTo(1));
      expect(names.any((n) => n.contains('(importado)')), isTrue);
    });

    test('importBackup nao conta falha para cadeias de workout pulado', () async {
      await db.customInsert(
        'INSERT INTO "workouts" ("name", "description", "sort_order", "is_archived", "created_at") VALUES (?, ?, ?, ?, ?)',
        variables: [
          const Variable<String>('Treino A'),
          const Variable<String>('Atual'),
          const Variable<int>(0),
          const Variable<bool>(false),
          const Variable<int>(1),
        ],
      );

      final jsonContent = jsonEncode(
        _payloadWithTables(
          {
            'workouts': [
              {
                'id': 5,
                'name': 'Treino A',
                'description': 'Importado',
                'sort_order': 0,
                'is_archived': 0,
                'created_at': 1,
              },
            ],
            'workout_executions': [
              {
                'id': 50,
                'workout_id': 5,
                'started_at': 100,
                'finished_at': 120,
                'notes': null,
              },
            ],
            'execution_sets': [
              {
                'id': 500,
                'execution_id': 50,
                'exercise_id': 9999,
                'set_number': 1,
                'planned_reps': 10,
                'planned_weight': null,
                'reps': 10,
                'weight': null,
                'duration': null,
                'distance': null,
                'is_completed': 1,
                'notes': null,
              },
            ],
            'execution_set_segments': [
              {
                'id': 5000,
                'execution_set_id': 500,
                'segment_order': 1,
                'reps': 10,
                'weight': null,
              },
            ],
          },
        ),
      );

      final result = await repository.importBackup(
        BackupImportRequest(
          jsonContent: jsonContent,
          conflictResolutions: const {
            'workout:5': BackupConflictResolution.keepExisting,
          },
        ),
      );
      final report = result.getOrThrow();

      expect(report.failedCount, 0);
      expect(report.skippedCount, 1);
    });

    test('importBackup usa fallback de IDs verificados sem catalogReferences', () async {
      final jsonContent = jsonEncode(
        _payloadWithTables(
          {
            'workouts': [
              {
                'id': 10,
                'name': 'Treino Fallback',
                'description': null,
                'sort_order': 0,
                'is_archived': 0,
                'created_at': 1,
              },
            ],
            'workout_exercises': [
              {
                'workout_id': 10,
                'exercise_id': 1,
                'order': 0,
                'sets': 3,
                'reps': 10,
                'rest': 60,
                'duration': null,
                'group_id': null,
                'is_unilateral': 0,
                'notes': null,
              },
            ],
            'workout_executions': [
              {
                'id': 11,
                'workout_id': 10,
                'started_at': 100,
                'finished_at': 120,
                'notes': null,
              },
            ],
            'execution_sets': [
              {
                'id': 12,
                'execution_id': 11,
                'exercise_id': 1,
                'set_number': 1,
                'planned_reps': 10,
                'planned_weight': null,
                'reps': 10,
                'weight': null,
                'duration': null,
                'distance': null,
                'is_completed': 1,
                'notes': null,
              },
            ],
            'user_equipments': [
              {
                'equipment_id': 1,
              },
            ],
          },
        ),
      );

      final result = await repository.importBackup(
        BackupImportRequest(
          jsonContent: jsonContent,
          conflictResolutions: const {},
        ),
      );
      final report = result.getOrThrow();

      final workoutExerciseRows =
          await db.customSelect('SELECT * FROM "workout_exercises"').get();
      final userEquipmentRows =
          await db.customSelect('SELECT * FROM "user_equipments"').get();

      expect(report.failedCount, 0);
      expect(workoutExerciseRows, isNotEmpty);
      expect(userEquipmentRows, isNotEmpty);
    });

    test('exportBackup exporta apenas equipamentos customizados', () async {
      await db.customInsert(
        'INSERT INTO "equipments" ("name", "category", "is_verified") VALUES (?, ?, ?)',
        variables: [
          const Variable<String>('Custom Band'),
          const Variable<String>('accessories'),
          const Variable<bool>(false),
        ],
      );
      final exportResult = await repository.exportBackup();
      final exportData = exportResult.getOrThrow();
      final parsed = jsonDecode(exportData.jsonContent) as Map<String, dynamic>;

      final tables = parsed['tables'] as Map<String, dynamic>;
      final exportedEquipments = (tables['equipments'] as List)
          .cast<Map>()
          .map((e) => Map<String, dynamic>.from(e.cast<String, dynamic>()))
          .toList();

      expect(
        exportedEquipments.any((row) => row['name'] == 'Custom Band'),
        isTrue,
      );
      expect(
        exportedEquipments.every((row) => row['is_verified'] == 0),
        isTrue,
      );
    });
  });
}

Map<String, dynamic> _payloadWithTables(
  Map<String, List<Map<String, dynamic>>> tablesOverride,
) {
  final tables = <String, List<Map<String, dynamic>>>{
    'user_profiles': [],
    'equipments': [],
    'exercises': [],
    'exercise_equipments': [],
    'exercise_target_muscles': [],
    'exercise_variations': [],
    'workouts': [],
    'workout_exercises': [],
    'workout_executions': [],
    'execution_sets': [],
    'execution_set_segments': [],
    'cycle_steps': [],
    'user_equipments': [],
  };
  tables.addAll(tablesOverride);

  return {
    'backupFormatVersion': 2,
    'databaseSchemaVersion': 12,
    'mode': 'user_only',
    'exportedAt': DateTime.now().toIso8601String(),
    'tables': tables,
    'catalogReferences': {
      'equipments': [],
      'exercises': [],
    },
  };
}
