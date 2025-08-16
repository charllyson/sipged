import 'package:flutter/material.dart';

class SisGedLogo extends StatelessWidget {

  final double? fontSize;
  final double? heightLogo;
  final double? widthLogo;

  const SisGedLogo({
    super.key,
    this.fontSize = 80,
    this.heightLogo = 50,
    this.widthLogo = 50,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'SiGed',
              style: TextStyle(
                fontFamily: 'Homework',
                color: Colors.white,
                fontSize: fontSize,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: heightLogo,
              width: widthLogo,
              child: Image(
                image: AssetImage(
                  'assets/logos/sisgeo/sisgeo.png',
                ),
              ),
            ),
          ],
        ),
        const Text(
          'Sistema Integrado de Gerenciamento de dados',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
