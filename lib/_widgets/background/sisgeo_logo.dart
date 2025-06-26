import 'package:flutter/material.dart';

class SisGeoLogo extends StatelessWidget {
  const SisGeoLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'SisGeo',
              style: TextStyle(
                fontFamily: 'Homework',
                color: Colors.white,
                fontSize: 80,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(
              height: 50,
              width: 50,
              child: Image(
                image: AssetImage(
                  'assets/logos/sisgeo/sisgeo.png',
                ),
              ),
            ),
          ],
        ),
        const Text(
          'Sistema Integrado de Gerenciamento de obras',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
