// lib/bootstrap.dart
import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siged/_blocs/actives/railway/active_railways_bloc.dart';
import 'package:siged/_blocs/actives/railway/active_railways_event.dart';
import 'package:siged/_blocs/actives/roads/active_road_bloc.dart';
import 'package:siged/_blocs/documents/measurement/adjustment/adjustment_measurement_bloc.dart';
import 'package:siged/_blocs/documents/measurement/adjustment/adjustment_measurement_store.dart';
import 'package:siged/_blocs/documents/measurement/revision/revision_measurement_bloc.dart';
import 'package:siged/_blocs/documents/measurement/revision/revision_measurement_store.dart';
import 'package:siged/_blocs/sectors/operation/road/schedule_road_bloc.dart';
import 'package:siged/_blocs/sectors/operation/road/schedule_road_repository.dart';

import '_blocs/actives/roads/active_roads_event.dart';
import '_services/dxf/map_overlay_cubit.dart';
import 'firebase_options_flavors.dart';

// ===== Emuladores (opcional via --dart-define=USE_EMULATOR=true) =====
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

// ************ IMPORTS via package: ************
import 'package:siged/_blocs/actives/oaes/active_oaes_bloc.dart';

import 'package:siged/_blocs/documents/contracts/additives/additives_bloc.dart';
import 'package:siged/_blocs/documents/contracts/additives/additives_storage_bloc.dart';
import 'package:siged/_blocs/documents/contracts/apostilles/apostilles_bloc.dart';
import 'package:siged/_blocs/documents/contracts/apostilles/apostilles_storage_bloc.dart';
import 'package:siged/_blocs/documents/contracts/budget/budget_bloc.dart';
import 'package:siged/_blocs/documents/contracts/contracts/contract_bloc.dart';
import 'package:siged/_blocs/documents/contracts/contracts/contract_storage_bloc.dart';
import 'package:siged/_blocs/documents/contracts/validity/validity_bloc.dart';
import 'package:siged/_blocs/documents/contracts/validity/validity_storage_bloc.dart';
import 'package:siged/_blocs/documents/measurement/report/report_measurement_bloc.dart';
import 'package:siged/_blocs/documents/measurement/report/report_measurement_storage_bloc.dart';

import 'package:siged/_blocs/sectors/financial/payments/adjustment/payment_adjustment_bloc.dart';
import 'package:siged/_blocs/sectors/financial/payments/report/payment_reports_bloc.dart';
import 'package:siged/_blocs/sectors/financial/payments/report/payments_report_storage_bloc.dart';
import 'package:siged/_blocs/sectors/financial/payments/revision/payment_revision_bloc.dart';
import 'package:siged/_blocs/sectors/transit/accidents/accidents_bloc.dart';
import 'package:siged/_blocs/sectors/transit/infractions/infractions_bloc.dart';
import 'package:siged/_blocs/sectors/transit/infractions/infractions_controller.dart';

import 'package:siged/_blocs/system/user/admin_bloc.dart';
import 'package:siged/_blocs/system/login/login_bloc.dart';
import 'package:siged/_blocs/system/info/system_bloc.dart';

import 'package:siged/_blocs/documents/contracts/additives/additive_store.dart';
import 'package:siged/_blocs/documents/contracts/apostilles/apostilles_store.dart';
import 'package:siged/_blocs/documents/contracts/budget/budget_store.dart';
import 'package:siged/_blocs/documents/contracts/contracts/contract_store.dart';
import 'package:siged/_blocs/documents/contracts/validity/validity_store.dart';
import 'package:siged/_blocs/documents/measurement/report/report_measurement_store.dart';

import 'package:siged/_blocs/system/user/user_repository.dart';
import 'package:siged/_blocs/documents/contracts/contracts/contracts_controller.dart';
import 'package:siged/siged_page.dart';

// OAEs
import '_blocs/actives/oaes/active_oaes_event.dart';

// User
import '_blocs/system/user/user_bloc.dart';
import '_blocs/system/user/user_event.dart';
import '_blocs/system/user/user_state.dart';

Future<void> _initFirebase() async {
  if (kIsWeb) {
    // Web precisa de options explícitas -> seleciona pelo flavor
    await Firebase.initializeApp(options: FirebaseOptionsFlavors.forWeb());
  } else {
    // Mobile/Desktop: usa configs nativas (google-services / GoogleService-Info)
    await Firebase.initializeApp();
  }
}

