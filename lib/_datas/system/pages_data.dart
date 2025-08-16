import 'package:flutter/material.dart';
import '../../screens/menus/drawer_menu.dart';


enum MenuItem {
  documentsContractsDashboard,
  documentsContractsRecords,
  documentsMeasurementsDashboard,
  documentsMeasurementsRecords,

  operationMonitoringWork,
  operationExpropriationDashboard,
  operationExpropriationRecords,

  planningDashboard,
  planningRegistration,

  trafficAccidentsDashboard,
  trafficAccidentsRecords,
  trafficInfractionsDashboard,
  trafficInfractionsRecords,

  financialPaymentsDashboard,
  financialPaymentsRecords,
  financialCommitmentDashboard,
  financialCommitmentRecords,

  activeRoadDashboard,
  activeRoadRegistration,
  activeRoadNetwork,

  activeOAEsDashboard,
  activeOAEsRegistration,
  activesOAEsNetwork,

  activeAirportsDashboard,
  activeAirportsRegistration,
  activeAirportsNetwork,

  activeRailwaysDashboard,
  activeRailwaysRegistration,
  activeRailwaysNetwork,

  activePortsDashboard,
  activeRegistrationPorts,
  activePortsNetwork,
}

class PagesData {

  static List<String> module = [
    'documents-contracts-dashboard',
    'documents-contracts-records',
    'documents-measurements-dashboard',
    'documents-measurements-records',

    'operation-work-timeline',
    'operation-expropriation-dashboard',
    'operation-expropriation-records',

    'planning-dashboard',
    'planning-records',

    'traffic-accidents-dashboard',
    'traffic-accidents-records',
    'traffic-infractions-dashboard',
    'traffic-infractions-records',

    'financial-payments-dashboard',
    'financial-payments-records',
    'financial-commitment-dashboard',
    'financial-commitment-records',

    'active-road-dashboard',
    'active-road-records',
    'active-road-network',

    'active-oaes-dashboard',
    'active-oaes-records',
    'active-oaes-network',

    'active-airports-dashboard',
    'active-airports-records',
    'active-airports-network',

    'active-railways-dashboard',
    'active-railways-records',
    'active-railways-network',

    'active-ports-dashboard',
    'active-ports-records',
    'active-ports-network',
  ];

  static List<DrawerItemModel> drawerDocuments = [
    DrawerItemModel(
      label: 'CONTRATOS',
      icon: Icons.document_scanner,
      subItems: [
        DrawerSubItem(
          label: 'PAINEL',
          menuItem: MenuItem.documentsContractsDashboard,
          permissionModule: 'documents-contracts-dashboard',
        ),
        DrawerSubItem(
          label: 'CONTRATOS',
          menuItem: MenuItem.documentsContractsRecords,
          permissionModule: 'documents-contracts-records',
        ),
        DrawerSubItem(
          label: 'PAINEL',
          menuItem: MenuItem.documentsMeasurementsDashboard,
          permissionModule: 'documents-measurements-dashboard',
        ),
        DrawerSubItem(
          label: 'MEDIÇÕES',
          menuItem: MenuItem.documentsMeasurementsRecords,
          permissionModule: 'documents-measurements-records',
        ),
      ],
    ),
  ];

  static List<DrawerItemModel> drawerDepartments = [
    DrawerItemModel(
      label: 'DOIRC',
      icon: Icons.engineering_outlined,
      subItems: [
        DrawerSubItem(
          label: 'CRONOGRAMA\nFÍSICO',
          menuItem: MenuItem.operationMonitoringWork,
          permissionModule: 'operation-work-timeline',
        ),
        DrawerSubItem(
          label: 'PAINEL',
          menuItem: MenuItem.operationExpropriationDashboard,
          permissionModule: 'operation-expropriation-dashboard',
        ),
        DrawerSubItem(
          label: 'DESAPROPRIAÇÃO',
          menuItem: MenuItem.operationExpropriationRecords,
          permissionModule: 'operation-expropriation-records',
        ),
      ],
    ),
    DrawerItemModel(
      label: 'DIPLA',
      icon: Icons.bar_chart,
      subItems: [
        DrawerSubItem(
          label: 'PAINEL',
          menuItem: MenuItem.planningDashboard,
          permissionModule: 'planning-dashboard',
        ),
        DrawerSubItem(
          label: 'PROJETOS',
          menuItem: MenuItem.planningRegistration,
          permissionModule: 'planning-records',
        ),
      ],
    ),
    DrawerItemModel(
      label: 'DTT',
      icon: Icons.traffic,
      subItems: [
        DrawerSubItem(
          label: 'PAINEL',
          menuItem: MenuItem.trafficAccidentsDashboard,
          permissionModule: 'traffic-accidents-dashboard',
        ),
        DrawerSubItem(
          label: 'ACIDENTES',
          menuItem: MenuItem.trafficAccidentsRecords,
          permissionModule: 'traffic-accidents-records',
        ),
        DrawerSubItem(
          label: 'PAINEL',
          menuItem: MenuItem.trafficInfractionsDashboard,
          permissionModule: 'traffic-infractions-dashboard',
        ),
        DrawerSubItem(
          label: 'INFRAÇÕES',
          menuItem: MenuItem.trafficInfractionsRecords,
          permissionModule: 'traffic-infractions-records',
        ),
      ],
    ),
    DrawerItemModel(
      label: 'DIF',
      icon: Icons.attach_money,
      subItems: [
        DrawerSubItem(
          label: 'PAINEL',
          menuItem: MenuItem.financialPaymentsDashboard,
          permissionModule: 'financial-payments-dashboard',
        ),
        DrawerSubItem(
          label: 'PAGAMENTOS',
          menuItem: MenuItem.financialPaymentsRecords,
          permissionModule: 'financial-payments-records',
        ),
        DrawerSubItem(
          label: 'PAINEL',
          menuItem: MenuItem.financialCommitmentDashboard,
          permissionModule: 'financial-commitment-dashboard',
        ),
        DrawerSubItem(
          label: 'EMPENHOS',
          menuItem: MenuItem.financialCommitmentRecords,
          permissionModule: 'financial-commitment-records',
        ),
      ],
    ),
  ];

