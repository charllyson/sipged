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

    'planning-projects-overview-dashboard',
    'planning-projects-records',
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

  static List<String> moduleName = [
    'OBRAS',
    'JURÍDICO',
  ];

  // pages_data.dart

  /// Qual flag de perfil do usuário habilita cada área do dropdown?
  static String? profileKeyForArea(String areaLabel) {
    switch (areaLabel.trim().toUpperCase()) {
      case 'OBRAS':
        return 'profileWork';
      case 'JURÍDICO':
        return 'profileLegal';
      default:
        return null;
    }
  }


  // mapeia o moduleName -> gradient (JURÍDICO com Bordô/Burgundy/Marsala)
  static Gradient gradientForModule(String name) {
    switch (name.toUpperCase()) {
      case 'OBRAS':
        return const LinearGradient(
          colors: [
            Color.fromARGB(255, 27, 32, 51),
            Color.fromARGB(255, 144, 202, 249),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'JURÍDICO':
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

  /// ===== Regra de acesso por ÁREA do dropdown =====
  /// Para considerar que o usuário tem acesso à área, ele deve possuir
  /// permissão READ em pelo menos UM destes módulos.
  static final Map<String, List<String>> areaRequiredModules = {
    'OBRAS': [
      'overview-overview-dashboard',
      'process-hiring-records',
      'operation-work-timeline',
      'active-road-network',
    ],
    'JURÍDICO': [
      'process-additive-records',
      'process-apostilles-records',
      'process-validity-records',
      'process-hiring-records',
    ],
  };

  static List<String> requiredModulesForArea(String areaLabel) {
    return areaRequiredModules[areaLabel.toUpperCase()] ?? const [];
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
        ),
        MenuDrawerSubItem(
          label: 'ESPECÍFICO',
          menuItem: MenuItem.specificDashboard,
          permissionModule: 'specific-overview-dashboard',
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
        ),
        MenuDrawerSubItem(
          label: 'VIGÊNCIAS',
          menuItem: MenuItem.processValidityRecords,
          permissionModule: 'process-validity-records',
        ),
        MenuDrawerSubItem(
          label: 'ADITIVOS',
          menuItem: MenuItem.processAdditiveRecords,
          permissionModule: 'process-additive-records',
        ),
        MenuDrawerSubItem(
          label: 'APOSTILAMENTOS',
          menuItem: MenuItem.processApostillesRecords,
          permissionModule: 'process-apostilles-records',
        ),
        MenuDrawerSubItem(
          label: 'MEDIÇÕES',
          menuItem: MenuItem.processMeasurementsRecords,
          permissionModule: 'process-measurements-records',
        ),
        MenuDrawerSubItem(
          label: 'REGULARIZAÇÃO DE TERRENOS',
          menuItem: MenuItem.processLandRegularizationRecords,
          permissionModule: 'process-land-regularization-records',
        ),
      ],
    ),
  ];

  static List<MenuDrawerItemModel> drawerDepartments = [
    MenuDrawerItemModel(
      label: 'DOIRC',
      icon: Icons.engineering_outlined,
      subItems: [
        MenuDrawerSubItem(
          label: 'CRONOGRAMA\nFÍSICO',
          menuItem: MenuItem.operationMonitoringWork,
          permissionModule: 'operation-work-timeline',
        ),
      ],
    ),
    MenuDrawerItemModel(
      label: 'DIPLA',
      icon: Icons.bar_chart,
      subItems: [
        MenuDrawerSubItem(
          label: 'PROJETOS',
          menuItem: MenuItem.planningProjectRegistration,
          permissionModule: 'planning-projects-records',
        ),
        MenuDrawerSubItem(
          label: 'FAIXA DE DOMÍNIO',
          menuItem: MenuItem.planningRightOfWayRecords,
          permissionModule: 'planning-rightWay-records',
        ),
        MenuDrawerSubItem(
          label: 'MEIO AMBIENTE',
          menuItem: MenuItem.planningEnvironmentRecords,
          permissionModule: 'planning-environment-records',
        ),
      ],
    ),
    MenuDrawerItemModel(
      label: 'DTT',
      icon: Icons.traffic,
      subItems: [
        MenuDrawerSubItem(
          label: 'PAINEL',
          menuItem: MenuItem.trafficAccidentsDashboard,
          permissionModule: 'traffic-accidents-overview-dashboard',
        ),
        MenuDrawerSubItem(
          label: 'SINISTROS',
          menuItem: MenuItem.trafficAccidentsRecords,
          permissionModule: 'traffic-accidents-records',
        ),
        MenuDrawerSubItem(
          label: 'PAINEL',
          menuItem: MenuItem.trafficInfractionsDashboard,
          permissionModule: 'traffic-infractions-overview-dashboard',
        ),
        MenuDrawerSubItem(
          label: 'INFRAÇÕES',
          menuItem: MenuItem.trafficInfractionsRecords,
          permissionModule: 'traffic-infractions-records',
        ),
      ],
    ),
    MenuDrawerItemModel(
      label: 'DIF',
      icon: Icons.attach_money,
      subItems: [
        MenuDrawerSubItem(
          label: 'PAINEL',
          menuItem: MenuItem.financialPaymentsDashboard,
          permissionModule: 'financial-payments-overview-dashboard',
        ),
        MenuDrawerSubItem(
          label: 'PAGAMENTOS',
          menuItem: MenuItem.financialPaymentsRecords,
          permissionModule: 'financial-payments-records',
        ),
        MenuDrawerSubItem(
          label: 'PAINEL',
          menuItem: MenuItem.financialCommitmentDashboard,
          permissionModule: 'financial-commitment-overview-dashboard',
        ),
        MenuDrawerSubItem(
          label: 'EMPENHOS',
          menuItem: MenuItem.financialCommitmentRecords,
          permissionModule: 'financial-commitment-records',
        ),
      ],
    ),
  ];

  /// ===== MODULOS =====
  static List<MenuDrawerItemModel> drawerActives = [
    MenuDrawerItemModel(
      label: 'RODOVIAS',
      icon: Icons.alt_route,
      subItems: [
        MenuDrawerSubItem(
          label: 'MALHA RODOVIÁRIA',
          menuItem: MenuItem.activeRoadNetwork,
          permissionModule: 'active-road-network',
        ),
        MenuDrawerSubItem(
          label: 'SISTEMA RODOVIÁRIO',
          menuItem: MenuItem.activeRoadRegistration,
          permissionModule: 'active-road-records',
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
        ),
        MenuDrawerSubItem(
          label: 'LEVANTAMENTO',
          menuItem: MenuItem.activeOAEsRegistration,
          permissionModule: 'active-oaes-records',
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
        ),
        MenuDrawerSubItem(
          label: 'LEVANTAMENTO',
          menuItem: MenuItem.activeAirportsRegistration,
          permissionModule: 'active-airports-records',
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
        ),
        MenuDrawerSubItem(
          label: 'LEVANTAMENTO',
          menuItem: MenuItem.activeRailwaysRegistration,
          permissionModule: 'active-railways-records',
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
        ),
        MenuDrawerSubItem(
          label: 'LEVANTAMENTO',
          menuItem: MenuItem.activeRegistrationPorts,
          permissionModule: 'active-ports-records',
        ),
      ],
    ),
  ];
}