/// Conecta nos Emuladores quando compilado com --dart-define=USE_EMULATOR=true
Future<void> _connectToEmulatorsIfNeeded() async {
  const useEmu = bool.fromEnvironment('USE_EMULATOR', defaultValue: false);
  if (!useEmu) return;

  // Observação: use '10.0.2.2' se rodar no Android Emulator.
  const host = 'localhost';
  FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
  await FirebaseAuth.instance.useAuthEmulator(host, 9099);
  FirebaseStorage.instance.useStorageEmulator(host, 9199);
}

Future<void> bootstrapAndRunApp() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (details) {
      if (kIsWeb) {
        debugPrint('FlutterError (web): ${details.exceptionAsString()}');
        final s = details.stack;
        if (s is StackTrace) debugPrint(s.toString());
        return;
      }
      FlutterError.presentError(details);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('PlatformDispatcher error: $error');
      debugPrint(stack.toString());
      return true;
    };

    await initializeDateFormatting('pt_BR');
    await _initFirebase();
    await _connectToEmulatorsIfNeeded();

    Provider.debugCheckInvalidValueType = null;

    runApp(
      MultiProvider(
        providers: [
          BlocProvider(create: (_) => MapOverlayCubit()),

          // --------- BLoCs / services ---------
          Provider<LoginBloc>(create: (_) => LoginBloc(), dispose: (_, b) => b.dispose()),
          Provider<SystemBloc>(create: (_) => SystemBloc(), dispose: (_, b) => b.dispose()),
          Provider<AdminBloc>(create: (_) => AdminBloc(), dispose: (_, b) => b.dispose()),

          /// ======= User =======
          Provider<UserRepository>(create: (_) => UserRepository()),
          Provider<UserBloc>(
            create: (ctx) => UserBloc(ctx.read<UserRepository>())
              ..add(const UserWarmupRequested(listenRealtime: true, bindCurrentUser: true)),
            dispose: (_, b) => b.close(),
          ),

          /// ======= Contract =======
          Provider<ContractBloc>(create: (_) => ContractBloc(), dispose: (_, b) => b.dispose()),
          Provider<ContractStorageBloc>(create: (_) => ContractStorageBloc()),
          ChangeNotifierProvider<ContractsStore>(
            create: (ctx) => ContractsStore(ctx.read<ContractBloc>(), ctx.read<ContractStorageBloc>()),
          ),

          /// ======= Additives =======
          Provider<AdditivesBloc>(create: (_) => AdditivesBloc(), dispose: (_, b) => b.dispose()),
          Provider<AdditivesStorageBloc>(create: (_) => AdditivesStorageBloc(), dispose: (_, b) => b.dispose()),
          ChangeNotifierProvider<AdditivesStore>(
            create: (ctx) => AdditivesStore(
              bloc: ctx.read<AdditivesBloc>(),
              storage: ctx.read<AdditivesStorageBloc>(),
            ),
          ),

          /// ======= Apostilles =======
          Provider<ApostillesBloc>(create: (_) => ApostillesBloc(), dispose: (_, b) => b.dispose()),
          Provider<ApostillesStorageBloc>(create: (_) => ApostillesStorageBloc(), dispose: (_, b) => b.dispose()),
          ChangeNotifierProvider<ApostillesStore>(
            create: (ctx) => ApostillesStore(
              bloc: ctx.read<ApostillesBloc>(),
              storage: ctx.read<ApostillesStorageBloc>(),
            ),
          ),

          /// ======= Report Measurement =======
          Provider<ReportMeasurementStorageBloc>(create: (_) => ReportMeasurementStorageBloc()),
          Provider<ReportMeasurementBloc>(create: (_) => ReportMeasurementBloc(), dispose: (_, b) => b.dispose()),
          ChangeNotifierProvider<ReportsMeasurementStore>(
            create: (ctx) => ReportsMeasurementStore(ctx.read<ReportMeasurementBloc>()),
          ),

          /// ======= Validity =======
          Provider<ValidityStorageBloc>(create: (_) => ValidityStorageBloc()),
          Provider<ValidityBloc>(create: (_) => ValidityBloc(), dispose: (_, b) => b.dispose()),
          ChangeNotifierProvider<ValidityStore>(
            create: (ctx) => ValidityStore(
              bloc: ctx.read<ValidityBloc>(),
              storage: ctx.read<ValidityStorageBloc>(),
            ),
          ),

          /// ======= Budget =======
          Provider<BudgetBloc>(create: (_) => BudgetBloc()),
          ChangeNotifierProvider<BudgetStore>(create: (ctx) => BudgetStore(bloc: ctx.read<BudgetBloc>())),

          /// ======= OAEs =======
          BlocProvider<ActiveOaesBloc>(
            create: (_) => ActiveOaesBloc()
              ..add(const ActiveOaesWarmupRequested()),
          ),
          /// ======= Roads =======
          BlocProvider<ActiveRoadsBloc>(
            create: (_) => ActiveRoadsBloc()
              ..add(const ActiveRoadsWarmupRequested()),
          ),
          /// ======= Railway =======
          BlocProvider<ActiveRailwaysBloc>(
            create: (_) => ActiveRailwaysBloc()
              ..add(const ActiveRailwaysWarmupRequested()),
          ),

          // ======= Accidents =======
          BlocProvider<AccidentsBloc>(                     // ✅ TROCA para BlocProvider
            create: (_) => AccidentsBloc(),
          ),

          /// ======= Infractions =======
          Provider<InfractionsBloc>(create: (_) => InfractionsBloc(), dispose: (_, b) => b.dispose()),
          ChangeNotifierProxyProvider<InfractionsBloc, InfractionsController>(
            create: (ctx) => InfractionsController(bloc: ctx.read<InfractionsBloc>()),
            update: (_, iBloc, ctrl) => ctrl!..updateDeps(iBloc),
          ),

          /// ======= Dashboard =======
          ChangeNotifierProvider<ContractsController>(
            create: (ctx) => ContractsController(
              store: ctx.read<ContractsStore>(),
              additivesStore: ctx.read<AdditivesStore>(),
              apostillesStore: ctx.read<ApostillesStore>(),
              reportsMeasurementStore: ctx.read<ReportsMeasurementStore>(),
              adjustmentsStore: ctx.read<AdjustmentsMeasurementStore>(),
              revisionsStore: ctx.read<RevisionsMeasurementStore>(),
              // ⬇️ necessário para salvar URL de PDF e uso na MainInformationPage
              contractStorageBloc: ctx.read<ContractStorageBloc>(),
            )..initialize(),
          ),


          // ======= Schedule (cronograma) =======
          RepositoryProvider<ScheduleRoadRepository>(create: (_) => ScheduleRoadRepository()),
          BlocProvider<ScheduleRoadBloc>(
            create: (ctx) => ScheduleRoadBloc(
              // se o construtor aceitar repo, descomente:
              // repo: ctx.read<ScheduleRepository>(),
            ),
          ),

          /// ======= Adjustment Measurement =======  👈 ADICIONE
          Provider<AdjustmentMeasurementBloc>(create: (_) => AdjustmentMeasurementBloc(), dispose: (_, b) => b.dispose()),
          ChangeNotifierProvider<AdjustmentsMeasurementStore>(
            create: (ctx) => AdjustmentsMeasurementStore(ctx.read<AdjustmentMeasurementBloc>()),
          ),

          /// ======= Revision Measurement =======    👈 ADICIONE
          Provider<RevisionMeasurementBloc>(create: (_) => RevisionMeasurementBloc(), dispose: (_, b) => b.dispose()),
          ChangeNotifierProvider<RevisionsMeasurementStore>(
            create: (ctx) => RevisionsMeasurementStore(ctx.read<RevisionMeasurementBloc>()),
          ),


          /// ======= Payments =======
          Provider<PaymentReportBloc>(create: (_) => PaymentReportBloc()),
          Provider<PaymentsReportStorageBloc>(create: (_) => PaymentsReportStorageBloc()),
          Provider<PaymentRevisionBloc>(create: (_) => PaymentRevisionBloc()),
          Provider<PaymentAdjustmentBloc>(create: (_) => PaymentAdjustmentBloc()),
        ],
        builder: (context, _) {
          return BlocBuilder<UserBloc, UserState>(
            buildWhen: (a, b) => a.current != b.current,
            builder: (context, userState) {
              final app = const SiGed();

              if (userState.current == null) {
                // sem user: não injeta OAEs
                return app;
              }

              return BlocProvider<ActiveOaesBloc>(
                create: (_) => ActiveOaesBloc()..add(const ActiveOaesWarmupRequested()),
                child: app,
              );
            },
          );
        },
      ),
    );
  }, (error, stack) {
    debugPrint('Uncaught (zone): $error');
    debugPrint(stack.toString());
  });
}
