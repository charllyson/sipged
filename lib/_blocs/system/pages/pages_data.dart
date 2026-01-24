import 'package:flutter/material.dart';
import '../../../_widgets/menu/drawer/menu_drawer_item.dart';
import '../../../_widgets/menu/drawer/menu_drawer_sub_item.dart';

enum MenuItem {
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

  financialPaymentsDashboard,
  financialPaymentsRecords,
  financialCommitmentDashboard,
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
class HomeSectionConfig {
  final String title;
  final List<MenuDrawerItemModule> groups;
  const HomeSectionConfig({required this.title, required this.groups});
}

class PagesData {
  /// ===== MÓDULOS (permissionModule) =====
  static List<String> module = [
    'overview-overview-dashboard',
    'specific-overview-dashboard',

    'operation-hiring-records',
    'operation-validity-records',
    'operation-additive-records',
    'operation-apostilles-records',
    'operation-measurements-records',
    'operation-hiring-budget', // <= corrigido: faltava vírgula
    'operation-hiring-schedule',

    'operation-work-timeline',

    'planning-sigmine-overview-dashboard',
    'planning-sigmine-records',
    'planning-rightWay-records',
    'planning-environment-overview-dashboard',
    'planning-environment-records',

    'traffic-accidents-overview-dashboard',
    'traffic-accidents-records',
    'traffic-infractions-overview-dashboard',
    'traffic-infractions-records',

    'financial-payments-overview-dashboard',
    'financial-payments-records',
    'financial-commitment-overview-dashboard',
    'financial-commitment-records',

    'active-road-records',
    'active-road-network',

    'active-oaes-records',
    'active-oaes-network',

    'active-airports-records',
    'active-airports-network',

    'active-railways-records',
    'active-railways-network',

    'active-ports-records',
    'active-ports-network',
  ];

  /// =========== PAINÉIS =============
  static List<MenuDrawerItemModule> panelDashboard = [
    MenuDrawerItemModule(
      label: 'PAINÉIS',
      icon: Icons.area_chart,
      subItems: [
        MenuDrawerSubItem(
          label: 'GERAL',
          menuItem: MenuItem.overviewDashboard,
          permissionModule: 'overview-overview-dashboard',
          homeIcon: Icons.insights,
          homeSubtitle: 'Indicadores e resumos',
          homeColor: Color(0xFF2563EB),
        ),
        MenuDrawerSubItem(
          label: 'ESPECÍFICO',
          menuItem: MenuItem.specificDashboard,
          permissionModule: 'specific-overview-dashboard',
          homeIcon: Icons.analytics,
          homeSubtitle: 'KPIs e análises por contrato',
          homeColor: Color(0xFF1D4ED8),
        ),
      ],
    ),
  ];

  /// ===== MENU PRINCIPAL =====
  static List<MenuDrawerItemModule> drawerDocuments = [
    MenuDrawerItemModule(
      label: 'CONTRATOS',
      icon: Icons.document_scanner,
      subItems: [
        MenuDrawerSubItem(
          label: 'CONTRATAÇÃO',
          menuItem: MenuItem.processHiringRecords,
          permissionModule: 'operation-hiring-records',
          homeIcon: Icons.gavel,
          homeSubtitle: 'Fluxos e registros de processo',
          homeColor: Color(0xFF0EA5E9),
        ),
        MenuDrawerSubItem(
          label: 'ADITIVOS',
          menuItem: MenuItem.processAdditiveRecords,
          permissionModule: 'operation-additive-records',
          homeIcon: Icons.edit_note,
          homeSubtitle: 'Fluxos e registros de processo',
          homeColor: Color(0xFF0EA5E9),
        ),
        MenuDrawerSubItem(
          label: 'APOSTILAMENTOS',
          menuItem: MenuItem.processApostillesRecords,
          permissionModule: 'operation-apostilles-records',
          homeIcon: Icons.bookmark_added,
          homeSubtitle: 'Fluxos e registros de processo',
          homeColor: Color(0xFF0EA5E9),
        ),
        MenuDrawerSubItem(
          label: 'MEDIÇÕES',
          menuItem: MenuItem.processMeasurementsRecords,
          permissionModule: 'operation-measurements-records',
          homeIcon: Icons.receipt_long,
          homeSubtitle: 'Fluxos e registros de processo',
          homeColor: Color(0xFF0EA5E9),
        ),
        MenuDrawerSubItem(
          label: 'VIGÊNCIAS',
          menuItem: MenuItem.processValidityRecords,
          permissionModule: 'operation-validity-records',
          homeIcon: Icons.task_alt,
          homeSubtitle: 'Fluxos e registros de processo',
          homeColor: Color(0xFF0EA5E9),
        ),
        MenuDrawerSubItem(
          label: 'ORÇAMENTO DA OBRA',
          menuItem: MenuItem.processHiringBudget,
          permissionModule: 'operation-hiring-budget',
          homeIcon: Icons.attach_money,
          homeSubtitle: 'Orçamento e insumos',
          homeColor: Color(0xFF0D9488),
        ),
      ],
    ),
  ];

