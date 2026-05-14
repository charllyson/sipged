import 'package:flutter/material.dart';

import 'package:sipged/_utils/theme/sipged_theme.dart';

import 'module_data.dart';

class ModuleCatalog {
  // ===========================================================================
  // IDS CANÔNICOS DOS MÓDULOS
  // ===========================================================================

  // GESTÃO DE CONTRATOS
  static const String modContractsList = modHiringRecords;
  static const String modOverviewDashboard = 'overview-overview-dashboard';
  static const String modSpecificDashboard = 'specific-overview-dashboard';
  static const String modHiringRecords = 'operation-hiring-records';
  static const String modValidityRecords = 'operation-validity-records';
  static const String modAdditiveRecords = 'operation-additive-records';
  static const String modApostillesRecords = 'operation-apostilles-records';
  static const String modMeasurementsRecords = 'operation-measurements-records';
  static const String modHiringBudget = 'operation-hiring-budget';
  static const String modFinancialPaymentsDashboard =
      'financial-payments-overview-dashboard';

  // OPERACIONAL
  static const String modWorkTimeline = 'operation-work-timeline';

  // PLANEJAMENTO
  static const String modPlanningSigmineRecords = 'planning-sigmine-records';

  // TRÁFEGO
  static const String modTrafficAccidentsDashboard =
      'traffic-accidents-overview-dashboard';
  static const String modTrafficAccidentsRecords = 'traffic-accidents-records';
  static const String modTrafficInfractionsDashboard =
      'traffic-infractions-overview-dashboard';
  static const String modTrafficInfractionsRecords =
      'traffic-infractions-records';

  // ATIVOS
  static const String modActiveRoadRecords = 'active-road-records';
  static const String modActiveRoadNetwork = 'active-road-network';
  static const String modActiveOAEsRecords = 'active-oaes-records';
  static const String modActiveOAEsNetwork = 'active-oaes-network';

  static final List<String> module = allPermissionModules;

  // ===========================================================================
  // CONTRATOS
  // ===========================================================================

  static final List<ModuleGroupData> drawerDocuments = [
    ModuleGroupData(
      labelSection: 'GESTÃO DE CONTRATOS',
      iconSection: Icons.document_scanner,
      colorSectionLabel: SipGedTheme.drawerSectionLabelColor,
      moduleItems: const [
        ModuleData(
          labelModule: 'PAINEL GERAL',
          menuModuleItem: ModuleEnum.overviewDashboard,
          permissionModule: modOverviewDashboard,
          colorModuleLabel: SipGedTheme.drawerModuleLabelColor,
          homeModuleIcon: Icons.insights,
          homeModuleColor: SipGedTheme.contractsColor,
        ),
        ModuleData(
          labelModule: 'PAINEL ESPECÍFICO',
          menuModuleItem: ModuleEnum.specificDashboard,
          permissionModule: modSpecificDashboard,
          colorModuleLabel: SipGedTheme.drawerModuleLabelColor,
          homeModuleIcon: Icons.analytics,
          homeModuleColor: SipGedTheme.contractsColor,
        ),
        ModuleData(
          labelModule: 'CONTRATOS',
          menuModuleItem: ModuleEnum.processHiringRecords,
          permissionModule: modHiringRecords,
          colorModuleLabel: SipGedTheme.drawerModuleLabelColor,
          homeModuleIcon: Icons.gavel,
          homeModuleColor: SipGedTheme.contractsColor,
        ),
        ModuleData(
          labelModule: 'ADITIVOS',
          menuModuleItem: ModuleEnum.processAdditiveRecords,
          permissionModule: modAdditiveRecords,
          colorModuleLabel: SipGedTheme.drawerModuleLabelColor,
          homeModuleIcon: Icons.edit_note,
          homeModuleColor: SipGedTheme.contractsColor,
        ),
        ModuleData(
          labelModule: 'REAJUSTES',
          menuModuleItem: ModuleEnum.processApostillesRecords,
          permissionModule: modApostillesRecords,
          colorModuleLabel: SipGedTheme.drawerModuleLabelColor,
          homeModuleIcon: Icons.bookmark_added,
          homeModuleColor: SipGedTheme.contractsColor,
        ),
        ModuleData(
          labelModule: 'MEDIÇÕES',
          menuModuleItem: ModuleEnum.processMeasurementsRecords,
          permissionModule: modMeasurementsRecords,
          colorModuleLabel: SipGedTheme.drawerModuleLabelColor,
          homeModuleIcon: Icons.receipt_long,
          homeModuleColor: SipGedTheme.contractsColor,
        ),
        ModuleData(
          labelModule: 'VIGÊNCIAS',
          menuModuleItem: ModuleEnum.processValidityRecords,
          permissionModule: modValidityRecords,
          colorModuleLabel: SipGedTheme.drawerModuleLabelColor,
          homeModuleIcon: Icons.task_alt,
          homeModuleColor: SipGedTheme.contractsColor,
        ),
        ModuleData(
          labelModule: 'ORÇAMENTO',
          menuModuleItem: ModuleEnum.processHiringBudget,
          permissionModule: modHiringBudget,
          colorModuleLabel: SipGedTheme.drawerModuleLabelColor,
          homeModuleIcon: Icons.attach_money,
          homeModuleColor: SipGedTheme.contractsColor,
        ),
        ModuleData(
          labelModule: 'FINANCEIRO',
          menuModuleItem: ModuleEnum.financialDashboard,
          permissionModule: modFinancialPaymentsDashboard,
          colorModuleLabel: SipGedTheme.drawerModuleLabelColor,
          homeModuleIcon: Icons.stacked_line_chart,
          homeModuleColor: SipGedTheme.contractsColor,
        ),
      ],
    ),
  ];

