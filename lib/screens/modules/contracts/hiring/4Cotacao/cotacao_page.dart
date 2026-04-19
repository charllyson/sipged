import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/progress_bloc.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/progress_repository.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/progress_state.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/4Cotacao/cotacao_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/4Cotacao/cotacao_data.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/4Cotacao/cotacao_state.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/hiring_stages.dart';

import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/_widgets/menu/tab/stage_progress.dart';

import 'package:sipged/screens/modules/contracts/hiring/4Cotacao/section_1_metadados.dart';
import 'package:sipged/screens/modules/contracts/hiring/4Cotacao/section_2_objeto_itens.dart';
import 'package:sipged/screens/modules/contracts/hiring/4Cotacao/section_3_convite_divulgacao.dart';
import 'package:sipged/screens/modules/contracts/hiring/4Cotacao/section_4_respostas_fornecedores.dart';
import 'package:sipged/screens/modules/contracts/hiring/4Cotacao/section_5_vencedora.dart';
import 'package:sipged/screens/modules/contracts/hiring/4Cotacao/section_6_consolidacao_resultado.dart';
import 'package:sipged/screens/modules/contracts/hiring/4Cotacao/section_7_anexos.dart';

import 'package:sipged/_utils/validates/sipged_validation.dart';
import 'package:sipged/_widgets/overlays/screen_lock.dart';
import 'package:sipged/_widgets/notification/app_notification.dart';
import 'package:sipged/_widgets/notification/notification_center.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/pipeline_progress_cubit.dart';
import 'package:sipged/_widgets/menu/tab/stage_gate.dart';

class CotacaoPage extends StatefulWidget {
  final String contractId;
  final bool readOnly;

  const CotacaoPage({
    super.key,
    required this.contractId,
    this.readOnly = false,
  });

  @override
  State<CotacaoPage> createState() => _CotacaoPageState();
}

