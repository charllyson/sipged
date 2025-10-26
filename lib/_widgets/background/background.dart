import 'package:flutter/material.dart';

class Background extends StatelessWidget {
  const Background({super.key, this.gradient});

  /// Se não vier nada, cai no degradê padrão.
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints.expand(), // 🔥 força ocupar toda a tela
      decoration: BoxDecoration(
        gradient: gradient ??
            const LinearGradient(
              colors: [
                Color(0xFF1B2033),
                Color(0xFF90CAF9)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
      ),
    );
  }
}
