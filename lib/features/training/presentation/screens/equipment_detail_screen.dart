import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/athlos_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../helpers/equipment_l10n.dart';
import '../providers/equipment_notifier.dart';

class EquipmentDetailScreen extends ConsumerWidget {
  final int equipmentId;

  const EquipmentDetailScreen({super.key, required this.equipmentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final equipmentAsync = ref.watch(equipmentByIdProvider(equipmentId));
    final userIdsAsync = ref.watch(userEquipmentIdsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.equipmentScreenTitle),
      ),
      body: equipmentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text(l10n.genericError)),
        data: (equipment) {
          if (equipment == null) {
            return Center(
              child: Text(
                l10n.genericError,
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }

          final displayName = localizedEquipmentName(
            equipment.name,
            isVerified: equipment.isVerified,
            l10n: l10n,
          );
          final categoryName = localizedCategoryName(equipment.category, l10n);
          final categoryDescription =
              localizedCategoryDescription(equipment.category, l10n);
          final isOwned =
              userIdsAsync.asData?.value.contains(equipment.id) ?? false;

          return ListView(
            padding: const EdgeInsets.all(AthlosSpacing.md),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AthlosSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.fitness_center,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: AthlosSpacing.sm),
                          Expanded(
                            child: Text(
                              displayName,
                              style: textTheme.titleLarge,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AthlosSpacing.sm),
                      Text(
                        categoryName,
                        style: textTheme.titleSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AthlosSpacing.xs),
                      Text(
                        categoryDescription,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if ((equipment.description ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: AthlosSpacing.md),
                        Text(
                          equipment.description!,
                          style: textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AthlosSpacing.md),
              Card(
                child: SwitchListTile.adaptive(
                  title: Text(l10n.iOwnEquipment),
                  subtitle: Text(
                    isOwned ? l10n.equipmentMarkedAsOwned : l10n.equipmentNotOwned,
                  ),
                  value: isOwned,
                  onChanged: userIdsAsync.isLoading
                      ? null
                      : (_) async {
                          try {
                            await ref
                                .read(userEquipmentIdsProvider.notifier)
                                .toggle(equipment.id);
                          } on Exception catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(l10n.genericError)),
                              );
                            }
                          }
                        },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