class _CotacaoPageState extends State<CotacaoPage>
    with SipGedValidation, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final ProgressCubit _progressBloc;

  CotacaoData _formData = const CotacaoData.empty();
  bool _hydrated = false;
  String? _currentCotacaoId;

  final _scrollController = ScrollController();
  int _fornCount = 1;

  @override
  void initState() {
    super.initState();
    _progressBloc = ProgressCubit(repo: ProgressRepository());
    context.read<CotacaoCubit>().load(widget.contractId);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _progressBloc.close();
    super.dispose();
  }

  void _inferFornCountFromData(CotacaoData d) {
    int count = 1;
    if ((d.f2Nome ?? '').isNotEmpty || (d.f2Valor ?? '').isNotEmpty) count = 2;
    if ((d.f3Nome ?? '').isNotEmpty || (d.f3Valor ?? '').isNotEmpty) count = 3;
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
    final cubit = context.read<CotacaoCubit>();

    final completer = Completer<void>();
    late final StreamSubscription sub;

    sub = cubit.stream.listen((s) {
      if (!s.saving) {
        if (!completer.isCompleted) completer.complete();
        sub.cancel();
      }
    });

    await cubit.saveAll(
      contractId: widget.contractId,
      sectionsData: _formData.toSectionsMap(),
    );

    await completer.future;

    if (!mounted) return;

    if (!cubit.state.saveSuccess) {
      final err = cubit.state.error ?? 'Falha ao salvar';
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

    return BlocProvider.value(
      value: _progressBloc,
      child: BlocListener<CotacaoCubit, CotacaoState>(
        listenWhen: (prev, curr) =>
        (prev.loading && !curr.loading) || (prev.cotacaoId != curr.cotacaoId),
        listener: (context, state) {
          if (!mounted) return;
          if (state.loading || !state.hasValidPath) return;

          final incomingId = state.cotacaoId;
          final needsHydrate = !_hydrated || _currentCotacaoId != incomingId;

          if (needsHydrate) {
            final data = CotacaoData.fromSectionsMap(state.sectionsData);

            setState(() {
              _formData = data;
              _inferFornCountFromData(data);
            });

            _hydrated = true;
            _currentCotacaoId = incomingId;

            if (incomingId != null && incomingId.isNotEmpty) {
              _progressBloc.bindToStage(
                contractId: widget.contractId,
                collectionName: 'cotacao',
              );
            }
          }
        },
        child: BlocBuilder<CotacaoCubit, CotacaoState>(
          builder: (context, state) {
            final pstate = context.watch<ProgressCubit>().state;

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
                      const BackgroundChange(),
                      SingleChildScrollView(
                        key: const PageStorageKey('cotacao-scroll'),
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SectionMetadados(
                              data: _formData,
                              isEditable: !widget.readOnly,
                              onChanged: (updated) => setState(() => _formData = updated),
                            ),
                            const SizedBox(height: 12),
                            SectionObjetoItens(
                              data: _formData,
                              isEditable: !widget.readOnly,
                              onChanged: (updated) => setState(() => _formData = updated),
                            ),
                            const SizedBox(height: 12),
                            SectionConviteDivulgacao(
                              data: _formData,
                              isEditable: !widget.readOnly,
                              onChanged: (updated) => setState(() => _formData = updated),
                            ),
                            const SizedBox(height: 12),
                            SectionRespostasFornecedores(
                              data: _formData,
                              isEditable: !widget.readOnly,
                              fornCount: _fornCount,
                              onChanged: (updated) => setState(() => _formData = updated),
                              onAdd: (!widget.readOnly && _fornCount < 3) ? _addFornecedor : null,
                              onRemoveOne: (!widget.readOnly && _fornCount > 1) ? _removeFornecedor : null,
                            ),
                            const SizedBox(height: 12),
                            SectionVencedora(
                              data: _formData,
                              isEditable: !widget.readOnly,
                              onChanged: (updated) => setState(() => _formData = updated),
                            ),
                            const SizedBox(height: 12),
                            SectionConsolidacaoResultado(
                              data: _formData,
                              isEditable: !widget.readOnly,
                              onChanged: (updated) => setState(() => _formData = updated),
                            ),
                            const SizedBox(height: 12),
                            SectionAnexos(
                              data: _formData,
                              isEditable: !widget.readOnly,
                              onChanged: (updated) => setState(() => _formData = updated),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ],
                  ),
                  bottomNavigationBar: BlocBuilder<ProgressCubit, ProgressState>(
                    builder: (context, pstate) {
                      return StageProgress(
                        title: 'Cotação de preços',
                        icon: Icons.request_quote_outlined,
                        busy: state.saving,
                        approved: pstate.approved,
                        onSave: _saveOnly,
                        onSaveAndNext: () async {
                          final cotacaoCubit = context.read<CotacaoCubit>();
                          final pipeline = context.read<PipelineProgressCubit>();
                          final controller = DefaultTabController.of(context);
                          final repo = _progressBloc.repo;

                          await _saveOnly();

                          if (!mounted) return;

                          final cotId = cotacaoCubit.state.cotacaoId;
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
                          final nameOrEmail =
                          (user?.displayName?.trim().isNotEmpty ?? false)
                              ? user!.displayName!
                              : (user?.email ?? uid);

                          try {
                            await repo.approveStage(
                              contractId: widget.contractId,
                              collectionName: 'cotacao',
                              approverUid: uid,
                              approverName: nameOrEmail,
                            );

                            await repo.setCompleted(
                              contractId: widget.contractId,
                              collectionName: 'cotacao',
                              completed: true,
                            );

                            if (!mounted) return;

                            pipeline.setStageEnabled(HiringStageKey.edital, true);
                            unawaited(pipeline.refresh());

                            controller.animateTo(
                              (controller.index + 1).clamp(0, controller.length - 1),
                            );

                            NotificationCenter.instance.show(
                              AppNotification(
                                title: const Text('Cotação'),
                                subtitle: const Text('Aprovado e etapa concluída.'),
                                type: AppNotificationType.success,
                              ),
                            );
                          } catch (e) {
                            if (!mounted) return;
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
    );
  }
}