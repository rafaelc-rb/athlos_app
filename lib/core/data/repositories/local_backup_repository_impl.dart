import 'dart:convert';
import 'dart:math' as math;

import 'package:drift/drift.dart';

import '../../database/app_database.dart';
import '../../domain/entities/local_backup_models.dart';
import '../../domain/repositories/local_backup_repository.dart';
import '../../errors/app_exception.dart';
import '../../errors/result.dart';

const _backupFormatVersion = 2;
const _fuzzyThreshold = 0.84;

const _tableUserProfiles = 'user_profiles';
const _tableEquipments = 'equipments';
const _tableExercises = 'exercises';
const _tableExerciseEquipments = 'exercise_equipments';
const _tableExerciseTargetMuscles = 'exercise_target_muscles';
const _tableExerciseVariations = 'exercise_variations';
const _tableWorkouts = 'workouts';
const _tableWorkoutExercises = 'workout_exercises';
const _tableWorkoutExecutions = 'workout_executions';
const _tableExecutionSets = 'execution_sets';
const _tableExecutionSetSegments = 'execution_set_segments';
const _tableCycleSteps = 'cycle_steps';
const _tableUserEquipments = 'user_equipments';

const _tableCatalogReferences = 'catalogReferences';
const _catalogEquipments = 'equipments';
const _catalogExercises = 'exercises';

class LocalBackupRepositoryImpl implements LocalBackupRepository {
  final AppDatabase _db;

  const LocalBackupRepositoryImpl(this._db);

  @override
  Future<Result<BackupExportData>> exportBackup() async {
    try {
      final profiles = await _fetchTableRows(_tableUserProfiles);
      final workouts = await _fetchTableRows(_tableWorkouts);
      final workoutExercises = await _fetchTableRows(_tableWorkoutExercises);
      final workoutExecutions = await _fetchTableRows(_tableWorkoutExecutions);
      final executionSets = await _fetchTableRows(_tableExecutionSets);
      final executionSetSegments =
          await _fetchTableRows(_tableExecutionSetSegments);
      final cycleSteps = await _fetchTableRows(_tableCycleSteps);
      final userEquipments = await _fetchTableRows(_tableUserEquipments);

      final allEquipments = await _fetchTableRows(_tableEquipments);
      final allExercises = await _fetchTableRows(_tableExercises);
      final equipmentById = {
        for (final row in allEquipments) _asInt(row['id'])!: row,
      };
      final exerciseById = {
        for (final row in allExercises) _asInt(row['id'])!: row,
      };

      final customEquipments = allEquipments
          .where((row) => !_asBool(row['is_verified']))
          .map(_toJsonMap)
          .toList();
      final customExercises = allExercises
          .where((row) => !_asBool(row['is_verified']))
          .map(_toJsonMap)
          .toList();
      final customExerciseIds = customExercises
          .map((row) => _asInt(row['id']))
          .whereType<int>()
          .toSet();

      final exerciseEquipments = await _fetchRowsForCustomExercises(
        _tableExerciseEquipments,
        customExerciseIds,
      );
      final targetMuscles = await _fetchRowsForCustomExercises(
        _tableExerciseTargetMuscles,
        customExerciseIds,
      );
      final variations = await _fetchCustomVariations(customExerciseIds);

      final referencedEquipmentIds = <int>{
        ...userEquipments
            .map((row) => _asInt(row['equipment_id']))
            .whereType<int>(),
        ...exerciseEquipments
            .map((row) => _asInt(row['equipment_id']))
            .whereType<int>(),
      };
      final referencedExerciseIds = <int>{
        ...workoutExercises
            .map((row) => _asInt(row['exercise_id']))
            .whereType<int>(),
        ...executionSets.map((row) => _asInt(row['exercise_id'])).whereType<int>(),
        ...variations
            .expand(
              (row) => [
                _asInt(row['exercise_id']),
                _asInt(row['variation_id']),
              ],
            )
            .whereType<int>(),
      };

      final catalogEquipmentRefs = referencedEquipmentIds
          .map((id) => equipmentById[id])
          .whereType<Map<String, dynamic>>()
          .where((row) => _asBool(row['is_verified']))
          .map(_toEquipmentCatalogRef)
          .whereType<Map<String, dynamic>>()
          .toList();
      final catalogExerciseRefs = referencedExerciseIds
          .map((id) => exerciseById[id])
          .whereType<Map<String, dynamic>>()
          .where((row) => _asBool(row['is_verified']))
          .map(_toExerciseCatalogRef)
          .whereType<Map<String, dynamic>>()
          .toList();

      final payload = <String, dynamic>{
        'backupFormatVersion': _backupFormatVersion,
        'databaseSchemaVersion': _db.schemaVersion,
        'mode': 'user_only',
        'exportedAt': DateTime.now().toIso8601String(),
        'tables': <String, dynamic>{
          _tableUserProfiles: profiles.map(_toJsonMap).toList(),
          _tableEquipments: customEquipments,
          _tableExercises: customExercises,
          _tableExerciseEquipments: exerciseEquipments.map(_toJsonMap).toList(),
          _tableExerciseTargetMuscles: targetMuscles.map(_toJsonMap).toList(),
          _tableExerciseVariations: variations.map(_toJsonMap).toList(),
          _tableWorkouts: workouts.map(_toJsonMap).toList(),
          _tableWorkoutExercises: workoutExercises.map(_toJsonMap).toList(),
          _tableWorkoutExecutions: workoutExecutions.map(_toJsonMap).toList(),
          _tableExecutionSets: executionSets.map(_toJsonMap).toList(),
          _tableExecutionSetSegments:
              executionSetSegments.map(_toJsonMap).toList(),
          _tableCycleSteps: cycleSteps.map(_toJsonMap).toList(),
          _tableUserEquipments: userEquipments.map(_toJsonMap).toList(),
        },
        _tableCatalogReferences: <String, dynamic>{
          _catalogEquipments: catalogEquipmentRefs,
          _catalogExercises: catalogExerciseRefs,
        },
      };

      final jsonContent = const JsonEncoder.withIndent('  ').convert(payload);
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .replaceAll('.', '-');

      return Success(
        BackupExportData(
          fileName: 'athlos_user_backup_$timestamp.json',
          jsonContent: jsonContent,
        ),
      );
    } on Exception catch (e) {
      return Failure(DatabaseException('Failed to export backup: $e'));
    }
  }

