import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/equipment.dart';
import '../../domain/enums/equipment_category.dart';
import '../helpers/equipment_l10n.dart';
import '../providers/equipment_notifier.dart';
import '../widgets/equipment_tile.dart';

/// Equipment screen (E-01, E-02, E-03).
///
/// Default view shows only the user's equipment as a flat list.
/// Tapping the search bar opens the catalog — a flat alphabetical
/// list of unowned items, each showing its category as subtitle.
class EquipmentScreen extends ConsumerStatefulWidget {
  const EquipmentScreen({super.key});

  @override
  ConsumerState<EquipmentScreen> createState() => _EquipmentScreenState();
}

class _EquipmentScreenState extends ConsumerState<EquipmentScreen> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  String _searchQuery = '';
  bool _isCatalogOpen = false;

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(() {
      if (_searchFocus.hasFocus && !_isCatalogOpen) {
        setState(() => _isCatalogOpen = true);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _closeCatalog() {
    _searchController.clear();
    _searchFocus.unfocus();
    setState(() {
      _searchQuery = '';
      _isCatalogOpen = false;
    });
  }

  List<Equipment> _sortAlphabetically(
      List<Equipment> items, AppLocalizations l10n) {
    return items
      ..sort((a, b) {
        final nameA = localizedEquipmentName(a.name,
            isVerified: a.isVerified, l10n: l10n);
        final nameB = localizedEquipmentName(b.name,
            isVerified: b.isVerified, l10n: l10n);
        return nameA.compareTo(nameB);
      });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final equipmentAsync = ref.watch(equipmentListProvider);
    final userIdsAsync = ref.watch(userEquipmentIdsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.equipmentScreenTitle)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        tooltip: l10n.addEquipment,
        child: const Icon(Icons.add),
      ),
      body: equipmentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (allEquipment) {
          final userIds = userIdsAsync.value ?? <int>{};

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocus,
                  decoration: InputDecoration(
                    hintText: l10n.searchEquipment,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _isCatalogOpen
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: _closeCatalog,
                          )
                        : null,
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
              const Gap(8),
              Expanded(
                child: _isCatalogOpen
                    ? _buildCatalog(allEquipment, userIds, l10n, colorScheme,
                        textTheme)
                    : _buildUserList(allEquipment, userIds, l10n, colorScheme,
                        textTheme),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUserList(
    List<Equipment> allEquipment,
    Set<int> userIds,
    AppLocalizations l10n,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final owned = _sortAlphabetically(
      allEquipment.where((e) => userIds.contains(e.id)).toList(),
      l10n,
    );

    if (owned.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.fitness_center,
                size: 48,
                color: colorScheme.onSurfaceVariant.withAlpha(100),
              ),
              const Gap(16),
              Text(
                l10n.emptyEquipment,
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const Gap(8),
              Text(
                l10n.emptyEquipmentHint,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: owned.length,
      itemBuilder: (context, index) {
        final equipment = owned[index];
        return EquipmentTile(
          key: ValueKey(equipment.id),
          displayName: localizedEquipmentName(
            equipment.name,
            isVerified: equipment.isVerified,
            l10n: l10n,
          ),
          category: localizedCategoryName(equipment.category, l10n),
          trailing: IconButton(
            icon: Icon(Icons.remove_circle_outline, color: colorScheme.error),
            tooltip: l10n.removeEquipment,
            onPressed: () => ref
                .read(userEquipmentIdsProvider.notifier)
                .toggle(equipment.id),
          ),
        );
      },
    );
  }

  Widget _buildCatalog(
    List<Equipment> allEquipment,
    Set<int> userIds,
    AppLocalizations l10n,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final query = _searchQuery.toLowerCase();
    final results = _sortAlphabetically(
      allEquipment.where((e) {
        if (userIds.contains(e.id)) return false;
        if (query.isEmpty) return true;
        final displayName = localizedEquipmentName(
          e.name,
          isVerified: e.isVerified,
          l10n: l10n,
        ).toLowerCase();
        return displayName.contains(query);
      }).toList(),
      l10n,
    );

    if (results.isEmpty) {
      return Center(
        child: Text(
          l10n.addEquipment,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final equipment = results[index];
        return EquipmentTile(
          key: ValueKey(equipment.id),
          displayName: localizedEquipmentName(
            equipment.name,
            isVerified: equipment.isVerified,
            l10n: l10n,
          ),
          category: localizedCategoryName(equipment.category, l10n),
          trailing: IconButton(
            icon: Icon(Icons.add_circle_outline, color: colorScheme.primary),
            onPressed: () => ref
                .read(userEquipmentIdsProvider.notifier)
                .toggle(equipment.id),
          ),
        );
      },
    );
  }

  void _showAddDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => const _AddEquipmentDialog(),
    );
  }
}

/// Dialog to add a user-created equipment (E-03).
class _AddEquipmentDialog extends ConsumerStatefulWidget {
  const _AddEquipmentDialog();

  @override
  ConsumerState<_AddEquipmentDialog> createState() =>
      _AddEquipmentDialogState();
}

class _AddEquipmentDialogState extends ConsumerState<_AddEquipmentDialog> {
  final _nameController = TextEditingController();
  EquipmentCategory _selectedCategory = EquipmentCategory.accessories;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.addEquipment),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: l10n.equipmentNameLabel,
            ),
            textCapitalization: TextCapitalization.sentences,
            autofocus: true,
          ),
          const Gap(16),
          DropdownButtonFormField<EquipmentCategory>(
            value: _selectedCategory,
            decoration: InputDecoration(
              labelText: l10n.equipmentCategoryLabel,
            ),
            items: EquipmentCategory.values.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Text(localizedCategoryName(category, l10n)),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedCategory = value);
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _onSave,
          child: Text(l10n.save),
        ),
      ],
    );
  }

  Future<void> _onSave() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    await ref.read(equipmentListProvider.notifier).addUserEquipment(
          name: name,
          category: _selectedCategory,
        );

    ref.invalidate(userEquipmentIdsProvider);

    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}
