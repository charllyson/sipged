import 'package:flutter/material.dart';

class ScheduleHeader extends StatelessWidget {
  final String title;
  final bool isLoading;
  final Color colorStripe;
  final double leftPadding;
  final double pctConcluido;
  final double pctAndamento;
  final double pctAIniciar;

  const ScheduleHeader({
    super.key,
    required this.title,
    required this.isLoading,
    required this.colorStripe,
    this.leftPadding = 0,
    required this.pctConcluido,
    required this.pctAndamento,
    required this.pctAIniciar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF1B2031),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(left: leftPadding),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 8,
          children: [
            // tracinho colorido
            Container(
              width: 10,
              height: 20,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(color: colorStripe, borderRadius: BorderRadius.circular(2)),
            ),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            if (isLoading)
              const SizedBox(height: 24, width: 24, child: CircularProgressIndicator.adaptive(backgroundColor: Colors.white24))
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.square, color: Colors.green, size: 12),
                  const SizedBox(width: 4),
                  Text("${pctConcluido.toStringAsFixed(1)}%", style: const TextStyle(color: Colors.white)),
                  const SizedBox(width: 14),
                  const Icon(Icons.square, color: Colors.orange, size: 12),
                  const SizedBox(width: 4),
                  Text("${pctAndamento.toStringAsFixed(1)}%", style: const TextStyle(color: Colors.white)),
                  const SizedBox(width: 14),
                  const Icon(Icons.square, color: Colors.grey, size: 12),
                  const SizedBox(width: 4),
                  Text("${pctAIniciar.toStringAsFixed(1)}%", style: const TextStyle(color: Colors.white)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
