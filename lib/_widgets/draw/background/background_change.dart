import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/system/user/user_cubit.dart';
import 'package:sipged/_blocs/system/user/user_data.dart';

class BackgroundChange extends StatelessWidget {
  const BackgroundChange({
    super.key,
    this.color,
    this.gradient,
  });

  final Color? color;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    if (gradient != null) {
      return Container(
        decoration: BoxDecoration(gradient: gradient),
      );
    }

    if (color != null) {
      return Container(
        decoration: BoxDecoration(color: color),
      );
    }

    final user = context.select<UserCubit, UserData?>(
          (c) => c.state.current,
    );

    final palette = UserData.paletteForUser(user);

    return Container(
      decoration: BoxDecoration(
        gradient: palette.gradient,
        color: palette.color,
      ),
    );
  }
}

class BgPalette {
  final Color? color;
  final Gradient? gradient;

  const BgPalette({
    this.color,
    this.gradient,
  });
}