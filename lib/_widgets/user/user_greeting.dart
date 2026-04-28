// lib/_widgets/user/user_greeting.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/system/user/user_cubit.dart';
import 'package:sipged/_blocs/system/user/user_data.dart';
import 'package:sipged/_blocs/system/user/user_state.dart';

class UserGreeting extends StatefulWidget {
  final User? firebaseUser;
  final TextStyle? style;
  final int maxLines;
  final TextOverflow overflow;
  final bool softWrap;

  const UserGreeting({
    super.key,
    required this.firebaseUser,
    this.style,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
    this.softWrap = false,
  });

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

    final state = context.read<UserCubit>().state;

    final already =
        (state.current?.uid == fb.uid) || state.byId.containsKey(fb.uid);

    if (!already) {
      context.read<UserCubit>().fetchById(fb.uid);
    }

    _dispatched = true;
  }

  @override
  void didUpdateWidget(covariant UserGreeting oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.firebaseUser?.uid != widget.firebaseUser?.uid) {
      _dispatched = false;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        final fb = widget.firebaseUser;
        if (fb == null || _dispatched) return;

        final state = context.read<UserCubit>().state;

        final already =
            (state.current?.uid == fb.uid) || state.byId.containsKey(fb.uid);

        if (!already) {
          context.read<UserCubit>().fetchById(fb.uid);
        }

        _dispatched = true;
      });
    }
  }

  TextStyle _resolvedStyle() {
    return widget.style ??
        const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        );
  }

  Widget _buildText(String name) {
    return Text(
      'Olá, $name',
      maxLines: widget.maxLines,
      overflow: widget.overflow,
      softWrap: widget.softWrap,
      style: _resolvedStyle(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fb = widget.firebaseUser;

    if (fb == null) {
      return _buildText('Usuário');
    }

    return BlocSelector<UserCubit, UserState, UserData?>(
      selector: (state) {
        if (state.current?.uid == fb.uid) return state.current;
        return state.byId[fb.uid];
      },
      builder: (context, user) {
        final name = (user?.name?.trim().isNotEmpty ?? false)
            ? user!.name!.trim()
            : 'Usuário';

        return _buildText(name);
      },
    );
  }
}