import 'package:flutter/material.dart';

class TermsAndConditions extends StatelessWidget {
  const TermsAndConditions({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        /*Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Terms()),
        );*/
      },
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          children: const [
            Text(
              'Ao cadastrar, você concorda com nossos:',
              style: TextStyle(
                fontSize: 11,
                color: Colors.blue,
              ),
            ),
            Text(
              ' Termos e Condições e Política de Privacidade',
              style: TextStyle(
                fontSize: 11,
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
