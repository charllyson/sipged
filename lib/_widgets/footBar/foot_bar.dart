import 'package:flutter/material.dart';

import 'package:siged/_blocs/system/info/system_bloc.dart';
import 'package:siged/_widgets/shimmer/shimmer_w60_h14.dart';

class FootBar extends StatelessWidget {
  const FootBar({super.key});

  @override
  Widget build(BuildContext context) {
    final systemBloc = SystemBloc();
    final textStyle = const TextStyle(color: Colors.grey, fontSize: 11);

    return Material(
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 30, // altura estável do rodapé
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Copyright © ${DateTime.now().year} • '
                      'Todos os direitos reservados • '
                      'Desenvolvido por C.A.S Engenharia & Tecnologia • '
                      'Versão 1.0.0',
                  style: textStyle,
                  softWrap: false, // não quebra
                  maxLines: 1,
                ),
                const SizedBox(width: 12),
                FutureBuilder<int>(
                  future: systemBloc.getBuildNumber(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const ShimmerW60H14();
                    return Text(
                      'Build nº ${snapshot.data}',
                      style: textStyle,
                      softWrap: false,
                      maxLines: 1,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
