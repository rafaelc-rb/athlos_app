import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../l10n/app_localizations.dart';
import '../widgets/equipment_management_body.dart';

/// Equipment screen.
class EquipmentScreen extends StatelessWidget {
  const EquipmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.equipmentScreenTitle)),
      body: EquipmentManagementBody(
        catalogOnly: true,
        defaultCatalogOpen: true,
        allowCustomManagement: false,
        onEquipmentTap: (equipment) {
          context.push(RoutePaths.trainingEquipmentDetail(equipment.id));
        },
      ),
    );
  }
}
