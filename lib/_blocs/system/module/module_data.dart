// lib/_data/module_data.dart
import 'package:flutter/material.dart';
import '../../../_widgets/menu/drawer/menu_drawer_item.dart';
import '../../../_widgets/menu/drawer/menu_drawer_sub_item.dart';

enum ModuleItem {
  overviewDashboard,
  specificDashboard,

  processHiringRecords,
  processValidityRecords,
  processAdditiveRecords,
  processApostillesRecords,
  processMeasurementsRecords,
  processHiringBudget,
  processHiringSchedule,

  operationMonitoringWork,

  planningProjectRegistration,
  planningRightOfWayRecords,
  planningEnvironmentRecords,

  trafficAccidentsDashboard,
  trafficAccidentsRecords,
  trafficInfractionsDashboard,
  trafficInfractionsRecords,

  financialDashboard,
  financialBudget,
  financialEmpenhos,
  financialCommitmentRecords,

  activeRoadRegistration,
  activeRoadNetwork,

  activeOAEsRegistration,
  activesOAEsNetwork,
}

/// Configuração de seções da HOME (título + grupos do drawer)
class ModuleSectionConfig {
  final String title;
  final List<MenuDrawerItemModule> groups;
  const ModuleSectionConfig({required this.title, required this.groups});
}

class ModuleData {
  // ===========================================================================
  // ✅ FONTE ÚNICA: IDs CANÔNICOS DOS MÓDULOS (permissionModule)
  // ===========================================================================
  static const String modOverviewDashboard = 'overview-overview-dashboard';
  static const String modSpecificDashboard = 'specific-overview-dashboard';

  // CONTRATOS (pipeline/registros)
  static const String modHiringRecords = 'operation-hiring-records';
  static const String modValidityRecords = 'operation-validity-records';
  static const String modAdditiveRecords = 'operation-additive-records';
  static const String modApostillesRecords = 'operation-apostilles-records';
  static const String modMeasurementsRecords = 'operation-measurements-records';
  static const String modHiringBudget = 'operation-hiring-budget';
  static const String modHiringSchedule = 'operation-hiring-schedule';

  // OPERACIONAL
  static const String modWorkTimeline = 'operation-work-timeline';

  // PLANEJAMENTO
  static const String modPlanningSigmineDashboard = 'planning-sigmine-overview-dashboard';
  static const String modPlanningSigmineRecords = 'planning-sigmine-records';
  static const String modPlanningRightWayRecords = 'planning-rightWay-records';
  static const String modPlanningEnvironmentDashboard = 'planning-environment-overview-dashboard';
  static const String modPlanningEnvironmentRecords = 'planning-environment-records';

  // TRÁFEGO
  static const String modTrafficAccidentsDashboard = 'traffic-accidents-overview-dashboard';
  static const String modTrafficAccidentsRecords = 'traffic-accidents-records';
  static const String modTrafficInfractionsDashboard = 'traffic-infractions-overview-dashboard';
  static const String modTrafficInfractionsRecords = 'traffic-infractions-records';

  // FINANCEIRO
  static const String modFinancialPaymentsDashboard = 'financial-payments-overview-dashboard';
  static const String modFinancialPaymentsRecords = 'financial-payments-records';
  static const String modFinancialCommitmentDashboard = 'financial-commitment-overview-dashboard';
  static const String modFinancialCommitmentRecords = 'financial-commitment-records';

  // ATIVOS
  static const String modActiveRoadRecords = 'active-road-records';
  static const String modActiveRoadNetwork = 'active-road-network';

  static const String modActiveOAEsRecords = 'active-oaes-records';
  static const String modActiveOAEsNetwork = 'active-oaes-network';

  /// (Opcional) helper: módulo “principal” que controla a página de demandas/lista de contratos
  /// Você pode trocar aqui caso a lista esteja em outro menu.
  static const String modContractsList = modHiringRecords;

