import 'package:flutter/material.dart';

import 'package:sisged/_blocs/system/system_bloc.dart';
import 'package:sisged/_widgets/shimmer/shimmer_w60_h14.dart';

class FootBar extends StatelessWidget {
  const FootBar({super.key});

  @override
  Widget build(BuildContext context) {
    final systemBloc = SystemBloc();

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          Text(
            'Copyright © 2025',
            style: TextStyle(color: Colors.grey, fontSize: 11),
          ),
          Text(
            'Todos os direitos reservados   •',
            style: TextStyle(color: Colors.grey, fontSize: 11),
          ),
          Text(
            'Desenvolvido por C.A.S Engenharia & Tecnologia',
            style: TextStyle(color: Colors.grey, fontSize: 11),
          ),
          Text(
            'Versão 1.0.0',
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
    );
  }
}
