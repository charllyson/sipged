import 'package:flutter/material.dart';
import 'package:sipged/_utils/theme/sipged_theme.dart';

class PaymentSummaryText extends StatelessWidget {
  const PaymentSummaryText({super.key,
    required this.label,
    required this.value,
    this.color,
  });

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: SipGedTheme.textMuted,
          fontWeight: FontWeight.w700,
        ),
        children: [
          TextSpan(text: '$label: '),
          TextSpan(
            text: value,
            style: TextStyle(
              color: color ?? SipGedTheme.textDark,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
