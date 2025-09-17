import 'package:flutter/material.dart';
import '../../../_widgets/drawer/menu_drawer_item.dart';
import '../../../_widgets/drawer/menu_drawer_sub_item.dart';


enum MenuItem {
  documentsContractsDashboard,
  documentsContractsRecords,
  documentsMeasurementsDashboard,
  documentsMeasurementsRecords,

  operationMonitoringWork,

  planningProjectDashboard,
  planningProjectRegistration,
  planningRightOfWayRecords,
  planningEnvironmentDashboard,
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
    'documents-contracts-dashboard',
    'documents-contracts-records',
    'documents-measurements-dashboard',
    'documents-measurements-records',

    'operation-work-timeline',

    'planning-projects-dashboard',
    'planning-projects-records',
    'planning-rightWay-records',
    'planning-environment-dashboard',
    'planning-environment-records',

    'traffic-accidents-dashboard',
    'traffic-accidents-records',
    'traffic-infractions-dashboard',
    'traffic-infractions-records',

    'financial-payments-dashboard',
    'financial-payments-records',
    'financial-commitment-dashboard',
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

  /// ===== MENU PRINCIPAL =====
  static List<MenuDrawerItemModel> drawerDocuments = [
    MenuDrawerItemModel(
      label: 'CONTRATOS',
      icon: Icons.document_scanner,
      subItems: [
        MenuDrawerSubItem(
          label: 'PAINEL',
          menuItem: MenuItem.documentsContractsDashboard,
          permissionModule: 'documents-contracts-dashboard',
        ),
        MenuDrawerSubItem(
          label: 'CONTRATOS',
          menuItem: MenuItem.documentsContractsRecords,
          permissionModule: 'documents-contracts-records',
        ),
        MenuDrawerSubItem(
          label: 'PAINEL',
          menuItem: MenuItem.documentsMeasurementsDashboard,
          permissionModule: 'documents-measurements-dashboard',
        ),
        MenuDrawerSubItem(
          label: 'MEDIÇÕES',
          menuItem: MenuItem.documentsMeasurementsRecords,
          permissionModule: 'documents-measurements-records',
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
          label: 'PAINEL',
          menuItem: MenuItem.planningProjectDashboard,
          permissionModule: 'planning-projects-dashboard',
        ),
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
          label: 'PAINEL',
          menuItem: MenuItem.planningEnvironmentDashboard,
          permissionModule: 'planning-environment-dashboard',
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
          permissionModule: 'traffic-accidents-dashboard',
        ),
        MenuDrawerSubItem(
          label: 'ACIDENTES',
          menuItem: MenuItem.trafficAccidentsRecords,
          permissionModule: 'traffic-accidents-records',
        ),
        MenuDrawerSubItem(
          label: 'PAINEL',
          menuItem: MenuItem.trafficInfractionsDashboard,
          permissionModule: 'traffic-infractions-dashboard',
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
          permissionModule: 'financial-payments-dashboard',
        ),
        MenuDrawerSubItem(
          label: 'PAGAMENTOS',
          menuItem: MenuItem.financialPaymentsRecords,
          permissionModule: 'financial-payments-records',
        ),
        MenuDrawerSubItem(
          label: 'PAINEL',
          menuItem: MenuItem.financialCommitmentDashboard,
          permissionModule: 'financial-commitment-dashboard',
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