  // ===========================================================================
  // DEPARTAMENTOS
  // ===========================================================================

  static final List<ModuleGroupData> drawerDepartments = [
    ModuleGroupData(
      labelSection: 'GESTÃO OPERACIONAL',
      iconSection: Icons.engineering_outlined,
      colorSectionLabel: SipGedTheme.drawerSectionLabelColor,
      moduleItems: const [
        ModuleData(
          labelModule: 'DIÁRIO DE OBRA',
          menuModuleItem: ModuleEnum.operationMonitoringWork,
          permissionModule: modWorkTimeline,
          colorModuleLabel: SipGedTheme.drawerModuleLabelColor,
          homeModuleIcon: Icons.timeline,
          homeModuleColor: SipGedTheme.operationColor,
        ),
      ],
    ),
    ModuleGroupData(
      labelSection: 'PLANEJAMENTO',
      iconSection: Icons.bar_chart,
      colorSectionLabel: SipGedTheme.drawerSectionLabelColor,
      moduleItems: const [
        ModuleData(
          labelModule: 'GEOESPACIAL',
          menuModuleItem: ModuleEnum.planningProjectRegistration,
          permissionModule: modPlanningSigmineRecords,
          colorModuleLabel: SipGedTheme.drawerModuleLabelColor,
          homeModuleIcon: Icons.architecture,
          homeModuleColor: SipGedTheme.planningColor,
        ),
      ],
    ),
    ModuleGroupData(
      labelSection: 'GESTÃO DE TRÁFEGO',
      iconSection: Icons.traffic,
      colorSectionLabel: SipGedTheme.drawerSectionLabelColor,
      moduleItems: const [
        ModuleData(
          labelModule: 'PAINEL DOS SINISTROS',
          menuModuleItem: ModuleEnum.trafficAccidentsDashboard,
          permissionModule: modTrafficAccidentsDashboard,
          colorModuleLabel: SipGedTheme.drawerModuleLabelColor,
          homeModuleIcon: Icons.query_stats,
          homeModuleColor: SipGedTheme.trafficColor,
        ),
        ModuleData(
          labelModule: 'LISTA DE SINISTRO',
          menuModuleItem: ModuleEnum.trafficAccidentsRecords,
          permissionModule: modTrafficAccidentsRecords,
          colorModuleLabel: SipGedTheme.drawerModuleLabelColor,
          homeModuleIcon: Icons.assignment_outlined,
          homeModuleColor: SipGedTheme.trafficColor,
        ),
        ModuleData(
          labelModule: 'PAINEL DAS INFRAÇÕES',
          menuModuleItem: ModuleEnum.trafficInfractionsDashboard,
          permissionModule: modTrafficInfractionsDashboard,
          colorModuleLabel: SipGedTheme.drawerModuleLabelColor,
          homeModuleIcon: Icons.rule_folder,
          homeModuleColor: SipGedTheme.trafficColor,
        ),
        ModuleData(
          labelModule: 'LISTA DE INFRAÇÕES',
          menuModuleItem: ModuleEnum.trafficInfractionsRecords,
          permissionModule: modTrafficInfractionsRecords,
          colorModuleLabel: SipGedTheme.drawerModuleLabelColor,
          homeModuleIcon: Icons.assignment_outlined,
          homeModuleColor: SipGedTheme.trafficColor,
        ),
      ],
    ),
  ];

  // ===========================================================================
  // ATIVOS
  // ===========================================================================

