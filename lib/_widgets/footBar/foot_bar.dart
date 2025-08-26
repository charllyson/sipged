import 'package:flutter/material.dart';

import 'package:sisged/_blocs/system/info/system_bloc.dart';
import 'package:sisged/_widgets/shimmer/shimmer_w60_h14.dart';

class FootBar extends StatelessWidget {
  const FootBar({super.key});

  @override
  Widget build(BuildContext context) {
    final systemBloc = SystemBloc();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        width: MediaQuery.of(context).size.width,
        color: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Copyright © 2025 • Todos os direitos reservados • Desenvolvido por C.A.S Engenharia & Tecnologia • Versão 1.0.0',
              style: TextStyle(color: Colors.grey, fontSize: 11),
            ),
            SizedBox(width: 8),
            FutureBuilder<int>(
              future: systemBloc.getBuildNumber(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const ShimmerW60H14();
                return Text('Build nº ${snapshot.data}', style: TextStyle(color: Colors.grey, fontSize: 11));
              },
            )
          ],
        ),
      ),
    );
  }
}
