import 'package:flutter/material.dart';

import '../../../../core/theme/athlos_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/enums/muscle_group.dart';
import '../helpers/exercise_l10n.dart';

/// Horizontal scrollable filter chips for muscle groups.
///
/// [selected] is null when "All" is active.
class MuscleGroupFilter extends StatelessWidget {
  final MuscleGroup? selected;
  final ValueChanged<MuscleGroup?> onSelected;

  const MuscleGroupFilter({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AthlosSpacing.md),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: AthlosSpacing.sm),
            child: FilterChip(
              label: Text(l10n.filterAll),
              selected: selected == null,
              onSelected: (_) => onSelected(null),
            ),
          ),
          ...MuscleGroup.values.map((group) => Padding(
                padding: const EdgeInsets.only(right: AthlosSpacing.sm),
                child: FilterChip(
                  label: Text(localizedMuscleGroupName(group, l10n)),
                  selected: selected == group,
                  onSelected: (_) => onSelected(group),
                ),
              )),
        ],
      ),
    );
  }
}
