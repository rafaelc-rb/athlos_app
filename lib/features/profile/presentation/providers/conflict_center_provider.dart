import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/repositories/local_backup_providers.dart';
import '../../../../core/domain/entities/local_backup_models.dart';
import '../../../../core/errors/result.dart';

class ConflictCenterViewData {
  final List<BackupPendingReview> runtimeLocalReviews;

  const ConflictCenterViewData({required this.runtimeLocalReviews});

  int get localDuplicateCount => runtimeLocalReviews.length;
}

final backupConflictCenterProvider =
    FutureProvider.autoDispose<ConflictCenterViewData>((ref) async {
      final scanUseCase = ref.watch(scanRuntimeLocalDuplicatesUseCaseProvider);

      final localRuntimeResult = await scanUseCase();

      return ConflictCenterViewData(
        runtimeLocalReviews: localRuntimeResult.getOrThrow(),
      );
    });
