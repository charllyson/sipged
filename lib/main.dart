import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:sisgeo/_blocs/login/login_bloc.dart';
import 'package:sisgeo/_blocs/user/user_bloc.dart';
import 'package:sisgeo/_datas/user/user_data.dart';
import 'package:sisgeo/screens/commons/login/sign_in.dart';
import 'package:sisgeo/side_menu_page.dart';

import '_provider/user/user_provider.dart';


void main() async {
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

  Provider.debugCheckInvalidValueType = null; // ← aqui

  runApp(
    MultiProvider(
      providers: [
        Provider<LoginBloc>.value(value: LoginBloc()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const SisGeo(),
    ),
  );
}


class SisGeo extends StatelessWidget {
  const SisGeo({super.key});

  @override
  Widget build(BuildContext context) {
    final loginBloc = Provider.of<LoginBloc>(context, listen: false);
    final userBloc = UserBloc(); // Pode ser trocado por Provider também se precisar compartilhar

    return MaterialApp(
      title: 'SISGEO',
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<LoginState>(
        stream: loginBloc.outState,
        initialData: LoginState.loading,
        builder: (context, snapshot) {
          final state = snapshot.data;
          final firebaseUser = FirebaseAuth.instance.currentUser;

          if (state == LoginState.loading) {
            return const Scaffold(
              body: Center(child: Text('Verificando usuário...')),
            );
          }

          if (state == LoginState.fail || firebaseUser == null) {
            return const SignIn();
          }

          if ([
            LoginState.successProfileCommom,
            LoginState.successProfileGovernment,
            LoginState.successProfileCollaborator,
            LoginState.successProfileCompany,
          ].contains(state)) {
            return FutureBuilder<UserData?>(
              future: userBloc.getUserData(uid: firebaseUser.uid),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) {
                  return const Scaffold(
                      body: Center(child: CircularProgressIndicator()));
                }

                final userData = userSnapshot.data!;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Provider.of<UserProvider>(context, listen: false)
                      .setUserData(userData);
                });

                return const SideMenuPage();
              },
            );
          }

          return const SignIn();
        },
      ),
    );
  }
}
