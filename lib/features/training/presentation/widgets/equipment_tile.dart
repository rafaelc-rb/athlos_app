import 'package:flutter/material.dart';

import '../../../../core/theme/athlos_radius.dart';
import '../../../../core/theme/athlos_spacing.dart';

/// Equipment item tile showing name, category subtitle, and a trailing action.
///
/// When [categoryDescription] is provided, tapping the category text shows
/// a tooltip with the description.
class EquipmentTile extends StatelessWidget {
  final String displayName;
  final String category;
  final String? categoryDescription;
  final Widget? trailing;

  const EquipmentTile({
    super.key,
    required this.displayName,
    required this.category,
    this.categoryDescription,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final categoryWidget = categoryDescription != null
        ? Tooltip(
            message: categoryDescription!,
            preferBelow: true,
            verticalOffset: 14,
            decoration: BoxDecoration(
              color: colorScheme.inverseSurface,
              borderRadius: AthlosRadius.smAll,
            ),
            textStyle: textTheme.bodySmall?.copyWith(
              color: colorScheme.onInverseSurface,
            ),
            triggerMode: TooltipTriggerMode.tap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  category,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: AthlosSpacing.xs),
                Icon(
                  Icons.info_outline,
                  size: 12,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ],
            ),
          )
        : Text(
            category,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          );

    return ListTile(
      title: Text(displayName, style: textTheme.bodyMedium),
      subtitle: categoryWidget,
      trailing: trailing,
    );
  }
}
