// lib/screens/menus/menu_list_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:provider/provider.dart';

// ===== Process (core) =====
import 'package:siged/_blocs/_process/process_data.dart';
import 'package:siged/_blocs/_process/process_store.dart';

// ===== Dashboards / Stores auxiliares =====
import 'package:siged/_blocs/process/hiring/1Dfd/dfd_cubit.dart';

// ===== Setores (Operação) =====
import 'package:siged/_blocs/sectors/operation/civil/civil_schedule_bloc.dart';
import 'package:siged/_blocs/sectors/operation/civil/civil_schedule_event.dart';

// ✅ Road agora usa Cubit
import 'package:siged/_blocs/sectors/operation/road/schedule_road_repository.dart';
import 'package:siged/_blocs/sectors/operation/road/schedule_road_cubit.dart';

// ===== UI / Serviços =====
import 'package:siged/_widgets/menu/footBar/foot_bar.dart';
import 'package:siged/_widgets/notification/notification_center.dart';
import 'package:siged/_widgets/notification/app_notification.dart';
import 'package:siged/_services/dxf/map_overlay_cubit.dart';
import 'package:siged/_widgets/list/demand/list_demand_page.dart';
import 'package:siged/screens/home/home_page.dart';

// ===== Páginas =====
import 'package:siged/screens-legal/crm/tab_bar_crm_precatory_page.dart';
import 'package:siged/screens/panels/specific-dashboard/specific_dashboard_page.dart';

import 'package:siged/screens/process/additive/tab_bar_additive_page.dart';
import 'package:siged/screens/process/apostilles/tab_bar_apostilles_page.dart';
import 'package:siged/screens/process/hiring/5Edital/hiring_budget_page.dart';
import 'package:siged/screens/process/hiring/5Edital/hiring_schedule_page.dart';
import 'package:siged/screens/process/hiring/tab_bar_hiring_page.dart';

import 'package:siged/screens/panels/overview-dashboard/general_dashboard_page.dart';
import 'package:siged/screens/process/measurement/tab_bar_measurement_page.dart';
import 'package:siged/screens/process/validity/validity_tab_bar.dart';

import 'package:siged/screens/sectors/operation/schedule/civil/schedule_civil_workspace_page.dart';
import 'package:siged/_widgets/toolBox/tool_widget_controller.dart';

import 'package:siged/screens/actives/airports/network/active_airports_network_page.dart';
import 'package:siged/screens/actives/airports/records/active_airports_records_page.dart';
import 'package:siged/screens/actives/railways/network/active_railways_network_page.dart';
import 'package:siged/screens/actives/railways/records/active_railways_records_page.dart';
import 'package:siged/screens/actives/oaes/network/active_oaes_network_page.dart';
import 'package:siged/screens/actives/oaes/records/active_oaes_records_page.dart';
import 'package:siged/screens/actives/roads/network/active_roads_network_page.dart';
import 'package:siged/screens/actives/roads/records/active_roads_records_page.dart';

import 'package:siged/screens/sectors/financial/tab_bar_financial_page.dart';

import 'package:siged/screens/sectors/operation/schedule/road/schedule_road_workspace_page.dart';
import 'package:siged/screens/sectors/planning/miner/planning_network_page.dart';
import 'package:siged/screens/menus/menu_drawer.dart';

import 'package:siged/_blocs/system/pages/pages_data.dart';
import 'package:siged/_widgets/buttons/float_button_menu.dart';

import 'package:siged/screens/sectors/planning/rightWay/planning_right_way_workspace_page.dart';

import 'package:siged/screens/sectors/traffic/accidents/accidents_records_network_page.dart';
import 'package:siged/screens/sectors/traffic/dashboard/accidents_dashboard_network_page.dart';
import 'package:siged/screens/sectors/traffic/infractions-dashboard/infractions_dashboard_page.dart';
import 'package:siged/screens/sectors/traffic/infrations-records/infractions_records_page.dart';

// ===== Sistema / Usuários =====
import 'package:siged/_blocs/system/user/user_bloc.dart';
import 'package:siged/_blocs/system/user/user_event.dart';
import 'package:siged/_blocs/system/user/user_state.dart';
import 'package:siged/_blocs/system/user/user_data.dart';

// ===== DFD via BLoC =====
import 'package:siged/_blocs/process/hiring/1Dfd/dfd_data.dart';

// ===== Publicação (para número do contrato) =====
import 'package:siged/_blocs/process/hiring/10Publicacao/publicacao_extrato_cubit.dart';
import 'package:siged/_blocs/process/hiring/10Publicacao/publicacao_extrato_data.dart';

class MenuListPage extends StatefulWidget {
  const MenuListPage({super.key});

