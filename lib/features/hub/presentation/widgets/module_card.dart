import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

/// A card representing a module on the Hub screen.
///
/// Example of a reusable feature-specific widget following conventions:
/// - Colors from Theme, never hardcoded
/// - Strings received as parameters (caller uses AppLocalizations)
/// - const constructor
/// - SizedBox/Gap for spacing instead of Padding
class ModuleCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool isEnabled;
  final String? disabledLabel;
  final VoidCallback? onTap;

  const ModuleCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.isEnabled = true,
    this.disabledLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Always get colors and text styles from the theme
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: isEnabled ? 2 : 0,
      color: isEnabled
          ? colorScheme.surfaceContainerLow
          : colorScheme.surfaceContainerLow.withAlpha(128),
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Module icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isEnabled
                      ? colorScheme.primaryContainer
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: isEnabled
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              const Gap(16),

              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(
                        color: isEnabled
                            ? colorScheme.onSurface
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      description,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow or "coming soon" badge
              if (isEnabled)
                Icon(
                  Icons.chevron_right,
                  color: colorScheme.onSurfaceVariant,
                )
              else if (disabledLabel != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    disabledLabel!,
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
