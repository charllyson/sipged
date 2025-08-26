import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ************ IMPORTS via package: ************
import 'package:sisged/_blocs/actives/roads/active_road_bloc.dart';
import 'package:sisged/_blocs/actives/oaes/active_oaes_bloc.dart';

import 'package:sisged/_blocs/documents/contracts/additives/additives_bloc.dart';
import 'package:sisged/_blocs/documents/contracts/additives/additives_storage_bloc.dart';
import 'package:sisged/_blocs/documents/contracts/apostilles/apostilles_bloc.dart';
import 'package:sisged/_blocs/documents/contracts/apostilles/apostilles_storage_bloc.dart';
import 'package:sisged/_blocs/documents/contracts/budget/budget_bloc.dart';
import 'package:sisged/_blocs/documents/contracts/contracts/contract_bloc.dart';
import 'package:sisged/_blocs/documents/contracts/contracts/contract_storage_bloc.dart';
import 'package:sisged/_blocs/documents/contracts/validity/validity_bloc.dart';
import 'package:sisged/_blocs/documents/contracts/validity/validity_storage_bloc.dart';
import 'package:sisged/_blocs/documents/measurement/report/report_measurement_bloc.dart';
import 'package:sisged/_blocs/documents/measurement/report/report_measurement_storage_bloc.dart';

import 'package:sisged/_blocs/sectors/financial/payments/adjustment/payment_adjustment_bloc.dart';
import 'package:sisged/_blocs/sectors/financial/payments/report/payment_reports_bloc.dart';
import 'package:sisged/_blocs/sectors/financial/payments/report/payments_report_storage_bloc.dart';
import 'package:sisged/_blocs/sectors/financial/payments/revision/payment_revision_bloc.dart';
import 'package:sisged/_blocs/sectors/transit/accidents/accidents_bloc.dart';
import 'package:sisged/_blocs/sectors/transit/accidents/accidents_controller.dart';
import 'package:sisged/_blocs/sectors/transit/infractions/infractions_bloc.dart';
import 'package:sisged/_blocs/sectors/transit/infractions/infractions_controller.dart';

import 'package:sisged/_blocs/system/user/admin_bloc.dart';
import 'package:sisged/_blocs/system/login/login_bloc.dart';
import 'package:sisged/_blocs/system/info/system_bloc.dart';

import 'package:sisged/_blocs/actives/roads/active_roads_store.dart';
import 'package:sisged/_blocs/documents/contracts/additives/additive_store.dart';
import 'package:sisged/_blocs/documents/contracts/apostilles/apostilles_store.dart';
import 'package:sisged/_blocs/documents/contracts/budget/budget_store.dart';
import 'package:sisged/_blocs/documents/contracts/contracts/contract_store.dart';
import 'package:sisged/_blocs/documents/contracts/validity/validity_store.dart';
import 'package:sisged/_blocs/documents/measurement/report/report_measurement_store.dart';

import 'package:sisged/_blocs/system/user/user_repository.dart';
import 'package:sisged/_blocs/documents/contracts/contracts/contracts_controller.dart';
import 'package:sisged/siged_page.dart';

// OAEs
import '_blocs/actives/oaes/active_oaes_repository.dart';
import '_blocs/actives/oaes/active_oaes_event.dart'; // para ActiveOaesWarmupRequested

// User
import '_blocs/system/user/user_bloc.dart';
import '_blocs/system/user/user_event.dart';
import '_blocs/system/user/user_state.dart';

void main() {
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

    await Firebase.initializeApp(
      options: kIsWeb
          ? const FirebaseOptions(
        apiKey: 'AIzaSyDZh7jcJNO0XEW2eCXecWq3MdTvRFPzHJk',
        authDomain: 'sisgeoderal.firebaseapp.com',
        projectId: 'sisgeoderal',
        storageBucket: 'sisgeoderal.appspot.com',
        messagingSenderId: '769410863294',
        appId: '1:769410863294:web:a51d56dfd32369dd4b0eef',
        measurementId: 'G-EJBDWKRPQ8',
      )
          : null,
    );

    Provider.debugCheckInvalidValueType = null;

    runApp(
      MultiProvider(
        providers: [
          // --------- BLoCs / services ---------
          Provider<LoginBloc>(create: (_) => LoginBloc(), dispose: (_, b) => b.dispose()),
          Provider<SystemBloc>(create: (_) => SystemBloc(), dispose: (_, b) => b.dispose()),
          Provider<AdminBloc>(create: (_) => AdminBloc(), dispose: (_, b) => b.dispose()),

          /// ======= User =======
          Provider<UserRepository>(create: (_) => UserRepository()),
          Provider<UserBloc>(
            create: (ctx) => UserBloc(ctx.read<UserRepository>())
              ..add(const UserWarmupRequested(
                listenRealtime: true,
                bindCurrentUser: true,
              )),
            dispose: (_, b) => b.close(),
          ),

          /// ======= Contract =======
          Provider<ContractBloc>(create: (_) => ContractBloc(), dispose: (_, b) => b.dispose()),
          Provider<ContractStorageBloc>(create: (_) => ContractStorageBloc()),
          ChangeNotifierProvider<ContractsStore>(
            create: (ctx) => ContractsStore(
              ctx.read<ContractBloc>(),
              ctx.read<ContractStorageBloc>(),
            ),
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
          ChangeNotifierProvider<BudgetStore>(
            create: (ctx) => BudgetStore(bloc: ctx.read<BudgetBloc>()),
          ),

          /// ======= OAEs =======
          Provider<ActiveOaesRepository>(create: (_) => ActiveOaesRepository()),

          /// ======= Roads (removido duplicado) =======
          Provider<ActiveRoadsBloc>(create: (_) => ActiveRoadsBloc()),
          ChangeNotifierProvider<ActiveRoadsStore>(
            create: (ctx) => ActiveRoadsStore(bloc: ctx.read<ActiveRoadsBloc>()),
          ),

          /// ======= Accidents =======
          Provider<AccidentsBloc>(create: (_) => AccidentsBloc(), dispose: (_, b) => b.dispose()),
          ChangeNotifierProxyProvider2<AccidentsBloc, SystemBloc, AccidentsController>(
            create: (ctx) => AccidentsController(
              accidentsBloc: ctx.read<AccidentsBloc>(),
              systemBloc: ctx.read<SystemBloc>(),
            ),
            update: (_, aBloc, sBloc, ctrl) => ctrl!..updateDeps(aBloc, sBloc),
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
            )..initialize(),
          ),

          /// ======= Payments =======
          Provider<PaymentReportBloc>(create: (_) => PaymentReportBloc()),
          Provider<PaymentsReportStorageBloc>(create: (_) => PaymentsReportStorageBloc()),
          Provider<PaymentRevisionBloc>(create: (_) => PaymentRevisionBloc()),
          Provider<PaymentAdjustmentBloc>(create: (_) => PaymentAdjustmentBloc()),
        ],
        // ⚠️ Use 'builder' para injetar o ActiveOaesBloc após o User estar pronto
        builder: (context, _) {
          return BlocBuilder<UserBloc, UserState>(
            buildWhen: (a, b) => a.current != b.current,
            builder: (context, userState) {
              // Árvore base da app
              final app = const SisGed();

              // Sem usuário ainda? não injeta o OAEsBloc (evita provider "vazio")
              if (userState.current == null) {
                return app;
              }

              // Quando houver usuário, envolve a app com o BlocProvider de OAEs
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
