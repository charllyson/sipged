// lib/screens/modules/contracts/hiring/3Tr/tr_page.dart
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Overlay / layout
import 'package:sipged/_widgets/overlays/screen_lock.dart';
import 'package:sipged/_widgets/background/background_change.dart';
import 'package:sipged/_widgets/menu/tab/stage_gate.dart';
import 'package:sipged/_widgets/menu/tab/stage_progress.dart';

// Notificações
import 'package:sipged/_widgets/notification/app_notification.dart';
import 'package:sipged/_widgets/notification/notification_center.dart';

// Progress (etapas)
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/progress_bloc.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/progress_repository.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/progress_state.dart';

// Pipeline (habilitação dinâmica das abas)
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/hiring_stages.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/pipeline_progress_cubit.dart';

// TR Cubit/State/Data
import 'package:sipged/_blocs/modules/contracts/hiring/3Tr/tr_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/3Tr/tr_state.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/3Tr/tr_data.dart';

// Seções
import 'package:sipged/screens/modules/contracts/hiring/3Tr/section_1_objeto_fundamentacao.dart';
import 'package:sipged/screens/modules/contracts/hiring/3Tr/section_2_escopo_requisitos.dart';
import 'package:sipged/screens/modules/contracts/hiring/3Tr/section_3_local_prazos_cronograma.dart';
import 'package:sipged/screens/modules/contracts/hiring/3Tr/section_4_medicao_aceite_indicadores.dart';
import 'package:sipged/screens/modules/contracts/hiring/3Tr/section_5_obrigacoes_equipe_gestao.dart';
import 'package:sipged/screens/modules/contracts/hiring/3Tr/section_6_licenciamento_seguranca_sustentabilidade.dart';
import 'package:sipged/screens/modules/contracts/hiring/3Tr/section_7_precos_pagamento_reajuste.dart';
import 'package:sipged/screens/modules/contracts/hiring/3Tr/section_8_riscos_penalidades_condicoes.dart';
import 'package:sipged/screens/modules/contracts/hiring/3Tr/section_9_documentos_referencias.dart';

import 'package:sipged/_utils/validates/sipged_validation.dart';

class TermoReferenciaPage extends StatefulWidget {
  final String contractId;
  final bool readOnly; // igual DfdPage

  const TermoReferenciaPage({
    super.key,
    required this.contractId,
    this.readOnly = false,
  });

  @override
  State<TermoReferenciaPage> createState() => _TermoReferenciaPageState();
}

