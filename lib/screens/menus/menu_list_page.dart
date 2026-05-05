import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

import 'package:sipged/_blocs/modules/contracts/_process/process_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_data.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/10Publicacao/publicacao_extrato_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/10Publicacao/publicacao_extrato_data.dart';

import 'package:sipged/_blocs/modules/operation/schedule/vertical/civil_schedule_bloc.dart';
import 'package:sipged/_blocs/modules/operation/schedule/vertical/civil_schedule_event.dart';

import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_road_cubit.dart';
import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_road_repository.dart';

import 'package:sipged/_blocs/system/module/module_data.dart';

import 'package:sipged/_blocs/system/notification/local/notification_local_cubit.dart';
import 'package:sipged/_blocs/system/notification/notification_data.dart';
import 'package:sipged/_blocs/system/notification/notification_type.dart';

import 'package:sipged/_blocs/system/permission/permission_cubit.dart';
import 'package:sipged/_blocs/system/permission/permission_data.dart';
import 'package:sipged/_blocs/system/permission/permission_state.dart';

import 'package:sipged/_blocs/system/user/user_cubit.dart';
import 'package:sipged/_blocs/system/user/user_data.dart';
import 'package:sipged/_blocs/system/user/user_state.dart';

import 'package:sipged/_services/files/dxf/map_overlay_cubit.dart';

import 'package:sipged/_widgets/loading/loading_tree_dots.dart';

import 'package:sipged/screens/common/demand/list_demand_page.dart';
import 'package:sipged/screens/common/home/home_page.dart';
import 'package:sipged/screens/menus/drawer_button.dart';
import 'package:sipged/screens/menus/drawer_menu.dart';

import 'package:sipged/screens/modules/actives/oaes/network/active_oaes_network_page.dart';
import 'package:sipged/screens/modules/actives/oaes/records/active_oaes_records_page.dart';
import 'package:sipged/screens/modules/actives/roads/network/active_roads_network_page.dart';
import 'package:sipged/screens/modules/actives/roads/records/active_roads_records_page.dart';

import 'package:sipged/screens/modules/contracts/additive/tab_bar_additive_page.dart';
import 'package:sipged/screens/modules/contracts/apostilles/tab_bar_apostilles_page.dart';
import 'package:sipged/screens/modules/contracts/budget/budget_page.dart';
import 'package:sipged/screens/modules/contracts/hiring/tab_bar_hiring_page.dart';
import 'package:sipged/screens/modules/contracts/measurement/tab_bar_measurement_page.dart';
import 'package:sipged/screens/modules/contracts/validity/validity_tab_bar.dart';

import 'package:sipged/screens/modules/financial/budget/budget_network_page.dart';
import 'package:sipged/screens/modules/financial/dashboard/financial_dashboard_network_page.dart';
import 'package:sipged/screens/modules/financial/empenhos/empenho_network_page.dart';

import 'package:sipged/screens/modules/operation/phys_fin/hiring_schedule_page.dart';
import 'package:sipged/screens/modules/operation/schedule/horizontal/schedule_road_workspace_page.dart';
import 'package:sipged/screens/modules/operation/schedule/vertical/schedule_civil_controller.dart';
import 'package:sipged/screens/modules/operation/schedule/vertical/schedule_civil_workspace_page.dart';

import 'package:sipged/screens/modules/planning/geo/geo_network_page.dart';
import 'package:sipged/screens/modules/planning/land/land_page.dart';

import 'package:sipged/screens/modules/traffic/accidents/dashboard/accident_dashboard_page.dart';
import 'package:sipged/screens/modules/traffic/accidents/records/accidents_records_network_page.dart';
import 'package:sipged/screens/modules/traffic/infractions/infractions_dashboard_page.dart';
import 'package:sipged/screens/modules/traffic/infractions/infractions_records_page.dart';

import 'package:sipged/screens/panels/overview-dashboard/general_dashboard_page.dart';
import 'package:sipged/screens/panels/specific-dashboard/specific_dashboard_page.dart';

class MenuListPage extends StatefulWidget {
  const MenuListPage({super.key});

  @override
  State<MenuListPage> createState() => _MenuListPageState();
}

class _MenuListPageState extends State<MenuListPage> {
  ModuleItem? _selectedItem;

  bool _didWarmupUserCubit = false;
  bool _didWarmupProcessCubit = false;

