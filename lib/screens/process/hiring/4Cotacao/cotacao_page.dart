// lib/screens/process/hiring/4Cotacao/cotacao_page.dart
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:siged/_blocs/_process/process_controller.dart';

// Overlays / Layout / Gates / Notificações
import 'package:siged/_widgets/overlays/screen_lock.dart';
import 'package:siged/_widgets/background/background_cleaner.dart';
import 'package:siged/_widgets/gates/stage_gate.dart';
import 'package:siged/_widgets/progress/stage_progress.dart';
import 'package:siged/_widgets/notification/app_notification.dart';
import 'package:siged/_widgets/notification/notification_center.dart';

// Progress
import 'package:siged/_blocs/process/hiring/0Progress/progress_bloc.dart';
import 'package:siged/_blocs/process/hiring/0Progress/progress_event.dart';
import 'package:siged/_blocs/process/hiring/0Progress/progress_repository.dart';
import 'package:siged/_blocs/process/hiring/0Progress/progress_state.dart';
import 'package:siged/_blocs/process/hiring/0Progress/pipeline_progress.dart';
import 'package:siged/_blocs/process/hiring/0Progress/pipeline_progress_cubit.dart';

import 'package:siged/_blocs/process/hiring/0Progress/hiring_stages.dart';

// Cotação (Bloc/Controller)
import 'package:siged/_blocs/process/hiring/4Cotacao/cotacao_bloc.dart';
import 'package:siged/_blocs/process/hiring/4Cotacao/cotacao_controller.dart';

// Seções (arquivos separados)
import 'package:siged/screens/process/hiring/4Cotacao/section_1_metadados.dart';
import 'package:siged/screens/process/hiring/4Cotacao/section_2_objeto_itens.dart';
import 'package:siged/screens/process/hiring/4Cotacao/section_3_convite_divulgacao.dart';
import 'package:siged/screens/process/hiring/4Cotacao/section_4_respostas_fornecedores.dart';
import 'package:siged/screens/process/hiring/4Cotacao/section_5_vencedora.dart';
import 'package:siged/screens/process/hiring/4Cotacao/section_6_consolidacao_resultado.dart';
import 'package:siged/screens/process/hiring/4Cotacao/section_7_anexos.dart';

class CotacaoPage extends StatefulWidget {
  final CotacaoController controller;
  final String contractId;
  final bool readOnly;

  const CotacaoPage({
    super.key,
    required this.controller,
    required this.contractId,
    this.readOnly = false,
  });

  @override
  State<CotacaoPage> createState() => _CotacaoPageState();
}

