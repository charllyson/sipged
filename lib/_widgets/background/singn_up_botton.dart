import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../_blocs/system/login_bloc.dart';
import '../../_blocs/system/user_bloc.dart';
import '../../_datas/system/user_data.dart';

class SignUpBotton extends StatelessWidget {
  const SignUpBotton({
    super.key,
    required this.userBloc, 
    required this.userData,
    required this.loginBloc,
    required this.formKey
  });
  final UserBloc userBloc;
  final UserData userData;
  final LoginBloc loginBloc;
  final GlobalKey<FormState> formKey;

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
