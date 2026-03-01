import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/athlos_durations.dart';
import '../../../../core/theme/athlos_elevation.dart';
import '../../../../core/theme/athlos_radius.dart';
import '../../../../core/theme/athlos_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/enums/experience_level.dart';

/// Selector for [ExperienceLevel].
class ExperienceSelector extends StatelessWidget {
  final ExperienceLevel? selected;
  final ValueChanged<ExperienceLevel> onSelected;
  final bool shouldShowHelp;

  const ExperienceSelector({
    super.key,
    required this.selected,
    required this.onSelected,
    this.shouldShowHelp = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.experienceSelectTitle, style: textTheme.titleMedium),
        const Gap(AthlosSpacing.md),
        ...ExperienceLevel.values.map((level) {
          final isSelected = level == selected;
          return Padding(
            padding: const EdgeInsets.only(bottom: AthlosSpacing.sm),
            child: Card(
              clipBehavior: Clip.antiAlias,
              elevation:
                  isSelected ? AthlosElevation.sm : AthlosElevation.none,
              color: isSelected
                  ? colorScheme.primaryContainer
                  : colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: AthlosRadius.mdAll,
                side: isSelected
                    ? BorderSide(color: colorScheme.primary, width: 2)
                    : BorderSide.none,
              ),
              child: InkWell(
                onTap: () => onSelected(level),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AthlosSpacing.md,
                    vertical: AthlosSpacing.smd,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            _iconFor(level),
                            color: isSelected
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSurfaceVariant,
                          ),
                          const Gap(AthlosSpacing.smd),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _titleFor(level, l10n),
                                  style: textTheme.titleSmall?.copyWith(
                                    color: isSelected
                                        ? colorScheme.onPrimaryContainer
                                        : colorScheme.onSurface,
                                  ),
                                ),
                                Text(
                                  _descriptionFor(level, l10n),
                                  style: textTheme.bodySmall?.copyWith(
                                    color: isSelected
                                        ? colorScheme.onPrimaryContainer
                                        : colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: colorScheme.primary,
                            ),
                        ],
                      ),
                      AnimatedSize(
                        duration: AthlosDurations.normal,
                        curve: Curves.easeInOut,
                        child: shouldShowHelp
                            ? Padding(
                                padding: const EdgeInsets.only(
                                    top: AthlosSpacing.smd),
                                child: Container(
                                  width: double.infinity,
                                  padding:
                                      const EdgeInsets.all(AthlosSpacing.smd),
                                  decoration: BoxDecoration(
                                    borderRadius: AthlosRadius.smAll,
                                    color: colorScheme.surfaceContainerHighest
                                        .withAlpha(120),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        size: 16,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      const Gap(AthlosSpacing.sm),
                                      Expanded(
                                        child: Text(
                                          _impactFor(level, l10n),
                                          style:
                                              textTheme.bodySmall?.copyWith(
                                            color:
                                                colorScheme.onSurfaceVariant,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  IconData _iconFor(ExperienceLevel level) => switch (level) {
        ExperienceLevel.beginner => Icons.emoji_events_outlined,
        ExperienceLevel.intermediate => Icons.trending_up,
        ExperienceLevel.advanced => Icons.military_tech,
      };

  String _titleFor(ExperienceLevel level, AppLocalizations l10n) =>
      switch (level) {
        ExperienceLevel.beginner => l10n.experienceBeginner,
        ExperienceLevel.intermediate => l10n.experienceIntermediate,
        ExperienceLevel.advanced => l10n.experienceAdvanced,
      };

  String _descriptionFor(ExperienceLevel level, AppLocalizations l10n) =>
      switch (level) {
        ExperienceLevel.beginner => l10n.experienceBeginnerDesc,
        ExperienceLevel.intermediate => l10n.experienceIntermediateDesc,
        ExperienceLevel.advanced => l10n.experienceAdvancedDesc,
      };

  String _impactFor(ExperienceLevel level, AppLocalizations l10n) =>
      switch (level) {
        ExperienceLevel.beginner => l10n.experienceBeginnerImpact,
        ExperienceLevel.intermediate => l10n.experienceIntermediateImpact,
        ExperienceLevel.advanced => l10n.experienceAdvancedImpact,
      };
}