  @override
  Future<Result<BackupImportPreview>> previewImport(String jsonContent) async {
    try {
      final payload = _parsePayload(jsonContent);
      final conflicts = await _scanConflicts(payload.tables);
      final pendingReviews = await _scanPendingReviews(payload);

      return Success(
        BackupImportPreview(
          totalRecords: payload.totalRecords,
          conflicts: conflicts,
          pendingReviews: pendingReviews,
        ),
      );
    } on AppException catch (e) {
      return Failure(e);
    } on Exception catch (e) {
      return Failure(DatabaseException('Failed to preview import: $e'));
    }
  }

  @override
  Future<Result<BackupImportReport>> importBackup(
    BackupImportRequest request,
  ) async {
    try {
      final payload = _parsePayload(request.jsonContent);

      var createdCount = 0;
      var updatedCount = 0;
      var skippedCount = 0;
      var failedCount = 0;

      final equipmentIdMap = <int, int>{};
      final exerciseIdMap = <int, int>{};

      await _db.transaction(() async {
        final canonicalResult = await _resolveCanonicalReferences(
          payload: payload,
          request: request,
        );
        equipmentIdMap.addAll(canonicalResult.equipmentIdMap);
        exerciseIdMap.addAll(canonicalResult.exerciseIdMap);
        failedCount += canonicalResult.unresolvedCount;

        final customEquipmentResult = await _importCustomCatalogRows(
          rows: payload.tables[_tableEquipments] ?? const [],
          tableName: _tableEquipments,
          conflictPrefix: 'equipment',
          pendingPrefix: 'fuzzy_equipment',
          nameField: 'name',
          entityType: BackupConflictType.equipment,
          idMap: equipmentIdMap,
          request: request,
        );
        createdCount += customEquipmentResult.createdCount;
        updatedCount += customEquipmentResult.updatedCount;
        skippedCount += customEquipmentResult.skippedCount;
        failedCount += customEquipmentResult.failedCount;

        final customExerciseResult = await _importCustomCatalogRows(
          rows: payload.tables[_tableExercises] ?? const [],
          tableName: _tableExercises,
          conflictPrefix: 'exercise',
          pendingPrefix: 'fuzzy_exercise',
          nameField: 'name',
          entityType: BackupConflictType.exercise,
          idMap: exerciseIdMap,
          request: request,
        );
        createdCount += customExerciseResult.createdCount;
        updatedCount += customExerciseResult.updatedCount;
        skippedCount += customExerciseResult.skippedCount;
        failedCount += customExerciseResult.failedCount;

        final workoutIdMap = <int, int>{};
        final executionIdMap = <int, int>{};
        final executionSetIdMap = <int, int>{};
        final importWorkoutDetails = <int, bool>{};
        final existingWorkoutByName = await _fetchNamedIds(_tableWorkouts);

        final workoutRows = payload.tables[_tableWorkouts] ?? const [];
        for (final row in workoutRows) {
          final oldId = _asInt(row['id']);
          final name = (row['name'] as String?)?.trim();
          if (oldId == null || name == null || name.isEmpty) {
            failedCount++;
            continue;
          }

          final key = _normalizeName(name);
          final existingId = existingWorkoutByName[key];
          if (existingId == null) {
            final newId = await _insertRow(
              _tableWorkouts,
              row,
              excludeKeys: const {'id'},
            );
            workoutIdMap[oldId] = newId;
            existingWorkoutByName[key] = newId;
            importWorkoutDetails[oldId] = true;
            createdCount++;
            continue;
          }

          final resolution = request.conflictResolutions['workout:$oldId'] ??
              BackupConflictResolution.keepExisting;
          switch (resolution) {
            case BackupConflictResolution.keepExisting:
              workoutIdMap[oldId] = existingId;
              importWorkoutDetails[oldId] = false;
              skippedCount++;
            case BackupConflictResolution.overwriteExisting:
              await _updateRowById(
                _tableWorkouts,
                existingId,
                row,
                excludeKeys: const {'id'},
              );
              workoutIdMap[oldId] = existingId;
              importWorkoutDetails[oldId] = true;
              updatedCount++;
            case BackupConflictResolution.keepBoth:
              final uniqueName = _buildUniqueName(name, existingWorkoutByName);
              final nextRow = Map<String, dynamic>.from(row)
                ..['name'] = uniqueName;
              final newId = await _insertRow(
                _tableWorkouts,
                nextRow,
                excludeKeys: const {'id'},
              );
              workoutIdMap[oldId] = newId;
              existingWorkoutByName[_normalizeName(uniqueName)] = newId;
              importWorkoutDetails[oldId] = true;
              createdCount++;
          }
        }

        final userEquipmentRows = payload.tables[_tableUserEquipments] ?? const [];
        for (final row in userEquipmentRows) {
          final oldEquipmentId = _asInt(row['equipment_id']);
          if (oldEquipmentId == null) continue;
          final newEquipmentId = equipmentIdMap[oldEquipmentId];
          if (newEquipmentId == null) {
            failedCount++;
            continue;
          }
          await _insertRow(
            _tableUserEquipments,
            {'equipment_id': newEquipmentId},
            orIgnore: true,
          );
        }

        final exerciseEquipmentRows =
            payload.tables[_tableExerciseEquipments] ?? const [];
        for (final row in exerciseEquipmentRows) {
          final oldExerciseId = _asInt(row['exercise_id']);
          final oldEquipmentId = _asInt(row['equipment_id']);
          if (oldExerciseId == null || oldEquipmentId == null) continue;
          final newExerciseId = exerciseIdMap[oldExerciseId];
          final newEquipmentId = equipmentIdMap[oldEquipmentId];
          if (newExerciseId == null || newEquipmentId == null) {
            failedCount++;
            continue;
          }
          await _insertRow(
            _tableExerciseEquipments,
            {
              'exercise_id': newExerciseId,
              'equipment_id': newEquipmentId,
            },
            orIgnore: true,
          );
        }

        final targetRows = payload.tables[_tableExerciseTargetMuscles] ?? const [];
        for (final row in targetRows) {
          final oldExerciseId = _asInt(row['exercise_id']);
          if (oldExerciseId == null) continue;
          final newExerciseId = exerciseIdMap[oldExerciseId];
          if (newExerciseId == null) {
            failedCount++;
            continue;
          }
          await _insertRow(
            _tableExerciseTargetMuscles,
            {
              'exercise_id': newExerciseId,
              'target_muscle': row['target_muscle'],
              'muscle_region': row['muscle_region'],
              'role': row['role'],
            },
            orIgnore: true,
          );
        }

        final variationRows = payload.tables[_tableExerciseVariations] ?? const [];
        for (final row in variationRows) {
          final oldExerciseId = _asInt(row['exercise_id']);
          final oldVariationId = _asInt(row['variation_id']);
          if (oldExerciseId == null || oldVariationId == null) continue;
          final newExerciseId = exerciseIdMap[oldExerciseId];
          final newVariationId = exerciseIdMap[oldVariationId];
          if (newExerciseId == null || newVariationId == null) {
            failedCount++;
            continue;
          }
          await _insertRow(
            _tableExerciseVariations,
            {
              'exercise_id': newExerciseId,
              'variation_id': newVariationId,
            },
            orIgnore: true,
          );
        }

        final workoutExerciseRows = payload.tables[_tableWorkoutExercises] ?? const [];
        for (final row in workoutExerciseRows) {
          final oldWorkoutId = _asInt(row['workout_id']);
          final oldExerciseId = _asInt(row['exercise_id']);
          if (oldWorkoutId == null || oldExerciseId == null) continue;
          if (importWorkoutDetails[oldWorkoutId] == false) continue;

          final newWorkoutId = workoutIdMap[oldWorkoutId];
          final newExerciseId = exerciseIdMap[oldExerciseId];
          if (newWorkoutId == null || newExerciseId == null) {
            failedCount++;
            continue;
          }
          await _insertRow(
            _tableWorkoutExercises,
            {
              'workout_id': newWorkoutId,
              'exercise_id': newExerciseId,
              'order': row['order'],
              'sets': row['sets'],
              'reps': row['reps'],
              'rest': row['rest'],
              'duration': row['duration'],
              'group_id': row['group_id'],
              'is_unilateral': row['is_unilateral'],
              'notes': row['notes'],
            },
            orReplace: true,
          );
        }

        final executionRows = payload.tables[_tableWorkoutExecutions] ?? const [];
        for (final row in executionRows) {
          final oldExecutionId = _asInt(row['id']);
          final oldWorkoutId = _asInt(row['workout_id']);
          if (oldExecutionId == null || oldWorkoutId == null) continue;
          if (importWorkoutDetails[oldWorkoutId] == false) continue;

          final newWorkoutId = workoutIdMap[oldWorkoutId];
          if (newWorkoutId == null) {
            failedCount++;
            continue;
          }
          final newExecutionId = await _insertRow(
            _tableWorkoutExecutions,
            {
              'workout_id': newWorkoutId,
              'started_at': row['started_at'],
              'finished_at': row['finished_at'],
              'notes': row['notes'],
            },
            excludeKeys: const {'id'},
          );
          executionIdMap[oldExecutionId] = newExecutionId;
        }

        final executionSetRows = payload.tables[_tableExecutionSets] ?? const [];
        for (final row in executionSetRows) {
          final oldSetId = _asInt(row['id']);
          final oldExecutionId = _asInt(row['execution_id']);
          final oldExerciseId = _asInt(row['exercise_id']);
          if (oldSetId == null || oldExecutionId == null || oldExerciseId == null) {
            continue;
          }

          final newExecutionId = executionIdMap[oldExecutionId];
          final newExerciseId = exerciseIdMap[oldExerciseId];
          if (newExecutionId == null || newExerciseId == null) {
            failedCount++;
            continue;
          }
          final newSetId = await _insertRow(
            _tableExecutionSets,
            {
              'execution_id': newExecutionId,
              'exercise_id': newExerciseId,
              'set_number': row['set_number'],
              'planned_reps': row['planned_reps'],
              'planned_weight': row['planned_weight'],
              'reps': row['reps'],
              'weight': row['weight'],
              'duration': row['duration'],
              'distance': row['distance'],
              'is_completed': row['is_completed'],
              'notes': row['notes'],
            },
            excludeKeys: const {'id'},
          );
          executionSetIdMap[oldSetId] = newSetId;
        }

        final segmentRows =
            payload.tables[_tableExecutionSetSegments] ?? const [];
        for (final row in segmentRows) {
          final oldExecutionSetId = _asInt(row['execution_set_id']);
          if (oldExecutionSetId == null) continue;
          final newExecutionSetId = executionSetIdMap[oldExecutionSetId];
          if (newExecutionSetId == null) {
            failedCount++;
            continue;
          }
          await _insertRow(
            _tableExecutionSetSegments,
            {
              'execution_set_id': newExecutionSetId,
              'segment_order': row['segment_order'],
              'reps': row['reps'],
              'weight': row['weight'],
            },
            excludeKeys: const {'id'},
          );
        }

        final cycleStepRows = payload.tables[_tableCycleSteps] ?? const [];
        for (final row in cycleStepRows) {
          final oldWorkoutId = _asInt(row['workout_id']);
          final newWorkoutId =
              oldWorkoutId != null ? workoutIdMap[oldWorkoutId] : null;
          if (oldWorkoutId != null &&
              (newWorkoutId == null ||
                  importWorkoutDetails[oldWorkoutId] == false)) {
            continue;
          }
          await _insertRow(
            _tableCycleSteps,
            {
              'order_index': row['order_index'],
              'step_type': row['step_type'],
              'workout_id': newWorkoutId,
            },
            excludeKeys: const {'id'},
          );
        }
      });

      return Success(
        BackupImportReport(
          createdCount: createdCount,
          updatedCount: updatedCount,
          skippedCount: skippedCount,
          failedCount: failedCount,
        ),
      );
    } on AppException catch (e) {
      return Failure(e);
    } on Exception catch (e) {
      return Failure(DatabaseException('Failed to import backup: $e'));
    }
  }

