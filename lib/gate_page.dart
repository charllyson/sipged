// lib/screens/common/gate/gate_page.dart

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/system/login/login_cubit.dart';
import 'package:sipged/_blocs/system/login/login_state.dart';

import 'package:sipged/_blocs/system/notification/local/notification_local_cubit.dart';
import 'package:sipged/_blocs/system/notification/local/notification_local_host.dart';
import 'package:sipged/_blocs/system/notification/notification_push.dart';
import 'package:sipged/_blocs/system/notification/preferences/notification_preferences_cubit.dart';
import 'package:sipged/_blocs/system/notification/remote/notification_remote_cubit.dart';

import 'package:sipged/_blocs/system/permission/permission_cubit.dart';
import 'package:sipged/_blocs/system/permission/permission_data.dart' as perm;

import 'package:sipged/_blocs/system/setup/setup_cubit.dart';

import 'package:sipged/_blocs/system/tenant/tenant_cubit.dart';
import 'package:sipged/_blocs/system/tenant/tenant_data.dart';
import 'package:sipged/_blocs/system/tenant/tenant_state.dart';

import 'package:sipged/_blocs/system/user/user_cubit.dart';
import 'package:sipged/_blocs/system/user/user_data.dart';
import 'package:sipged/_blocs/system/user/user_repository.dart';

import 'package:sipged/_utils/theme/app_theme.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots.dart';

import 'package:sipged/screens/common/login/sign_in/sign_in.dart';
import 'package:sipged/screens/common/login/sign_in/tenant_selection_page.dart';
import 'package:sipged/screens/common/setup/initial_setup_page.dart';
import 'package:sipged/screens/menus/menu_list_page.dart';

const bool kForceInitialSetupOverlay = false;

class GatePage extends StatefulWidget {
  const GatePage({super.key});

  @override
  State<GatePage> createState() => _GatePageState();
}

class _GatePageState extends State<GatePage> {
  Future<_StartupContext>? _startupLoadFuture;
  Future<UserData?>? _userLoadFuture;

  String? _loadedUserUid;
  String? _loadedStartupUid;

  String? _pushInitializedUserId;
  String? _notificationPreferencesInitializedUserId;

  bool _isActivatingTenant = false;

