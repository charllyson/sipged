import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:sisged/_blocs/system/login/login_bloc.dart';
import 'package:sisged/_datas/system/user_data.dart';

class SignUpBotton extends StatelessWidget {
  const SignUpBotton({
    super.key,
    required this.userData,
    required this.loginBloc,
    required this.formKey
  });
  final UserData userData;
  final LoginBloc loginBloc;
  final GlobalKey<FormState> formKey;

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
