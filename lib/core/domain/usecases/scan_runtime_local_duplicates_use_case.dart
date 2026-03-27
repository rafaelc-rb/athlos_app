import '../../errors/result.dart';
import '../entities/local_backup_models.dart';
import '../repositories/local_backup_repository.dart';

class ScanRuntimeLocalDuplicatesUseCase {
  final LocalBackupRepository _repository;

  const ScanRuntimeLocalDuplicatesUseCase(this._repository);

  Future<Result<List<BackupPendingReview>>> call() =>
      _repository.scanRuntimeLocalDuplicates();
}