  static List<MenuDrawerItemModule> drawerDepartments = [
    MenuDrawerItemModule(
      label: 'OPERACIONAL',
      icon: Icons.engineering_outlined,
      subItems: [
        MenuDrawerSubItem(
          label: 'DIÁRIO DE OBRA',
          menuItem: MenuItem.operationMonitoringWork,
          permissionModule: 'operation-work-timeline',
          homeIcon: Icons.timeline,
          homeSubtitle: 'Execução e acompanhamento',
          homeColor: Color(0xFF059669),
        ),
        MenuDrawerSubItem(
          label: 'CRONOGRAMA',
          menuItem: MenuItem.processHiringSchedule,
          permissionModule: 'operation-hiring-schedule',
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
          menuItem: MenuItem.planningProjectRegistration,
          permissionModule: 'planning-sigmine-records',
          homeIcon: Icons.architecture,
          homeSubtitle: 'Planejamento e cadastros',
          homeColor: Color(0xFF1E40AF),
        ),
        MenuDrawerSubItem(
          label: 'FAIXA DE DOMÍNIO',
          menuItem: MenuItem.planningRightOfWayRecords,
          permissionModule: 'planning-rightWay-records',
          homeIcon: Icons.signpost_outlined,
          homeSubtitle: 'Planejamento e cadastros',
          homeColor: Color(0xFF1E40AF),
        ),
        MenuDrawerSubItem(
          label: 'MEIO AMBIENTE',
          menuItem: MenuItem.planningEnvironmentRecords,
          permissionModule: 'planning-environment-records',
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
          menuItem: MenuItem.trafficAccidentsDashboard,
          permissionModule: 'traffic-accidents-overview-dashboard',
          homeIcon: Icons.query_stats,
          homeSubtitle: 'Sinistros e infrações',
          homeColor: Color(0xFFEA580C),
        ),
        MenuDrawerSubItem(
          label: 'BOLETIM DE SINISTRO',
          menuItem: MenuItem.trafficAccidentsRecords,
          permissionModule: 'traffic-accidents-records',
          homeIcon: Icons.report,
          homeSubtitle: 'Sinistros e infrações',
          homeColor: Color(0xFFEA580C),
        ),
        MenuDrawerSubItem(
          label: 'PAINEL DAS INFRAÇÕES',
          menuItem: MenuItem.trafficInfractionsDashboard,
          permissionModule: 'traffic-infractions-overview-dashboard',
          homeIcon: Icons.rule_folder,
          homeSubtitle: 'Sinistros e infrações',
          homeColor: Color(0xFFEA580C),
        ),
        MenuDrawerSubItem(
          label: 'BOLETIM DE INFRAÇÃO',
          menuItem: MenuItem.trafficInfractionsRecords,
          permissionModule: 'traffic-infractions-records',
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
          menuItem: MenuItem.financialPaymentsDashboard,
          permissionModule: 'financial-payments-overview-dashboard',
          homeIcon: Icons.stacked_line_chart,
          homeSubtitle: 'Pagamentos e empreendimentos',
          homeColor: Color(0xFF0D9488),
        ),
        MenuDrawerSubItem(
          label: 'ORÇAMENTO DO ÓRGÃO',
          menuItem: MenuItem.financialPaymentsRecords,
          permissionModule: 'financial-payments-records',
          homeIcon: Icons.payments,
          homeSubtitle: 'Pagamentos e empreendimentos',
          homeColor: Color(0xFF0D9488),
        ),
        MenuDrawerSubItem(
          label: 'EMPENHOS',
          menuItem: MenuItem.financialCommitmentDashboard,
          permissionModule: 'financial-commitment-overview-dashboard',
          homeIcon: Icons.auto_graph,
          homeSubtitle: 'Pagamentos e empreendimentos',
          homeColor: Color(0xFF0D9488),
        ),
        MenuDrawerSubItem(
          label: 'PAGAMENTOS',
          menuItem: MenuItem.financialCommitmentRecords,
          permissionModule: 'financial-commitment-records',
          homeIcon: Icons.receipt_long_outlined,
          homeSubtitle: 'Pagamentos e empreendimentos',
          homeColor: Color(0xFF0D9488),
        ),
      ],
    ),
  ];

