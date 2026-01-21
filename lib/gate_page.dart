// lib/gate_page.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_widgets/notification/notification_center.dart';
import 'package:siged/_widgets/login/sign_in.dart';
import 'package:siged/screens/menus/menu_list_page.dart';

import '_blocs/system/login/login_bloc.dart';
import '_blocs/system/user/user_repository.dart';
import '_blocs/system/user/user_data.dart';
import '_blocs/system/setup/setup_cubit.dart';
import '_blocs/system/setup/setup_state.dart';

/// 🔧 FLAG TEMPORÁRIA
/// enquanto estiver personalizando a InitialSetupPage, deixe como `true`.
/// Depois, coloque `false` para que a tela só apareça quando não houver
/// nenhuma empresa cadastrada.
const bool kForceInitialSetupOverlay = false;

class GatePage extends StatelessWidget {
  const GatePage({super.key});

  @override
  Widget build(BuildContext context) {
    final loginBloc = context.read<LoginBloc>();
    final userRepo  = context.read<UserRepository>();

    return MaterialApp(
      title: 'SIGED',
      debugShowCheckedModeBanner: false,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [
        Locale('pt', 'BR'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => Scaffold(
        body: NotificationCenterHost(child: child ?? const SizedBox()),
      ),
      home: StreamBuilder<LoginState>(
        stream: loginBloc.outState,
        initialData: LoginState.loading,
        builder: (context, snapshot) {
          final state = snapshot.data;
          final firebaseUser = FirebaseAuth.instance.currentUser;

          if (state == LoginState.loading) {
            return const Scaffold(
              backgroundColor: Colors.white,
              body: Center(child: Text('Verificando os dados...')),
            );
          }

          if (state == LoginState.fail || firebaseUser == null) {
            return const SignIn();
          }

          return FutureBuilder<UserData?>(
            future: userRepo.getById(firebaseUser.uid),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  backgroundColor: Colors.white,
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final userData = userSnapshot.data;
              if (userData == null) {
                return const SignIn();
              }

              // 👉 Sistema + overlay de setup
              return BlocBuilder<SetupCubit, SetupState>(
                builder: (context, setupState) {
                  final base = MenuListPage();
                  final bool needsSetup = kForceInitialSetupOverlay ||
                      setupState.companies.isEmpty;

                  if (!needsSetup) {
                    return base;
                  }
                  return Stack(
                    children: [
                      base,
                      /*Positioned.fill(
                        child: InitialSetupPage(user: userData),
                      ),*/
                    ],
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
