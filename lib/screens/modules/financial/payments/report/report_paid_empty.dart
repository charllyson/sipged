import 'package:flutter/material.dart';
import 'package:sipged/_utils/theme/sipged_theme.dart';

class PaymentEmpty extends StatelessWidget {
  const PaymentEmpty({super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        minHeight: 150,
      ),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: SipGedTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: SipGedTheme.blackAlpha(0.06),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 42,
            color: SipGedTheme.textMuted.withValues(alpha: 0.72),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: SipGedTheme.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: SipGedTheme.textMuted,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}