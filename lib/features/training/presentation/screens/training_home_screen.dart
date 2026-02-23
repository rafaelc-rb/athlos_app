import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/athlos_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/equipment_notifier.dart';
import '../providers/exercise_notifier.dart';

/// Training module — Home / Dashboard tab.
class TrainingHomeScreen extends ConsumerWidget {
  const TrainingHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final userIdsAsync = ref.watch(userEquipmentIdsProvider);
    final selectedEquipmentCount = userIdsAsync.value?.length ?? 0;

    final exercisesAsync = ref.watch(exerciseListProvider);
    final exerciseCount = exercisesAsync.value?.length ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AthlosSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Catalogs section
          Text(
            l10n.catalogsSection,
            style: textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const Gap(AthlosSpacing.sm),

          _CatalogCard(
            icon: Icons.sports_gymnastics,
            title: l10n.exercisesCatalog,
            subtitle: exerciseCount > 0
                ? l10n.exercisesCount(exerciseCount)
                : l10n.exercisesCatalogDesc,
            onTap: () => context.go(RoutePaths.trainingExercises),
          ),
          const Gap(AthlosSpacing.sm),

          _CatalogCard(
            icon: Icons.fitness_center,
            title: l10n.myEquipment,
            subtitle: selectedEquipmentCount > 0
                ? l10n.equipmentSelected(selectedEquipmentCount)
                : l10n.myEquipmentDesc,
            onTap: () => context.go(RoutePaths.trainingEquipment),
          ),
        ],
      ),
    );
  }
}

class _CatalogCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _CatalogCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AthlosSpacing.md),
          child: Row(
            children: [
              Icon(icon, size: 32, color: colorScheme.primary),
              const Gap(AthlosSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: textTheme.titleMedium),
                    const Gap(2),
                    Text(
                      subtitle,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
