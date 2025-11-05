// lib/_blocs/system/pages/pages_data.dart
import 'package:flutter/material.dart';
import '../../../_widgets/drawer/menu_drawer_item.dart';
import '../../../_widgets/drawer/menu_drawer_sub_item.dart';

enum MenuItem {
  overviewDashboard,
  specificDashboard,

  processHiringRecords,
  processValidityRecords,
  processAdditiveRecords,
  processApostillesRecords,
  processMeasurementsRecords,
  processLandRegularizationRecords,

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

  crmLegal,
}

class PagesData {
  /// ===== MÓDULOS =====
  static List<String> module = [
    'overview-overview-dashboard',
    'specific-overview-dashboard',

    'process-hiring-records',
    'process-validity-records',
    'process-additive-records',
    'process-apostilles-records',
    'process-measurements-records',
    'process-land-regularization-records',

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

    'crm-legal',
  ];

  static List<String> moduleName = [
    'DER',
    'DNIT-RO',
    'AM PRECATÓRIOS',
  ];

  /// Qual flag de perfil do usuário habilita cada área do dropdown?
  static String? profileKeyForArea(String areaLabel) {
    switch (areaLabel.trim().toUpperCase()) {
      case 'DNIT-RO':
        return 'profileWork';
      case 'AM PRECATÓRIOS':
        return 'profileLegal';
      case 'DER':
      default:
        return 'profileWork';
    }
  }

  /// Helper opcional (se precisar fora do TenantFirebase)
  static String flavorForArea(String areaLabel) {
    switch (areaLabel.trim().toUpperCase()) {
      case 'DNIT-RO':
        return 'dnitro';
      case 'AM PRECATÓRIOS':
        return 'amprecatorios';
      case 'DER':
      default:
        return 'der';
    }
  }

