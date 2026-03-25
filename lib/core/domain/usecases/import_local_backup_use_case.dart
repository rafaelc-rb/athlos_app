import '../../errors/result.dart';
import '../entities/local_backup_models.dart';
import '../repositories/local_backup_repository.dart';

class ImportLocalBackupUseCase {
  final LocalBackupRepository _repository;

  const ImportLocalBackupUseCase(this._repository);

  Future<Result<BackupImportReport>> call(BackupImportRequest request) =>
      _repository.importBackup(request);
}