class _CotacaoPageState extends State<CotacaoPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final ProgressBloc _progressBloc;
  bool _hydrated = false;
  String? _currentCotacaoId;

  // Controle de quantidade de fornecedores visíveis na seção 4
  int _fornCount = 1;

  @override
  void initState() {
    super.initState();
    _progressBloc = ProgressBloc(repo: ProgressRepository());
    context.read<CotacaoBloc>().add(CotacaoLoadRequested(widget.contractId));
  }

  @override
  void dispose() {
    _progressBloc.close();
    super.dispose();
  }

  void _inferFornCountFromController(CotacaoController c) {
    int count = 1;
    if (c.f2NomeCtrl.text.isNotEmpty || c.f2ValorCtrl.text.isNotEmpty) count = 2;
    if (c.f3NomeCtrl.text.isNotEmpty || c.f3ValorCtrl.text.isNotEmpty) count = 3;
    _fornCount = count.clamp(1, 3);
  }

  void _removeFornecedor() {
    if (_fornCount <= 1) return;
    setState(() => _fornCount = (_fornCount - 1).clamp(1, 3));
  }

  void _addFornecedor() {
    setState(() => _fornCount = (_fornCount + 1).clamp(1, 3));
  }

  Future<void> _saveOnly() async {
    final bloc = context.read<CotacaoBloc>();

    final quick = widget.controller.quickValidate();
    if (quick != null) {
      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Validação da Cotação'),
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

    bloc.add(CotacaoSaveRequested(
      contractId: widget.contractId,
      sectionsData: widget.controller.toSectionMaps(),
    ));

    await completer.future;

    if (!bloc.state.saveSuccess) {
      final err = bloc.state.error ?? 'Falha ao salvar';
      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Cotação'),
          subtitle: const Text('Erro ao salvar.'),
          details: Text(err),
          type: AppNotificationType.error,
        ),
      );
      return;
    }

    NotificationCenter.instance.show(
      AppNotification(
        title: const Text('Cotação'),
        subtitle: const Text('Alterações salvas com sucesso.'),
        type: AppNotificationType.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // Mantém a semântica do TR: ProgressBloc no Provider acima e Controller disponível no subtree
    return BlocProvider.value(
      value: _progressBloc,
      child: ChangeNotifierProvider<CotacaoController>.value(
        value: widget.controller..isEditable = !widget.readOnly,
        child: BlocListener<CotacaoBloc, CotacaoState>(
          listenWhen: (prev, curr) =>
          (prev.loading && !curr.loading) || (prev.cotacaoId != curr.cotacaoId),
          listener: (context, state) {
            if (!mounted || state.loading || !state.hasValidPath) return;

            final incomingId = state.cotacaoId;
            final needsHydrate = !_hydrated || _currentCotacaoId != incomingId;

            if (needsHydrate) {
              widget.controller.fromSectionMaps(state.sectionsData);
              _inferFornCountFromController(widget.controller);

              _hydrated = true;
              _currentCotacaoId = incomingId;

              if (incomingId != null && incomingId.isNotEmpty) {
                _progressBloc.add(ProgressBindRequested(
                  contractId: widget.contractId,
                  collectionName: 'cotacao',
                  stageId: incomingId,
                ));
              }
            }
          },
          child: BlocBuilder<CotacaoBloc, CotacaoState>(
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
                  stageKey: HiringStageKey.cotacao,
                  child: Scaffold(
                    body: Stack(
                      children: [
                        const BackgroundClean(),
                        SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 120),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SectionMetadados(c: context.read<CotacaoController>()),
                              SectionObjetoItens(controller: context.read<CotacaoController>()),
                              SectionConviteDivulgacao(controller: context.read<CotacaoController>()),
                              SectionRespostasFornecedores(
                                controller: context.read<CotacaoController>(),
                                fornCount: _fornCount,
                                onAdd: (!context.read<CotacaoController>().isEditable || _fornCount >= 3)
                                    ? null
                                    : _addFornecedor,
                                onRemoveOne: (!context.read<CotacaoController>().isEditable || _fornCount <= 1)
                                    ? null
                                    : _removeFornecedor,
                              ),
                              SectionVencedora(
                                controller: context.read<CotacaoController>(),
                                contractsController: context.read<ProcessController>(),
                              ),
                              SectionConsolidacaoResultado(controller: context.read<CotacaoController>()),
                              SectionAnexos(controller: context.read<CotacaoController>()),
                            ],
                          ),
                        ),
                      ],
                    ),
                    bottomNavigationBar: BlocBuilder<ProgressBloc, ProgressState>(
                      builder: (context, pstate) {
                        return StageProgress(
                          title: 'Cotação de preços',
                          icon: Icons.request_quote_outlined,
                          busy: state.saving,
                          approved: pstate.approved,
                          onSave: _saveOnly,
                          onSaveAndNext: () async {
                            await _saveOnly();

                            final cotId = context.read<CotacaoBloc>().state.cotacaoId;
                            if (cotId == null || cotId.isEmpty) {
                              NotificationCenter.instance.show(
                                AppNotification(
                                  title: const Text('Cotação'),
                                  subtitle: const Text('Documento não encontrado para aprovar.'),
                                  type: AppNotificationType.error,
                                ),
                              );
                              return;
                            }

                            final user = FirebaseAuth.instance.currentUser;
                            final uid = user?.uid ?? '';
                            final nameOrEmail = (user?.displayName?.trim().isNotEmpty ?? false)
                                ? user!.displayName!
                                : (user?.email ?? uid);

                            final repo = _progressBloc.repo;
                            try {
                              await repo.approveStage(
                                contractId: widget.contractId,
                                collectionName: 'cotacao',
                                stageId: cotId,
                                approverUid: uid,
                                approverName: nameOrEmail,
                              );
                              await repo.setCompleted(
                                contractId: widget.contractId,
                                collectionName: 'cotacao',
                                stageId: cotId,
                                completed: true,
                              );

                              // 🔹 Liberação otimista: Edital
                              final pipeline = context.read<PipelineProgressCubit>();
                              pipeline.setStageEnabled(HiringStageKey.edital, true);
                              unawaited(pipeline.refresh());

                              final controller = DefaultTabController.of(context);
                              if (controller != null) {
                                controller.animateTo(
                                  (controller.index + 1).clamp(0, controller.length - 1),
                                );
                              }

                              NotificationCenter.instance.show(
                                AppNotification(
                                  title: const Text('Cotação'),
                                  subtitle: const Text('Aprovado e etapa concluída.'),
                                  type: AppNotificationType.success,
                                ),
                              );
                            } catch (e) {
                              NotificationCenter.instance.show(
                                AppNotification(
                                  title: const Text('Cotação'),
                                  subtitle: const Text('Erro ao aprovar.'),
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
      ),
    );
  }
}
