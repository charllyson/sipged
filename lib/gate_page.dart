import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/system/login/login_cubit.dart';
import 'package:sipged/_blocs/system/login/login_state.dart';

import 'package:sipged/_blocs/system/notification/local/notification_local_cubit.dart';
import 'package:sipged/_blocs/system/notification/local/notification_local_host.dart';
import 'package:sipged/_blocs/system/notification/notification_push.dart';
import 'package:sipged/_blocs/system/notification/remote/notification_remote_cubit.dart';

import 'package:sipged/_blocs/system/setup/setup_cubit.dart';
import 'package:sipged/_blocs/system/setup/setup_state.dart';

import 'package:sipged/_blocs/system/user/user_data.dart';
import 'package:sipged/_blocs/system/user/user_repository.dart';

import 'package:sipged/_utils/theme/app_theme.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots.dart';

import 'package:sipged/screens/common/login/sign_in/sign_in.dart';
import 'package:sipged/screens/common/setup/initial_setup_page.dart';
import 'package:sipged/screens/menus/menu_list_page.dart';

const bool kForceInitialSetupOverlay = false;

class GatePage extends StatefulWidget {
  const GatePage({super.key});

  @override
  State<GatePage> createState() => _GatePageState();
}

class _GatePageState extends State<GatePage> {
  Future<void>? _setupLoadFuture;
  Future<UserData?>? _userLoadFuture;

  String? _loadedUserUid;
  String? _pushInitializedUserId;

  Future<void> _loadSetupOnce() {
    _setupLoadFuture ??= context.read<SetupCubit>().loadSystemSetup().timeout(
      const Duration(seconds: 20),
      onTimeout: () {
        debugPrint('[GatePage] Timeout ao carregar setup do sistema.');
      },
    );

    return _setupLoadFuture!;
  }

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

  void _resetCachedUser() {
    _loadedUserUid = null;
    _userLoadFuture = null;
    _pushInitializedUserId = null;

    unawaited(NotificationPush.instance.dispose());
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
        onMessageOpened: _handlePushOpened,
      );
    } catch (e, s) {
      _pushInitializedUserId = null;

      debugPrint('[GatePage] Erro ao inicializar push: $e');
      debugPrintStack(stackTrace: s);
    }
  }

  void _handlePushOpened(RemoteMessage message) {
    final data = message.data;

    final route = data['route']?.toString();
    final module = data['module']?.toString();
    final contractId = data['contractId']?.toString();
    final processId = data['processId']?.toString();
    final notificationId = data['notificationId']?.toString();

    debugPrint('[GatePage] Push aberta.');
    debugPrint('[GatePage] route=$route');
    debugPrint('[GatePage] module=$module');
    debugPrint('[GatePage] contractId=$contractId');
    debugPrint('[GatePage] processId=$processId');
    debugPrint('[GatePage] notificationId=$notificationId');

    /// Ponto central para navegação futura.
    ///
    /// Exemplo futuro:
    ///
    /// AppNotificationRouter.open(
    ///   context,
    ///   route: route,
    ///   module: module,
    ///   contractId: contractId,
    ///   processId: processId,
    ///   notificationId: notificationId,
    /// );
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
                  '[GatePage] Erro ao carregar usuário: ${userSnapshot.error}',
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

              unawaited(_initializePushForUser(uid));

              return FutureBuilder<void>(
                future: _loadSetupOnce(),
                builder: (context, setupLoadSnapshot) {
                  if (setupLoadSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Scaffold(
                      body: LoadingTreeDots(
                        message: Text('Carregando a configuração...'),
                      ),
                    );
                  }

                  if (setupLoadSnapshot.hasError) {
                    debugPrint(
                      '[GatePage] Erro ao carregar setup: ${setupLoadSnapshot.error}',
                    );

                    return _StartupErrorView(
                      title: 'Não foi possível carregar a configuração.',
                      message:
                      'Verifique sua conexão e tente recarregar o sistema.',
                      onRetry: () {
                        setState(() {
                          _setupLoadFuture = null;
                        });
                      },
                    );
                  }

                  return BlocBuilder<SetupCubit, SetupState>(
                    builder: (context, setupState) {
                      final base = const MenuListPage();

                      final needsSetup = kForceInitialSetupOverlay ||
                          setupState.companyProfile == null;

                      if (!needsSetup) {
                        return base;
                      }

                      return Stack(
                        children: [
                          base,
                          Positioned.fill(
                            child: InitialSetupPage(
                              user: userData,
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
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
            maxWidth: 420,
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