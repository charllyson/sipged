// lib/_blocs/system/module/module_catalog.dart

import 'package:flutter/material.dart';

import 'module_data.dart';

class ModuleCatalog {
  // ===========================================================================
  // IDS CANÔNICOS DOS MÓDULOS
  // ===========================================================================

  static const String modOverviewDashboard = 'overview-overview-dashboard';
  static const String modSpecificDashboard = 'specific-overview-dashboard';

  // CONTRATOS
  static const String modHiringRecords = 'operation-hiring-records';
  static const String modValidityRecords = 'operation-validity-records';
  static const String modAdditiveRecords = 'operation-additive-records';
  static const String modApostillesRecords = 'operation-apostilles-records';
  static const String modMeasurementsRecords = 'operation-measurements-records';
  static const String modHiringBudget = 'operation-hiring-budget';

  // FINANCEIRO
  static const String modFinancialPaymentsDashboard =
      'financial-payments-overview-dashboard';
  static const String modFinancialPaymentsRecords =
      'financial-payments-records';
  static const String modFinancialCommitmentDashboard =
      'financial-commitment-overview-dashboard';
  static const String modFinancialCommitmentRecords =
      'financial-commitment-records';

  // OPERACIONAL
  static const String modWorkTimeline = 'operation-work-timeline';

  // PLANEJAMENTO
  static const String modPlanningSigmineDashboard =
      'planning-sigmine-overview-dashboard';
  static const String modPlanningSigmineRecords = 'planning-sigmine-records';
  static const String modPlanningRightWayRecords = 'planning-rightWay-records';
  static const String modPlanningEnvironmentDashboard =
      'planning-environment-overview-dashboard';

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

  static const String modContractsList = modHiringRecords;

  static final List<String> module = allPermissionModules;

  // ===========================================================================
  // CORES PADRÃO
  // ===========================================================================

  static const Color drawerSectionLabelColor = Colors.white;
  static const Color drawerModuleLabelColor = Colors.white70;

  static const Color contractsColor = Color(0xFF0EA5E9);
  static const Color operationColor = Color(0xFF059669);
  static const Color planningColor = Color(0xFF1E40AF);
  static const Color trafficColor = Color(0xFFEA580C);
  static const Color activeColor = Color(0xFF334155);

  // ===========================================================================
  // CONTRATOS
  // ===========================================================================

