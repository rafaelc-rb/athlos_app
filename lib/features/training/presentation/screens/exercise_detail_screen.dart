import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/athlos_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../helpers/equipment_l10n.dart';
import '../helpers/exercise_l10n.dart';
import '../providers/equipment_notifier.dart';
import '../providers/exercise_notifier.dart';

/// Detail screen for a single exercise (EX-03, EX-04, EX-05).
///
/// Shows muscle group, target muscles, muscle region,
/// required equipment, and variations.
class ExerciseDetailScreen extends ConsumerWidget {
  final int exerciseId;

  const ExerciseDetailScreen({super.key, required this.exerciseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final allExercisesAsync = ref.watch(exerciseListProvider);

    return allExercisesAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('$error')),
      ),
      data: (exercises) {
        final exercise = exercises
            .where((e) => e.id == exerciseId)
            .firstOrNull;

        if (exercise == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(l10n.exerciseNotFound)),
          );
        }

        final displayName = localizedExerciseName(
          exercise.name,
          isVerified: exercise.isVerified,
          l10n: l10n,
        );

        return Scaffold(
          appBar: AppBar(title: Text(displayName)),
          body: ListView(
            padding: const EdgeInsets.all(AthlosSpacing.md),
            children: [
              _buildInfoSection(
                context,
                icon: Icons.sports_gymnastics,
                title: l10n.exerciseDetailMuscleGroup,
                value: localizedMuscleGroupName(exercise.muscleGroup, l10n),
                colorScheme: colorScheme,
                textTheme: textTheme,
              ),
              if (exercise.targetMuscles != null &&
                  exercise.targetMuscles!.isNotEmpty) ...[
                const Gap(AthlosSpacing.md),
                _buildInfoSection(
                  context,
                  icon: Icons.my_location,
                  title: l10n.exerciseDetailTargetMuscles,
                  value: localizedTargetMuscles(exercise.targetMuscles, l10n),
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                ),
              ],
              if (exercise.muscleRegion != null &&
                  exercise.muscleRegion!.isNotEmpty) ...[
                const Gap(AthlosSpacing.md),
                _buildInfoSection(
                  context,
                  icon: Icons.pin_drop_outlined,
                  title: l10n.exerciseDetailMuscleRegion,
                  value: localizedMuscleRegion(exercise.muscleRegion, l10n),
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                ),
              ],
              const Gap(AthlosSpacing.lg),
              _EquipmentSection(exerciseId: exerciseId),
              const Gap(AthlosSpacing.lg),
              _VariationsSection(
                exerciseId: exerciseId,
                currentExerciseName: displayName,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const Gap(AthlosSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const Gap(AthlosSpacing.xs),
              Text(value, style: textTheme.bodyLarge),
            ],
          ),
        ),
      ],
    );
  }
}

/// Shows equipment required for the exercise.
class _EquipmentSection extends ConsumerWidget {
  final int exerciseId;

  const _EquipmentSection({required this.exerciseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final equipmentIdsAsync = ref.watch(exerciseEquipmentIdsProvider(exerciseId));
    final allEquipmentAsync = ref.watch(equipmentListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.fitness_center, size: 20, color: colorScheme.primary),
            const Gap(AthlosSpacing.sm),
            Text(
              l10n.exerciseDetailEquipment,
              style: textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const Gap(AthlosSpacing.sm),
        equipmentIdsAsync.when(
          loading: () => const SizedBox(
            height: 32,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (error, _) => Text('$error'),
          data: (eqIds) {
            if (eqIds.isEmpty) {
              return Padding(
                padding: const EdgeInsets.only(left: 28),
                child: Text(
                  l10n.exerciseNoEquipment,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            }

            return allEquipmentAsync.when(
              loading: () => const SizedBox(
                height: 32,
                child:
                    Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (error, _) => Text('$error'),
              data: (allEquipment) {
                final linked = allEquipment
                    .where((eq) => eqIds.contains(eq.id))
                    .toList();

                return Padding(
                  padding: const EdgeInsets.only(left: 28),
                  child: Wrap(
                    spacing: AthlosSpacing.sm,
                    runSpacing: AthlosSpacing.xs,
                    children: linked
                        .map((eq) => Chip(
                              label: Text(
                                localizedEquipmentName(
                                  eq.name,
                                  isVerified: eq.isVerified,
                                  l10n: l10n,
                                ),
                              ),
                              visualDensity: VisualDensity.compact,
                            ))
                        .toList(),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

/// Shows exercise variations.
class _VariationsSection extends ConsumerWidget {
  final int exerciseId;
  final String currentExerciseName;

  const _VariationsSection({
    required this.exerciseId,
    required this.currentExerciseName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final variationsAsync = ref.watch(exerciseVariationsProvider(exerciseId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.swap_horiz, size: 20, color: colorScheme.primary),
            const Gap(AthlosSpacing.sm),
            Text(
              l10n.exerciseDetailVariations,
              style: textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const Gap(AthlosSpacing.sm),
        variationsAsync.when(
          loading: () => const SizedBox(
            height: 32,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (error, _) => Text('$error'),
          data: (variations) {
            if (variations.isEmpty) {
              return Padding(
                padding: const EdgeInsets.only(left: 28),
                child: Text(
                  l10n.exerciseNoVariations,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.only(left: 28),
              child: Column(
                children: variations.map((v) {
                  final name = localizedExerciseName(
                    v.name,
                    isVerified: v.isVerified,
                    l10n: l10n,
                  );
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(name),
                    subtitle: Text(
                      localizedMuscleGroupName(v.muscleGroup, l10n),
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) =>
                              ExerciseDetailScreen(exerciseId: v.id),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }
}
