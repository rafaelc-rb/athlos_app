import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/equipment_notifier.dart';

/// Training module — Home / Dashboard tab.
class TrainingHomeScreen extends ConsumerWidget {
  const TrainingHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final userIdsAsync = ref.watch(userEquipmentIdsProvider);
    final selectedCount = userIdsAsync.value?.length ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Equipment card
          Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => context.go(RoutePaths.trainingEquipment),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.fitness_center,
                      size: 32,
                      color: colorScheme.primary,
                    ),
                    const Gap(16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.myEquipment,
                            style: textTheme.titleMedium,
                          ),
                          const Gap(2),
                          Text(
                            selectedCount > 0
                                ? l10n.equipmentSelected(selectedCount)
                                : l10n.myEquipmentDesc,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
