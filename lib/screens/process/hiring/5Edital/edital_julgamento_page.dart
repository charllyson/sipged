// lib/screens/process/hiring/5Edital/edital_julgamento_page.dart
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_widgets/overlays/screen_lock.dart';
import 'package:siged/_widgets/background/background_cleaner.dart';
import 'package:siged/_widgets/gates/stage_gate.dart';
import 'package:siged/_widgets/progress/stage_progress.dart';
import 'package:siged/_widgets/notification/app_notification.dart';
import 'package:siged/_widgets/notification/notification_center.dart';

import 'package:siged/_blocs/process/hiring/0Progress/progress_bloc.dart';
import 'package:siged/_blocs/process/hiring/0Progress/progress_event.dart';
import 'package:siged/_blocs/process/hiring/0Progress/progress_repository.dart';
import 'package:siged/_blocs/process/hiring/0Progress/progress_state.dart';

import 'package:siged/_blocs/process/hiring/0Progress/hiring_stages.dart';

import 'package:siged/_blocs/process/hiring/5Edital/edital_julgamento_controller.dart';
import 'package:siged/_blocs/process/hiring/5Edital/edital_bloc.dart';
import 'package:siged/_blocs/process/hiring/0Progress/pipeline_progress_cubit.dart';

// Seções extraídas
import 'package:siged/screens/process/hiring/5Edital/section_1_divulgacao_recebimento.dart';
import 'package:siged/screens/process/hiring/5Edital/section_2_sessao_julgamento.dart';
import 'package:siged/screens/process/hiring/5Edital/section_3_propostas.dart';
import 'package:siged/screens/process/hiring/5Edital/section_4_lances.dart';
import 'package:siged/screens/process/hiring/5Edital/section_5_parecer_recursos.dart';
import 'package:siged/screens/process/hiring/5Edital/section_6_resultado.dart';

class EditalJulgamentoPage extends StatefulWidget {
  final EditalJulgamentoController controller;
  final String contractId;
  final bool readOnly;

  const EditalJulgamentoPage({
    super.key,
    required this.controller,
    required this.contractId,
    this.readOnly = false,
  });

  @override
  State<EditalJulgamentoPage> createState() => _EditalJulgamentoPageState();
}

