import 'package:flutter/material.dart';

/// Equipment item tile showing name, category subtitle, and a trailing action.
class EquipmentTile extends StatelessWidget {
  final String displayName;
  final String category;
  final Widget? trailing;

  const EquipmentTile({
    super.key,
    required this.displayName,
    required this.category,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListTile(
      title: Text(displayName, style: textTheme.bodyMedium),
      subtitle: Text(
        category,
        style: textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: trailing,
    );
  }
}
