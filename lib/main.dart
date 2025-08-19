// lib/main.dart
import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'package:sisged/_blocs/actives/active_road_bloc.dart';
import 'package:sisged/_blocs/documents/contracts/apostilles/apostilles_bloc.dart';
import 'package:sisged/_blocs/documents/contracts/apostilles/apostilles_storage_bloc.dart';
import 'package:sisged/_blocs/documents/contracts/budget/budget_bloc.dart';
import 'package:sisged/_blocs/documents/measurement/report/report_measurement_bloc.dart';
import 'package:sisged/_blocs/sectors/financial/payments/report/payments_report_storage_bloc.dart';

import 'package:sisged/_blocs/system/login_bloc.dart';
import 'package:sisged/_blocs/system/system_bloc.dart';
import 'package:sisged/_blocs/system/user_bloc.dart';
import 'package:sisged/siged_page.dart';

import 'package:sisged/_blocs/documents/contracts/additives/additives_bloc.dart';
import 'package:sisged/_blocs/documents/contracts/contracts/contract_bloc.dart';
import 'package:sisged/_blocs/documents/contracts/validity/validity_bloc.dart';
import 'package:sisged/_blocs/system/admin_bloc.dart';
import 'package:sisged/_provider/user/user_provider.dart';

import '_blocs/actives/active_oaes_bloc.dart';
import '_blocs/documents/contracts/additives/additives_storage_bloc.dart';
import '_blocs/documents/contracts/contracts/contract_storage_bloc.dart';
import '_blocs/documents/contracts/validity/validity_storage_bloc.dart';
import '_blocs/documents/measurement/report/report_measurement_storage_bloc.dart';

import '_datas/actives/oaes/active_oaes_store.dart';
import '_datas/actives/roads/active_roads_store.dart';
import '_datas/documents/contracts/additive/additive_store.dart';
import '_datas/documents/contracts/apostilles/apostilles_store.dart';
import '_datas/documents/contracts/budget/budget_store.dart';
import '_datas/documents/contracts/contracts/contract_store.dart';
import '_datas/documents/contracts/validity/validity_store.dart';
import '_datas/documents/measurement/reports/report_measurement_store.dart';

void main() {
  BindingBase.debugZoneErrorsAreFatal = true; // opcional

  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    // Handlers de erro dentro da mesma Zone
    FlutterError.onError = (FlutterErrorDetails details) {
      Zone.current.handleUncaughtError(
        details.exception,
        details.stack ?? StackTrace.empty,
      );
      FlutterError.dumpErrorToConsole(details, forceReport: true);
    };

    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      // Ignora frames agendados após a view já estar dispose no Web
      if (kIsWeb && error.toString().contains('EngineFlutterView') && error.toString().contains('isDisposed')) {
        return true; // sinaliza que tratou (não propaga/loga)
      }
      debugPrint('Uncaught: $error\n$stack');
      return true;
    };


    ErrorWidget.builder = (FlutterErrorDetails details) {
      return const Material(
        color: Colors.transparent,
        child: Center(
          child: Text(
            'Ocorreu um erro.',
            style: TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
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
          // --- BLoCs (dispose explícito)
          Provider<LoginBloc>(create: (_) => LoginBloc(), dispose: (_, b) => b.dispose()),
          Provider<UserBloc>(create: (_) => UserBloc(), dispose: (_, b) => b.dispose()),
          Provider<SystemBloc>(create: (_) => SystemBloc(), dispose: (_, b) => b.dispose()),
          Provider<AdminBloc>(create: (_) => AdminBloc(), dispose: (_, b) => b.dispose()),
          Provider<ContractBloc>(create: (_) => ContractBloc(), dispose: (_, b) => b.dispose()),
          Provider<AdditivesBloc>(create: (_) => AdditivesBloc(), dispose: (_, b) => b.dispose()),
          Provider<ApostillesBloc>(create: (_) => ApostillesBloc(), dispose: (_, b) => b.dispose()),
          Provider<ValidityBloc>(create: (_) => ValidityBloc(), dispose: (_, b) => b.dispose()),
          Provider<ReportMeasurementBloc>(create: (_) => ReportMeasurementBloc(), dispose: (_, b) => b.dispose()),
          Provider<BudgetBloc>(create: (_) => BudgetBloc()),
          Provider<ContractStorageBloc>(create: (_) => ContractStorageBloc()),
          Provider<AdditivesStorageBloc>(create: (_) => AdditivesStorageBloc(), dispose: (_, b) => b.dispose()),
          Provider<ReportMeasurementStorageBloc>(create: (_) => ReportMeasurementStorageBloc()),
          Provider<ValidityStorageBloc>(create: (_) => ValidityStorageBloc()),
          Provider<PaymentsReportStorageBloc>(create: (_) => PaymentsReportStorageBloc()),
          Provider<ApostillesStorageBloc>(create: (_) => ApostillesStorageBloc(), dispose: (_, b) => b.dispose()),

          // --- Stores (ChangeNotifier)
          ChangeNotifierProvider<UserProvider>(create: (_) => UserProvider()),
          ChangeNotifierProvider<ContractsStore>(
            create: (ctx) => ContractsStore(
              ctx.read<ContractBloc>(),
              ctx.read<ContractStorageBloc>(),
            ),
          ),
          ChangeNotifierProvider<AdditivesStore>(
            create: (ctx) => AdditivesStore(
              bloc: ctx.read<AdditivesBloc>(),
              storage: ctx.read<AdditivesStorageBloc>(),
            ),
          ),
          ChangeNotifierProvider<ApostillesStore>(
            create: (ctx) => ApostillesStore(
                bloc: ctx.read<ApostillesBloc>(),
                storage: ctx.read<ApostillesStorageBloc>()),
          ),
          ChangeNotifierProvider<ReportsMeasurementStore>(
            create: (ctx) => ReportsMeasurementStore(
                ctx.read<ReportMeasurementBloc>(),
            ),
          ),
          ChangeNotifierProvider<ValidityStore>(
            create: (ctx) => ValidityStore(
                bloc: ctx.read<ValidityBloc>(),
                storage: ctx.read<ValidityStorageBloc>()),
          ),
          ChangeNotifierProvider<BudgetStore>(
            create: (ctx) => BudgetStore(bloc: ctx.read<BudgetBloc>()),
          ),
          ChangeNotifierProvider<ActiveOaesStore>(
            create: (ctx) => ActiveOaesStore(ctx.read<ActiveOaesBloc>()),
          ),
          ChangeNotifierProvider<ActiveRoadsStore>(
            create: (ctx) => ActiveRoadsStore(bloc: ctx.read<ActiveRoadsBloc>()),
          ),
        ],
        child: const SisGed(),
      ),
    );
  }, (error, stack) {
    debugPrint('runZonedGuarded: $error');
    debugPrint(stack.toString());
  });
}