  // ===========================================================================
  // (LEGADO/RETRO) Se você ainda precisa de uma lista simples:
  // AGORA essa lista é derivada automaticamente de homeGroups,
  // mas mantive para retrocompatibilidade.
  // ===========================================================================
  static List<String> module = [
    modOverviewDashboard,
    modSpecificDashboard,

    modHiringRecords,
    modValidityRecords,
    modAdditiveRecords,
    modApostillesRecords,
    modMeasurementsRecords,
    modHiringBudget,
    modHiringSchedule,

    modWorkTimeline,

    modPlanningSigmineDashboard,
    modPlanningSigmineRecords,
    modPlanningRightWayRecords,
    modPlanningEnvironmentDashboard,
    modPlanningEnvironmentRecords,

    modTrafficAccidentsDashboard,
    modTrafficAccidentsRecords,
    modTrafficInfractionsDashboard,
    modTrafficInfractionsRecords,

    modFinancialPaymentsDashboard,
    modFinancialPaymentsRecords,
    modFinancialCommitmentDashboard,
    modFinancialCommitmentRecords,

    modActiveRoadRecords,
    modActiveRoadNetwork,

    modActiveOAEsRecords,
    modActiveOAEsNetwork,
  ];

  // ===========================================================================
  // CONTRATOS
  // ===========================================================================
  static List<MenuDrawerItemModule> drawerDocuments = [
    MenuDrawerItemModule(
      label: 'CONTRATOS',
      icon: Icons.document_scanner,
      subItems: [
        MenuDrawerSubItem(
          label: 'PAINEL GERAL',
          menuItem: ModuleItem.overviewDashboard,
          permissionModule: modOverviewDashboard,
          homeIcon: Icons.insights,
          homeColor: Color(0xFF0EA5E9),
        ),
        MenuDrawerSubItem(
          label: 'PAINEL ESPECÍFICO',
          menuItem: ModuleItem.specificDashboard,
          permissionModule: modSpecificDashboard,
          homeIcon: Icons.analytics,
          homeColor: Color(0xFF0EA5E9),
        ),
        MenuDrawerSubItem(
          label: 'CONTRATOS',
          menuItem: ModuleItem.processHiringRecords,
          permissionModule: modHiringRecords,
          homeIcon: Icons.gavel,
          homeColor: Color(0xFF0EA5E9),
        ),
        MenuDrawerSubItem(
          label: 'ADITIVOS',
          menuItem: ModuleItem.processAdditiveRecords,
          permissionModule: modAdditiveRecords,
          homeIcon: Icons.edit_note,
          homeColor: Color(0xFF0EA5E9),
        ),
        MenuDrawerSubItem(
          label: 'REAJUSTES',
          menuItem: ModuleItem.processApostillesRecords,
          permissionModule: modApostillesRecords,
          homeIcon: Icons.bookmark_added,
          homeColor: Color(0xFF0EA5E9),
        ),
        MenuDrawerSubItem(
          label: 'MEDIÇÕES',
          menuItem: ModuleItem.processMeasurementsRecords,
          permissionModule: modMeasurementsRecords,
          homeIcon: Icons.receipt_long,
          homeColor: Color(0xFF0EA5E9),
        ),
        MenuDrawerSubItem(
          label: 'VIGÊNCIAS',
          menuItem: ModuleItem.processValidityRecords,
          permissionModule: modValidityRecords,
          homeIcon: Icons.task_alt,
          homeColor: Color(0xFF0EA5E9),
        ),
        MenuDrawerSubItem(
          label: 'ORÇAMENTO DA OBRA',
          menuItem: ModuleItem.processHiringBudget,
          permissionModule: modHiringBudget,
          homeIcon: Icons.attach_money,
          homeColor: Color(0xFF0EA5E9),
        ),
      ],
    ),
  ];