  String? _lastPermissionUid;

  void _showNotification({
    required String title,
    String? subtitle,
    String? details,
    String? leadingLabel,
    NotificationStatus status = NotificationStatus.info,
    Duration duration = const Duration(seconds: 5),
  }) {
    if (!mounted) return;

    context.read<NotificationLocalCubit>().show(
      NotificationData(
        title: title,
        subtitle: subtitle,
        details: details,
        leadingLabel: leadingLabel,
        status: status,
        duration: duration,
        extra: const <String, dynamic>{
          'module': 'menu',
          'source': 'menu_list_page',
        },
      ),
    );
  }

  void _onSelectPage(ModuleItem item) {
    if (!mounted) return;

    setState(() => _selectedItem = item);
    Navigator.of(context).maybePop();
  }

  void _goHome() {
    if (!mounted) return;

    setState(() => _selectedItem = null);
    Navigator.of(context).maybePop();
  }

  Future<String> _buildContractLabel(
      BuildContext context,
      String contractId, {
        DfdData? dfdData,
      }) async {
    final dfdCubit = context.read<DfdCubit>();
    final pubCubit = context.read<PublicacaoExtratoCubit>();

    DfdData? dfd = dfdData;

    if (dfd == null) {
      try {
        dfd = await dfdCubit.getDataForContract(contractId);
      } catch (_) {}
    }

    PublicacaoExtratoData? publicacao;

    try {
      publicacao = await pubCubit.getDataForContract(contractId);
    } catch (_) {}

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
    final navigator = Navigator.of(context);
    final dfdCubit = context.read<DfdCubit>();

    final contractId = contract.id ?? '';

    if (contractId.isEmpty) {
      _showNotification(
        title: 'Contrato sem ID',
        subtitle: 'Não foi possível abrir o cronograma.',
        leadingLabel: 'Contratos',
        status: NotificationStatus.error,
      );
      return;
    }

    final DfdData? dfd = await dfdCubit.getDataForContract(contractId);

    if (!context.mounted) return;

    final tipoObra = (dfd?.tipoObra ?? '').trim().toUpperCase();

    final resumoContrato = await _buildContractLabel(
      context,
      contractId,
      dfdData: dfd,
    );

    if (!context.mounted) return;

    if (tipoObra.isEmpty) {
      _showNotification(
        title: 'Tipo de obra não definido no DFD',
        subtitle: 'Cadastre o tipo no DFD para abrir o cronograma.',
        details: resumoContrato,
        leadingLabel: 'DFD',
        status: NotificationStatus.error,
        duration: const Duration(seconds: 7),
      );
      return;
    }

    final km = dfd?.extensaoKm ?? 0.0;
    final totalEstacas = ((km * 1000) / 20).ceil();

    if (tipoObra.contains('RODOV')) {
      navigator.push(
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

    if (tipoObra.contains('CONSTRU')) {
      final scheduleCtrl = ScheduleCivilController();

      navigator.push(
        MaterialPageRoute(
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider<CivilScheduleBloc>(
                create: (_) => CivilScheduleBloc()
                  ..add(
                    CivilWarmupRequested(contractId),
                  ),
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
      _showNotification(
        title: 'Cronograma para OAEs ainda não disponível.',
        leadingLabel: 'OAE',
        status: NotificationStatus.warning,
      );
      return;
    }

    _showNotification(
      title: 'Tipo de obra não suportado',
      subtitle: 'Tipo lido no DFD: $tipoObra',
      leadingLabel: 'DFD',
      status: NotificationStatus.error,
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

  Future<void> _openScheduleRoadContextPage({
    required BuildContext context,
    required ProcessData contract,
    required Widget Function(ProcessData contract) pageBuilder,
    String emptyIdMessage = 'Não foi possível abrir o módulo.',
  }) async {
    final navigator = Navigator.of(context);
    final processCubit = context.read<ProcessCubit>();
    final dfdCubit = context.read<DfdCubit>();

    processCubit.select(contract);

    final contractId = contract.id ?? '';

    if (contractId.isEmpty) {
      _showNotification(
        title: 'Contrato sem ID',
        subtitle: emptyIdMessage,
        leadingLabel: 'Contratos',
        status: NotificationStatus.error,
      );
      return;
    }

    final DfdData? dfd = await dfdCubit.getDataForContract(contractId);

    if (!context.mounted) return;

    final km = dfd?.extensaoKm ?? 0.0;
    final totalEstacas = ((km * 1000) / 20).ceil();

    final resumoContrato = await _buildContractLabel(
      context,
      contractId,
      dfdData: dfd,
    );

    if (!context.mounted) return;

    navigator.push(
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
            child: pageBuilder(contract),
          ),
        ),
      ),
    );
  }

  Widget _getPage({
    required ModuleItem item,
    required UserData currentUser,
    required UserPermissionData? permissions,
    required String? tenantId,
  }) {
    switch (item) {
      case ModuleItem.overviewDashboard:
        return const GeneralDashboardPage();

      case ModuleItem.specificDashboard:
        return _buildContractsListPage(
              (context, contract) async {
            await _openScheduleRoadContextPage(
              context: context,
              contract: contract,
              pageBuilder: (contract) {
                return SpecificDashboardPage(contractData: contract);
              },
            );
          },
          pageTitle: 'Planejamento específico',
        );

      case ModuleItem.processHiringRecords:
        return _buildContractsListPage(
              (context, contract) {
            final storesCtx = context;

            Navigator.of(context)
                .push(
              MaterialPageRoute(
                builder: (_) => TabBarHiringPage(contractData: contract),
              ),
            )
                .then((_) async {
              if (!storesCtx.mounted) return;

              await storesCtx.read<ProcessCubit>().refresh(
                currentUser: currentUser,
                currentPermissions: permissions,
                tenantId: tenantId,
              );
            });
          },
          pageTitle: 'Contratos',
        );

      case ModuleItem.processValidityRecords:
        return _buildContractsListPage(
              (context, contract) {
            context.read<ProcessCubit>().select(contract);

            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ValidityTabBarPage(contractData: contract),
              ),
            );
          },
          pageTitle: 'Ordens e Vigência',
        );

      case ModuleItem.processAdditiveRecords:
        return _buildContractsListPage(
              (context, contract) {
            context.read<ProcessCubit>().select(contract);

            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => TabBarAdditivePage(contractData: contract),
              ),
            );
          },
          pageTitle: 'Aditivos',
        );

      case ModuleItem.processApostillesRecords:
        return _buildContractsListPage(
              (context, contract) {
            context.read<ProcessCubit>().select(contract);

            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => TabBarApostillesPage(contractData: contract),
              ),
            );
          },
          pageTitle: 'Apostilamentos',
        );