  static List<DrawerItemModel> drawerModals = [
    DrawerItemModel(
      label: 'RODOVIAS',
      icon: Icons.alt_route,
      subItems: [
        DrawerSubItem(
          label: 'PAINEL',
          menuItem: MenuItem.activeRoadDashboard,
          permissionModule: 'active-road-dashboard',
        ),
        DrawerSubItem(
          label: 'MALHA RODOVIÁRIA',
          menuItem: MenuItem.activeRoadNetwork,
          permissionModule: 'active-road-network',
        ),
        DrawerSubItem(
          label: 'SISTEMA RODOVIÁRIO',
          menuItem: MenuItem.activeRoadRegistration,
          permissionModule: 'active-road-records',
        ),
      ],
    ),
    DrawerItemModel(
      label: 'PONTES',
      icon: Icons.car_repair,
      subItems: [
        DrawerSubItem(
          label: 'PAINEL',
          menuItem: MenuItem.activeOAEsDashboard,
          permissionModule: 'active-oaes-dashboard',
        ),
        DrawerSubItem(
          label: 'MALHA OAEs',
          menuItem: MenuItem.activesOAEsNetwork,
          permissionModule: 'active-oaes-network',
        ),
        DrawerSubItem(
          label: 'LEVANTAMENTO',
          menuItem: MenuItem.activeOAEsRegistration,
          permissionModule: 'active-oaes-records',
        ),
      ],
    ),
    DrawerItemModel(
      label: 'AEROPORTOS',
      icon: Icons.local_airport,
      subItems: [
        DrawerSubItem(
          label: 'PAINEL',
          menuItem: MenuItem.activeAirportsDashboard,
          permissionModule: 'active-airports-dashboard',
        ),
        DrawerSubItem(
          label: 'MALHA AEROPORTUÁRIA',
          menuItem: MenuItem.activeAirportsNetwork,
          permissionModule: 'active-airports-network',
        ),
        DrawerSubItem(
          label: 'LEVANTAMENTO',
          menuItem: MenuItem.activeAirportsRegistration,
          permissionModule: 'active-airports-records',
        ),
      ],
    ),
    DrawerItemModel(
      label: 'FERROVIAS',
      icon: Icons.train,
      subItems: [
        DrawerSubItem(
          label: 'PAINEL',
          menuItem: MenuItem.activeRailwaysDashboard,
          permissionModule: 'active-railways-dashboard',
        ),
        DrawerSubItem(
          label: 'MALHA FERROVIÁRIA',
          menuItem: MenuItem.activeRailwaysNetwork,
          permissionModule: 'active-railways-network',
        ),
        DrawerSubItem(
          label: 'LEVANTAMENTO',
          menuItem: MenuItem.activeRailwaysRegistration,
          permissionModule: 'active-railways-records',
        ),
      ],
    ),
    DrawerItemModel(
      label: 'PORTOS E BALSAS',
      icon: Icons.directions_boat,
      subItems: [
        DrawerSubItem(
          label: 'PAINEL',
          menuItem: MenuItem.activePortsDashboard,
          permissionModule: 'active-ports-dashboard',
        ),
        DrawerSubItem(
          label: 'MALHA PORTUÁRIA',
          menuItem: MenuItem.activePortsNetwork,
          permissionModule: 'active-ports-network',
        ),
        DrawerSubItem(
          label: 'LEVANTAMENTO',
          menuItem: MenuItem.activeRegistrationPorts,
          permissionModule: 'active-ports-records',
        ),
      ],
    ),

  ];

  static List<String> permission = [
    'create',
    'read',
  ];
}