  Future<_CanonicalResolutionResult> _resolveCanonicalReferences({
    required _BackupParsedPayload payload,
    required BackupImportRequest request,
  }) async {
    final equipmentIdMap = <int, int>{};
    final exerciseIdMap = <int, int>{};
    var unresolvedCount = 0;

    final equipmentRefs = payload.catalogReferences[_catalogEquipments] ?? const [];
    final exerciseRefs = payload.catalogReferences[_catalogExercises] ?? const [];

    final verifiedEquipments = await _fetchVerifiedRows(_tableEquipments);
    final verifiedExercises = await _fetchVerifiedRows(_tableExercises);

    for (final ref in equipmentRefs) {
      final resolved = await _resolveCatalogReference(
        ref: ref,
        tableName: _tableEquipments,
        entityType: BackupConflictType.equipment,
        verifiedRows: verifiedEquipments,
        request: request,
      );
      if (resolved == null) {
        unresolvedCount++;
        continue;
      }
      equipmentIdMap[ref.localId] = resolved;
    }

    for (final ref in exerciseRefs) {
      final resolved = await _resolveCatalogReference(
        ref: ref,
        tableName: _tableExercises,
        entityType: BackupConflictType.exercise,
        verifiedRows: verifiedExercises,
        request: request,
      );
      if (resolved == null) {
        unresolvedCount++;
        continue;
      }
      exerciseIdMap[ref.localId] = resolved;
    }

    return _CanonicalResolutionResult(
      equipmentIdMap: equipmentIdMap,
      exerciseIdMap: exerciseIdMap,
      unresolvedCount: unresolvedCount,
    );
  }

