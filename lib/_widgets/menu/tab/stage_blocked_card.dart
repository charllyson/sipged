import 'package:flutter/material.dart';
import 'package:sipged/_utils/theme/sipged_theme.dart';

class StageBlockedCard extends StatelessWidget {
  const StageBlockedCard({super.key,
    required this.stageKey,
    this.blockedMessage,
  });

  final String stageKey;
  final String? blockedMessage;

  @override
  Widget build(BuildContext context) {
    final TabController? tabController = DefaultTabController.maybeOf(context);

    final bool canGoPrevious =
        tabController != null && tabController.length > 0 && tabController.index > 0;

    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: SipGedTheme.primaryColor,
            width: 2,
          ),
          color: Colors.white,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.lock_outline,
                size: 44,
                color: SipGedTheme.primaryColor,
              ),
              const SizedBox(height: 12),
              Text(
                'Etapa bloqueada',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: SipGedTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                blockedMessage ?? 'Conclua e salve a etapa anterior para avançar.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.35,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: SipGedTheme.primaryColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade700,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                ),
                onPressed: canGoPrevious
                    ? () {
                  final int currentIndex = tabController.index;
                  final int previousIndex =
                  currentIndex <= 0 ? 0 : currentIndex - 1;

                  tabController.animateTo(previousIndex);
                }
                    : null,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Ir para etapa anterior'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}