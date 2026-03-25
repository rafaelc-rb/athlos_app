import '../../errors/result.dart';
import '../entities/local_backup_models.dart';
import '../repositories/local_backup_repository.dart';

class PreviewLocalBackupImportUseCase {
  final LocalBackupRepository _repository;

  const PreviewLocalBackupImportUseCase(this._repository);

  Future<Result<BackupImportPreview>> call(String jsonContent) =>
      _repository.previewImport(jsonContent);
}