  Future<int?> _resolveCatalogReference({
    required BackupCatalogReference ref,
    required String tableName,
    required BackupConflictType entityType,
    required List<Map<String, dynamic>> verifiedRows,
    required BackupImportRequest request,
  }) async {
    final byRemote = verifiedRows.firstWhere(
      (row) => row['catalog_remote_id']?.toString() == ref.catalogRemoteId,
      orElse: () => const {},
    );
    if (byRemote.isNotEmpty) return _asInt(byRemote['id']);

    final suggestions = _topFuzzyCandidates(
      ref.name,
      verifiedRows,
      limit: 1,
    );
    final pendingId = 'missing_${entityType.name}_${ref.localId}';
    final resolution = request.pendingReviewResolutions[pendingId];

    if (resolution == BackupPendingReviewResolution.linkSuggested &&
        suggestions.isNotEmpty) {
      return _asInt(suggestions.first['id']);
    }

    if (resolution == BackupPendingReviewResolution.createCustom) {
      return _insertRow(
        tableName,
        ref.fallbackData,
        excludeKeys: const {'id', 'catalog_remote_id'},
      );
    }

    return null;
  }

  Future<_ImportCatalogResult> _importCustomCatalogRows({
    required List<Map<String, dynamic>> rows,
    required String tableName,
    required String conflictPrefix,
    required String pendingPrefix,
    required String nameField,
    required BackupConflictType entityType,
    required Map<int, int> idMap,
    required BackupImportRequest request,
  }) async {
    var createdCount = 0;
    var updatedCount = 0;
    var skippedCount = 0;
    var failedCount = 0;

    final existingRows = await _fetchTableRows(tableName);
    final byNormalized = <String, Map<String, dynamic>>{};
    for (final row in existingRows) {
      final name = row[nameField] as String?;
      if (name == null || name.trim().isEmpty) continue;
      byNormalized[_normalizeName(name)] = row;
    }

    for (final row in rows) {
      final oldId = _asInt(row['id']);
      final name = (row[nameField] as String?)?.trim();
      if (oldId == null || name == null || name.isEmpty) {
        failedCount++;
        continue;
      }

      final normalized = _normalizeName(name);
      final existing = byNormalized[normalized];
      if (existing != null) {
        final existingId = _asInt(existing['id'])!;
        final resolution = request.conflictResolutions['$conflictPrefix:$oldId'] ??
            BackupConflictResolution.keepExisting;
        switch (resolution) {
          case BackupConflictResolution.keepExisting:
            idMap[oldId] = existingId;
            skippedCount++;
          case BackupConflictResolution.overwriteExisting:
            await _updateRowById(
              tableName,
              existingId,
              row,
              excludeKeys: const {'id'},
            );
            idMap[oldId] = existingId;
            updatedCount++;
          case BackupConflictResolution.keepBoth:
            final uniqueName = _buildUniqueName(
              name,
              byNormalized.map((key, value) => MapEntry(key, _asInt(value['id'])!)),
            );
            final nextRow = Map<String, dynamic>.from(row)..[nameField] = uniqueName;
            final newId = await _insertRow(
              tableName,
              nextRow,
              excludeKeys: const {'id'},
            );
            idMap[oldId] = newId;
            byNormalized[_normalizeName(uniqueName)] = nextRow..['id'] = newId;
            createdCount++;
        }
        continue;
      }

      final fuzzy = _topFuzzyCandidates(name, existingRows, limit: 1);
      if (fuzzy.isNotEmpty && fuzzy.first['score'] >= _fuzzyThreshold) {
        final pendingId = '${pendingPrefix}_$oldId';
        final pendingResolution = request.pendingReviewResolutions[pendingId] ??
            BackupPendingReviewResolution.createCustom;

        if (pendingResolution == BackupPendingReviewResolution.linkSuggested) {
          final suggestedId = _asInt(fuzzy.first['id']);
          if (suggestedId != null) {
            idMap[oldId] = suggestedId;
            skippedCount++;
            continue;
          }
        }

        if (pendingResolution == BackupPendingReviewResolution.skip) {
          skippedCount++;
          continue;
        }
      }

      final newId = await _insertRow(
        tableName,
        row,
        excludeKeys: const {'id'},
      );
      idMap[oldId] = newId;
      createdCount++;
    }

    return _ImportCatalogResult(
      createdCount: createdCount,
      updatedCount: updatedCount,
      skippedCount: skippedCount,
      failedCount: failedCount,
    );
  }

