// lib/main.dart
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'package:sisged/_blocs/system/login_bloc.dart';
import 'package:sisged/_blocs/system/system_bloc.dart';
import 'package:sisged/_blocs/system/user_bloc.dart';
import 'package:sisged/siged_page.dart';

import 'package:sisged/_blocs/documents/contracts/additives/additives_bloc.dart';
import 'package:sisged/_blocs/documents/contracts/contracts/contracts_bloc.dart';
import 'package:sisged/_blocs/documents/contracts/validity/validity_bloc.dart';
import 'package:sisged/_blocs/system/admin_bloc.dart';
import 'package:sisged/_provider/user/user_provider.dart';

import '_datas/documents/contracts/contracts/contract_store.dart';

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
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
          // BLoCs que NÃO são ChangeNotifier
          Provider<LoginBloc>(create: (_) => LoginBloc()),
          Provider<UserBloc>(create: (_) => UserBloc()),
          Provider<SystemBloc>(create: (_) => SystemBloc()),
          Provider<AdminBloc>(create: (_) => AdminBloc()),
          Provider<ContractsBloc>(create: (_) => ContractsBloc()),
          Provider<ValidityBloc>(create: (_) => ValidityBloc()),
          Provider<AdditivesBloc>(create: (_) => AdditivesBloc()),

          // Notifiers reais
          ChangeNotifierProvider<UserProvider>(create: (_) => UserProvider()),

          // Store global dos contratos (depende do ContractsBloc)
          ChangeNotifierProvider<ContractsStore>(
            create: (ctx) => ContractsStore(ctx.read<ContractsBloc>()),
          ),

          // ❌ Não registre ContractData como Provider global
        ],
        child: const SisGed(),
      ),
    );
  }, (error, stack) {
    debugPrint('Erro não tratado: $error');
  });
}
