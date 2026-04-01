// lib/_widgets/gates/stage_gate.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sipged/_utils/theme/sipged_theme.dart';
import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/pipeline_progress_cubit.dart';

class StageGate extends StatelessWidget {
  final String stageKey;
  final Widget child;

  /// Mensagem opcional enquanto bloqueado.
  final String? blockedMessage;

  const StageGate({
    super.key,
    required this.stageKey,
    required this.child,
    this.blockedMessage,
  });

  @override
  Widget build(BuildContext context) {
    // Reatividade fina: só reconstrói quando o "enabled" mudar.
    final (loading, enabled) = context.select<PipelineProgressCubit, (bool, bool)>((cubit) {
      final isEnabled = cubit.isStageEnabled(stageKey);
      return (cubit.state.loading, isEnabled);
    });

    // Enquanto carrega o pipeline, não bloqueia (evita "piscar" de overlay)
    if (loading || enabled) return child;

    // UI de bloqueio
    final blocker = Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SipGedTheme.primaryColor, width: 2),
          color: Colors.white,
          boxShadow: [
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
            children: [
              Icon(Icons.lock_outline, size: 44, color: SipGedTheme.primaryColor),
              const SizedBox(height: 12),
              Text(
                'Etapa bloqueada',
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
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: SipGedTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  final tab = DefaultTabController.of(context);
                  final prev = (tab.index - 1).clamp(0, tab.length - 1);
                  tab.animateTo(prev);
                                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Ir para etapa anterior'),
              ),
            ],
          ),
        ),
      ),
    );

    // Usamos AnimatedSwitcher para transição suave quando liberar/bloquear
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: Stack(
        key: const ValueKey('stage-gate-stack'),
        children: [
          child,
          // camadinha de dim + card de bloqueio
          Positioned.fill(
            child: IgnorePointer(
              ignoring: false,
              child: Stack(
                children: [
                  BackgroundChange(),
                  blocker,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