class _EditalJulgamentoPageState extends State<EditalJulgamentoPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final ProgressBloc _progressBloc;
  bool _hydrated = false;
  String? _currentEditalId;

  // Scroll + ancora do resultado
  final _scrollCtrl = ScrollController();
  final _resultadoKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _progressBloc = ProgressBloc(repo: ProgressRepository());
    widget.controller.addListener(_onControllerChanged);

    context.read<EditalBloc>().add(EditalLoadRequested(widget.contractId));
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _scrollCtrl.dispose();
    _progressBloc.close();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _scrollToResultado() async {
    final ctx = _resultadoKey.currentContext;
    if (ctx != null) {
      await Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        alignment: 0.05,
      );
    }
  }

  void _definirVencedorEIr(int index) {
    widget.controller.definirVencedorPorIndice(index);
    _scrollToResultado();
  }

  Future<void> _saveOnly() async {
    final bloc = context.read<EditalBloc>();

    final quick = widget.controller.quickValidate();
    if (quick != null) {
      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Validação do Edital'),
          subtitle: Text(quick),
          type: AppNotificationType.warning,
        ),
      );
      return;
    }

    final completer = Completer<void>();
    late final StreamSubscription sub;
    sub = bloc.stream.listen((s) {
      if (!s.saving) {
        if (!completer.isCompleted) completer.complete();
        sub.cancel();
      }
    });

    bloc.add(EditalSaveRequested(
      contractId: widget.contractId,
      sectionsData: widget.controller.toSectionMaps(),
    ));

    await completer.future;

    if (!bloc.state.saveSuccess) {
      final err = bloc.state.error ?? 'Falha ao salvar';
      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Edital'),
          subtitle: const Text('Erro ao salvar.'),
          details: Text(err),
          type: AppNotificationType.error,
        ),
      );
      return;
    }

    NotificationCenter.instance.show(
      AppNotification(
        title: const Text('Edital'),
        subtitle: const Text('Alterações salvas com sucesso.'),
        type: AppNotificationType.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final c = widget.controller..isEditable = !widget.readOnly;

    return BlocProvider.value(
      value: _progressBloc,
      child: BlocListener<EditalBloc, EditalState>(
        listenWhen: (prev, curr) =>
        (prev.loading && !curr.loading) || (prev.editalId != curr.editalId),
        listener: (context, state) {
          if (!mounted || state.loading || !state.hasValidPath) return;

          final incomingId = state.editalId;
          final needsHydrate = !_hydrated || _currentEditalId != incomingId;

          if (needsHydrate) {
            c.fromSectionMaps(state.sectionsData);
            _hydrated = true;
            _currentEditalId = incomingId;

            if (incomingId != null && incomingId.isNotEmpty) {
              _progressBloc.add(ProgressBindRequested(
                contractId: widget.contractId,
                collectionName: 'edital',
                stageId: incomingId,
              ));
            }
          }
        },
        child: BlocBuilder<EditalBloc, EditalState>(
          builder: (context, state) {
            final pstate = context.watch<ProgressBloc>().state;

            final locked = state.loading || state.saving || pstate.loading;
            final msg = state.loading
                ? 'Sincronizando os dados...'
                : state.saving
                ? 'Salvando os dados...'
                : pstate.loading
                ? 'Atualizando aprovação...'
                : null;

            return ScreenLock(
              locked: locked,
              message: msg,
              details: locked ? 'Por favor, aguarde.' : null,
              keepAppBarUndimmed: true,
              child: StageGate(
                stageKey: HiringStageKey.edital,
                child: Scaffold(
                  body: Stack(
                    children: [
                      const BackgroundClean(),
                      SingleChildScrollView(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 120),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SectionDivulgacaoRecebimento(controller: c),
                            SectionSessaoJulgamento(controller: c),
                            SectionPropostas(
                              controller: c,
                              onDefinirVencedorEIr: _definirVencedorEIr,
                            ),
                            SectionLances(controller: c),
                            SectionParecerRecursos(controller: c),
                            SectionResultado(
                              controller: c,
                              keyResultado: _resultadoKey,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  bottomNavigationBar:
                  BlocBuilder<ProgressBloc, ProgressState>(
                    builder: (context, p) {
                      return StageProgress(
                        title: 'Edital – Julgamento',
                        icon: Icons.gavel_outlined,
                        busy: state.saving,
                        approved: p.approved,
                        onSave: _saveOnly,
                        onSaveAndNext: () async {
                          await _saveOnly();

                          final editalId =
                              context.read<EditalBloc>().state.editalId;
                          if (editalId == null || editalId.isEmpty) {
                            NotificationCenter.instance.show(
                              AppNotification(
                                title: const Text('Edital'),
                                subtitle: const Text(
                                    'Documento não encontrado para aprovar.'),
                                type: AppNotificationType.error,
                              ),
                            );
                            return;
                          }

                          final user = FirebaseAuth.instance.currentUser;
                          final uid = user?.uid ?? '';
                          final nameOrEmail =
                          (user?.displayName?.trim().isNotEmpty ?? false)
                              ? user!.displayName!
                              : (user?.email ?? uid);

                          final repo = _progressBloc.repo;
                          try {
                            await repo.approveStage(
                              contractId: widget.contractId,
                              collectionName: 'edital',
                              stageId: editalId,
                              approverUid: uid,
                              approverName: nameOrEmail,
                            );
                            await repo.setCompleted(
                              contractId: widget.contractId,
                              collectionName: 'edital',
                              stageId: editalId,
                              completed: true,
                            );

                            // 🔹 Liberação otimista: Habilitação
                            final pipeline =
                            context.read<PipelineProgressCubit>();
                            pipeline.setStageEnabled(
                                HiringStageKey.habilitacao, true);
                            unawaited(pipeline.refresh());

                            final controller =
                            DefaultTabController.of(context);
                            controller?.animateTo(
                              (controller.index + 1)
                                  .clamp(0, controller.length - 1),
                            );

                            NotificationCenter.instance.show(
                              AppNotification(
                                title: const Text('Edital'),
                                subtitle:
                                const Text('Aprovado e etapa concluída.'),
                                type: AppNotificationType.success,
                              ),
                            );
                          } catch (e) {
                            NotificationCenter.instance.show(
                              AppNotification(
                                title: const Text('Edital'),
                                subtitle:
                                const Text('Erro ao aprovar a etapa.'),
                                details: Text('$e'),
                                type: AppNotificationType.error,
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
