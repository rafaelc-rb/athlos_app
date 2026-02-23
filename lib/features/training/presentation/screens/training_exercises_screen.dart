import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/athlos_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/enums/muscle_group.dart';
import '../helpers/exercise_l10n.dart';
import '../providers/exercise_notifier.dart';
import '../widgets/exercise_tile.dart';
import '../widgets/muscle_group_filter.dart';

/// Training module — Exercises tab (EX-01 to EX-05).
///
/// Displays the exercise catalog with muscle group filtering and search.
class TrainingExercisesScreen extends ConsumerStatefulWidget {
  const TrainingExercisesScreen({super.key});

  @override
  ConsumerState<TrainingExercisesScreen> createState() =>
      _TrainingExercisesScreenState();
}

class _TrainingExercisesScreenState
    extends ConsumerState<TrainingExercisesScreen> {
  MuscleGroup? _selectedGroup;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final exercisesAsync = ref.watch(exerciseListProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AthlosSpacing.md,
            AthlosSpacing.sm,
            AthlosSpacing.md,
            0,
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: l10n.searchExercises,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ),
        const Gap(AthlosSpacing.sm),
        MuscleGroupFilter(
          selected: _selectedGroup,
          onSelected: (group) => setState(() => _selectedGroup = group),
        ),
        const Gap(AthlosSpacing.xs),
        Expanded(
          child: exercisesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('$error')),
            data: (exercises) {
              final filtered = _filterExercises(exercises, l10n);

              if (filtered.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AthlosSpacing.xl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.sports_gymnastics,
                          size: 48,
                          color: colorScheme.onSurfaceVariant.withAlpha(100),
                        ),
                        const Gap(AthlosSpacing.md),
                        Text(
                          l10n.emptyExercises,
                          style: textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final exercise = filtered[index];
                  return ExerciseTile(
                    key: ValueKey(exercise.id),
                    displayName: localizedExerciseName(
                      exercise.name,
                      isVerified: exercise.isVerified,
                      l10n: l10n,
                    ),
                    muscleGroupLabel:
                        localizedMuscleGroupName(exercise.muscleGroup, l10n),
                    targetMusclesLabel:
                        localizedTargetMuscles(exercise.targetMuscles, l10n),
                    onTap: () => context.push(
                      '${RoutePaths.trainingExercises}/${exercise.id}',
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  List<Exercise> _filterExercises(
      List<Exercise> exercises, AppLocalizations l10n) {
    var filtered = exercises.toList();

    if (_selectedGroup != null) {
      filtered =
          filtered.where((e) => e.muscleGroup == _selectedGroup).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((e) {
        final name = localizedExerciseName(
          e.name,
          isVerified: e.isVerified,
          l10n: l10n,
        ).toLowerCase();
        return name.contains(query);
      }).toList();
    }

    filtered.sort((a, b) {
      final nameA = localizedExerciseName(a.name,
          isVerified: a.isVerified, l10n: l10n);
      final nameB = localizedExerciseName(b.name,
          isVerified: b.isVerified, l10n: l10n);
      return nameA.compareTo(nameB);
    });

    return filtered;
  }
}
