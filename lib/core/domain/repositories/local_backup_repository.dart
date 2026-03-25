import '../../errors/result.dart';
import '../entities/local_backup_models.dart';

abstract interface class LocalBackupRepository {
  Future<Result<BackupExportData>> exportBackup();

  Future<Result<BackupImportPreview>> previewImport(String jsonContent);

  Future<Result<BackupImportReport>> importBackup(BackupImportRequest request);
}
