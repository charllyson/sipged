import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_widgets/notification/notification_center.dart';
import 'package:sipged/screens/common/login/sign_in/sign_in.dart';

import 'package:sipged/_blocs/system/login/login_cubit.dart';
import 'package:sipged/_blocs/system/login/login_state.dart';

import 'package:sipged/_blocs/system/user/user_repository.dart';
import 'package:sipged/_blocs/system/user/user_data.dart';

import 'package:sipged/_blocs/system/setup/setup_cubit.dart';
import 'package:sipged/_blocs/system/setup/setup_state.dart';
import 'package:sipged/screens/menus/menu_list_page.dart';
import 'package:sipged/screens/modules/planning/geo/geo_network_page.dart';

/// 🔧 FLAG TEMPORÁRIA
const bool kForceInitialSetupOverlay = false;

class GatePage extends StatelessWidget {
  const GatePage({super.key});

  @override
  Widget build(BuildContext context) {
    final userRepo = context.read<UserRepository>();

    return MaterialApp(
      title: 'SIPGED',
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
      home: BlocBuilder<LoginCubit, LoginState>(
        builder: (context, loginState) {
          final firebaseUser = FirebaseAuth.instance.currentUser;

          if (loginState.status == LoginStatus.loading) {
            return const Scaffold(
              backgroundColor: Colors.white,
              body: Center(child: Text('Verificando os dados...')),
            );
          }

          if (firebaseUser == null || loginState.status == LoginStatus.unauthenticated || loginState.status == LoginStatus.failure) {
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

              return BlocBuilder<SetupCubit, SetupState>(
                builder: (context, setupState) {
                  final base = GeoNetworkPage();
                  final bool needsSetup = kForceInitialSetupOverlay || setupState.companies.isEmpty;
                  if (!needsSetup) return base;
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
