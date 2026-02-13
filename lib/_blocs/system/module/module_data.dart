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

  activeAirportsRegistration,
  activeAirportsNetwork,

  activeRailwaysRegistration,
  activeRailwaysNetwork,

  activeRegistrationPorts,
  activePortsNetwork,
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

  static const String modActiveAirportsRecords = 'active-airports-records';
  static const String modActiveAirportsNetwork = 'active-airports-network';

  static const String modActiveRailwaysRecords = 'active-railways-records';
  static const String modActiveRailwaysNetwork = 'active-railways-network';

  static const String modActivePortsRecords = 'active-ports-records';
  static const String modActivePortsNetwork = 'active-ports-network';

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

    modActiveAirportsRecords,
    modActiveAirportsNetwork,

    modActiveRailwaysRecords,
    modActiveRailwaysNetwork,

    modActivePortsRecords,
    modActivePortsNetwork,
  ];

  // ===========================================================================
  // PAINÉIS
  // ===========================================================================
  static List<MenuDrawerItemModule> panelDashboard = [
    MenuDrawerItemModule(
      label: 'PAINÉIS',
      icon: Icons.area_chart,
      subItems: [
        MenuDrawerSubItem(
          label: 'GERAL',
          menuItem: ModuleItem.overviewDashboard,
          permissionModule: modOverviewDashboard,
          homeIcon: Icons.insights,
          homeSubtitle: 'Indicadores e resumos',
          homeColor: Color(0xFF2563EB),
        ),
        MenuDrawerSubItem(
          label: 'ESPECÍFICO',
          menuItem: ModuleItem.specificDashboard,
          permissionModule: modSpecificDashboard,
          homeIcon: Icons.analytics,
          homeSubtitle: 'KPIs e análises por contrato',
          homeColor: Color(0xFF1D4ED8),
        ),
      ],
    ),
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
          label: 'CONTRATAÇÃO',
          menuItem: ModuleItem.processHiringRecords,
          permissionModule: modHiringRecords,
          homeIcon: Icons.gavel,
          homeSubtitle: 'Fluxos e registros de processo',
          homeColor: Color(0xFF0EA5E9),
        ),
        MenuDrawerSubItem(
          label: 'ADITIVOS',
          menuItem: ModuleItem.processAdditiveRecords,
          permissionModule: modAdditiveRecords,
          homeIcon: Icons.edit_note,
          homeSubtitle: 'Fluxos e registros de processo',
          homeColor: Color(0xFF0EA5E9),
        ),
        MenuDrawerSubItem(
          label: 'APOSTILAMENTOS',
          menuItem: ModuleItem.processApostillesRecords,
          permissionModule: modApostillesRecords,
          homeIcon: Icons.bookmark_added,
          homeSubtitle: 'Fluxos e registros de processo',
          homeColor: Color(0xFF0EA5E9),
        ),
        MenuDrawerSubItem(
          label: 'MEDIÇÕES',
          menuItem: ModuleItem.processMeasurementsRecords,
          permissionModule: modMeasurementsRecords,
          homeIcon: Icons.receipt_long,
          homeSubtitle: 'Fluxos e registros de processo',
          homeColor: Color(0xFF0EA5E9),
        ),
        MenuDrawerSubItem(
          label: 'VIGÊNCIAS',
          menuItem: ModuleItem.processValidityRecords,
          permissionModule: modValidityRecords,
          homeIcon: Icons.task_alt,
          homeSubtitle: 'Fluxos e registros de processo',
          homeColor: Color(0xFF0EA5E9),
        ),
        MenuDrawerSubItem(
          label: 'ORÇAMENTO DA OBRA',
          menuItem: ModuleItem.processHiringBudget,
          permissionModule: modHiringBudget,
          homeIcon: Icons.attach_money,
          homeSubtitle: 'Orçamento e insumos',
          homeColor: Color(0xFF0D9488),
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
          homeSubtitle: 'Execução e acompanhamento',
          homeColor: Color(0xFF059669),
        ),
        MenuDrawerSubItem(
          label: 'CRONOGRAMA',
          menuItem: ModuleItem.processHiringSchedule,
          permissionModule: modHiringSchedule,
          homeIcon: Icons.calendar_month,
          homeSubtitle: 'Execução e acompanhamento',
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
          homeSubtitle: 'Planejamento e cadastros',
          homeColor: Color(0xFF1E40AF),
        ),
        MenuDrawerSubItem(
          label: 'FAIXA DE DOMÍNIO',
          menuItem: ModuleItem.planningRightOfWayRecords,
          permissionModule: modPlanningRightWayRecords,
          homeIcon: Icons.signpost_outlined,
          homeSubtitle: 'Planejamento e cadastros',
          homeColor: Color(0xFF1E40AF),
        ),
        MenuDrawerSubItem(
          label: 'MEIO AMBIENTE',
          menuItem: ModuleItem.planningEnvironmentRecords,
          permissionModule: modPlanningEnvironmentRecords,
          homeIcon: Icons.local_florist_outlined,
          homeSubtitle: 'Planejamento e cadastros',
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
          homeSubtitle: 'Sinistros e infrações',
          homeColor: Color(0xFFEA580C),
        ),
        MenuDrawerSubItem(
          label: 'BOLETIM DE SINISTRO',
          menuItem: ModuleItem.trafficAccidentsRecords,
          permissionModule: modTrafficAccidentsRecords,
          homeIcon: Icons.report,
          homeSubtitle: 'Sinistros e infrações',
          homeColor: Color(0xFFEA580C),
        ),
        MenuDrawerSubItem(
          label: 'PAINEL DAS INFRAÇÕES',
          menuItem: ModuleItem.trafficInfractionsDashboard,
          permissionModule: modTrafficInfractionsDashboard,
          homeIcon: Icons.rule_folder,
          homeSubtitle: 'Sinistros e infrações',
          homeColor: Color(0xFFEA580C),
        ),
        MenuDrawerSubItem(
          label: 'BOLETIM DE INFRAÇÃO',
          menuItem: ModuleItem.trafficInfractionsRecords,
          permissionModule: modTrafficInfractionsRecords,
          homeIcon: Icons.rule,
          homeSubtitle: 'Sinistros e infrações',
          homeColor: Color(0xFFEA580C),
        ),
      ],
    ),
    MenuDrawerItemModule(
      label: 'FINANCEIRO',
      icon: Icons.attach_money,
      subItems: [
        MenuDrawerSubItem(
          label: 'PAINEL',
          menuItem: ModuleItem.financialDashboard,
          permissionModule: modFinancialPaymentsDashboard,
          homeIcon: Icons.stacked_line_chart,
          homeSubtitle: 'Pagamentos e empreendimentos',
          homeColor: Color(0xFF0D9488),
        ),
        MenuDrawerSubItem(
          label: 'ORÇAMENTO DO ÓRGÃO',
          menuItem: ModuleItem.financialBudget,
          permissionModule: modFinancialPaymentsRecords,
          homeIcon: Icons.payments,
          homeSubtitle: 'Pagamentos e empreendimentos',
          homeColor: Color(0xFF0D9488),
        ),
        MenuDrawerSubItem(
          label: 'EMPENHOS',
          menuItem: ModuleItem.financialEmpenhos,
          permissionModule: modFinancialCommitmentDashboard,
          homeIcon: Icons.auto_graph,
          homeSubtitle: 'Pagamentos e empreendimentos',
          homeColor: Color(0xFF0D9488),
        ),
        MenuDrawerSubItem(
          label: 'PAGAMENTOS',
          menuItem: ModuleItem.financialCommitmentRecords,
          permissionModule: modFinancialCommitmentRecords,
          homeIcon: Icons.receipt_long_outlined,
          homeSubtitle: 'Pagamentos e empreendimentos',
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
          homeSubtitle: 'Malha e levantamentos',
          homeColor: Color(0xFF334155),
        ),
        MenuDrawerSubItem(
          label: 'SISTEMA RODOVIÁRIO',
          menuItem: ModuleItem.activeRoadRegistration,
          permissionModule: modActiveRoadRecords,
          homeIcon: Icons.map_outlined,
          homeSubtitle: 'Malha e levantamentos',
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
          homeSubtitle: 'Malha e levantamentos',
          homeColor: Color(0xFF334155),
        ),
        MenuDrawerSubItem(
          label: 'LEVANTAMENTO',
          menuItem: ModuleItem.activeOAEsRegistration,
          permissionModule: modActiveOAEsRecords,
          homeIcon: Icons.assignment_outlined,
          homeSubtitle: 'Malha e levantamentos',
          homeColor: Color(0xFF334155),
        ),
      ],
    ),
    MenuDrawerItemModule(
      label: 'AEROPORTOS',
      icon: Icons.local_airport,
      subItems: [
        MenuDrawerSubItem(
          label: 'MALHA AEROPORTUÁRIA',
          menuItem: ModuleItem.activeAirportsNetwork,
          permissionModule: modActiveAirportsNetwork,
          homeIcon: Icons.flight_takeoff,
          homeSubtitle: 'Malha e levantamentos',
          homeColor: Color(0xFF334155),
        ),
        MenuDrawerSubItem(
          label: 'LEVANTAMENTO',
          menuItem: ModuleItem.activeAirportsRegistration,
          permissionModule: modActiveAirportsRecords,
          homeIcon: Icons.assignment_turned_in_outlined,
          homeSubtitle: 'Malha e levantamentos',
          homeColor: Color(0xFF334155),
        ),
      ],
    ),
    MenuDrawerItemModule(
      label: 'FERROVIAS',
      icon: Icons.train,
      subItems: [
        MenuDrawerSubItem(
          label: 'MALHA FERROVIÁRIA',
          menuItem: ModuleItem.activeRailwaysNetwork,
          permissionModule: modActiveRailwaysNetwork,
          homeIcon: Icons.train_outlined,
          homeSubtitle: 'Malha e levantamentos',
          homeColor: Color(0xFF334155),
        ),
        MenuDrawerSubItem(
          label: 'LEVANTAMENTO',
          menuItem: ModuleItem.activeRailwaysRegistration,
          permissionModule: modActiveRailwaysRecords,
          homeIcon: Icons.fact_check_outlined,
          homeSubtitle: 'Malha e levantamentos',
          homeColor: Color(0xFF334155),
        ),
      ],
    ),
    MenuDrawerItemModule(
      label: 'PORTOS E BALSAS',
      icon: Icons.directions_boat,
      subItems: [
        MenuDrawerSubItem(
          label: 'MALHA PORTUÁRIA',
          menuItem: ModuleItem.activePortsNetwork,
          permissionModule: modActivePortsNetwork,
          homeIcon: Icons.sailing_outlined,
          homeSubtitle: 'Malha e levantamentos',
          homeColor: Color(0xFF334155),
        ),
        MenuDrawerSubItem(
          label: 'LEVANTAMENTO',
          menuItem: ModuleItem.activeRegistrationPorts,
          permissionModule: modActivePortsRecords,
          homeIcon: Icons.checklist_outlined,
          homeSubtitle: 'Malha e levantamentos',
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
        ...panelDashboard,
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
    ...panelDashboard,
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
