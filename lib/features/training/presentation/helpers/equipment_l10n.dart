import '../../../../core/localization/domain_label_resolver.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/enums/equipment_category.dart';

/// Maps a verified equipment's English key [name] to its localized display name.
/// Falls back to [name] directly for unverified (user-created) items.
String localizedEquipmentName(
  String name, {
  required bool isVerified,
  required AppLocalizations l10n,
}) {
  final resolver = DomainLabelResolver(l10n);
  return resolver.toDisplayName(
    kind: DomainLabelKind.equipment,
    canonicalName: name,
    isVerified: isVerified,
  );
}

/// Returns the localized display name for an [EquipmentCategory].
String localizedCategoryName(
  EquipmentCategory category,
  AppLocalizations l10n,
) => switch (category) {
  EquipmentCategory.freeWeights => l10n.categoryFreeWeights,
  EquipmentCategory.machines => l10n.categoryMachines,
  EquipmentCategory.structures => l10n.categoryStructures,
  EquipmentCategory.accessories => l10n.categoryAccessories,
  EquipmentCategory.cardio => l10n.categoryCardio,
};

/// Returns a short description of what belongs in an [EquipmentCategory].
String localizedCategoryDescription(
  EquipmentCategory category,
  AppLocalizations l10n,
) => switch (category) {
  EquipmentCategory.freeWeights => l10n.categoryFreeWeightsDesc,
  EquipmentCategory.machines => l10n.categoryMachinesDesc,
  EquipmentCategory.structures => l10n.categoryStructuresDesc,
  EquipmentCategory.accessories => l10n.categoryAccessoriesDesc,
  EquipmentCategory.cardio => l10n.categoryCardioDesc,
};