  Future<List<BackupImportConflict>> _scanConflicts(
    Map<String, List<Map<String, dynamic>>> tables,
  ) async {
    final conflicts = <BackupImportConflict>[];

    final importedProfiles = tables[_tableUserProfiles] ?? const [];
    if (importedProfiles.isNotEmpty) {
      final existingProfiles = await _fetchTableRows(_tableUserProfiles);
      if (existingProfiles.isNotEmpty) {
        final imported = importedProfiles.first;
        final existing = existingProfiles.first;
        conflicts.add(
          BackupImportConflict(
            conflictId: 'profile:${_asInt(imported['id']) ?? 0}',
            type: BackupConflictType.profile,
            existingLabel: (existing['name'] as String?) ?? 'Perfil atual',
            importedLabel: (imported['name'] as String?) ?? 'Perfil importado',
            allowedResolutions: const [
              BackupConflictResolution.keepExisting,
              BackupConflictResolution.overwriteExisting,
            ],
          ),
        );
      }
    }

    conflicts.addAll(
      await _scanNamedConflicts(
        importedRows: tables[_tableEquipments] ?? const [],
        tableName: _tableEquipments,
        type: BackupConflictType.equipment,
        idPrefix: 'equipment',
      ),
    );
    conflicts.addAll(
      await _scanNamedConflicts(
        importedRows: tables[_tableExercises] ?? const [],
        tableName: _tableExercises,
        type: BackupConflictType.exercise,
        idPrefix: 'exercise',
      ),
    );
    conflicts.addAll(
      await _scanNamedConflicts(
        importedRows: tables[_tableWorkouts] ?? const [],
        tableName: _tableWorkouts,
        type: BackupConflictType.workout,
        idPrefix: 'workout',
      ),
    );

    return conflicts;
  }

  Future<List<BackupImportConflict>> _scanNamedConflicts({
    required List<Map<String, dynamic>> importedRows,
    required String tableName,
    required BackupConflictType type,
    required String idPrefix,
  }) async {
    final conflicts = <BackupImportConflict>[];
    final existingByName = await _fetchNamedIds(tableName);
    for (final row in importedRows) {
      final id = _asInt(row['id']);
      final name = (row['name'] as String?)?.trim();
      if (id == null || name == null || name.isEmpty) continue;
      if (!existingByName.containsKey(_normalizeName(name))) continue;
      conflicts.add(
        BackupImportConflict(
          conflictId: '$idPrefix:$id',
          type: type,
          existingLabel: name,
          importedLabel: name,
          allowedResolutions: const [
            BackupConflictResolution.keepExisting,
            BackupConflictResolution.overwriteExisting,
            BackupConflictResolution.keepBoth,
          ],
        ),
      );
    }
    return conflicts;
  }