      case ModuleItem.processHiringBudget:
        return _buildContractsListPage(
              (context, contract) {
            context.read<ProcessCubit>().select(contract);

            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BudgetPage(contractData: contract),
              ),
            );
          },
          pageTitle: 'Orçamento',
        );

      case ModuleItem.processHiringSchedule:
        return _buildContractsListPage(
              (context, contract) async {
            await _openScheduleRoadContextPage(
              context: context,
              contract: contract,
              emptyIdMessage: 'Não foi possível abrir o cronograma.',
              pageBuilder: (contract) {
                return HiringSchedulePage(contract: contract);
              },
            );
          },
          pageTitle: 'Cronograma',
        );

      case ModuleItem.processMeasurementsRecords:
        return _buildContractsListPage(
              (context, contract) {
            context.read<ProcessCubit>().select(contract);

            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => TabBarMeasurementPage(contractData: contract),
              ),
            );
          },
          pageTitle: 'Medições',
        );

      case ModuleItem.operationMonitoringWork:
        return _buildContractsListPage(
              (context, contract) async {
            context.read<ProcessCubit>().select(contract);
            await _navigateByWorkType(context, contract);
          },
          pageTitle: 'Diário de Obra',
        );

      case ModuleItem.planningProjectRegistration:
        return const GeoNetworkPage();

      case ModuleItem.planningRightOfWayRecords:
        return _buildContractsListPage(
              (context, contract) {
            context.read<ProcessCubit>().select(contract);

            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => LandPage(contractData: contract),
              ),
            );
          },
          pageTitle: 'Faixa de Domínio',
        );

      case ModuleItem.planningEnvironmentRecords:
        return const GeoNetworkPage();

      case ModuleItem.trafficAccidentsDashboard:
        return const AccidentDashboardPage();

      case ModuleItem.trafficAccidentsRecords:
        return const AccidentsRecordsNetworkPage();

      case ModuleItem.trafficInfractionsDashboard:
        return const InfractionsDashboardPage();

      case ModuleItem.trafficInfractionsRecords:
        return const InfractionsRecordsPage();

      case ModuleItem.financialDashboard:
        return const FinancialDashboardNetworkPage();

      case ModuleItem.financialBudget:
        return _buildContractsListPage(
              (context, contract) {
            context.read<ProcessCubit>().select(contract);

            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BudgetNetworkPage(contractData: contract),
              ),
            );
          },
          pageTitle: 'Orçamento (por contrato)',
        );

      case ModuleItem.financialEmpenhos:
        return const EmpenhoNetworkPage();

      case ModuleItem.financialCommitmentRecords:
        return _buildContractsListPage(
              (context, contract) {
            context.read<ProcessCubit>().select(contract);

            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => FinancialDashboardNetworkPage(
                  contractData: contract,
                ),
              ),
            );
          },
          pageTitle: 'Financeiro (por contrato)',
        );

      case ModuleItem.activeRoadNetwork:
        return const ActiveRoadsNetworkPage();

      case ModuleItem.activeRoadRegistration:
        return const ActiveRoadsRecordsPage();

      case ModuleItem.activesOAEsNetwork:
        return const ActiveOAEsNetworkPage();

      case ModuleItem.activeOAEsRegistration:
        return const ActiveOaesRecordsPage();
    }
  }

  void _warmupUserCubitOnce() {
    if (_didWarmupUserCubit) return;

    _didWarmupUserCubit = true;

    final userCubit = context.read<UserCubit>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      userCubit.warmup(
        listenRealtime: true,
        bindCurrentUser: true,
      );
    });
  }

  void _watchPermissionsForUser(UserData currentUser) {
    final uid = (currentUser.uid ?? '').trim();

    if (uid.isEmpty) return;
    if (_lastPermissionUid == uid) return;

    _lastPermissionUid = uid;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context.read<PermissionCubit>().watchByUid(uid);
    });
  }

  void _warmupProcessCubitOnce({
    required UserData currentUser,
    required UserPermissionData? permissions,
    required String? tenantId,
  }) {
    if (_didWarmupProcessCubit) return;

    if (permissions == null || permissions.uid.trim().isEmpty) {
      return;
    }

    _didWarmupProcessCubit = true;

    final processCubit = context.read<ProcessCubit>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      processCubit.warmup(
        currentUser: currentUser,
        currentPermissions: permissions,
        tenantId: tenantId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    _warmupUserCubitOnce();

    return BlocBuilder<UserCubit, UserState>(
      buildWhen: (prev, curr) {
        return prev.current != curr.current ||
            prev.isLoadingUsers != curr.isLoadingUsers;
      },
      builder: (context, userState) {
        final currentUser = userState.current;

        if (currentUser == null) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: LoadingTreeDots(
              message: Text('Carregando usuário...'),
            ),
          );
        }

        _watchPermissionsForUser(currentUser);

        return BlocBuilder<PermissionCubit, PermissionState>(
          buildWhen: (prev, curr) {
            return prev.current != curr.current ||
                prev.isLoading != curr.isLoading ||
                prev.activeTenantId != curr.activeTenantId ||
                prev.error != curr.error;
          },
          builder: (context, permissionState) {
            final permissions = permissionState.current;
            final tenantId = permissionState.activeTenantId;

            if (permissionState.isLoading && permissions == null) {
              return const Scaffold(
                backgroundColor: Colors.white,
                body: LoadingTreeDots(
                  message: Text('Carregando permissões...'),
                ),
              );
            }

            if (permissionState.error != null &&
                permissionState.error!.trim().isNotEmpty &&
                permissions == null) {
              return Scaffold(
                backgroundColor: Colors.white,
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Erro ao carregar permissões:\n${permissionState.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }

            _warmupProcessCubitOnce(
              currentUser: currentUser,
              permissions: permissions,
              tenantId: tenantId,
            );

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
                    HomePage(onSelect: _onSelectPage)
                  else
                    _getPage(
                      item: _selectedItem!,
                      currentUser: currentUser,
                      permissions: permissions,
                      tenantId: tenantId,
                    ),
                  const DrawerButtonChange(),
                ],
              ),
            );
          },
        );
      },
    );
  }
}