class _TermoReferenciaPageState extends State<TermoReferenciaPage>
    with SipGedValidation, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Progress bloc FIXO (não recriar no build)
  late final ProgressCubit _progressBloc;

  // Estado local baseado em MODEL (padrão DfdPage)
  TrData _formData = const TrData.empty();
  bool _hydrated = false;
  String? _currentTrId;

  @override
  void initState() {
    super.initState();
    _progressBloc = ProgressCubit(repo: ProgressRepository());

    // Dispara o load inicial do TR (via Cubit)
    context.read<TrCubit>().load(widget.contractId);
  }

  @override
  void dispose() {
    _progressBloc.close();
    super.dispose();
  }

  Future<void> _saveOnly() async {
    final cubit = context.read<TrCubit>();

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

    if (!cubit.state.saveSuccess) {
      final err = cubit.state.error ?? 'Falha ao salvar';
      if (mounted) {
        NotificationCenter.instance.show(
          AppNotification(
            title: const Text('TR'),
            subtitle: const Text('Erro ao salvar.'),
            details: Text(err),
            type: AppNotificationType.error,
          ),
        );
      }
      return;
    }

    if (mounted) {
      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('TR'),
          subtitle: const Text('Alterações salvas com sucesso.'),
          type: AppNotificationType.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocProvider.value(
      value: _progressBloc,
      child: BlocListener<TrCubit, TrState>(
        listenWhen: (prev, curr) =>
        (prev.loading && !curr.loading) || (prev.trId != curr.trId),
        listener: (context, state) {
          if (!mounted || state.loading || !state.hasValidPath) return;

          final incomingId = state.trId;
          final needsHydrate = !_hydrated || _currentTrId != incomingId;

          if (needsHydrate) {
            // monta o DATA a partir dos maps (igual DfdData.fromSectionsMap)
            final data = TrData.fromSectionsMap(state.sectionsData);
            setState(() => _formData = data);

            _hydrated = true;
            _currentTrId = incomingId;

            // Bind único (ProgressBloc deduplica)
            if (incomingId != null && incomingId.isNotEmpty) {
              _progressBloc.bindToStage(
                contractId: widget.contractId,
                collectionName: 'tr',
              );
            }
          }
        },
        child: BlocBuilder<TrCubit, TrState>(
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
                stageKey: HiringStageKey.tr,
                child: Scaffold(
                  body: Stack(
                    children: [
                      const BackgroundChange(),
                      SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1) Objeto / Fundamentação
                            SectionObjetoFundamentacao(
                              data: _formData,
                              isEditable: !widget.readOnly,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            const SizedBox(height: 12),

                            // 2) Escopo / Requisitos
                            SectionEscopoRequisitos(
                              data: _formData,
                              isEditable: !widget.readOnly,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            const SizedBox(height: 12),

                            // 3) Local / Prazos / Cronograma
                            SectionLocalPrazosCronograma(
                              data: _formData,
                              isEditable: !widget.readOnly,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            const SizedBox(height: 12),

                            // 4) Medição / Aceite / Indicadores
                            SectionMedicaoAceiteIndicadores(
                              data: _formData,
                              isEditable: !widget.readOnly,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            const SizedBox(height: 12),

                            // 5) Obrigações / Equipe / Gestão
                            SectionObrigacoesEquipeGestao(
                              data: _formData,
                              isEditable: !widget.readOnly,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            const SizedBox(height: 12),

                            // 6) Licenciamento / Segurança / Sustentabilidade
                            SectionLicenciamentoSegurancaSustentabilidade(
                              data: _formData,
                              isEditable: !widget.readOnly,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            const SizedBox(height: 12),

                            // 7) Preços / Pagamento / Reajuste
                            SectionPrecosPagamentoReajuste(
                              data: _formData,
                              isEditable: !widget.readOnly,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            const SizedBox(height: 12),

                            // 8) Riscos / Penalidades / Condições
                            SectionRiscosPenalidadesCondicoes(
                              data: _formData,
                              isEditable: !widget.readOnly,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            const SizedBox(height: 12),

                            // 9) Documentos / Referências
                            SectionDocumentosReferencias(
                              data: _formData,
                              isEditable: !widget.readOnly,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ],
                  ),
                  bottomNavigationBar:
                  BlocBuilder<ProgressCubit, ProgressState>(
                    builder: (context, pstate) {
                      return StageProgress(
                        title: 'Termo de Referência',
                        icon: Icons.rule_folder_outlined,
                        busy: state.saving,
                        approved: pstate.approved,
                        onSave: _saveOnly,
                        onSaveAndNext: () async {
                          await _saveOnly();

                          final trId =
                              context.read<TrCubit>().state.trId;
                          if (trId == null || trId.isEmpty) {
                            NotificationCenter.instance.show(
                              AppNotification(
                                title: const Text('TR'),
                                subtitle: const Text(
                                  'Documento não encontrado para aprovar.',
                                ),
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
                              collectionName: 'tr',
                              approverUid: uid,
                              approverName: nameOrEmail,
                            );

                            await repo.setCompleted(
                              contractId: widget.contractId,
                              collectionName: 'tr',
                              completed: true,
                            );

                            // 🔹 Liberação otimista: Cotação
                            final pipeline =
                            context.read<PipelineProgressCubit>();
                            pipeline.setStageEnabled(
                              HiringStageKey.cotacao,
                              true,
                            );
                            unawaited(pipeline.refresh());

                            final tab =
                            DefaultTabController.of(context);
                            tab.animateTo(
                              (tab.index + 1)
                                  .clamp(0, tab.length - 1),
                            );

                            NotificationCenter.instance.show(
                              AppNotification(
                                title: const Text('TR'),
                                subtitle: const Text(
                                  'Aprovado e etapa concluída.',
                                ),
                                type: AppNotificationType.success,
                              ),
                            );
                          } catch (e) {
                            NotificationCenter.instance.show(
                              AppNotification(
                                title: const Text('TR'),
                                subtitle: const Text(
                                  'Erro ao aprovar.',
                                ),
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
