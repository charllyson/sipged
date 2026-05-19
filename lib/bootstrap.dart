import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '_blocs/system/setup/firebase_options_flavors.dart';
import 'gate_page.dart';

import 'package:sipged/_blocs/system/connectivity/connectivity_cubit.dart';
import 'package:sipged/_blocs/system/notification/global/global_banner_cubit.dart';

import 'package:sipged/_blocs/system/module/module_cubit.dart';
import 'package:sipged/_blocs/system/permission/permission_cubit.dart';

import 'package:sipged/_services/files/dxf/map_overlay_cubit.dart';

import 'package:sipged/_services/my_location/nominatim_cubit.dart';
import 'package:sipged/_services/my_location/nominatim_geocoder.dart';
import 'package:sipged/_services/my_location/nominatim_repository.dart';

import 'package:sipged/_blocs/system/notification/notification_push.dart';
import 'package:sipged/_blocs/system/notification/bell/notification_bell_cubit.dart';
import 'package:sipged/_blocs/system/notification/local/notification_local_cubit.dart';
import 'package:sipged/_blocs/system/notification/preferences/notification_preferences_cubit.dart';
import 'package:sipged/_blocs/system/notification/remote/notification_remote_cubit.dart';
import 'package:sipged/_blocs/system/notification/remote/notification_remote_repository.dart';

import 'package:sipged/_blocs/system/tenant/tenant_cubit.dart';

import 'package:sipged/_blocs/system/setup/setup_cubit.dart';
import 'package:sipged/_blocs/system/login/login_cubit.dart';
import 'package:sipged/_blocs/system/login/login_repository.dart';
import 'package:sipged/_blocs/system/user/user_cubit.dart';
import 'package:sipged/_blocs/system/user/user_repository.dart';

import 'package:sipged/_blocs/modules/contracts/contract/contract_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/contract/contract_repository.dart';

import 'package:sipged/_blocs/modules/transit/accidents/accidents_cubit.dart';
import 'package:sipged/_blocs/modules/transit/infractions/infractions_cubit.dart';
import 'package:sipged/_blocs/modules/transit/infractions/infractions_repository.dart';

Future<void> _loadEnvIfNeeded() async {
  final shouldLoadEnv = !kIsWeb || !kReleaseMode;

  if (!shouldLoadEnv) return;

  try {
    await dotenv.load(fileName: '.env');
  } catch (e, s) {
    debugPrint('[Bootstrap] Falha ao carregar .env: $e');
    debugPrintStack(stackTrace: s);
  }
}

Future<void> _initFirebase() async {
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: FirebaseOptionsFlavors.forWeb(),
    );
  } else {
    await Firebase.initializeApp();
  }
}

Future<void> _connectToEmulatorsIfNeeded() async {
  const useEmu = bool.fromEnvironment(
    'USE_EMULATOR',
    defaultValue: false,
  );

  if (!useEmu) return;

  const host = 'localhost';

  FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
  await FirebaseAuth.instance.useAuthEmulator(host, 9099);
  FirebaseStorage.instance.useStorageEmulator(host, 9199);
}

Future<void> bootstrapAndRunApp() async {
  await runZonedGuarded<Future<void>>(
        () async {
      WidgetsFlutterBinding.ensureInitialized();

      Intl.defaultLocale = 'pt_BR';

      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);

        if (details.stack != null) {
          debugPrintStack(
            label: details.exceptionAsString(),
            stackTrace: details.stack,
          );
        }
      };

      PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
        debugPrint('[PlatformDispatcher] $error');
        debugPrintStack(stackTrace: stack);
        return true;
      };

      await _loadEnvIfNeeded();
      await initializeDateFormatting('pt_BR');
      await _initFirebase();

      if (!kIsWeb) {
        FirebaseMessaging.onBackgroundMessage(
          sipgedFirebaseMessagingBackgroundHandler,
        );
      }

      await _connectToEmulatorsIfNeeded();

      Provider.debugCheckInvalidValueType = null;

      runApp(
        MultiProvider(
          providers: [
            BlocProvider<GlobalBannerCubit>(
              create: (_) => GlobalBannerCubit(),
            ),

            BlocProvider<ConnectivityCubit>(
              create: (ctx) => ConnectivityCubit(
                globalBannerCubit: ctx.read<GlobalBannerCubit>(),
              ),
            ),

            BlocProvider<ModuleCubit>(
              create: (_) => ModuleCubit(),
            ),

            BlocProvider<PermissionCubit>(
              create: (_) => PermissionCubit(),
            ),

            BlocProvider<MapOverlayCubit>(
              create: (_) => MapOverlayCubit(),
            ),

            BlocProvider<TenantCubit>(
              create: (_) => TenantCubit(),
            ),

            BlocProvider<SetupCubit>(
              create: (_) => SetupCubit(),
            ),

            RepositoryProvider<LoginRepository>(
              create: (_) => LoginRepository(),
            ),

            BlocProvider<LoginCubit>(
              create: (ctx) => LoginCubit(
                repository: ctx.read<LoginRepository>(),
              ),
            ),

            BlocProvider<NotificationPreferencesCubit>(
              create: (_) => NotificationPreferencesCubit(),
            ),

            BlocProvider<NotificationLocalCubit>(
              create: (_) => NotificationLocalCubit(
                maxVisible: 4,
              ),
            ),

            RepositoryProvider<NotificationRemoteRepository>(
              create: (_) => NotificationRemoteRepository(),
            ),

            BlocProvider<NotificationRemoteCubit>(
              create: (ctx) => NotificationRemoteCubit(
                repository: ctx.read<NotificationRemoteRepository>(),
              ),
            ),

            BlocProvider<NotificationBellCubit>(
              create: (ctx) => NotificationBellCubit(
                repository: ctx.read<NotificationRemoteRepository>(),
              ),
            ),

            RepositoryProvider<NominatimRepository>(
              create: (_) {
                const userAgent = 'sipged/1.0';

                return NominatimRepository(
                  userAgent: userAgent,
                  service: const NominatimGeocoder(
                    userAgent: userAgent,
                    acceptLanguage: 'pt-BR',
                    countryCodes: 'br',
                    defaultLimit: 8,
                  ),
                );
              },
            ),

            BlocProvider<NominatimCubit>(
              create: (ctx) => NominatimCubit(
                repository: ctx.read<NominatimRepository>(),
              ),
            ),

            RepositoryProvider<UserRepository>(
              create: (_) => UserRepository(),
            ),

            BlocProvider<UserCubit>(
              create: (ctx) => UserCubit(
                ctx.read<UserRepository>(),
              )..warmup(
                listenRealtime: true,
                bindCurrentUser: true,
              ),
            ),

            BlocProvider<AccidentsCubit>(
              create: (_) => AccidentsCubit(),
            ),

            RepositoryProvider<InfractionsRepository>(
              create: (_) => InfractionsRepository(),
            ),

            BlocProvider<InfractionsCubit>(
              create: (ctx) => InfractionsCubit(
                repository: ctx.read<InfractionsRepository>(),
              ),
            ),

            RepositoryProvider<ContractRepository>(
              create: (_) => ContractRepository(),
            ),

            BlocProvider<ContractCubit>(
              create: (ctx) => ContractCubit(
                repository: ctx.read<ContractRepository>(),
              ),
            ),
          ],
          builder: (context, _) {
            return const GatePage();
          },
        ),
      );
    },
        (Object error, StackTrace stack) {
      debugPrint('[Bootstrap Zone] $error');
      debugPrintStack(stackTrace: stack);
    },
  );
}