  // ===========================================================================
  // DEPARTAMENTOS
  // ===========================================================================
  static List<MenuDrawerItemModule> drawerDepartments = [
    MenuDrawerItemModule(
      label: 'OPERACIONAL',
      icon: Icons.engineering_outlined,
      subItems: [
        MenuDrawerSubItem(
          label: 'DIÁRIO DE OBRA',
          menuItem: ModuleItem.operationMonitoringWork,
          permissionModule: modWorkTimeline,
          homeIcon: Icons.timeline,
          homeColor: Color(0xFF059669),
        ),
        MenuDrawerSubItem(
          label: 'CRONOGRAMA',
          menuItem: ModuleItem.processHiringSchedule,
          permissionModule: modHiringSchedule,
          homeIcon: Icons.calendar_month,
          homeColor: Color(0xFF059669),
        ),
      ],
    ),
    MenuDrawerItemModule(
      label: 'PLANEJAMENTO',
      icon: Icons.bar_chart,
      subItems: [
        MenuDrawerSubItem(
          label: 'GEOESPACIAL',
          menuItem: ModuleItem.planningProjectRegistration,
          permissionModule: modPlanningSigmineRecords,
          homeIcon: Icons.architecture,
          homeColor: Color(0xFF1E40AF),
        ),
        MenuDrawerSubItem(
          label: 'FAIXA DE DOMÍNO',
          menuItem: ModuleItem.planningRightOfWayRecords,
          permissionModule: modPlanningRightWayRecords,
          homeIcon: Icons.signpost_outlined,
          homeColor: Color(0xFF1E40AF),
        ),
        MenuDrawerSubItem(
          label: 'MEIO AMBIENTE',
          menuItem: ModuleItem.planningEnvironmentRecords,
          permissionModule: modPlanningEnvironmentRecords,
          homeIcon: Icons.local_florist_outlined,
          homeColor: Color(0xFF1E40AF),
        ),
      ],
    ),
    MenuDrawerItemModule(
      label: 'TRÁFEGO',
      icon: Icons.traffic,
      subItems: [
        MenuDrawerSubItem(
          label: 'PAINEL DOS SINISTROS',
          menuItem: ModuleItem.trafficAccidentsDashboard,
          permissionModule: modTrafficAccidentsDashboard,
          homeIcon: Icons.query_stats,
          homeColor: Color(0xFFEA580C),
        ),
        MenuDrawerSubItem(
          label: 'REGISTROS DE SINISTRO',
          menuItem: ModuleItem.trafficAccidentsRecords,
          permissionModule: modTrafficAccidentsRecords,
          homeIcon: Icons.assignment_outlined,
          homeColor: Color(0xFFEA580C),
        ),
        MenuDrawerSubItem(
          label: 'PAINEL DAS INFRAÇÕES',
          menuItem: ModuleItem.trafficInfractionsDashboard,
          permissionModule: modTrafficInfractionsDashboard,
          homeIcon: Icons.rule_folder,
          homeColor: Color(0xFFEA580C),
        ),
        MenuDrawerSubItem(
          label: 'REGISTROS DE INFRAÇÃO',
          menuItem: ModuleItem.trafficInfractionsRecords,
          permissionModule: modTrafficInfractionsRecords,
          homeIcon: Icons.assignment_outlined,
          homeColor: Color(0xFFEA580C),
        ),
      ],
    ),
    MenuDrawerItemModule(
      label: 'FINANCEIRO',
      icon: Icons.attach_money,
      subItems: [
        MenuDrawerSubItem(
          label: 'PAINEL FINANCEIRO',
          menuItem: ModuleItem.financialDashboard,
          permissionModule: modFinancialPaymentsDashboard,
          homeIcon: Icons.stacked_line_chart,
          homeColor: Color(0xFF0D9488),
        ),
        MenuDrawerSubItem(
          label: 'ORÇAMENTO',
          menuItem: ModuleItem.financialBudget,
          permissionModule: modFinancialPaymentsRecords,
          homeIcon: Icons.payments,
          homeColor: Color(0xFF0D9488),
        ),
        MenuDrawerSubItem(
          label: 'EMPENHOS',
          menuItem: ModuleItem.financialEmpenhos,
          permissionModule: modFinancialCommitmentDashboard,
          homeIcon: Icons.auto_graph,
          homeColor: Color(0xFF0D9488),
        ),
        MenuDrawerSubItem(
          label: 'PAGAMENTOS',
          menuItem: ModuleItem.financialCommitmentRecords,
          permissionModule: modFinancialCommitmentRecords,
          homeIcon: Icons.receipt_long_outlined,
          homeColor: Color(0xFF0D9488),
        ),
      ],
    ),
  ];

