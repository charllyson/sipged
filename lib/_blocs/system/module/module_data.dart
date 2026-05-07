// lib/_blocs/system/module/module_data.dart

import 'package:flutter/material.dart';

enum ModuleEnum {
  overviewDashboard,
  specificDashboard,

  processHiringRecords,
  processValidityRecords,
  processAdditiveRecords,
  processApostillesRecords,
  processMeasurementsRecords,
  processHiringBudget,

  operationMonitoringWork,

  planningProjectRegistration,
  planningRightOfWayRecords,

  trafficAccidentsDashboard,
  trafficAccidentsRecords,
  trafficInfractionsDashboard,
  trafficInfractionsRecords,

  financialDashboard,
  financialCommitmentRecords,

  activeRoadRegistration,
  activeRoadNetwork,

  activeOAEsRegistration,
  activesOAEsNetwork,
}

class ModuleData {
  final String labelModule;
  final ModuleEnum menuModuleItem;
  final String permissionModule;

  /// Cor do texto do módulo no Drawer.
  final Color colorModuleLabel;

  /// Ícone exclusivo do card da Home.
  /// Se null, herda o ícone da seção.
  final IconData? homeModuleIcon;

  /// Cor exclusiva do card da Home.
  /// Se null, usa fallback calculado pelo ModuleGrid.
  final Color? homeModuleColor;

  const ModuleData({
    required this.labelModule,
    required this.menuModuleItem,
    required this.permissionModule,
    this.colorModuleLabel = Colors.white70,
    this.homeModuleIcon,
    this.homeModuleColor,
  });
}

class ModuleGroupData {
  final String labelSection;
  final IconData iconSection;

  /// Cor do título/grupo da seção no Drawer.
  final Color colorSectionLabel;

  final List<ModuleData> moduleItems;

  const ModuleGroupData({
    required this.labelSection,
    required this.iconSection,
    required this.moduleItems,
    this.colorSectionLabel = Colors.white,
  });

  ModuleGroupData copyWith({
    String? labelSection,
    IconData? iconSection,
    Color? colorSectionLabel,
    List<ModuleData>? moduleItems,
  }) {
    return ModuleGroupData(
      labelSection: labelSection ?? this.labelSection,
      iconSection: iconSection ?? this.iconSection,
      colorSectionLabel: colorSectionLabel ?? this.colorSectionLabel,
      moduleItems: moduleItems ?? this.moduleItems,
    );
  }
}