  /// mapeia o moduleName -> gradient (JURÍDICO com Bordô/Burgundy/Marsala)
  static Gradient gradientForModule(String name) {
    switch (name.toUpperCase()) {
      case 'DNIT-RO':
        return const LinearGradient(
          colors: [
            Color.fromARGB(255, 27, 32, 51),
            Color.fromARGB(255, 144, 202, 249),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'AM PRECATÓRIOS':
        return const LinearGradient(
          colors: [
            Color(0xFF4B0016), // Bordô
            Color(0xFF800020), // Burgundy
            Color(0xFF955251), // Marsala
          ],
          stops: [0.0, 0.58, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'DER':
      default:
        return const LinearGradient(
          colors: [
            Color.fromARGB(255, 27, 32, 51),
            Color.fromARGB(255, 144, 202, 249),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  /// =========== PAINÉIS =============
  static List<MenuDrawerItemModel> panelDashboard = [
    MenuDrawerItemModel(
      label: 'PAINÉIS',
      icon: Icons.area_chart,
      subItems: [
        MenuDrawerSubItem(
          label: 'GERAL',
          menuItem: MenuItem.overviewDashboard,
          permissionModule: 'overview-overview-dashboard',
          homeIcon: Icons.insights, // ícone exclusivo do card da Home
        ),
        MenuDrawerSubItem(
          label: 'ESPECÍFICO',
          menuItem: MenuItem.specificDashboard,
          permissionModule: 'specific-overview-dashboard',
          homeIcon: Icons.analytics,
        ),
      ],
    ),
  ];

  /// ===== MENU PRINCIPAL =====
  static List<MenuDrawerItemModel> drawerDocuments = [
    MenuDrawerItemModel(
      label: 'PROCESSOS',
      icon: Icons.document_scanner,
      subItems: [
        MenuDrawerSubItem(
          label: 'CONTRATAÇÃO',
          menuItem: MenuItem.processHiringRecords,
          permissionModule: 'process-hiring-records',
          homeIcon: Icons.gavel,
        ),
        MenuDrawerSubItem(
          label: 'VIGÊNCIAS',
          menuItem: MenuItem.processValidityRecords,
          permissionModule: 'process-validity-records',
          homeIcon: Icons.task_alt,
        ),
        MenuDrawerSubItem(
          label: 'ADITIVOS',
          menuItem: MenuItem.processAdditiveRecords,
          permissionModule: 'process-additive-records',
          homeIcon: Icons.edit_note,
        ),
        MenuDrawerSubItem(
          label: 'APOSTILAMENTOS',
          menuItem: MenuItem.processApostillesRecords,
          permissionModule: 'process-apostilles-records',
          homeIcon: Icons.bookmark_added,
        ),
        MenuDrawerSubItem(
          label: 'MEDIÇÕES',
          menuItem: MenuItem.processMeasurementsRecords,
          permissionModule: 'process-measurements-records',
          homeIcon: Icons.receipt_long,
        ),
        MenuDrawerSubItem(
          label: 'REGULARIZAÇÃO DE TERRENOS',
          menuItem: MenuItem.processLandRegularizationRecords,
          permissionModule: 'process-land-regularization-records',
          homeIcon: Icons.layers,
        ),
      ],
    ),
  ];

  static List<MenuDrawerItemModel> drawerDepartments = [
    MenuDrawerItemModel(
      label: 'OPERACIONAL',
      icon: Icons.engineering_outlined,
      subItems: [
        MenuDrawerSubItem(
          label: 'DIÁRIO DE OBRA',
          menuItem: MenuItem.operationMonitoringWork,
          permissionModule: 'operation-work-timeline',
          homeIcon: Icons.timeline,
        ),
      ],
    ),
    MenuDrawerItemModel(
      label: 'PLANEJAMENTO',
      icon: Icons.bar_chart,
      subItems: [
        MenuDrawerSubItem(
          label: 'PROJETOS',
          menuItem: MenuItem.planningProjectRegistration,
          permissionModule: 'planning-sigmine-records',
          homeIcon: Icons.architecture,
        ),
        MenuDrawerSubItem(
          label: 'FAIXA DE DOMÍNIO',
          menuItem: MenuItem.planningRightOfWayRecords,
          permissionModule: 'planning-rightWay-records',
          homeIcon: Icons.signpost_outlined,
        ),
        MenuDrawerSubItem(
          label: 'MEIO AMBIENTE',
          menuItem: MenuItem.planningEnvironmentRecords,
          permissionModule: 'planning-environment-records',
          homeIcon: Icons.local_florist_outlined,
        ),
      ],
    ),
    MenuDrawerItemModel(
      label: 'TRÁFEGO',
      icon: Icons.traffic,
      subItems: [
        MenuDrawerSubItem(
          label: 'PAINEL DOS SINISTROS',
          menuItem: MenuItem.trafficAccidentsDashboard,
          permissionModule: 'traffic-accidents-overview-dashboard',
          homeIcon: Icons.query_stats,
        ),
        MenuDrawerSubItem(
          label: 'BOLETIM DE SINISTRO',
          menuItem: MenuItem.trafficAccidentsRecords,
          permissionModule: 'traffic-accidents-records',
          homeIcon: Icons.report,
        ),
        MenuDrawerSubItem(
          label: 'PAINEL DAS INFRAÇÕES',
          menuItem: MenuItem.trafficInfractionsDashboard,
          permissionModule: 'traffic-infractions-overview-dashboard',
          homeIcon: Icons.rule_folder,
        ),
        MenuDrawerSubItem(
          label: 'BOLETIM DE INFRAÇÃO',
          menuItem: MenuItem.trafficInfractionsRecords,
          permissionModule: 'traffic-infractions-records',
          homeIcon: Icons.rule,
        ),
      ],
    ),
    MenuDrawerItemModel(
      label: 'FINANCEIRO',
      icon: Icons.attach_money,
      subItems: [
        MenuDrawerSubItem(
          label: 'PAINEL',
          menuItem: MenuItem.financialPaymentsDashboard,
          permissionModule: 'financial-payments-overview-dashboard',
          homeIcon: Icons.stacked_line_chart,
        ),
        MenuDrawerSubItem(
          label: 'PAGAMENTOS',
          menuItem: MenuItem.financialPaymentsRecords,
          permissionModule: 'financial-payments-records',
          homeIcon: Icons.payments,
        ),
        MenuDrawerSubItem(
          label: 'PAINEL',
          menuItem: MenuItem.financialCommitmentDashboard,
          permissionModule: 'financial-commitment-overview-dashboard',
          homeIcon: Icons.auto_graph,
        ),
        MenuDrawerSubItem(
          label: 'EMPENHOS',
          menuItem: MenuItem.financialCommitmentRecords,
          permissionModule: 'financial-commitment-records',
          homeIcon: Icons.receipt_long_outlined,
        ),
      ],
    ),
  ];

  /// ===== ATIVOS =====
  static List<MenuDrawerItemModel> drawerActives = [
    MenuDrawerItemModel(
      label: 'RODOVIAS',
      icon: Icons.alt_route,
      subItems: [
        MenuDrawerSubItem(
          label: 'MALHA RODOVIÁRIA',
          menuItem: MenuItem.activeRoadNetwork,
          permissionModule: 'active-road-network',
          homeIcon: Icons.alt_route,
        ),
        MenuDrawerSubItem(
          label: 'SISTEMA RODOVIÁRIO',
          menuItem: MenuItem.activeRoadRegistration,
          permissionModule: 'active-road-records',
          homeIcon: Icons.map_outlined,
        ),
      ],
    ),
    MenuDrawerItemModel(
      label: 'PONTES',
      icon: Icons.car_repair,
      subItems: [
        MenuDrawerSubItem(
          label: 'MALHA OAEs',
          menuItem: MenuItem.activesOAEsNetwork,
          permissionModule: 'active-oaes-network',
          homeIcon: Icons.construction,
        ),
        MenuDrawerSubItem(
          label: 'LEVANTAMENTO',
          menuItem: MenuItem.activeOAEsRegistration,
          permissionModule: 'active-oaes-records',
          homeIcon: Icons.assignment_outlined,
        ),
      ],
    ),
    MenuDrawerItemModel(
      label: 'AEROPORTOS',
      icon: Icons.local_airport,
      subItems: [
        MenuDrawerSubItem(
          label: 'MALHA AEROPORTUÁRIA',
          menuItem: MenuItem.activeAirportsNetwork,
          permissionModule: 'active-airports-network',
          homeIcon: Icons.flight_takeoff,
        ),
        MenuDrawerSubItem(
          label: 'LEVANTAMENTO',
          menuItem: MenuItem.activeAirportsRegistration,
          permissionModule: 'active-airports-records',
          homeIcon: Icons.assignment_turned_in_outlined,
        ),
      ],
    ),
    MenuDrawerItemModel(
      label: 'FERROVIAS',
      icon: Icons.train,
      subItems: [
        MenuDrawerSubItem(
          label: 'MALHA FERROVIÁRIA',
          menuItem: MenuItem.activeRailwaysNetwork,
          permissionModule: 'active-railways-network',
          homeIcon: Icons.train_outlined,
        ),
        MenuDrawerSubItem(
          label: 'LEVANTAMENTO',
          menuItem: MenuItem.activeRailwaysRegistration,
          permissionModule: 'active-railways-records',
          homeIcon: Icons.fact_check_outlined,
        ),
      ],
    ),
    MenuDrawerItemModel(
      label: 'PORTOS E BALSAS',
      icon: Icons.directions_boat,
      subItems: [
        MenuDrawerSubItem(
          label: 'MALHA PORTUÁRIA',
          menuItem: MenuItem.activePortsNetwork,
          permissionModule: 'active-ports-network',
          homeIcon: Icons.sailing_outlined,
        ),
        MenuDrawerSubItem(
          label: 'LEVANTAMENTO',
          menuItem: MenuItem.activeRegistrationPorts,
          permissionModule: 'active-ports-records',
          homeIcon: Icons.checklist_outlined,
        ),
      ],
    ),
  ];

  /// =========== JURÍDICO =============
  static List<MenuDrawerItemModel> crmLegal = [
    MenuDrawerItemModel(
      label: 'PROCESSOS',
      icon: Icons.area_chart,
      subItems: [
        MenuDrawerSubItem(
          label: 'CRM',
          menuItem: MenuItem.crmLegal,
          permissionModule: 'crm-legal',
          homeIcon: Icons.account_tree_outlined,
        ),
      ],
    ),
  ];
}
