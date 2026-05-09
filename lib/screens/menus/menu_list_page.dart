import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

import 'package:sipged/_blocs/modules/contracts/contract/contract_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_data.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/10Publicacao/publicacao_extrato_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/10Publicacao/publicacao_extrato_data.dart';

import 'package:sipged/_blocs/modules/operation/schedule/vertical/civil_schedule_bloc.dart';
import 'package:sipged/_blocs/modules/operation/schedule/vertical/civil_schedule_event.dart';

import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_road_cubit.dart';
import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_road_repository.dart';

import 'package:sipged/_blocs/system/module/module_access_guard.dart';
import 'package:sipged/_blocs/system/module/module_catalog.dart';
import 'package:sipged/_blocs/system/module/module_data.dart';

import 'package:sipged/_blocs/system/notification/local/notification_local_cubit.dart';
import 'package:sipged/_blocs/system/notification/notification_data.dart';
import 'package:sipged/_blocs/system/notification/notification_type.dart';

import 'package:sipged/_blocs/system/permission/permission_cubit.dart';
import 'package:sipged/_blocs/system/permission/permission_data.dart';
import 'package:sipged/_blocs/system/permission/permission_resolver.dart';
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

import 'package:sipged/screens/modules/financial/dashboard/financial_dashboard_network_page.dart';
import 'package:sipged/screens/modules/financial/tab_bar_financial_page.dart';

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

typedef DemandNavigationCallback = void Function(
    BuildContext context,
    ContractData contract,
    );

class MenuListPage extends StatefulWidget {
  const MenuListPage({super.key});

  @override
  State<MenuListPage> createState() => _MenuListPageState();
}

class _MenuListPageState extends State<MenuListPage> {
  ModuleEnum? _selectedItem;

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

  void _onSelectPage(ModuleEnum item) {
    if (!mounted) return;

    final permissionState = context.read<PermissionCubit>().state;
    final currentUser = context.read<UserCubit>().state.current;

    final permissions = PermissionResolver.resolveForUser(
      user: currentUser,
      permissionState: permissionState,
    );

    final tenantId = PermissionResolver.cleanTenantId(
      permissionState.activeTenantId,
    );

    final canRead = ModuleAccessGuard.canRead(
      item: item,
      permissions: permissions,
      tenantId: tenantId,
    );

    if (!canRead) {
      _showNotification(
        title: 'Acesso não permitido',
        subtitle: 'Você não possui permissão para abrir este módulo.',
        leadingLabel: 'Permissões',
        status: NotificationStatus.warning,
      );

      Navigator.of(context).maybePop();
      return;
    }

    setState(() {
      _selectedItem = item;
    });

    Navigator.of(context).maybePop();
  }

  void _goHome() {
    if (!mounted) return;

    setState(() {
      _selectedItem = null;
    });

    Navigator.of(context).maybePop();
  }

  Future<String> _buildContractLabel(
      BuildContext context,
      String contractId, {
        DfdData? dfdData,
      }) async {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) {
      return 'Contrato não identificado';
    }

    final dfdCubit = context.read<DfdCubit>();
    final pubCubit = context.read<PublicacaoExtratoCubit>();

    DfdData? dfd = dfdData;

    if (dfd == null) {
      try {
        dfd = await dfdCubit.getDataForContract(cleanContractId);
      } catch (_) {}
    }

    PublicacaoExtratoData? publicacao;

    try {
      publicacao = await pubCubit.getDataForContract(cleanContractId);
    } catch (_) {}

    final numero = (publicacao?.numeroContrato ?? '').trim();
    final descricao = (dfd?.descricaoObjeto ?? '').trim();

    if (numero.isNotEmpty && descricao.isNotEmpty) {
      return '$numero - $descricao';
    }

    if (numero.isNotEmpty) return numero;
    if (descricao.isNotEmpty) return descricao;

