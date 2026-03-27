import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/result.dart';
import '../../data/repositories/training_providers.dart';
import '../../domain/entities/training_program.dart';
import '../../domain/enums/duration_mode.dart';
import 'training_analytics_provider.dart';

part 'program_notifier.g.dart';

/// The currently active program, or null if training in free-cycle mode.
@riverpod
Future<TrainingProgram?> activeProgram(Ref ref) async {
  final repo = ref.watch(programRepositoryProvider);
  final result = await repo.getActive();
  return result.getOrThrow();
}

/// All programs (active + archived), newest first.
@riverpod
Future<List<TrainingProgram>> programList(Ref ref) async {
  final repo = ref.watch(programRepositoryProvider);
  final result = await repo.getAll();
  return result.getOrThrow();
}

/// Convenience: the active program's ID or null.
@riverpod
Future<int?> activeProgramId(Ref ref) async {
  final program = await ref.watch(activeProgramProvider.future);
  return program?.id;
}

/// Number of finished sessions for a given program.
@riverpod
Future<int> programSessionCount(Ref ref, int programId) async {
  final repo = ref.watch(programRepositoryProvider);
  final result = await repo.getSessionCount(programId);
  return result.getOrThrow();
}

/// Program progress info: current sessions done vs total planned.
class ProgramProgressInfo {
  final int completedSessions;
  final int totalSessions;

  const ProgramProgressInfo({
    required this.completedSessions,
    required this.totalSessions,
  });

  double get fraction =>
      totalSessions > 0 ? (completedSessions / totalSessions).clamp(0.0, 1.0) : 0;

  bool get isCompleted => completedSessions >= totalSessions;
}

@riverpod
Future<ProgramProgressInfo> programProgress(Ref ref, int programId) async {
  final programs = await ref.watch(programListProvider.future);
  final program = programs.where((p) => p.id == programId).firstOrNull;
  if (program == null) {
    return const ProgramProgressInfo(completedSessions: 0, totalSessions: 1);
  }

  final sessionCount =
      await ref.watch(programSessionCountProvider(programId).future);

  int totalSessions;
  if (program.durationMode == DurationMode.rotations) {
    final steps = await ref.watch(
      cycleStepsForProgramProvider(programId).future,
    );
    totalSessions =
        steps.isEmpty ? program.durationValue : program.durationValue * steps.length;
  } else {
    totalSessions = program.durationValue;
  }

  return ProgramProgressInfo(
    completedSessions: sessionCount,
    totalSessions: totalSessions,
  );
}

/// Notifier for program mutations (create, update, activate, archive).
@riverpod
class ProgramActions extends _$ProgramActions {
  @override
  FutureOr<void> build() {}

  Future<int> createProgram(TrainingProgram program) async {
    final repo = ref.read(programRepositoryProvider);
    final result = await repo.create(program);
    final id = result.getOrThrow();
    ref.invalidate(programListProvider);
    ref.invalidate(activeProgramProvider);
    return id;
  }

  Future<void> updateProgram(TrainingProgram program) async {
    final repo = ref.read(programRepositoryProvider);
    final result = await repo.update(program);
    result.getOrThrow();
    ref.invalidate(programListProvider);
    ref.invalidate(activeProgramProvider);
  }

  Future<void> activateProgram(int programId) async {
    final repo = ref.read(programRepositoryProvider);
    final result = await repo.activate(programId);
    result.getOrThrow();
    ref.invalidate(programListProvider);
    ref.invalidate(activeProgramProvider);
  }

  Future<void> archiveProgram(int programId) async {
    final repo = ref.read(programRepositoryProvider);
    final result = await repo.archive(programId);
    result.getOrThrow();
    ref.invalidate(programListProvider);
    ref.invalidate(activeProgramProvider);
  }
}
