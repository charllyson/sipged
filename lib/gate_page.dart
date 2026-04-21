import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_utils/theme/app_theme.dart';
import 'package:sipged/_widgets/notification/notification_center.dart';
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _setupLoadFuture ??= context.read<SetupCubit>().loadSystemSetup();
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
        return Scaffold(
          body: NotificationCenterHost(
            child: child ?? const SizedBox.shrink(),
          ),
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

          if (firebaseUser == null ||
              loginState.status == LoginStatus.unauthenticated ||
              loginState.status == LoginStatus.failure) {
            return const SignIn();
          }

          return FutureBuilder<UserData?>(
            future: userRepo.getById(firebaseUser.uid),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final userData = userSnapshot.data;
              if (userData == null) {
                return const SignIn();
              }

              return FutureBuilder<void>(
                future: _setupLoadFuture,
                builder: (context, setupLoadSnapshot) {
                  if (setupLoadSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  return BlocBuilder<SetupCubit, SetupState>(
                    builder: (context, setupState) {
                      final base = const MenuListPage();

                      final needsSetup =
                          kForceInitialSetupOverlay ||
                              setupState.companyProfile == null;

                      if (!needsSetup) return base;

                      return Stack(
                        children: [
                          base,
                          Positioned.fill(
                            child: InitialSetupPage(user: userData),
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