  Future<List<BackupPendingReview>> _scanPendingReviews(
    _BackupParsedPayload payload,
  ) async {
    final pending = <BackupPendingReview>[];
    final verifiedEquipments = await _fetchVerifiedRows(_tableEquipments);
    final verifiedExercises = await _fetchVerifiedRows(_tableExercises);

    final equipmentRefs = payload.catalogReferences[_catalogEquipments] ?? const [];
    for (final ref in equipmentRefs) {
      final byRemote = verifiedEquipments.any(
        (row) => row['catalog_remote_id']?.toString() == ref.catalogRemoteId,
      );
      if (byRemote) continue;

      final suggestion = _topFuzzyCandidates(ref.name, verifiedEquipments, limit: 1);
      pending.add(
        BackupPendingReview(
          reviewId: 'missing_equipment_${ref.localId}',
          type: BackupPendingReviewType.missingCanonicalReference,
          entityType: BackupConflictType.equipment,
          importedLabel: ref.name,
          suggestedLabel:
              suggestion.isNotEmpty ? suggestion.first['name'] as String? : null,
          similarityScore:
              suggestion.isNotEmpty ? suggestion.first['score'] as double : null,
        ),
      );
    }

    final exerciseRefs = payload.catalogReferences[_catalogExercises] ?? const [];
    for (final ref in exerciseRefs) {
      final byRemote = verifiedExercises.any(
        (row) => row['catalog_remote_id']?.toString() == ref.catalogRemoteId,
      );
      if (byRemote) continue;

      final suggestion = _topFuzzyCandidates(ref.name, verifiedExercises, limit: 1);
      pending.add(
        BackupPendingReview(
          reviewId: 'missing_exercise_${ref.localId}',
          type: BackupPendingReviewType.missingCanonicalReference,
          entityType: BackupConflictType.exercise,
          importedLabel: ref.name,
          suggestedLabel:
              suggestion.isNotEmpty ? suggestion.first['name'] as String? : null,
          similarityScore:
              suggestion.isNotEmpty ? suggestion.first['score'] as double : null,
        ),
      );
    }

    final fuzzyRows = [
      (
        tableName: _tableEquipments,
        rows: payload.tables[_tableEquipments] ?? const [],
        type: BackupConflictType.equipment,
        prefix: 'fuzzy_equipment',
      ),
      (
        tableName: _tableExercises,
        rows: payload.tables[_tableExercises] ?? const [],
        type: BackupConflictType.exercise,
        prefix: 'fuzzy_exercise',
      ),
      (
        tableName: _tableWorkouts,
        rows: payload.tables[_tableWorkouts] ?? const [],
        type: BackupConflictType.workout,
        prefix: 'fuzzy_workout',
      ),
    ];

    for (final item in fuzzyRows) {
      final localRows = await _fetchTableRows(item.tableName);
      final localByNormalized = {
        for (final row in localRows)
          if ((row['name'] as String?)?.trim().isNotEmpty ?? false)
            _normalizeName(row['name'] as String): row,
      };
      for (final row in item.rows) {
        final oldId = _asInt(row['id']);
        final name = (row['name'] as String?)?.trim();
        if (oldId == null || name == null || name.isEmpty) continue;
        if (localByNormalized.containsKey(_normalizeName(name))) continue;

        final suggestion = _topFuzzyCandidates(name, localRows, limit: 1);
        if (suggestion.isEmpty) continue;
        final best = suggestion.first['score'] as double;
        if (best < _fuzzyThreshold) continue;

        pending.add(
          BackupPendingReview(
            reviewId: '${item.prefix}_$oldId',
            type: BackupPendingReviewType.fuzzyMatchCandidate,
            entityType: item.type,
            importedLabel: name,
            suggestedLabel: suggestion.first['name'] as String?,
            similarityScore: best,
          ),
        );
      }
    }

    return pending;
  }

  _BackupParsedPayload _parsePayload(String jsonContent) {
    dynamic parsed;
    try {
      parsed = jsonDecode(jsonContent);
    } on FormatException {
      throw const ValidationException('Invalid JSON file.');
    }

    if (parsed is! Map<String, dynamic>) {
      throw const ValidationException('Invalid backup format.');
    }

    final backupFormatVersion = _asInt(parsed['backupFormatVersion']);
    if (backupFormatVersion != _backupFormatVersion) {
      throw const ValidationException('Unsupported backup format version.');
    }

    final schemaVersion = _asInt(parsed['databaseSchemaVersion']);
    if (schemaVersion == null || schemaVersion > _db.schemaVersion) {
      throw ValidationException(
        'Backup schema version ($schemaVersion) is incompatible with current app schema (${_db.schemaVersion}).',
      );
    }

    final tablesNode = parsed['tables'];
    if (tablesNode is! Map<String, dynamic>) {
      throw const ValidationException('Backup payload does not contain tables.');
    }

    final tableNames = <String>[
      _tableUserProfiles,
      _tableEquipments,
      _tableExercises,
      _tableExerciseEquipments,
      _tableExerciseTargetMuscles,
      _tableExerciseVariations,
      _tableWorkouts,
      _tableWorkoutExercises,
      _tableWorkoutExecutions,
      _tableExecutionSets,
      _tableExecutionSetSegments,
      _tableCycleSteps,
      _tableUserEquipments,
    ];

    final tables = <String, List<Map<String, dynamic>>>{};
    var totalRecords = 0;
    for (final tableName in tableNames) {
      final rows = _readRowsList(tablesNode[tableName]);
      tables[tableName] = rows;
      totalRecords += rows.length;
    }

    final refsNode = parsed[_tableCatalogReferences];
    final catalogRefs = <String, List<BackupCatalogReference>>{
      _catalogEquipments: const [],
      _catalogExercises: const [],
    };
    if (refsNode is Map<String, dynamic>) {
      catalogRefs[_catalogEquipments] =
          _readCatalogRefs(refsNode[_catalogEquipments]);
      catalogRefs[_catalogExercises] =
          _readCatalogRefs(refsNode[_catalogExercises]);
    }

    return _BackupParsedPayload(
      tables: tables,
      catalogReferences: catalogRefs,
      totalRecords: totalRecords,
    );
  }

