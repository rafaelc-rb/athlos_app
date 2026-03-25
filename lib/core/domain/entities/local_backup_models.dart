enum BackupConflictType {
  profile,
  equipment,
  exercise,
  workout,
}

enum BackupConflictResolution {
  keepExisting,
  overwriteExisting,
  keepBoth,
}

enum BackupPendingReviewType {
  missingCanonicalReference,
  fuzzyMatchCandidate,
}

enum BackupPendingReviewResolution {
  linkSuggested,
  createCustom,
  skip,
}

enum BackupImportResultStatus {
  created,
  updated,
  skipped,
  failed,
}

class BackupExportData {
  final String fileName;
  final String jsonContent;

  const BackupExportData({
    required this.fileName,
    required this.jsonContent,
  });
}

class BackupImportConflict {
  final String conflictId;
  final BackupConflictType type;
  final String existingLabel;
  final String importedLabel;
  final List<BackupConflictResolution> allowedResolutions;

  const BackupImportConflict({
    required this.conflictId,
    required this.type,
    required this.existingLabel,
    required this.importedLabel,
    required this.allowedResolutions,
  });
}

class BackupImportPreview {
  final int totalRecords;
  final List<BackupImportConflict> conflicts;
  final List<BackupPendingReview> pendingReviews;

  const BackupImportPreview({
    required this.totalRecords,
    required this.conflicts,
    required this.pendingReviews,
  });
}

class BackupImportReport {
  final int createdCount;
  final int updatedCount;
  final int skippedCount;
  final int failedCount;

  const BackupImportReport({
    required this.createdCount,
    required this.updatedCount,
    required this.skippedCount,
    required this.failedCount,
  });
}

class BackupImportRequest {
  final String jsonContent;
  final Map<String, BackupConflictResolution> conflictResolutions;
  final Map<String, BackupPendingReviewResolution> pendingReviewResolutions;

  const BackupImportRequest({
    required this.jsonContent,
    required this.conflictResolutions,
    this.pendingReviewResolutions = const {},
  });
}

class BackupCatalogReference {
  final int localId;
  final String catalogRemoteId;
  final String name;
  final Map<String, dynamic> fallbackData;

  const BackupCatalogReference({
    required this.localId,
    required this.catalogRemoteId,
    required this.name,
    required this.fallbackData,
  });
}

class BackupPendingReview {
  final String reviewId;
  final BackupPendingReviewType type;
  final BackupConflictType entityType;
  final String importedLabel;
  final String? suggestedLabel;
  final double? similarityScore;

  const BackupPendingReview({
    required this.reviewId,
    required this.type,
    required this.entityType,
    required this.importedLabel,
    this.suggestedLabel,
    this.similarityScore,
  });
}
