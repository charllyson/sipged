// lib/_widgets/background/background_cleaner.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_blocs/system/user/user_bloc.dart';
import 'package:siged/_blocs/system/user/user_data.dart';

class BackgroundClean extends StatelessWidget {
  const BackgroundClean({
    super.key,
    this.color,     // override opcional
    this.gradient,  // override opcional
  });

  /// Se você passar [gradient] ou [color], eles têm prioridade sobre o tema do usuário.
  final Color? color;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    // 1) Overrides explícitos vencem
    if (gradient != null) {
      return Container(decoration: BoxDecoration(gradient: gradient));
    }
    if (color != null) {
      return Container(decoration: BoxDecoration(color: color));
    }

    // 2) Paleta automática por perfil do usuário
    final user = context.select<UserBloc, UserData?>((b) => b.state.current);
    final palette = UserData.paletteForUser(user);

    return Container(
      decoration: BoxDecoration(
        gradient: palette.gradient,
        color: palette.color, // usado quando gradient == null
      ),
    );
  }
}

class BgPalette {
  final Color? color;
  final Gradient? gradient;
  const BgPalette({this.color, this.gradient});
}