  List<Map<String, dynamic>> _readRowsList(dynamic node) {
    if (node is! List) return const [];
    final rows = <Map<String, dynamic>>[];
    for (final item in node) {
      if (item is Map<String, dynamic>) {
        rows.add(Map<String, dynamic>.from(item));
      } else if (item is Map) {
        rows.add(Map<String, dynamic>.from(item.cast<String, dynamic>()));
      }
    }
    return rows;
  }

  List<BackupCatalogReference> _readCatalogRefs(dynamic node) {
    if (node is! List) return const [];
    final refs = <BackupCatalogReference>[];
    for (final item in node) {
      if (item is! Map) continue;
      final map = item.cast<String, dynamic>();
      final localId = _asInt(map['localId']);
      final remoteId = map['catalogRemoteId']?.toString();
      final name = map['name']?.toString();
      if (localId == null || remoteId == null || name == null) continue;
      refs.add(
        BackupCatalogReference(
          localId: localId,
          catalogRemoteId: remoteId,
          name: name,
          fallbackData: Map<String, dynamic>.from(
            (map['fallbackData'] as Map?)?.cast<String, dynamic>() ?? const {},
          ),
        ),
      );
    }
    return refs;
  }

  Future<List<Map<String, dynamic>>> _fetchRowsForCustomExercises(
    String tableName,
    Set<int> customExerciseIds,
  ) async {
    if (customExerciseIds.isEmpty) return const [];
    final ids = customExerciseIds.join(', ');
    final rows = await _db.customSelect(
      'SELECT * FROM $tableName WHERE exercise_id IN ($ids)',
    ).get();
    return rows.map((row) => Map<String, dynamic>.from(row.data)).toList();
  }

  Future<List<Map<String, dynamic>>> _fetchCustomVariations(
    Set<int> customExerciseIds,
  ) async {
    if (customExerciseIds.isEmpty) return const [];
    final ids = customExerciseIds.join(', ');
    final rows = await _db.customSelect(
      'SELECT * FROM $_tableExerciseVariations WHERE exercise_id IN ($ids) OR variation_id IN ($ids)',
    ).get();
    return rows.map((row) => Map<String, dynamic>.from(row.data)).toList();
  }

  Future<List<Map<String, dynamic>>> _fetchVerifiedRows(String tableName) async {
    final rows = await _db
        .customSelect('SELECT * FROM $tableName WHERE is_verified = 1')
        .get();
    return rows.map((row) => Map<String, dynamic>.from(row.data)).toList();
  }

  Future<List<Map<String, dynamic>>> _fetchTableRows(String tableName) async {
    final rows = await _db.customSelect('SELECT * FROM $tableName').get();
    return rows.map((row) => Map<String, dynamic>.from(row.data)).toList();
  }

  Future<Map<String, int>> _fetchNamedIds(String tableName) async {
    final rows = await _db.customSelect('SELECT id, name FROM $tableName').get();
    final namedIds = <String, int>{};
    for (final row in rows) {
      final id = _asInt(row.data['id']);
      final name = row.data['name'] as String?;
      if (id == null || name == null || name.trim().isEmpty) continue;
      namedIds[_normalizeName(name)] = id;
    }
    return namedIds;
  }

  Map<String, dynamic> _toJsonMap(Map<String, dynamic> row) {
    return row.map((key, value) => MapEntry(key, _toJsonValue(value)));
  }

  Map<String, dynamic>? _toEquipmentCatalogRef(Map<String, dynamic> row) {
    final id = _asInt(row['id']);
    final remoteId = row['catalog_remote_id']?.toString();
    final name = row['name'] as String?;
    if (id == null || remoteId == null || name == null) return null;
    return {
      'localId': id,
      'catalogRemoteId': remoteId,
      'name': name,
      'fallbackData': {
        'name': name,
        'description': row['description'],
        'category': row['category'],
        'is_verified': 0,
      },
    };
  }

  Map<String, dynamic>? _toExerciseCatalogRef(Map<String, dynamic> row) {
    final id = _asInt(row['id']);
    final remoteId = row['catalog_remote_id']?.toString();
    final name = row['name'] as String?;
    if (id == null || remoteId == null || name == null) return null;
    return {
      'localId': id,
      'catalogRemoteId': remoteId,
      'name': name,
      'fallbackData': {
        'name': name,
        'muscle_group': row['muscle_group'],
        'type': row['type'],
        'movement_pattern': row['movement_pattern'],
        'description': row['description'],
        'is_verified': 0,
      },
    };
  }

  dynamic _toJsonValue(dynamic value) {
    if (value is DateTime) return value.toIso8601String();
    return value;
  }