  /// ===== ATIVOS =====
  static List<MenuDrawerItemModule> drawerActives = [
    MenuDrawerItemModule(
      label: 'RODOVIAS',
      icon: Icons.alt_route,
      subItems: [
        MenuDrawerSubItem(
          label: 'MALHA RODOVIÁRIA',
          menuItem: MenuItem.activeRoadNetwork,
          permissionModule: 'active-road-network',
          homeIcon: Icons.alt_route,
          homeSubtitle: 'Malha e levantamentos',
          homeColor: Color(0xFF334155),
        ),
        MenuDrawerSubItem(
          label: 'SISTEMA RODOVIÁRIO',
          menuItem: MenuItem.activeRoadRegistration,
          permissionModule: 'active-road-records',
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
          menuItem: MenuItem.activesOAEsNetwork,
          permissionModule: 'active-oaes-network',
          homeIcon: Icons.construction,
          homeSubtitle: 'Malha e levantamentos',
          homeColor: Color(0xFF334155),
        ),
        MenuDrawerSubItem(
          label: 'LEVANTAMENTO',
          menuItem: MenuItem.activeOAEsRegistration,
          permissionModule: 'active-oaes-records',
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
          menuItem: MenuItem.activeAirportsNetwork,
          permissionModule: 'active-airports-network',
          homeIcon: Icons.flight_takeoff,
          homeSubtitle: 'Malha e levantamentos',
          homeColor: Color(0xFF334155),
        ),
        MenuDrawerSubItem(
          label: 'LEVANTAMENTO',
          menuItem: MenuItem.activeAirportsRegistration,
          permissionModule: 'active-airports-records',
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
          menuItem: MenuItem.activeRailwaysNetwork,
          permissionModule: 'active-railways-network',
          homeIcon: Icons.train_outlined,
          homeSubtitle: 'Malha e levantamentos',
          homeColor: Color(0xFF334155),
        ),
        MenuDrawerSubItem(
          label: 'LEVANTAMENTO',
          menuItem: MenuItem.activeRailwaysRegistration,
          permissionModule: 'active-railways-records',
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
          menuItem: MenuItem.activePortsNetwork,
          permissionModule: 'active-ports-network',
          homeIcon: Icons.sailing_outlined,
          homeSubtitle: 'Malha e levantamentos',
          homeColor: Color(0xFF334155),
        ),
        MenuDrawerSubItem(
          label: 'LEVANTAMENTO',
          menuItem: MenuItem.activeRegistrationPorts,
          permissionModule: 'active-ports-records',
          homeIcon: Icons.checklist_outlined,
          homeSubtitle: 'Malha e levantamentos',
          homeColor: Color(0xFF334155),
        ),
      ],
    ),
  ];

  /// ==========================
  /// HOME (Fonte única de seções)
  /// ==========================
  static List<HomeSectionConfig> homeSections = [
    HomeSectionConfig(
      title: 'MÓDULOS',
      groups: [
        ...panelDashboard,
        ...drawerDocuments,
        ...drawerDepartments,
      ],
    ),
    HomeSectionConfig(
      title: 'ATIVOS',
      groups: drawerActives,
    ),
  ];

  /// ==========================
  /// HOME (grupos exibidos como seções)
  /// Ordem: PAINÉIS -> CONTRATOS -> OPERACIONAL/PLANEJAMENTO/TRÁFEGO/FINANCEIRO -> ATIVOS -> CRM
  /// ==========================
  static List<MenuDrawerItemModule> homeGroups = [
    ...panelDashboard,
    ...drawerDocuments,
    ...drawerDepartments,
    ...drawerActives,
  ];

}


