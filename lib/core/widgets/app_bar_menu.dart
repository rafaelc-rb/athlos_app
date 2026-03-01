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
    vertical: AthlosSpacing.xs,
  );
  static const double _minLeadingWidth = 28;

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
              child: ListTile(
                leading: Icon(Icons.home_outlined, color: colorScheme.onSurface),
                title: Text(l10n.backToHub),
                contentPadding: _itemPadding,
                minLeadingWidth: _minLeadingWidth,
                dense: true,
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'profile',
              child: ListTile(
                leading: Icon(Icons.person_outline, color: colorScheme.onSurface),
                title: Text(l10n.profile),
                contentPadding: _itemPadding,
                minLeadingWidth: _minLeadingWidth,
                dense: true,
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'theme',
              child: ListTile(
                leading: Icon(
                  ref.watch(themeModeProvider.notifier).icon,
                  color: colorScheme.onSurface,
                ),
                title: Text(l10n.toggleTheme),
                contentPadding: _itemPadding,
                minLeadingWidth: _minLeadingWidth,
                dense: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
