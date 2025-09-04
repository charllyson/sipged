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
        child: Container(
          width: double.infinity, // 👈 ocupa 100%
          height: 30,
          color: Colors.white,
          alignment: Alignment.center, // 👈 centraliza o conteúdo
          child: FutureBuilder<int>(
            future: systemBloc.getBuildNumber(),
            builder: (context, snapshot) {
              final buildText = snapshot.hasData
                  ? ' • Build nº ${snapshot.data}'
                  : '';

              return Text(
                'Copyright © ${DateTime.now().year} • '
                    'Todos os direitos reservados • '
                    'Desenvolvido por C.A.S Engenharia & Tecnologia • '
                    'Versão 1.0.0$buildText',
                style: textStyle,
                textAlign: TextAlign.center, // 👈 texto centralizado
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              );
            },
          ),
        ),
      ),
    );
  }
}
