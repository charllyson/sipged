// lib/_widgets/draw/background/background_change.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/system/user/user_cubit.dart';
import 'package:sipged/_blocs/system/user/user_data.dart';

class BackgroundChange extends StatelessWidget {
  const BackgroundChange({
    super.key,
    this.color,
    this.gradient,
    this.palette,
    this.useUserTheme = true,
  });

  final Color? color;
  final Gradient? gradient;
  final BgPalette? palette;

  /// Quando true, tenta adaptar o fundo com base no usuário atual.
  ///
  /// dentro de UserData.
  final bool useUserTheme;

  static const BgPalette defaultLightPalette = BgPalette(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFF7FBFF),
        Color(0xFFE3F2FD),
      ],
    ),
  );

  static const BgPalette defaultDarkPalette = BgPalette(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF0F172A),
        Color(0xFF1E293B),
      ],
    ),
  );

  static BgPalette paletteForUser(UserData? user) {
    final isDark = user?.themeDark == true;

    if (isDark) {
      return defaultDarkPalette;
    }

    return defaultLightPalette;
  }

  @override
  Widget build(BuildContext context) {
    if (gradient != null) {
      return Container(
        decoration: BoxDecoration(
          gradient: gradient,
        ),
      );
    }

    if (color != null) {
      return Container(
        decoration: BoxDecoration(
          color: color,
        ),
      );
    }

    if (palette != null) {
      return Container(
        decoration: BoxDecoration(
          gradient: palette!.gradient,
          color: palette!.color,
        ),
      );
    }

    final user = useUserTheme
        ? context.select<UserCubit, UserData?>(
          (cubit) => cubit.state.current,
    )
        : null;

    final resolvedPalette = paletteForUser(user);

    return Container(
      decoration: BoxDecoration(
        gradient: resolvedPalette.gradient,
        color: resolvedPalette.color,
      ),
    );
  }
}

class BgPalette {
  const BgPalette({
    this.color,
    this.gradient,
  });

  final Color? color;
  final Gradient? gradient;
}