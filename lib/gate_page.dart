// lib/gate_page.dart

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_utils/theme/app_theme.dart';
import 'package:sipged/_widgets/notification/notification_center.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots_grey.dart';
import 'package:sipged/screens/common/login/sign_in/sign_in.dart';

import 'package:sipged/_blocs/system/login/login_cubit.dart';
import 'package:sipged/_blocs/system/login/login_state.dart';

import 'package:sipged/_blocs/system/user/user_repository.dart';
import 'package:sipged/_blocs/system/user/user_data.dart';

import 'package:sipged/_blocs/system/setup/setup_cubit.dart';
import 'package:sipged/_blocs/system/setup/setup_state.dart';
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

  Future<void> _loadSetupOnce() {
    _setupLoadFuture ??= context
        .read<SetupCubit>()
        .loadSystemSetup()
        .timeout(
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
        return NotificationCenterHost(
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
                  body: LoadingTreeDotsGrey(),
                );
              }

              if (userSnapshot.hasError) {
                debugPrint('[GatePage] Erro ao carregar usuário: '
                    '${userSnapshot.error}');

                return _StartupErrorView(
                  title: 'Não foi possível carregar o usuário.',
                  message:
                  'Verifique sua conexão e tente recarregar o sistema.',
                  onRetry: () {
                    setState(() {
                      _resetCachedUser();
                    });
                  },
                );
              }

              final userData = userSnapshot.data;

              if (userData == null) {
                return const SignIn();
              }

              return FutureBuilder<void>(
                future: _loadSetupOnce(),
                builder: (context, setupLoadSnapshot) {
                  if (setupLoadSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Scaffold(
                      body: LoadingTreeDotsGrey(),
                    );
                  }

                  if (setupLoadSnapshot.hasError) {
                    debugPrint('[GatePage] Erro ao carregar setup: '
                        '${setupLoadSnapshot.error}');

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