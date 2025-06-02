import 'package:flutter/material.dart';

class DERLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'DER-AL',
              style: TextStyle(
                fontFamily: 'Homework',
                color: Colors.white,
                fontSize: 100,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(
              height: 65,
              width: 65,
              child: Image(
                image: AssetImage(
                  'assets/logos/deral/logo-deral.png',
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: const Text(
            'Gerenciamento de contratos, e acompanhamento de obras',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'RobotoMono',
            ),
          ),
        ),
      ],
    );
  }
}