  @override
  State<MenuListPage> createState() => _MenuListPageState();
}

class _MenuListPageState extends State<MenuListPage> {
  MenuItem? _selectedItem;
  bool _didWarmupUserBloc = false;
  bool _didWarmupStores = false;

  @override
  void initState() {
    super.initState();
  }

  void _onSelectPage(MenuItem item) {
    setState(() => _selectedItem = item);
    Navigator.of(context).maybePop();
  }

  void _goHome() {
    setState(() => _selectedItem = null);
    Navigator.of(context).maybePop();
  }

  /// Monta o rótulo do contrato SEM usar campos legados do ProcessData.
  /// Prioridades:
  ///   1) PublicacaoExtratoData.numeroContrato
  ///   2) DfdData.descricaoObjeto
  ///   3) "Contrato {id}"
  Future<String> _buildContractLabel(
      BuildContext context,
      String contractId, {
        DfdData? dfdData,
      }) async {
    DfdData? dfd = dfdData;

    // Garante DFD carregado
    if (dfd == null) {
      try {
        final dfdBloc = context.read<DfdCubit>();
        dfd = await dfdBloc.getDataForContract(contractId);
      } catch (e) {
        // ignore
      }
    }

    PublicacaoExtratoData? publicacao;
    try {
      final pubBloc = context.read<PublicacaoExtratoCubit>();
      publicacao = await pubBloc.getDataForContract(contractId);
    } catch (e) {
      // ignore
    }

    final numero = (publicacao?.numeroContrato ?? '').trim();
    final descricao = (dfd?.descricaoObjeto ?? '').trim();

    if (numero.isNotEmpty && descricao.isNotEmpty) {
      return '$numero - $descricao';
    }
    if (numero.isNotEmpty) return numero;
    if (descricao.isNotEmpty) return descricao;

    return 'Contrato $contractId';
  }

