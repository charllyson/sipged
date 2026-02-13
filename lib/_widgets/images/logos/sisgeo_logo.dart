import 'package:flutter/material.dart';

class SiGedLogo extends StatelessWidget {
  final double? fontSize;
  final double? heightLogo;
  final double? widthLogo;

  /// Callback para voltar à Home dentro do MenuListPage
  final VoidCallback? onTapHome;

  const SiGedLogo({
    super.key,
    this.fontSize = 80,
    this.heightLogo = 50,
    this.widthLogo = 50,
    this.onTapHome,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTapHome, // 👈 deixa o MenuListPage decidir como ir pra Home
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'SipGed',
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
                child: const Image(
                  image: AssetImage('assets/logos/sipged/sipged.png'),
                ),
              ),
            ],
          ),
          const Text(
            'Sistema Integrado de Planejameto e Gestão de dados',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
