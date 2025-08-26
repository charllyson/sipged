import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sisged/_blocs/system/user/user_bloc.dart';
import 'package:sisged/_blocs/system/user/user_event.dart';
import 'package:sisged/_blocs/system/user/user_state.dart';
import 'package:sisged/_blocs/system/user/user_data.dart';

class UserGreeting extends StatefulWidget {
  final User? firebaseUser;

  const UserGreeting({super.key, required this.firebaseUser});

  @override
  State<UserGreeting> createState() => _UserGreetingState();
}

class _UserGreetingState extends State<UserGreeting> {
  bool _dispatched = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final fb = widget.firebaseUser;
    if (fb == null || _dispatched) return;

    // Se o usuário ainda não estiver no estado, dispara uma busca por id.
    final state = context.read<UserBloc>().state;
    final already =
        (state.current?.id == fb.uid) || state.byId.containsKey(fb.uid);

    if (!already) {
      context.read<UserBloc>().add(UserFetchByIdRequested(fb.uid));
    }
    _dispatched = true;
  }

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(color: Colors.white, fontSize: 12);

    final fb = widget.firebaseUser;
    if (fb == null) return const Text('Olá, Usuário', style: style);

    return BlocSelector<UserBloc, UserState, UserData?>(
      selector: (state) {
        // Prioriza o "current"; se não for o mesmo uid, tenta o cache byId.
        if (state.current?.id == fb.uid) return state.current;
        return state.byId[fb.uid];
      },
      builder: (context, user) {
        final name = (user?.name?.trim().isNotEmpty ?? false)
            ? user!.name!.trim()
            : 'Usuário';
        return Text('Olá, $name', style: style);
      },
    );
  }
}