  // ===========================================================================
  // ATIVOS
  // ===========================================================================
  static List<MenuDrawerItemModule> drawerActives = [
    MenuDrawerItemModule(
      label: 'RODOVIAS',
      icon: Icons.alt_route,
      subItems: [
        MenuDrawerSubItem(
          label: 'MALHA RODOVIÁRIA',
          menuItem: ModuleItem.activeRoadNetwork,
          permissionModule: modActiveRoadNetwork,
          homeIcon: Icons.alt_route,
          homeColor: Color(0xFF334155),
        ),
        MenuDrawerSubItem(
          label: 'REGISTROS DAS RODOVIAS',
          menuItem: ModuleItem.activeRoadRegistration,
          permissionModule: modActiveRoadRecords,
          homeIcon: Icons.assignment_outlined,
          homeColor: Color(0xFF334155),
        ),
      ],
    ),
    MenuDrawerItemModule(
      label: 'PONTES',
      icon: Icons.car_repair,
      subItems: [
        MenuDrawerSubItem(
          label: 'MALHA OAEs',
          menuItem: ModuleItem.activesOAEsNetwork,
          permissionModule: modActiveOAEsNetwork,
          homeIcon: Icons.construction,
          homeColor: Color(0xFF334155),
        ),
        MenuDrawerSubItem(
          label: 'REGISTROS DAS OAE\'s',
          menuItem: ModuleItem.activeOAEsRegistration,
          permissionModule: modActiveOAEsRecords,
          homeIcon: Icons.assignment_outlined,
          homeColor: Color(0xFF334155),
        ),
      ],
    ),
  ];

  // ===========================================================================
  // HOME
  // ===========================================================================
  static List<ModuleSectionConfig> homeSections = [
    ModuleSectionConfig(
      title: 'MÓDULOS',
      groups: [
        ...drawerDocuments,
        ...drawerDepartments,
      ],
    ),
    ModuleSectionConfig(
      title: 'ATIVOS',
      groups: drawerActives,
    ),
  ];

  static List<MenuDrawerItemModule> homeGroups = [
    ...drawerDocuments,
    ...drawerDepartments,
    ...drawerActives,
  ];

  // ===========================================================================
  // HELPERS PARA TELA DE PERMISSÕES
  // ===========================================================================
  static const _groupOrder = <String>[
    'PAINÉIS',
    'CONTRATOS',
    'OPERACIONAL',
    'PLANEJAMENTO',
    'TRÁFEGO',
    'FINANCEIRO',
    'ATIVOS',
  ];

  static Map<String, List<PermItem>> permissionModulesByDrawerGroup() {
    final out = <String, List<PermItem>>{};

    for (final group in homeGroups) {
      final groupLabel = group.label.trim().toUpperCase();

      for (final sub in group.subItems) {
        final module = sub.permissionModule.trim();
        if (module.isEmpty) continue;

        out.putIfAbsent(groupLabel, () => []);
        out[groupLabel]!.add(
          PermItem(label: sub.label.trim(), module: module),
        );
      }
    }

    for (final k in out.keys) {
      out[k]!.sort((a, b) {
        final c1 = a.label.toUpperCase().compareTo(b.label.toUpperCase());
        if (c1 != 0) return c1;
        return a.module.compareTo(b.module);
      });
    }

    final sorted = <String, List<PermItem>>{};
    for (final k in _groupOrder) {
      if (out.containsKey(k)) sorted[k] = out[k]!;
    }
    for (final k in out.keys) {
      if (!sorted.containsKey(k)) sorted[k] = out[k]!;
    }

    return sorted;
  }

  static List<String> get allPermissionModules {
    final set = <String>{};
    for (final group in homeGroups) {
      for (final sub in group.subItems) {
        final m = sub.permissionModule.trim();
        if (m.isNotEmpty) set.add(m);
      }
    }
    final list = set.toList()..sort();
    return list;
  }
}

class PermItem {
  final String label;
  final String module;
  const PermItem({required this.label, required this.module});
}