  Future<void> _navigateByWorkType(
      BuildContext context,
      ProcessData contract,
      ) async {
    final contractId = contract.id ?? '';
    if (contractId.isEmpty) {
      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Contrato sem ID'),
          subtitle: const Text('Não foi possível abrir o cronograma.'),
          type: AppNotificationType.error,
        ),
      );
      return;
    }

    final dfdBloc = context.read<DfdCubit>();
    final DfdData? dfd = await dfdBloc.getDataForContract(contractId);

    final tipoObra = (dfd?.tipoObra ?? '').trim().toUpperCase();
    final resumoContrato =
    await _buildContractLabel(context, contractId, dfdData: dfd);
    if (tipoObra.isEmpty) {
      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Tipo de obra não definido no DFD'),
          subtitle: Text(
            'Cadastre o tipo no DFD para: $resumoContrato',
          ),
          type: AppNotificationType.error,
        ),
      );
      return;
    }

    final km = dfd?.extensaoKm ?? 0.0;
    final totalEstacas = ((km * 1000) / 20).ceil();

    // ====== RODOVIÁRIO -> ScheduleRoadWorkspacePage (agora com Cubit) ======
    if (tipoObra.contains('RODOV')) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RepositoryProvider<ScheduleRoadRepository>(
            create: (_) => ScheduleRoadRepository(),
            child: BlocProvider<ScheduleRoadCubit>(
              create: (ctx) => ScheduleRoadCubit(
                repository: ctx.read<ScheduleRoadRepository>(),
              )..warmup(
                contractId: contractId,
                totalEstacas: totalEstacas,
                initialServiceKey: 'geral',
                summarySubjectContract: resumoContrato,
              ),
              child: Scaffold(
                body: ScheduleRoadWorkspacePage(contractData: contract),
              ),
            ),
          ),
        ),
      );
      return;
    }

    // ====== CIVIL (cronograma residencial) - mantém BLoC antigo ======
    if (tipoObra.contains('CONSTRU')) {
      final scheduleCtrl = ScheduleCivilController();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider<CivilScheduleBloc>(
                create: (ctx) =>
                CivilScheduleBloc()..add(CivilWarmupRequested(contractId)),
              ),
              BlocProvider<MapOverlayCubit>(
                create: (_) => MapOverlayCubit(),
              ),
            ],
            child: Scaffold(
              body: ScheduleCivilWorkspacePage(
                title: 'Cronograma Residencial',
                pageNumber: 1,
                controller: scheduleCtrl,
                contractId: contractId,
              ),
            ),
          ),
        ),
      );
      return;
    }

    if (tipoObra.contains('OAE') || tipoObra.contains('ARTES ESPECIAIS')) {
      NotificationCenter.instance.show(
        AppNotification(
          title:
          const Text('Cronograma para OAEs ainda não disponível.'),
          type: AppNotificationType.warning,
        ),
      );
      return;
    }

    NotificationCenter.instance.show(
      AppNotification(
        title: const Text('Tipo de obra não suportado'),
        subtitle: Text('Tipo lido no DFD: $tipoObra'),
        type: AppNotificationType.error,
      ),
    );
  }

  Widget _buildContractsListPage(
      DemandNavigationCallback onTap, {
        required String pageTitle,
      }) {
    return ListDemandPage(
      pageTitle: pageTitle,
      onTapItem: onTap,
    );
  }

  Widget _getPage(MenuItem item, UserData currentUser) {
    switch (item) {
      case MenuItem.overviewDashboard:
      // Cubit DemandsDashboardCubit já é injetado globalmente no bootstrap.
        return const GeneralDashboardPage();

      case MenuItem.specificDashboard:
        return _buildContractsListPage((context, contract) async {
          context.read<ProcessStore>().select(contract);

          final dfdBloc = context.read<DfdCubit>();
          final DfdData? dfd =
          await dfdBloc.getDataForContract(contract.id ?? '');
          final km = dfd?.extensaoKm ?? 0.0;
          final totalEstacas = ((km * 1000) / 20).ceil();

          final contractId = contract.id ?? '';
          final resumoContrato =
          await _buildContractLabel(context, contractId, dfdData: dfd);

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RepositoryProvider<ScheduleRoadRepository>(
                create: (_) => ScheduleRoadRepository(),
                child: BlocProvider<ScheduleRoadCubit>(
                  create: (ctx) => ScheduleRoadCubit(
                    repository: ctx.read<ScheduleRoadRepository>(),
                  )..warmup(
                    contractId: contractId,
                    totalEstacas: totalEstacas,
                    initialServiceKey: 'geral',
                    summarySubjectContract: resumoContrato,
                  ),
                  child: SpecificDashboardPage(
                    contractData: contract,
                  ),
                ),
              ),
            ),
          );
        }, pageTitle: 'Planejamento específico');

      case MenuItem.processHiringRecords:
        return _buildContractsListPage((context, contract) {
          final storesCtx = context;

          Navigator.of(context)
              .push(
            MaterialPageRoute(
              builder: (_) => TabBarHiringPage(contractData: contract)
            ),
          )
              .then((_) async {
            await storesCtx.read<ProcessStore>().refresh();
          });
        }, pageTitle: 'Contratação');

      case MenuItem.processValidityRecords:
        return _buildContractsListPage((context, contract) {
          context.read<ProcessStore>().select(contract);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ValidityTabBarPage(contractData: contract),
            ),
          );
        }, pageTitle: 'Ordens e Vigência');

      case MenuItem.processAdditiveRecords:
        return _buildContractsListPage((context, contract) {
          context.read<ProcessStore>().select(contract);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TabBarAdditivePage(contractData: contract),
            ),
          );
        }, pageTitle: 'Aditivos');

      case MenuItem.processApostillesRecords:
        return _buildContractsListPage((context, contract) {
          context.read<ProcessStore>().select(contract);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  TabBarApostillesPage(contractData: contract),
            ),
          );
        }, pageTitle: 'Apostilamentos');

      case MenuItem.processHiringBudget:
        return _buildContractsListPage((context, contract) {
          context.read<ProcessStore>().select(contract);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => HiringBudgetPage(contractData: contract),
            ),
          );
        }, pageTitle: 'Orçamento');

      case MenuItem.processHiringSchedule:
        return _buildContractsListPage((context, contract) async {
          context.read<ProcessStore>().select(contract);

          final contractId = contract.id ?? '';
          if (contractId.isEmpty) {
            NotificationCenter.instance.show(
              AppNotification(
                title: const Text('Contrato sem ID'),
                subtitle:
                const Text('Não foi possível abrir o cronograma.'),
                type: AppNotificationType.error,
              ),
            );
            return;
          }

          final dfdBloc = context.read<DfdCubit>();
          final DfdData? dfd =
          await dfdBloc.getDataForContract(contractId);
          final km = dfd?.extensaoKm ?? 0.0;
          final totalEstacas = ((km * 1000) / 20).ceil();

          final resumoContrato =
          await _buildContractLabel(context, contractId, dfdData: dfd);

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RepositoryProvider<ScheduleRoadRepository>(
                create: (_) => ScheduleRoadRepository(),
                child: BlocProvider<ScheduleRoadCubit>(
                  create: (ctx) => ScheduleRoadCubit(
                    repository: ctx.read<ScheduleRoadRepository>(),
                  )..warmup(
                    contractId: contractId,
                    totalEstacas: totalEstacas,
                    initialServiceKey: 'geral',
                    summarySubjectContract: resumoContrato,
                  ),
                  child: HiringSchedulePage(contract: contract),
                ),
              ),
            ),
          );
        }, pageTitle: 'Cronograma');

      case MenuItem.processMeasurementsRecords:
        return _buildContractsListPage((context, contract) {
          context.read<ProcessStore>().select(contract);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  TabBarMeasurementPage(contractData: contract),
            ),
          );
        }, pageTitle: 'Medições');

      case MenuItem.operationMonitoringWork:
        return _buildContractsListPage((context, contract) async {
          context.read<ProcessStore>().select(contract);
          await _navigateByWorkType(context, contract);
        }, pageTitle: 'Diário de Obra');

      case MenuItem.planningProjectRegistration:
        return PlanningNetworkPage();

      case MenuItem.planningRightOfWayRecords:
        return _buildContractsListPage((context, contract) {
          context.read<ProcessStore>().select(contract);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  PlanningRightWayWorkspacePage(contractData: contract),
            ),
          );
        }, pageTitle: 'Desapropriações');

      case MenuItem.planningEnvironmentRecords:
        return const PlanningNetworkPage();

      case MenuItem.trafficAccidentsDashboard:
        return const AccidentsDashboardNetworkPage();

      case MenuItem.trafficAccidentsRecords:
        return const AccidentsRecordsNetworkPage();

      case MenuItem.trafficInfractionsDashboard:
        return const InfractionsDashboardPage();

      case MenuItem.trafficInfractionsRecords:
        return const InfractionsRecordsPage();

      case MenuItem.financialPaymentsDashboard:
        return const TabBarFinancialPage();

      case MenuItem.financialPaymentsRecords:
        return _buildContractsListPage((context, contract) {
          context.read<ProcessStore>().select(contract);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  TabBarFinancialPage(contractData: contract),
            ),
          );
        }, pageTitle: 'Pagamentos de medições');

      case MenuItem.financialCommitmentDashboard:
        return const TabBarFinancialPage();

      case MenuItem.financialCommitmentRecords:
        return _buildContractsListPage((context, contract) {
          context.read<ProcessStore>().select(contract);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  TabBarFinancialPage(contractData: contract),
            ),
          );
        }, pageTitle: 'Pagamentos de medições');

      case MenuItem.activeRoadNetwork:
        return const ActiveRoadsNetworkPage();

      case MenuItem.activeRoadRegistration:
        return const ActiveRoadsRecordsPage();

      case MenuItem.activesOAEsNetwork:
        return const ActiveOAEsNetworkPage();

      case MenuItem.activeOAEsRegistration:
        return const ActiveOaesRecordsPage();

      case MenuItem.activeAirportsNetwork:
        return const ActiveAirportNetworkPage();

      case MenuItem.activeAirportsRegistration:
        return const ActiveAirportRecordsPage();

      case MenuItem.activeRailwaysNetwork:
        return const ActiveRailwaysNetworkPage();

      case MenuItem.activeRailwaysRegistration:
        return const ActiveRailwaysRecordsPage();

      case MenuItem.activePortsNetwork:
        return const ActiveRoadsNetworkPage();

      case MenuItem.activeRegistrationPorts:
        return const ActiveRoadsRecordsPage();

      case MenuItem.crmLegal:
        return TabBarCrmPrecatoryPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Warmup do UserBloc (apenas 1x)
    if (!_didWarmupUserBloc) {
      _didWarmupUserBloc = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<UserBloc>().add(
          const UserWarmupRequested(
            listenRealtime: true,
            bindCurrentUser: true,
          ),
        );
      });
    }

    return BlocBuilder<UserBloc, UserState>(
      buildWhen: (prev, curr) =>
      prev.current != curr.current ||
          prev.isLoadingUsers != curr.isLoadingUsers,
      builder: (context, userState) {
        final currentUser = userState.current;

        if (currentUser == null) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Warmup do ProcessStore (apenas 1x após usuário carregado)
        if (!_didWarmupStores) {
          _didWarmupStores = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<ProcessStore>().warmup(currentUser);
          });
        }

        return Scaffold(
          backgroundColor: Colors.white,
          drawer: PointerInterceptor(
            child: DrawerMenu(
              onTap: _onSelectPage,
              onTapHome: _goHome,
            ),
          ),
          body: Stack(
            children: [
              if (_selectedItem == null)
                HomeBody(onSelect: _onSelectPage)
              else
                _getPage(_selectedItem!, currentUser),
              const FloatButtonMenu(),
            ],
          ),
          bottomNavigationBar: const FootBar(),
        );
      },
    );
  }
}
