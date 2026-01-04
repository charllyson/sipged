import 'package:flutter/material.dart';

class TopMenuButton extends StatelessWidget {
  final String label;
  final bool isOpen;      // ainda aceito, mas não uso visualmente
  final TextStyle textStyle;
  final VoidCallback onTap;

  const TopMenuButton({
    super.key,
    required this.label,
    required this.isOpen,
    required this.textStyle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Não muda mais cor por isOpen – quem controla é o pai (HorizontalMenuBar)
    final color = textStyle.color ?? Colors.black87;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: onTap,
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.transparent, // sem fundo – o Container pai do menu que pinta
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: textStyle.copyWith(color: color),
          ),
        ),
      ),
    );
  }
}