  static final List<ModuleGroupData> drawerActives = [
    ModuleGroupData(
      labelSection: 'GESTÃO DE ATIVOS',
      iconSection: Icons.alt_route,
      colorSectionLabel: SipGedTheme.drawerSectionLabelColor,
      moduleItems: const [
        ModuleData(
          labelModule: 'MAPA DE RODOVIÁRIA',
          menuModuleItem: ModuleEnum.activeRoadNetwork,
          permissionModule: modActiveRoadNetwork,
          colorModuleLabel: SipGedTheme.drawerModuleLabelColor,
          homeModuleIcon: Icons.alt_route,
          homeModuleColor: SipGedTheme.activeColor,
        ),
        ModuleData(
          labelModule: 'LISTA DE RODOVIAS',
          menuModuleItem: ModuleEnum.activeRoadRegistration,
          permissionModule: modActiveRoadRecords,
          colorModuleLabel: SipGedTheme.drawerModuleLabelColor,
          homeModuleIcon: Icons.assignment_outlined,
          homeModuleColor: SipGedTheme.activeColor,
        ),
        ModuleData(
          labelModule: 'MAPA DE OAEs',
          menuModuleItem: ModuleEnum.activesOAEsNetwork,
          permissionModule: modActiveOAEsNetwork,
          colorModuleLabel: SipGedTheme.drawerModuleLabelColor,
          homeModuleIcon: Icons.construction,
          homeModuleColor: SipGedTheme.activeColor,
        ),
        ModuleData(
          labelModule: 'LISTA DE OAE\'s',
          menuModuleItem: ModuleEnum.activeOAEsRegistration,
          permissionModule: modActiveOAEsRecords,
          colorModuleLabel: SipGedTheme.drawerModuleLabelColor,
          homeModuleIcon: Icons.assignment_outlined,
          homeModuleColor: SipGedTheme.activeColor,
        ),
      ],
    ),
  ];

  static final List<ModuleGroupData> homeGroups = [
    ...drawerDocuments,
    ...drawerDepartments,
    ...drawerActives,
  ];

  // ===========================================================================
  // HELPERS PARA PERMISSÕES, ACESSO E NAVEGAÇÃO
  // ===========================================================================

  static const List<String> _groupOrder = [
    'GESTÃO DE CONTRATOS',
    'GESTÃO OPERACIONAL',
    'PLANEJAMENTO',
    'GESTÃO DE TRÁFEGO',
    'GESTÃO DE ATIVOS',
  ];

  static List<ModuleData> get allModuleData {
    return [
      for (final group in homeGroups)
        for (final item in group.moduleItems) item,
    ];
  }

  static ModuleData? moduleDataOf(ModuleEnum item) {
    for (final module in allModuleData) {
      if (module.menuModuleItem == item) {
        return module;
      }
    }

    return null;
  }

  static String permissionModuleOf(ModuleEnum item) {
    return moduleDataOf(item)?.permissionModule.trim() ?? '';
  }

  static String labelModuleOf(ModuleEnum item) {
    final label = moduleDataOf(item)?.labelModule.trim();

    if (label == null || label.isEmpty) {
      return 'Módulo';
    }

    return label;
  }

  static bool containsModule(ModuleEnum item) {
    return moduleDataOf(item) != null;
  }

  static Map<String, List<ModuleData>> permissionModulesByDrawerGroup() {
    final out = <String, List<ModuleData>>{};

    for (final group in homeGroups) {
      final groupLabel = group.labelSection.trim().toUpperCase();

      if (groupLabel.isEmpty) continue;

      for (final item in group.moduleItems) {
        final permissionModule = item.permissionModule.trim();

        if (permissionModule.isEmpty) continue;

        out.putIfAbsent(groupLabel, () => <ModuleData>[]);
        out[groupLabel]!.add(item);
      }
    }

    for (final key in out.keys) {
      out[key]!.sort((a, b) {
        final labelCompare = a.labelModule.toUpperCase().compareTo(
          b.labelModule.toUpperCase(),
        );

        if (labelCompare != 0) return labelCompare;

        return a.permissionModule.compareTo(b.permissionModule);
      });
    }

    final sorted = <String, List<ModuleData>>{};

    for (final key in _groupOrder) {
      if (out.containsKey(key)) {
        sorted[key] = out[key]!;
      }
    }

    for (final key in out.keys) {
      if (!sorted.containsKey(key)) {
        sorted[key] = out[key]!;
      }
    }

    return sorted;
  }

  static List<String> get allPermissionModules {
    final set = <String>{};

    for (final item in allModuleData) {
      final permissionModule = item.permissionModule.trim();

      if (permissionModule.isNotEmpty) {
        set.add(permissionModule);
      }
    }

    final list = set.toList()..sort();

    return list;
  }
}