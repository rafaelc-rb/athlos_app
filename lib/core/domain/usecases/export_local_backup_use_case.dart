import '../../errors/result.dart';
import '../entities/local_backup_models.dart';
import '../repositories/local_backup_repository.dart';

class ExportLocalBackupUseCase {
  final LocalBackupRepository _repository;

  const ExportLocalBackupUseCase(this._repository);

  Future<Result<BackupExportData>> call() => _repository.exportBackup();
}