  static final List<ModuleGroupData> drawerDocuments = [
    ModuleGroupData(
      labelSection: 'GESTÃO DE CONTRATOS',
      iconSection: Icons.document_scanner,
      colorSectionLabel: drawerSectionLabelColor,
      moduleItems: const [
        ModuleData(
          labelModule: 'PAINEL GERAL',
          menuModuleItem: ModuleEnum.overviewDashboard,
          permissionModule: modOverviewDashboard,
          colorModuleLabel: drawerModuleLabelColor,
          homeModuleIcon: Icons.insights,
          homeModuleColor: contractsColor,
        ),
        ModuleData(
          labelModule: 'PAINEL ESPECÍFICO',
          menuModuleItem: ModuleEnum.specificDashboard,
          permissionModule: modSpecificDashboard,
          colorModuleLabel: drawerModuleLabelColor,
          homeModuleIcon: Icons.analytics,
          homeModuleColor: contractsColor,
        ),
        ModuleData(
          labelModule: 'CONTRATOS',
          menuModuleItem: ModuleEnum.processHiringRecords,
          permissionModule: modHiringRecords,
          colorModuleLabel: drawerModuleLabelColor,
          homeModuleIcon: Icons.gavel,
          homeModuleColor: contractsColor,
        ),
        ModuleData(
          labelModule: 'ADITIVOS',
          menuModuleItem: ModuleEnum.processAdditiveRecords,
          permissionModule: modAdditiveRecords,
          colorModuleLabel: drawerModuleLabelColor,
          homeModuleIcon: Icons.edit_note,
          homeModuleColor: contractsColor,
        ),
        ModuleData(
          labelModule: 'REAJUSTES',
          menuModuleItem: ModuleEnum.processApostillesRecords,
          permissionModule: modApostillesRecords,
          colorModuleLabel: drawerModuleLabelColor,
          homeModuleIcon: Icons.bookmark_added,
          homeModuleColor: contractsColor,
        ),
        ModuleData(
          labelModule: 'MEDIÇÕES',
          menuModuleItem: ModuleEnum.processMeasurementsRecords,
          permissionModule: modMeasurementsRecords,
          colorModuleLabel: drawerModuleLabelColor,
          homeModuleIcon: Icons.receipt_long,
          homeModuleColor: contractsColor,
        ),
        ModuleData(
          labelModule: 'VIGÊNCIAS',
          menuModuleItem: ModuleEnum.processValidityRecords,
          permissionModule: modValidityRecords,
          colorModuleLabel: drawerModuleLabelColor,
          homeModuleIcon: Icons.task_alt,
          homeModuleColor: contractsColor,
        ),
        ModuleData(
          labelModule: 'ORÇAMENTO',
          menuModuleItem: ModuleEnum.processHiringBudget,
          permissionModule: modHiringBudget,
          colorModuleLabel: drawerModuleLabelColor,
          homeModuleIcon: Icons.attach_money,
          homeModuleColor: contractsColor,
        ),
        ModuleData(
          labelModule: 'PAINEL FINANCEIRO',
          menuModuleItem: ModuleEnum.financialDashboard,
          permissionModule: modFinancialPaymentsDashboard,
          colorModuleLabel: drawerModuleLabelColor,
          homeModuleIcon: Icons.stacked_line_chart,
          homeModuleColor: contractsColor,
        ),
        ModuleData(
          labelModule: 'PAGAMENTOS',
          menuModuleItem: ModuleEnum.financialCommitmentRecords,
          permissionModule: modFinancialCommitmentRecords,
          colorModuleLabel: drawerModuleLabelColor,
          homeModuleIcon: Icons.receipt_long_outlined,
          homeModuleColor: contractsColor,
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
      colorSectionLabel: drawerSectionLabelColor,
      moduleItems: const [
        ModuleData(
          labelModule: 'DIÁRIO DE OBRA',
          menuModuleItem: ModuleEnum.operationMonitoringWork,
          permissionModule: modWorkTimeline,
          colorModuleLabel: drawerModuleLabelColor,
          homeModuleIcon: Icons.timeline,
          homeModuleColor: operationColor,
        ),
      ],
    ),
    ModuleGroupData(
      labelSection: 'PLANEJAMENTO',
      iconSection: Icons.bar_chart,
      colorSectionLabel: drawerSectionLabelColor,
      moduleItems: const [
        ModuleData(
          labelModule: 'GEOESPACIAL',
          menuModuleItem: ModuleEnum.planningProjectRegistration,
          permissionModule: modPlanningSigmineRecords,
          colorModuleLabel: drawerModuleLabelColor,
          homeModuleIcon: Icons.architecture,
          homeModuleColor: planningColor,
        ),
        ModuleData(
          labelModule: 'FAIXA DE DOMÍNO',
          menuModuleItem: ModuleEnum.planningRightOfWayRecords,
          permissionModule: modPlanningRightWayRecords,
          colorModuleLabel: drawerModuleLabelColor,
          homeModuleIcon: Icons.signpost_outlined,
          homeModuleColor: planningColor,
        ),
      ],
    ),
    ModuleGroupData(
      labelSection: 'GESTÃO DE TRÁFEGO',
      iconSection: Icons.traffic,
      colorSectionLabel: drawerSectionLabelColor,
      moduleItems: const [
        ModuleData(
          labelModule: 'PAINEL DOS SINISTROS',
          menuModuleItem: ModuleEnum.trafficAccidentsDashboard,
          permissionModule: modTrafficAccidentsDashboard,
          colorModuleLabel: drawerModuleLabelColor,
          homeModuleIcon: Icons.query_stats,
          homeModuleColor: trafficColor,
        ),
        ModuleData(
          labelModule: 'LISTA DE SINISTRO',
          menuModuleItem: ModuleEnum.trafficAccidentsRecords,
          permissionModule: modTrafficAccidentsRecords,
          colorModuleLabel: drawerModuleLabelColor,
          homeModuleIcon: Icons.assignment_outlined,
          homeModuleColor: trafficColor,
        ),
        ModuleData(
          labelModule: 'PAINEL DAS INFRAÇÕES',
          menuModuleItem: ModuleEnum.trafficInfractionsDashboard,
          permissionModule: modTrafficInfractionsDashboard,
          colorModuleLabel: drawerModuleLabelColor,
          homeModuleIcon: Icons.rule_folder,
          homeModuleColor: trafficColor,
        ),
        ModuleData(
          labelModule: 'LISTA DE INFRAÇÕES',
          menuModuleItem: ModuleEnum.trafficInfractionsRecords,
          permissionModule: modTrafficInfractionsRecords,
          colorModuleLabel: drawerModuleLabelColor,
          homeModuleIcon: Icons.assignment_outlined,
          homeModuleColor: trafficColor,
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
      colorSectionLabel: drawerSectionLabelColor,
      moduleItems: const [
        ModuleData(
          labelModule: 'MAPA DE RODOVIÁRIA',
          menuModuleItem: ModuleEnum.activeRoadNetwork,
          permissionModule: modActiveRoadNetwork,
          colorModuleLabel: drawerModuleLabelColor,
          homeModuleIcon: Icons.alt_route,
          homeModuleColor: activeColor,
        ),
        ModuleData(
          labelModule: 'LISTA DE RODOVIAS',
          menuModuleItem: ModuleEnum.activeRoadRegistration,
          permissionModule: modActiveRoadRecords,
          colorModuleLabel: drawerModuleLabelColor,
          homeModuleIcon: Icons.assignment_outlined,
          homeModuleColor: activeColor,
        ),
        ModuleData(
          labelModule: 'MAPA DE OAEs',
          menuModuleItem: ModuleEnum.activesOAEsNetwork,
          permissionModule: modActiveOAEsNetwork,
          colorModuleLabel: drawerModuleLabelColor,
          homeModuleIcon: Icons.construction,
          homeModuleColor: activeColor,
        ),
        ModuleData(
          labelModule: 'LISTA DE OAE\'s',
          menuModuleItem: ModuleEnum.activeOAEsRegistration,
          permissionModule: modActiveOAEsRecords,
          colorModuleLabel: drawerModuleLabelColor,
          homeModuleIcon: Icons.assignment_outlined,
          homeModuleColor: activeColor,
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