import '../../errors/result.dart';
import '../entities/local_backup_models.dart';

abstract interface class LocalBackupRepository {
  Future<Result<BackupExportData>> exportBackup();

  Future<Result<BackupImportPreview>> previewImport(String jsonContent);

  Future<Result<BackupImportReport>> importBackup(BackupImportRequest request);

  Future<Result<List<BackupPendingReview>>> scanRuntimeLocalDuplicates();

  Future<Result<void>> resolveRuntimeDuplicate({
    required BackupConflictType entityType,
    required int leftEntityId,
    required int rightEntityId,
    required RuntimeDuplicateDecision decision,
    int? winnerId,
    Map<String, dynamic>? mergedAttributes,
  });

  Future<Result<Map<String, dynamic>>> loadEntityAttributes({
    required BackupConflictType entityType,
    required int entityId,
  });
}
