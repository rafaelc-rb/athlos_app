import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../router/route_paths.dart';
import '../services/gemini_config.dart';
import '../theme/athlos_elevation.dart';
import '../theme/athlos_radius.dart';
import '../theme/athlos_spacing.dart';
import '../theme/theme_mode_provider.dart';
import '../../features/chiron/presentation/widgets/chiron_bottom_sheet.dart';
import '../../l10n/app_localizations.dart';

/// App bar actions: Chiron (if configured) + hamburger menu (Home, Profile, Theme).
/// Use in [AppBar.actions] so the same menu is available from any screen.
/// Menu opens below the icon with mobile-style styling.
class AppBarMenu extends ConsumerWidget {
  const AppBarMenu({super.key});

  static const _itemPadding = EdgeInsets.symmetric(
    horizontal: AthlosSpacing.sm,
    vertical: AthlosSpacing.xxs,
  );
  static const double _menuItemHeight = 34;
  static const double _menuIconSize = 18;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isGeminiConfigured)
          IconButton(
            icon: const Icon(Icons.auto_awesome_outlined),
            tooltip: l10n.chironTitle,
            onPressed: () => showChironSheet(context),
          ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.menu),
          position: PopupMenuPosition.under,
          offset: const Offset(0, AthlosSpacing.xs),
          elevation: AthlosElevation.sm,
          shape: RoundedRectangleBorder(
            borderRadius: AthlosRadius.mdAll,
          ),
          color: colorScheme.surfaceContainerHigh,
          surfaceTintColor: Colors.transparent,
          onSelected: (value) {
            switch (value) {
              case 'home':
                context.go(RoutePaths.hub);
              case 'profile':
                context.push(RoutePaths.profile);
              case 'theme':
                try {
                  ref.read(themeModeProvider.notifier).toggle();
                } on Exception catch (_) {}
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'home',
              height: _menuItemHeight,
              padding: EdgeInsets.zero,
              child: Padding(
                padding: _itemPadding,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.home_outlined,
                      size: _menuIconSize,
                      color: colorScheme.onSurface,
                    ),
                    const SizedBox(width: AthlosSpacing.xs),
                    Text(
                      l10n.backToHub,
                      style: theme.textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
            ),
            const PopupMenuDivider(height: 1),
            PopupMenuItem(
              value: 'profile',
              height: _menuItemHeight,
              padding: EdgeInsets.zero,
              child: Padding(
                padding: _itemPadding,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: _menuIconSize,
                      color: colorScheme.onSurface,
                    ),
                    const SizedBox(width: AthlosSpacing.xs),
                    Text(
                      l10n.profile,
                      style: theme.textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
            ),
            const PopupMenuDivider(height: 1),
            PopupMenuItem(
              value: 'theme',
              height: _menuItemHeight,
              padding: EdgeInsets.zero,
              child: Padding(
                padding: _itemPadding,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      ref.watch(themeModeProvider.notifier).icon,
                      size: _menuIconSize,
                      color: colorScheme.onSurface,
                    ),
                    const SizedBox(width: AthlosSpacing.xs),
                    Text(
                      l10n.toggleTheme,
                      style: theme.textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
