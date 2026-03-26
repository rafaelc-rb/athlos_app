import 'package:athlos_app/core/domain/entities/local_backup_models.dart';
import 'package:athlos_app/core/domain/repositories/local_backup_repository.dart';
import 'package:athlos_app/core/domain/usecases/export_local_backup_use_case.dart';
import 'package:athlos_app/core/domain/usecases/import_local_backup_use_case.dart';
import 'package:athlos_app/core/domain/usecases/preview_local_backup_import_use_case.dart';
import 'package:athlos_app/core/domain/usecases/resolve_runtime_duplicate_use_case.dart';
import 'package:athlos_app/core/domain/usecases/scan_runtime_local_duplicates_use_case.dart';
import 'package:athlos_app/core/errors/app_exception.dart';
import 'package:athlos_app/core/errors/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Local backup use cases', () {
    test('ExportLocalBackupUseCase delega ao repositorio', () async {
      final repository = _FakeLocalBackupRepository();
      repository.exportResult = const Success(
        BackupExportData(fileName: 'backup.json', jsonContent: '{}'),
      );
      final useCase = ExportLocalBackupUseCase(repository);

      final result = await useCase();

      expect(repository.exportCalls, 1);
      expect(result.isSuccess, isTrue);
    });

    test('PreviewLocalBackupImportUseCase delega ao repositorio', () async {
      final repository = _FakeLocalBackupRepository();
      repository.previewResult = const Success(
        BackupImportPreview(totalRecords: 5, conflicts: [], pendingReviews: []),
      );
      final useCase = PreviewLocalBackupImportUseCase(repository);

      final result = await useCase('{"backupFormatVersion":2}');

      expect(repository.previewCalls, 1);
      expect(repository.lastPreviewPayload, contains('"backupFormatVersion"'));
      expect(result.isSuccess, isTrue);
    });

    test('ImportLocalBackupUseCase delega ao repositorio', () async {
      final repository = _FakeLocalBackupRepository();
      repository.importResult = const Success(
        BackupImportReport(
          createdCount: 1,
          updatedCount: 2,
          skippedCount: 3,
          failedCount: 0,
        ),
      );
      final useCase = ImportLocalBackupUseCase(repository);
      const request = BackupImportRequest(
        jsonContent: '{}',
        conflictResolutions: {},
      );

      final result = await useCase(request);

      expect(repository.importCalls, 1);
      expect(repository.lastImportRequest, same(request));
      expect(result.isSuccess, isTrue);
    });

    test('ScanRuntimeLocalDuplicatesUseCase delega ao repositorio', () async {
      final repository = _FakeLocalBackupRepository();
      repository.runtimeScanResult = const Success([]);
      final useCase = ScanRuntimeLocalDuplicatesUseCase(repository);

      final result = await useCase();

      expect(repository.scanRuntimeCalls, 1);
      expect(result.isSuccess, isTrue);
    });

    test('ResolveRuntimeDuplicateUseCase delega ao repositorio', () async {
      final repository = _FakeLocalBackupRepository();
      repository.resolveRuntimeResult = const Success(null);
      final useCase = ResolveRuntimeDuplicateUseCase(repository);

      final result = await useCase(
        entityType: BackupConflictType.equipment,
        leftEntityId: 10,
        rightEntityId: 20,
        decision: RuntimeDuplicateDecision.notDuplicate,
      );

      expect(repository.resolveRuntimeCalls, 1);
      expect(result.isSuccess, isTrue);
    });
  });
}

class _FakeLocalBackupRepository implements LocalBackupRepository {
  Result<BackupExportData> exportResult = const Failure(
    DatabaseException('not configured'),
  );
  Result<BackupImportPreview> previewResult = const Failure(
    DatabaseException('not configured'),
  );
  Result<BackupImportReport> importResult = const Failure(
    DatabaseException('not configured'),
  );
  Result<List<BackupPendingReview>> runtimeScanResult = const Failure(
    DatabaseException('not configured'),
  );
  Result<void> resolveRuntimeResult = const Failure(
    DatabaseException('not configured'),
  );

  int exportCalls = 0;
  int previewCalls = 0;
  int importCalls = 0;
  int scanRuntimeCalls = 0;
  int resolveRuntimeCalls = 0;
  String? lastPreviewPayload;
  BackupImportRequest? lastImportRequest;

  @override
  Future<Result<BackupExportData>> exportBackup() async {
    exportCalls++;
    return exportResult;
  }

  @override
  Future<Result<BackupImportPreview>> previewImport(String jsonContent) async {
    previewCalls++;
    lastPreviewPayload = jsonContent;
    return previewResult;
  }

  @override
  Future<Result<BackupImportReport>> importBackup(
    BackupImportRequest request,
  ) async {
    importCalls++;
    lastImportRequest = request;
    return importResult;
  }

  @override
  Future<Result<List<BackupPendingReview>>> scanRuntimeLocalDuplicates() async {
    scanRuntimeCalls++;
    return runtimeScanResult;
  }

  @override
  Future<Result<void>> resolveRuntimeDuplicate({
    required BackupConflictType entityType,
    required int leftEntityId,
    required int rightEntityId,
    required RuntimeDuplicateDecision decision,
    int? winnerId,
    Map<String, dynamic>? mergedAttributes,
  }) async {
    resolveRuntimeCalls++;
    return resolveRuntimeResult;
  }

  @override
  Future<Result<Map<String, dynamic>>> loadEntityAttributes({
    required BackupConflictType entityType,
    required int entityId,
  }) async {
    return const Success({'id': 1, 'name': 'test'});
  }
}
