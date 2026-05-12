// lib/_widgets/gates/progress_stage.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/0Progress/progress_cubit.dart';
import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/_widgets/menu/tab/stage_blocked_card.dart';

class ProgressStage extends StatelessWidget {
  const ProgressStage({
    super.key,
    required this.stageKey,
    required this.child,
    this.blockedMessage,
  });

  final String stageKey;
  final Widget child;

  /// Mensagem opcional enquanto bloqueado.
  final String? blockedMessage;

  @override
  Widget build(BuildContext context) {
    final gateState = context.select<ProgressCubit, ({bool loading, bool enabled})>(
          (cubit) {
        final enabled = cubit.isStageEnabled(stageKey);

        return (
        loading: cubit.state.loading,
        enabled: enabled,
        );
      },
    );

    // Enquanto carrega o progresso, não bloqueia.
    // Evita piscar a tela bloqueada antes do ProgressCubit terminar o bind/watch.
    if (gateState.loading || gateState.enabled) {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: KeyedSubtree(
          key: ValueKey<String>('stage-gate-enabled-$stageKey'),
          child: child,
        ),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: Stack(
        key: ValueKey<String>('stage-gate-blocked-$stageKey'),
        children: <Widget>[
          child,

          // Overlay de bloqueio.
          // O ModalBarrier bloqueia cliques no conteúdo de baixo,
          // mas o card continua interativo porque está acima dele no Stack.
          Positioned.fill(
            child: Stack(
              children: <Widget>[
                const Positioned.fill(
                  child: BackgroundChange(),
                ),
                Positioned.fill(
                  child: ModalBarrier(
                    dismissible: false,
                    color: Colors.white.withValues(alpha: 0.72),
                  ),
                ),
                Positioned.fill(
                  child: StageBlockedCard(
                    stageKey: stageKey,
                    blockedMessage: blockedMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