  Future<UserData?> _loadUserOnce({
    required String uid,
    required UserRepository userRepo,
  }) {
    if (_loadedUserUid != uid || _userLoadFuture == null) {
      _loadedUserUid = uid;

      _userLoadFuture = userRepo.getById(uid).timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          debugPrint('[GatePage] Timeout ao carregar usuário uid=$uid.');
          return null;
        },
      );
    }

    return _userLoadFuture!;
  }

  Future<_StartupContext> _loadStartupDataOnce({
    required String uid,
    required UserData userData,
  }) {
    if (_loadedStartupUid != uid || _startupLoadFuture == null) {
      _loadedStartupUid = uid;

      _startupLoadFuture = _loadStartupData(
        uid: uid,
        userData: userData,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint('[GatePage] Timeout ao carregar dados iniciais.');

          throw TimeoutException(
            'Tempo limite excedido ao carregar os dados iniciais.',
            const Duration(seconds: 30),
          );
        },
      );
    }

    return _startupLoadFuture!;
  }

  Future<_StartupContext> _loadStartupData({
    required String uid,
    required UserData userData,
  }) async {
    final userCubit = context.read<UserCubit>();
    final permissionCubit = context.read<PermissionCubit>();
    final tenantCubit = context.read<TenantCubit>();

    userCubit.setCurrentUser(userData);

    await permissionCubit.loadByUid(uid);

    if (!mounted) {
      throw StateError('Tela desmontada durante carregamento inicial.');
    }

    final permissionData = permissionCubit.state.current ??
        _fallbackPermissionFromUser(
          uid: uid,
          userData: userData,
        );

    await tenantCubit.loadAvailableTenants(
      autoSelectWhenSingle: false,
      keepCurrentSelection: true,
    );

    if (!mounted) {
      throw StateError('Tela desmontada durante carregamento dos tenants.');
    }

    final tenantError = tenantCubit.state.error;

    if (tenantError != null && tenantError.trim().isNotEmpty) {
      throw StateError(tenantError);
    }

    final availableTenants = tenantCubit.state.availableTenants;

    final allowedTenants = _filterAllowedTenants(
      userData: userData,
      permissionData: permissionData,
      availableTenants: availableTenants,
    );

    if (allowedTenants.isEmpty) {
      return _StartupContext(
        userData: userData,
        permissionData: permissionData,
        availableTenants: availableTenants,
        allowedTenants: const <TenantData>[],
        selectedTenantId: null,
      );
    }

    final currentStateTenantId = tenantCubit.state.selectedTenantId?.trim();

    final currentTenantId =
    currentStateTenantId != null && currentStateTenantId.isNotEmpty
        ? currentStateTenantId
        : _currentTenantIdFromUser(userData);

    final selectedTenantId = _resolvePreviouslySelectedTenantId(
      currentTenantId: currentTenantId,
      permissionData: permissionData,
      allowedTenants: allowedTenants,
    );

    if (selectedTenantId != null && selectedTenantId.trim().isNotEmpty) {
      await _activateTenant(
        tenantId: selectedTenantId,
      );
    }

    return _StartupContext(
      userData: userData,
      permissionData: permissionData,
      availableTenants: availableTenants,
      allowedTenants: allowedTenants,
      selectedTenantId: selectedTenantId,
    );
  }

  perm.UserPermissionData _fallbackPermissionFromUser({
    required String uid,
    required UserData userData,
  }) {
    final raw = userData.userSnap?.data();

    if (raw is Map<String, dynamic>) {
      return perm.UserPermissionData.fromMap(
        uid: uid,
        map: raw,
      );
    }

    return perm.UserPermissionData(
      uid: uid,
    );
  }

  bool _canAccessAllTenants(perm.UserPermissionData permissionData) {
    return permissionData.hasGlobalFreeAccess ||
        permissionData.isGlobalSuperUser ||
        permissionData.globalRole == perm.SystemUserRole.administrador ||
        permissionData.globalRole == perm.SystemUserRole.desenvolvedor;
  }

  List<TenantData> _filterAllowedTenants({
    required UserData userData,
    required perm.UserPermissionData permissionData,
    required List<TenantData> availableTenants,
  }) {
    final validTenants = availableTenants
        .where((tenant) => tenant.id.trim().isNotEmpty)
        .toList();

    validTenants.sort(
          (a, b) => _tenantSortLabel(a).compareTo(_tenantSortLabel(b)),
    );

    if (_canAccessAllTenants(permissionData)) {
      return validTenants;
    }

    final availableIds = validTenants
        .map((tenant) => tenant.id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();

    final selectableIds = permissionData
        .selectableTenantIds(
      availableTenantIds: availableIds,
    )
        .toSet();

    final fallbackIds = <String>{
      ..._tenantIdsFromUser(userData),
      ...permissionData.enabledTenantIds,
    }.map((id) => id.trim()).where((id) => id.isNotEmpty).toSet();

    final allowedIds = <String>{
      ...selectableIds,
      ...fallbackIds.where(availableIds.contains),
    };

    final filtered = validTenants
        .where((tenant) => allowedIds.contains(tenant.id.trim()))
        .toList();

    filtered.sort(
          (a, b) => _tenantSortLabel(a).compareTo(_tenantSortLabel(b)),
    );

    return filtered;
  }

  String _tenantSortLabel(TenantData tenant) {
    final companyName = tenant.companyName?.trim();
    final fantasyName = tenant.fantasyName?.trim();
    final label = tenant.label.trim();

    if (companyName != null && companyName.isNotEmpty) {
      return companyName.toLowerCase();
    }

    if (fantasyName != null && fantasyName.isNotEmpty) {
      return fantasyName.toLowerCase();
    }

    if (label.isNotEmpty) {
      return label.toLowerCase();
    }

    return tenant.id.toLowerCase();
  }

  String? _resolvePreviouslySelectedTenantId({
    required String? currentTenantId,
    required perm.UserPermissionData permissionData,
    required List<TenantData> allowedTenants,
  }) {
    if (allowedTenants.isEmpty) return null;

    final allowedIds = allowedTenants
        .map((tenant) => tenant.id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();

    final current = currentTenantId?.trim();

    if (current != null && current.isNotEmpty && allowedIds.contains(current)) {
      return current;
    }

    final activePermissionTenant = permissionData.activeTenantId?.trim();

    if (activePermissionTenant != null &&
        activePermissionTenant.isNotEmpty &&
        allowedIds.contains(activePermissionTenant)) {
      return activePermissionTenant;
    }

    return null;
  }

  Future<void> _activateTenant({
    required String tenantId,
  }) async {
    final cleanTenantId = tenantId.trim();

    if (cleanTenantId.isEmpty) {
      throw StateError('Empresa não informada.');
    }

    final tenantCubit = context.read<TenantCubit>();
    final permissionCubit = context.read<PermissionCubit>();
    final setupCubit = context.read<SetupCubit>();

    await tenantCubit.selectTenant(cleanTenantId);

    if (!mounted) {
      throw StateError('Tela desmontada durante seleção da empresa.');
    }

    permissionCubit.setActiveTenant(cleanTenantId);

    await setupCubit.loadSystemSetup();

    final setupError = setupCubit.state.error;

    if (setupError != null && setupError.trim().isNotEmpty) {
      throw StateError(setupError);
    }
  }

  List<String> _tenantIdsFromUser(UserData userData) {
    final raw = userData.userSnap?.data();

    if (raw == null) return const <String>[];

    final values = <String>{};

    void addValue(dynamic value) {
      if (value == null) return;

      if (value is String) {
        final clean = value.trim();

        if (clean.isNotEmpty) {
          values.add(clean);
        }

        return;
      }

      if (value is Iterable) {
        for (final item in value) {
          addValue(item);
        }

        return;
      }

      if (value is Map) {
        for (final entry in value.entries) {
          final key = entry.key?.toString().trim() ?? '';
          final itemValue = entry.value;

          if (itemValue == true && key.isNotEmpty) {
            values.add(key);
            continue;
          }

          if (itemValue is Map) {
            final enabled = itemValue['enabled'] != false &&
                itemValue['active'] != false &&
                itemValue['allowed'] != false &&
                itemValue['disabled'] != true;

            if (enabled && key.isNotEmpty) {
              values.add(key);
            }
          }
        }
      }
    }

    addValue(raw['tenantIds']);
    addValue(raw['allowedTenantIds']);
    addValue(raw['accessibleTenantIds']);
    addValue(raw['companyIds']);
    addValue(raw['allowedCompanyIds']);
    addValue(raw['accessibleCompanyIds']);
    addValue(raw['tenants']);
    addValue(raw['tenantAccess']);
    addValue(raw['tenantsAccess']);
    addValue(raw['companyAccess']);
    addValue(raw['companiesAccess']);
    addValue(raw['tenantRoles']);
    addValue(raw['tenantModuleOverrides']);

    final list = values.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return list;
  }

  String? _currentTenantIdFromUser(UserData userData) {
    final raw = userData.userSnap?.data();

    if (raw == null) return null;

    final candidates = [
      raw['currentTenantId'],
      raw['selectedTenantId'],
      raw['activeTenantId'],
      raw['lastTenantId'],
    ];

    for (final candidate in candidates) {
      final value = candidate?.toString().trim();

      if (value != null && value.isNotEmpty) {
        return value;
      }
    }

    return null;
  }

  void _resetCachedUser() {
    _loadedUserUid = null;
    _loadedStartupUid = null;

    _userLoadFuture = null;
    _startupLoadFuture = null;

    _pushInitializedUserId = null;
    _notificationPreferencesInitializedUserId = null;

    _isActivatingTenant = false;

    unawaited(NotificationPush.instance.dispose());
  }

  void _resetStartupOnly() {
    _loadedStartupUid = null;
    _startupLoadFuture = null;

    _isActivatingTenant = false;
  }

  Future<void> _initializeNotificationPreferencesForUser(String uid) async {
    final cleanUid = uid.trim();

    if (cleanUid.isEmpty) return;
    if (_notificationPreferencesInitializedUserId == cleanUid) return;

    _notificationPreferencesInitializedUserId = cleanUid;

    try {
      final preferencesCubit = context.read<NotificationPreferencesCubit>();

      await preferencesCubit.initializeDefaults(cleanUid);
      preferencesCubit.watch(cleanUid);
    } catch (e, s) {
      _notificationPreferencesInitializedUserId = null;

      debugPrint(
        '[GatePage] Erro ao inicializar preferências de notificação: $e',
      );
      debugPrintStack(stackTrace: s);
    }
  }

  Future<void> _initializePushForUser(String uid) async {
    final cleanUid = uid.trim();

    if (cleanUid.isEmpty) return;
    if (_pushInitializedUserId == cleanUid) return;

    _pushInitializedUserId = cleanUid;

    final localCubit = context.read<NotificationLocalCubit>();
    final remoteCubit = context.read<NotificationRemoteCubit>();

    try {
      remoteCubit.watchBellNotifications(
        userId: cleanUid,
        systemLimit: 30,
        unreadUserLimit: 30,
      );

      remoteCubit.watchHistory(
        userId: cleanUid,
        limit: 50,
      );

      await NotificationPush.instance.initialize(
        userId: cleanUid,
        localCubit: localCubit,
        remoteCubit: remoteCubit,
      );
    } catch (e, s) {
      _pushInitializedUserId = null;

      debugPrint('[GatePage] Erro ao inicializar push: $e');
      debugPrintStack(stackTrace: s);
    }
  }

  Widget _buildTenantActivationLoading({
    String message = 'Ativando empresa...',
  }) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LoadingTreeDots(
        message: Text(message),
      ),
    );
  }

  Widget _buildAuthenticatedArea({
    required UserData userData,
    required String uid,
  }) {
    unawaited(_initializeNotificationPreferencesForUser(uid));
    unawaited(_initializePushForUser(uid));

    return FutureBuilder<_StartupContext>(
      future: _loadStartupDataOnce(
        uid: uid,
        userData: userData,
      ),
      builder: (context, startupSnapshot) {
        if (startupSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: LoadingTreeDots(
              message: Text('Carregando a configuração...'),
            ),
          );
        }

        if (startupSnapshot.hasError) {
          debugPrint(
            '[GatePage] Erro ao carregar configuração inicial: '
                '${startupSnapshot.error}',
          );

          return _StartupErrorView(
            title: 'Não foi possível carregar a configuração.',
            message: startupSnapshot.error?.toString() ??
                'Verifique sua conexão e tente recarregar o sistema.',
            onRetry: () {
              setState(() {
                _resetStartupOnly();
              });
            },
          );
        }

        final startup = startupSnapshot.data;

        if (startup == null) {
          return _StartupErrorView(
            title: 'Configuração indisponível.',
            message: 'Não foi possível montar o contexto inicial do usuário.',
            onRetry: () {
              setState(() {
                _resetStartupOnly();
              });
            },
          );
        }

        if (startup.allowedTenants.isEmpty) {
          return _StartupErrorView(
            title: 'Nenhuma empresa disponível.',
            message: startup.permissionData.hasGlobalFreeAccess
                ? 'Nenhuma empresa foi cadastrada em tenants.'
                : 'Seu usuário ainda não possui vínculo com nenhuma empresa. Solicite acesso ao administrador.',
            onRetry: () {
              setState(() {
                _resetStartupOnly();
              });
            },
          );
        }

        return BlocBuilder<TenantCubit, TenantState>(
          builder: (context, tenantState) {
            final selectedTenantId = tenantState.selectedTenantId?.trim();

            final hasTenantSelected =
                selectedTenantId != null && selectedTenantId.isNotEmpty;

            if (_isActivatingTenant) {
              return _buildTenantActivationLoading(
                message: 'Ativando empresa...',
              );
            }

            if (!hasTenantSelected) {
              return TenantSelectionPage(
                userData: startup.userData,
                tenants: startup.allowedTenants,
                permissionData: startup.permissionData,
                onTenantSelected: (tenantId) async {
                  if (!mounted) return;

                  setState(() {
                    _isActivatingTenant = true;
                  });

                  try {
                    await _activateTenant(
                      tenantId: tenantId,
                    );
                  } finally {
                    if (!mounted) return;

                    setState(() {
                      _isActivatingTenant = false;
                    });
                  }
                },
              );
            }

            final activeTenant =
                tenantState.tenantProfile ?? tenantState.selectedTenant;

            final isTenantStillLoading =
                activeTenant == null && tenantState.isLoading;

            if (isTenantStillLoading) {
              return _buildTenantActivationLoading(
                message: 'Carregando dados da empresa...',
              );
            }

            final base = const MenuListPage();

            final needsSetup =
                kForceInitialSetupOverlay || activeTenant == null;

            if (!needsSetup) {
              return base;
            }

            return Stack(
              children: [
                base,
                Positioned.fill(
                  child: InitialSetupPage(
                    user: startup.userData,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userRepo = context.read<UserRepository>();

    return MaterialApp(
      title: 'SIPGED',
      debugShowCheckedModeBanner: false,
      locale: const Locale('pt', 'BR'),
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      supportedLocales: const [
        Locale('pt', 'BR'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return NotificationLocalHost(
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: BlocBuilder<LoginCubit, LoginState>(
        builder: (context, loginState) {
          final firebaseUser = FirebaseAuth.instance.currentUser;

          if (loginState.status == LoginStatus.loading) {
            return const Scaffold(
              body: Center(
                child: Text('Verificando os dados...'),
              ),
            );
          }

          final shouldShowLogin = firebaseUser == null ||
              loginState.status == LoginStatus.unauthenticated ||
              loginState.status == LoginStatus.failure;

          if (shouldShowLogin) {
            _resetCachedUser();

            return const SignIn();
          }

          final uid = firebaseUser.uid;

          return FutureBuilder<UserData?>(
            future: _loadUserOnce(
              uid: uid,
              userRepo: userRepo,
            ),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: LoadingTreeDots(
                    message: Text('Carregando os dados...'),
                  ),
                );
              }

              if (userSnapshot.hasError) {
                debugPrint(
                  '[GatePage] Erro ao carregar usuário: '
                      '${userSnapshot.error}',
                );

                return _StartupErrorView(
                  title: 'Não foi possível carregar o usuário.',
                  message: 'Verifique sua conexão e tente recarregar o sistema.',
                  onRetry: () {
                    setState(() {
                      _resetCachedUser();
                    });
                  },
                );
              }

              final userData = userSnapshot.data;

              if (userData == null) {
                _resetCachedUser();

                return const SignIn();
              }

              if (userData.hasStatusRestriction) {
                _resetCachedUser();

                return _BlockedUserView(
                  userData: userData,
                  onSignOut: () async {
                    await context.read<LoginCubit>().signOut();

                    if (!mounted) return;

                    setState(() {
                      _resetCachedUser();
                    });
                  },
                );
              }

              return _buildAuthenticatedArea(
                userData: userData,
                uid: uid,
              );
            },
          );
        },
      ),
    );
  }
}

class _StartupContext {
  const _StartupContext({
    required this.userData,
    required this.permissionData,
    required this.availableTenants,
    required this.allowedTenants,
    required this.selectedTenantId,
  });

  final UserData userData;
  final perm.UserPermissionData permissionData;
  final List<TenantData> availableTenants;
  final List<TenantData> allowedTenants;
  final String? selectedTenantId;
}

class _StartupErrorView extends StatelessWidget {
  const _StartupErrorView({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 460,
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 42,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BlockedUserView extends StatelessWidget {
  const _BlockedUserView({
    required this.userData,
    required this.onSignOut,
  });

  final UserData userData;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    final statusLabel = userData.statusLabel;
    final statusColor = userData.statusColor;
    final statusIcon = userData.statusIcon;

    final reason = userData.deletedReason ??
        userData.blockedReason ??
        userData.deactivatedReason ??
        'A conta não está autorizada a acessar o sistema.';

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 460,
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      statusIcon,
                      size: 46,
                      color: statusColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Usuário $statusLabel',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      reason,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: onSignOut,
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Sair'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}