  Future<int> _insertRow(
    String tableName,
    Map<String, dynamic> row, {
    Set<String> excludeKeys = const {},
    bool orIgnore = false,
    bool orReplace = false,
  }) async {
    final filtered = Map<String, dynamic>.from(row)
      ..removeWhere((key, _) => excludeKeys.contains(key));
    if (filtered.isEmpty) {
      throw const ValidationException('Cannot insert empty row.');
    }

    final columns = <String>[];
    final placeholders = <String>[];
    final variables = <Variable<Object>>[];
    for (final entry in filtered.entries) {
      columns.add(entry.key);
      if (entry.value == null) {
        placeholders.add('NULL');
      } else {
        placeholders.add('?');
        variables.add(_toVariable(entry.value));
      }
    }

    final mode = orIgnore
        ? 'INSERT OR IGNORE'
        : (orReplace ? 'INSERT OR REPLACE' : 'INSERT');
    final sql =
        '$mode INTO $tableName (${columns.join(', ')}) VALUES (${placeholders.join(', ')})';
    return _db.customInsert(sql, variables: variables);
  }

  Future<void> _updateRowById(
    String tableName,
    int id,
    Map<String, dynamic> row, {
    Set<String> excludeKeys = const {},
  }) async {
    final filtered = Map<String, dynamic>.from(row)
      ..removeWhere((key, _) => key == 'id' || excludeKeys.contains(key));
    if (filtered.isEmpty) return;

    final setters = <String>[];
    final variables = <Variable<Object>>[];
    for (final entry in filtered.entries) {
      if (entry.value == null) {
        setters.add('${entry.key} = NULL');
      } else {
        setters.add('${entry.key} = ?');
        variables.add(_toVariable(entry.value));
      }
    }
    variables.add(Variable<int>(id));
    final sql = 'UPDATE $tableName SET ${setters.join(', ')} WHERE id = ?';
    await _db.customUpdate(sql, variables: variables);
  }

  List<Map<String, dynamic>> _topFuzzyCandidates(
    String inputName,
    List<Map<String, dynamic>> rows, {
    int limit = 3,
  }) {
    final normalizedInput = _normalizeName(inputName);
    final scored = <Map<String, dynamic>>[];
    for (final row in rows) {
      final name = row['name'] as String?;
      final id = _asInt(row['id']);
      if (name == null || id == null) continue;
      final score = _similarity(normalizedInput, _normalizeName(name));
      scored.add({'id': id, 'name': name, 'score': score});
    }
    scored.sort(
      (a, b) => (b['score'] as double).compareTo(a['score'] as double),
    );
    return scored.take(limit).toList();
  }

  double _similarity(String a, String b) {
    if (a.isEmpty || b.isEmpty) return 0;
    if (a == b) return 1;
    final distance = _levenshtein(a, b);
    final maxLen = math.max(a.length, b.length);
    return 1 - (distance / maxLen);
  }

  int _levenshtein(String a, String b) {
    final m = a.length;
    final n = b.length;
    final matrix = List.generate(
      m + 1,
      (_) => List<int>.filled(n + 1, 0),
    );
    for (var i = 0; i <= m; i++) {
      matrix[i][0] = i;
    }
    for (var j = 0; j <= n; j++) {
      matrix[0][j] = j;
    }
    for (var i = 1; i <= m; i++) {
      for (var j = 1; j <= n; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        matrix[i][j] = math.min(
          math.min(
            matrix[i - 1][j] + 1,
            matrix[i][j - 1] + 1,
          ),
          matrix[i - 1][j - 1] + cost,
        );
      }
    }
    return matrix[m][n];
  }

  bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is num) return value.toInt() == 1;
    if (value is String) return value == '1' || value.toLowerCase() == 'true';
    return false;
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  Variable<Object> _toVariable(dynamic value) {
    if (value is bool) return Variable<bool>(value) as Variable<Object>;
    if (value is int) return Variable<int>(value) as Variable<Object>;
    if (value is double) return Variable<double>(value) as Variable<Object>;
    if (value is num) {
      if (value % 1 == 0) return Variable<int>(value.toInt()) as Variable<Object>;
      return Variable<double>(value.toDouble()) as Variable<Object>;
    }
    if (value is DateTime) return Variable<DateTime>(value) as Variable<Object>;
    return Variable<String>(value.toString()) as Variable<Object>;
  }

  String _normalizeName(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  String _buildUniqueName(String baseName, Map<String, int> existingByName) {
    var index = 1;
    var candidate = '$baseName (importado)';
    while (existingByName.containsKey(_normalizeName(candidate))) {
      index++;
      candidate = '$baseName (importado $index)';
    }
    return candidate;
  }
}

class _BackupParsedPayload {
  final Map<String, List<Map<String, dynamic>>> tables;
  final Map<String, List<BackupCatalogReference>> catalogReferences;
  final int totalRecords;

  const _BackupParsedPayload({
    required this.tables,
    required this.catalogReferences,
    required this.totalRecords,
  });
}

class _ImportCatalogResult {
  final int createdCount;
  final int updatedCount;
  final int skippedCount;
  final int failedCount;

  const _ImportCatalogResult({
    required this.createdCount,
    required this.updatedCount,
    required this.skippedCount,
    required this.failedCount,
  });
}

class _CanonicalResolutionResult {
  final Map<int, int> equipmentIdMap;
  final Map<int, int> exerciseIdMap;
  final int unresolvedCount;

  const _CanonicalResolutionResult({
    required this.equipmentIdMap,
    required this.exerciseIdMap,
    required this.unresolvedCount,
  });
}