    return 'Contrato $cleanContractId';
  }

  Future<void> _navigateByWorkType(
      BuildContext context,
      ContractData contract,
      ) async {
    final navigator = Navigator.of(context);
    final dfdCubit = context.read<DfdCubit>();

    final contractId = (contract.id ?? '').trim();

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
                body: ScheduleRoadWorkspacePage(
                  contractData: contract,
                ),
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
        required ModuleEnum moduleItem,
      }) {
    return ListDemandPage(
      pageTitle: pageTitle,
      permissionModule: ModuleCatalog.permissionModuleOf(moduleItem),
      onTapItem: onTap,
    );
  }

  Future<void> _openScheduleRoadContextPage({
    required BuildContext context,
    required ContractData contract,
    required Widget Function(ContractData contract) pageBuilder,
    String emptyIdMessage = 'Não foi possível abrir o módulo.',
  }) async {
    final navigator = Navigator.of(context);
    final processCubit = context.read<ContractCubit>();
    final dfdCubit = context.read<DfdCubit>();

    processCubit.select(contract);

    final contractId = (contract.id ?? '').trim();

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
    required ModuleEnum item,
    required UserData currentUser,
    required UserPermissionData? permissions,
    required String? tenantId,
  }) {
    final canReadCurrentModule = ModuleAccessGuard.canRead(
      item: item,
      permissions: permissions,
      tenantId: tenantId,
    );

    if (!canReadCurrentModule) {
      return ModuleAccessGuard.deniedPage(
        item: item,
      );
    }

    switch (item) {
      case ModuleEnum.overviewDashboard:
        return const GeneralDashboardPage();

      case ModuleEnum.specificDashboard:
        return _buildContractsListPage(
              (context, contract) async {
            await _openScheduleRoadContextPage(
              context: context,
              contract: contract,
              pageBuilder: (contract) {
                return SpecificDashboardPage(
                  contractData: contract,
                );
              },
            );
          },
          pageTitle: 'Planejamento específico',
          moduleItem: item,
        );

      case ModuleEnum.processHiringRecords:
        return _buildContractsListPage(
              (context, contract) {
            final storesCtx = context;

            Navigator.of(context)
                .push(
              MaterialPageRoute(
                builder: (_) => TabBarHiringPage(
                  contractData: contract,
                ),
              ),
            )
                .then((_) async {
              if (!storesCtx.mounted) return;

              await storesCtx.read<ContractCubit>().refresh(
                currentUser: currentUser,
                currentPermissions: permissions,
                tenantId: tenantId,
                permissionModule: ModuleCatalog.permissionModuleOf(item),
              );
            });
          },
          pageTitle: 'Contratos',
          moduleItem: item,
        );

      case ModuleEnum.processValidityRecords:
        return _buildContractsListPage(
              (context, contract) {
            context.read<ContractCubit>().select(contract);

            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ValidityTabBarPage(
                  contractData: contract,
                ),
              ),
            );
          },
          pageTitle: 'Ordens e Vigência',
          moduleItem: item,
        );

      case ModuleEnum.processAdditiveRecords:
        return _buildContractsListPage(
              (context, contract) {
            context.read<ContractCubit>().select(contract);

            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => TabBarAdditivePage(
                  contractData: contract,
                ),
              ),
            );
          },
          pageTitle: 'Aditivos',
          moduleItem: item,
        );

      case ModuleEnum.processApostillesRecords:
        return _buildContractsListPage(
              (context, contract) {
            context.read<ContractCubit>().select(contract);

            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => TabBarApostillesPage(
                  contractData: contract,
                ),
              ),
            );
          },
          pageTitle: 'Apostilamentos',
          moduleItem: item,
        );

      case ModuleEnum.processHiringBudget:
        return _buildContractsListPage(
              (context, contract) {
            context.read<ContractCubit>().select(contract);

            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BudgetPage(
                  contractData: contract,
                ),
              ),
            );
          },
          pageTitle: 'Orçamento',
          moduleItem: item,
        );

      case ModuleEnum.processMeasurementsRecords:
        return _buildContractsListPage(
              (context, contract) {
            context.read<ContractCubit>().select(contract);

            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => TabBarMeasurementPage(
                  contractData: contract,
                ),
              ),
            );
          },
          pageTitle: 'Medições',
          moduleItem: item,
        );

      case ModuleEnum.operationMonitoringWork:
        return _buildContractsListPage(
              (context, contract) async {
            context.read<ContractCubit>().select(contract);

            await _navigateByWorkType(
              context,
              contract,
            );
          },
          pageTitle: 'Diário de Obra',
          moduleItem: item,
        );

      case ModuleEnum.planningProjectRegistration:
        return const GeoNetworkPage();

      case ModuleEnum.planningRightOfWayRecords:
        return _buildContractsListPage(
              (context, contract) {
            context.read<ContractCubit>().select(contract);

            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => LandPage(
                  contractData: contract,
                ),
              ),
            );
          },
          pageTitle: 'Faixa de Domínio',
          moduleItem: item,
        );

      case ModuleEnum.trafficAccidentsDashboard:
        return const AccidentDashboardPage();

      case ModuleEnum.trafficAccidentsRecords:
        return const AccidentsRecordsNetworkPage();

      case ModuleEnum.trafficInfractionsDashboard:
        return const InfractionsDashboardPage();

      case ModuleEnum.trafficInfractionsRecords:
        return const InfractionsRecordsPage();

      case ModuleEnum.financialDashboard:
        return FinancialDashboardNetworkPage();

      case ModuleEnum.financialCommitmentRecords:
        return _buildContractsListPage(
              (context, contract) {
            context.read<ContractCubit>().select(contract);

            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => TabBarFinancialPage(
                  contractData: contract,
                ),
              ),
            );
          },
          pageTitle: 'Pagamentos',
          moduleItem: item,
        );

      case ModuleEnum.activeRoadNetwork:
        return const ActiveRoadsNetworkPage();

      case ModuleEnum.activeRoadRegistration:
        return const ActiveRoadsRecordsPage();

      case ModuleEnum.activesOAEsNetwork:
        return const ActiveOAEsNetworkPage();

      case ModuleEnum.activeOAEsRegistration:
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

    final cleanUid = permissions?.uid.trim();

    if (cleanUid == null || cleanUid.isEmpty) {
      return;
    }

    _didWarmupProcessCubit = true;

    final processCubit = context.read<ContractCubit>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      processCubit.warmup(
        currentUser: currentUser,
        currentPermissions: permissions,
        tenantId: tenantId,
        permissionModule: ModuleCatalog.modContractsList,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    _warmupUserCubitOnce();

    return BlocSelector<UserCubit, UserState, UserData?>(
      selector: (state) {
        return state.current;
      },
      builder: (context, currentUser) {
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
          buildWhen: (previous, current) {
            return previous.current != current.current ||
                previous.isLoading != current.isLoading ||
                previous.activeTenantId != current.activeTenantId ||
                previous.error != current.error;
          },
          builder: (context, permissionState) {
            final permissions = PermissionResolver.resolveForUser(
              user: currentUser,
              permissionState: permissionState,
            );

            final tenantId = PermissionResolver.cleanTenantId(
              permissionState.activeTenantId,
            );

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
                    HomePage(
                      onSelect: _onSelectPage,
                    )
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