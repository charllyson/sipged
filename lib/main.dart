import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:sisgeo/_blocs/login/login_bloc.dart';
import 'package:sisgeo/_models/user/user_model.dart';
import 'package:sisgeo/screens/commons/login/sign_in.dart';
import 'package:sisgeo/sideMenuPage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR');

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyDZh7jcJNO0XEW2eCXecWq3MdTvRFPzHJk',
        authDomain: 'sisgeoderal.firebaseapp.com',
        projectId: 'sisgeoderal',
        storageBucket: 'sisgeoderal.appspot.com',
        messagingSenderId: '769410863294',
        appId: '1:769410863294:web:a51d56dfd32369dd4b0eef',
        measurementId: 'G-EJBDWKRPQ8',
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  runApp(const SisGeo());
}

class SisGeo extends StatefulWidget {
  const SisGeo({super.key});

  @override
  State<SisGeo> createState() => _SisGeoState();
}

class _SisGeoState extends State<SisGeo> {
  late final LoginBloc _loginBloc;

  @override
  void initState() {
    super.initState();
    _loginBloc = LoginBloc();
  }

  @override
  Widget build(BuildContext context) {
    return ScopedModel<UserModel>(
      model: UserModel(),
      child: ScopedModelDescendant<UserModel>(
        builder: (context, child, model) {
          return MaterialApp(
            title: 'SISGEO',
            debugShowCheckedModeBanner: false,
            home: StreamBuilder<LoginState>(
              stream: _loginBloc.outState,
              initialData: LoginState.loading,
              builder: (context, snapshot) {
                final state = snapshot.data;
                if (state == LoginState.loading) {
                  return const Scaffold(
                    body: Center(child: Text('Verificando usuário...')),
                  );
                } else if (state == LoginState.fail || state == LoginState.idle || state == null) {
                  return SignIn();
                } else {
                  UserModel.of(context).loadCurrentUser();
                  return const SideMenuPage();
                }
              },
            ),
          );
        },
      ),
    );
  }
}
