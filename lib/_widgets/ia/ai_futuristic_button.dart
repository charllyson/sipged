import 'package:flutter/material.dart';

class AiFuturisticButton extends StatelessWidget {
  final VoidCallback onTap;

  const AiFuturisticButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF00E0FF),
              Color(0xFF7B61FF),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blueAccent.withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              Icons.auto_awesome,
              size: 14,
              color: Colors.white,
            ),
            SizedBox(width: 6),
            Text(
              'SIPGED • IA',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}