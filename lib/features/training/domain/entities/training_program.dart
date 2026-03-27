import '../enums/duration_mode.dart';
import '../enums/program_focus.dart';

/// A training program (mesocycle) — a named, time-bound container
/// that owns a cycle and tracks progress.
class TrainingProgram {
  final int id;
  final String name;
  final ProgramFocus focus;
  final DurationMode durationMode;
  final int durationValue;
  final int? defaultRestSeconds;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? archivedAt;

  const TrainingProgram({
    required this.id,
    required this.name,
    required this.focus,
    required this.durationMode,
    required this.durationValue,
    this.defaultRestSeconds,
    this.isActive = false,
    required this.createdAt,
    this.archivedAt,
  });

  bool get isArchived => archivedAt != null;
}
