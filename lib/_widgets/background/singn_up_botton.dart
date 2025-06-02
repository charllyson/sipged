import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../_blocs/login/login_bloc.dart';
import '../../_blocs/user/user_bloc.dart';
import '../../_datas/user/user_data.dart';

class SignUpBotton extends StatelessWidget {
  const SignUpBotton({
    super.key,
    required this.userBloc, 
    required this.userData,
    required this.loginBloc,
    required this.passController,
    required this.repeatPassController,
    required this.formKey
  });
  final UserBloc userBloc;
  final UserData userData;
  final LoginBloc loginBloc;
  final passController;
  final repeatPassController;
  final GlobalKey<FormState> formKey;

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
