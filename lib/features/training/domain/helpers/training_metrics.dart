/// Calculates the effective load for a set.
///
/// For bodyweight exercises: profile weight + added weight (ballast).
/// For regular exercises: the set weight itself.
/// Returns null if weight data is unavailable.
double? effectiveLoad({
  required bool isBodyweight,
  required double? setWeight,
  required double? profileWeight,
}) {
  if (isBodyweight) {
    final body = profileWeight ?? 0;
    final added = setWeight ?? 0;
    return body + added;
  }
  return setWeight;
}

/// Estimates 1-rep max using the Epley formula:
/// `1RM = weight × (1 + reps / 30)`
///
/// Returns null if weight is null/zero or reps <= 0.
double? estimated1RM({required double? weight, required int? reps}) {
  if (weight == null || weight <= 0 || reps == null || reps <= 0) {
    return null;
  }
  if (reps == 1) return weight;
  return weight * (1 + reps / 30);
}
