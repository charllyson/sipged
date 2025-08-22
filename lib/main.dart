// lib/main.dart
import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

// ************ IMPORTS via package: ************
import 'package:sisged/_blocs/actives/active_road_bloc.dart';
import 'package:sisged/_blocs/actives/active_oaes_bloc.dart';

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

import 'package:sisged/_blocs/system/admin_bloc.dart';
import 'package:sisged/_blocs/system/login/login_bloc.dart';
import 'package:sisged/_blocs/system/system_bloc.dart';
import 'package:sisged/_blocs/system/user_provider.dart';

import 'package:sisged/_datas/actives/oaes/active_oaes_store.dart';
import 'package:sisged/_datas/actives/roads/active_roads_store.dart';
import 'package:sisged/_datas/documents/contracts/additive/additive_store.dart';
import 'package:sisged/_datas/documents/contracts/apostilles/apostilles_store.dart';
import 'package:sisged/_datas/documents/contracts/budget/budget_store.dart';
import 'package:sisged/_datas/documents/contracts/contracts/contract_store.dart';
import 'package:sisged/_datas/documents/contracts/validity/validity_store.dart';
import 'package:sisged/_datas/documents/measurement/reports/report_measurement_store.dart';

import 'package:sisged/_repository/system/user_repository.dart';

import 'package:sisged/siged_page.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Handlers de erro mais "seguros" pro Web (evita travar hot-restart)
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
      return true; // impede crash em release/web
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

    // Provider antigo pode acusar tipos Web/JS — desliga checagem
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
          ChangeNotifierProvider<UserProvider>(
            create: (ctx) {
              final up = UserProvider(repo: ctx.read<UserRepository>());
              Future.microtask(() => up.ensureLoaded(listenRealtime: true));
              up.bindCurrentUser();
              return up;
            },
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

          /// ======= Oaes =======
          Provider<ActiveOaesBloc>(create: (_) => ActiveOaesBloc()),
          ChangeNotifierProvider<ActiveOaesStore>(
            create: (ctx) => ActiveOaesStore(ctx.read<ActiveOaesBloc>()),
          ),

          /// ======= Roads =======
          Provider<ActiveRoadsBloc>(create: (_) => ActiveRoadsBloc()),
          ChangeNotifierProvider<ActiveRoadsStore>(
            create: (ctx) => ActiveRoadsStore(bloc: ctx.read<ActiveRoadsBloc>()),
          ),

          /// ======= Accidents =======
          Provider<AccidentsBloc>(create: (_) => AccidentsBloc(), dispose: (_, b) => b.dispose(),),
          ChangeNotifierProxyProvider2<AccidentsBloc, SystemBloc, AccidentsController>(
            create: (ctx) => AccidentsController(
              accidentsBloc: ctx.read<AccidentsBloc>(),
              systemBloc: ctx.read<SystemBloc>(),
            ),
            update: (_, aBloc, sBloc, ctrl) => ctrl!..updateDeps(aBloc, sBloc),
          ),

          /// ======= Infractions =======
          Provider<InfractionsBloc>(create: (_) => InfractionsBloc(), dispose: (_, b) => b.dispose(),),
          ChangeNotifierProxyProvider<InfractionsBloc, InfractionsController>(
            create: (ctx) => InfractionsController(
              bloc: ctx.read<InfractionsBloc>(),
            ),
            update: (_, iBloc, ctrl) => ctrl!..updateDeps(iBloc),
          ),

          /// ======= Payments Report =======
          Provider<PaymentReportBloc>(create: (_) => PaymentReportBloc()),
          Provider<PaymentsReportStorageBloc>(create: (_) => PaymentsReportStorageBloc()),

          /// ======= Payments Revision =======
          Provider<PaymentRevisionBloc>(create: (_) => PaymentRevisionBloc()),

          /// ======= Payments Adjustment =======
          Provider<PaymentAdjustmentBloc>(create: (_) => PaymentAdjustmentBloc()),

        ],
        child: const SisGed(),
      ),
    );
  }, (error, stack) {
    debugPrint('Uncaught (zone): $error');
    debugPrint(stack.toString());
  });
}
