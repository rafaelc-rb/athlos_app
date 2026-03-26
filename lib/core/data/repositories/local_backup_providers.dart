import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/app_database.dart';
import '../../domain/repositories/local_backup_repository.dart';
import '../../domain/usecases/export_local_backup_use_case.dart';
import '../../domain/usecases/import_local_backup_use_case.dart';
import '../../domain/usecases/preview_local_backup_import_use_case.dart';
import '../../domain/usecases/resolve_runtime_duplicate_use_case.dart';
import '../../domain/usecases/scan_runtime_local_duplicates_use_case.dart';
import 'local_backup_repository_impl.dart';

final localBackupRepositoryProvider = Provider<LocalBackupRepository>(
  (ref) => LocalBackupRepositoryImpl(ref.watch(appDatabaseProvider)),
);

final exportLocalBackupUseCaseProvider = Provider<ExportLocalBackupUseCase>(
  (ref) => ExportLocalBackupUseCase(ref.watch(localBackupRepositoryProvider)),
);

final previewLocalBackupImportUseCaseProvider =
    Provider<PreviewLocalBackupImportUseCase>(
      (ref) => PreviewLocalBackupImportUseCase(
        ref.watch(localBackupRepositoryProvider),
      ),
    );

final importLocalBackupUseCaseProvider = Provider<ImportLocalBackupUseCase>(
  (ref) => ImportLocalBackupUseCase(ref.watch(localBackupRepositoryProvider)),
);

final scanRuntimeLocalDuplicatesUseCaseProvider =
    Provider<ScanRuntimeLocalDuplicatesUseCase>(
      (ref) => ScanRuntimeLocalDuplicatesUseCase(
        ref.watch(localBackupRepositoryProvider),
      ),
    );

final resolveRuntimeDuplicateUseCaseProvider =
    Provider<ResolveRuntimeDuplicateUseCase>(
      (ref) => ResolveRuntimeDuplicateUseCase(
        ref.watch(localBackupRepositoryProvider),
      ),
    );
