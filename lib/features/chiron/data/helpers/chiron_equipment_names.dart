import 'dart:ui' show Locale;

import '../../../../core/localization/domain_label_resolver.dart';
import '../../../../l10n/app_localizations.dart';

final AppLocalizations _ptBrL10n = lookupAppLocalizations(const Locale('pt'));
final DomainLabelResolver _resolver = DomainLabelResolver(_ptBrL10n);

String chironEquipmentDisplayName({
  required String canonicalName,
  required bool isVerified,
}) {
  return _resolver.toDisplayName(
    kind: DomainLabelKind.equipment,
    canonicalName: canonicalName,
    isVerified: isVerified,
  );
}

String chironCanonicalEquipmentName(String candidate) {
  return _resolver.toCanonicalName(
    kind: DomainLabelKind.equipment,
    candidate: candidate,
  );
}
