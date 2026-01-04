// lib/screens/process/hiring/11Arquivamento/termo_arquivamento_page.dart
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ===== Progress (etapas)
import 'package:siged/_blocs/process/hiring/0Stages/progress_bloc.dart';
import 'package:siged/_blocs/process/hiring/0Stages/progress_repository.dart';
import 'package:siged/_blocs/process/hiring/0Stages/progress_state.dart';

// ===== Termo de Arquivamento
import 'package:siged/_blocs/process/hiring/11Arquivamento/termo_arquivamento_cubit.dart';
import 'package:siged/_blocs/process/hiring/11Arquivamento/termo_arquivamento_data.dart';
import 'package:siged/_blocs/process/hiring/11Arquivamento/termo_arquivamento_state.dart';
import 'package:siged/_blocs/process/hiring/0Stages/hiring_stages.dart';

// ===== Widgets / UI
import 'package:siged/_widgets/background/background_cleaner.dart';
import 'package:siged/_widgets/menu/tab/stage_progress.dart';

// ===== Seções
import 'package:siged/screens/process/hiring/11Arquivamento/section_1_metadados.dart';
import 'package:siged/screens/process/hiring/11Arquivamento/section_2_motivo_abrangencia.dart';
import 'package:siged/screens/process/hiring/11Arquivamento/section_3_fundamentacao.dart';
import 'package:siged/screens/process/hiring/11Arquivamento/section_4_pecas_anexas.dart';
import 'package:siged/screens/process/hiring/11Arquivamento/section_5_decisao_autoridade.dart';
import 'package:siged/screens/process/hiring/11Arquivamento/section_6_reabertura.dart';

// ===== Utils
import 'package:siged/_utils/validates/form_validation_mixin.dart';

// ===== Overlay leve
import 'package:siged/_widgets/overlays/screen_lock.dart';

// ===== Notificações
import 'package:siged/_widgets/notification/app_notification.dart';
import 'package:siged/_widgets/notification/notification_center.dart';

// ===== Pipeline (habilitação dinâmica das abas)
import 'package:siged/_blocs/process/hiring/0Stages/pipeline_progress_cubit.dart';

// ===== Stage Gate (habilitação por etapa)
import 'package:siged/_widgets/menu/tab/stage_gate.dart';

class TermoArquivamentoPage extends StatefulWidget {
  final String contractId;
  final bool readOnly;

  const TermoArquivamentoPage({
    super.key,
    required this.contractId,
    this.readOnly = false,
  });

  @override
  State<TermoArquivamentoPage> createState() => _TermoArquivamentoPageState();
}

class _TermoArquivamentoPageState extends State<TermoArquivamentoPage>
    with FormValidationMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final ProgressCubit _progressBloc;

  TermoArquivamentoData _formData = const TermoArquivamentoData.empty();
  bool _hydrated = false;
  String? _currentTaId;

  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _progressBloc = ProgressCubit(repo: ProgressRepository());

    // Dispara o load inicial
    context.read<TermoArquivamentoCubit>().load(widget.contractId);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _progressBloc.close();
    super.dispose();
  }

  Future<void> _saveOnly() async {
    final cubit = context.read<TermoArquivamentoCubit>();

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
            title: const Text('Termo de Arquivamento'),
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
          title: const Text('Termo de Arquivamento'),
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
      child: BlocListener<TermoArquivamentoCubit, TermoArquivamentoState>(
        listenWhen: (prev, curr) =>
        (prev.loading && !curr.loading) || (prev.taId != curr.taId),
        listener: (context, state) {
          if (!mounted) return;
          if (state.loading || !state.hasValidPath) return;

          final incomingId = state.taId;
          final needsHydrate = !_hydrated || _currentTaId != incomingId;

          if (needsHydrate) {
            final data =
            TermoArquivamentoData.fromSectionsMap(state.sectionsData);

            setState(() {
              _formData = data;
            });

            _hydrated = true;
            _currentTaId = incomingId;

            if (incomingId != null && incomingId.isNotEmpty) {
              _progressBloc.bindToStage(
                contractId: widget.contractId,
                collectionName: 'arquivamento',
              );
            }
          }
        },
        child: BlocBuilder<TermoArquivamentoCubit, TermoArquivamentoState>(
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
                stageKey: HiringStageKey.arquivamento,
                child: Scaffold(
                  body: Stack(
                    children: [
                      const BackgroundClean(),
                      SingleChildScrollView(
                        key: const PageStorageKey('termo-arquivamento-scroll'),
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1) Metadados
                            SectionMetadadosTA(
                              data: _formData,
                              isEditable: !widget.readOnly,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            const SizedBox(height: 12),

                            // 2) Motivo e Abrangência
                            SectionMotivoAbrangenciaTA(
                              data: _formData,
                              isEditable: !widget.readOnly,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            const SizedBox(height: 12),

                            // 3) Fundamentação
                            SectionFundamentacaoTA(
                              data: _formData,
                              isEditable: !widget.readOnly,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            const SizedBox(height: 12),

                            // 4) Peças Anexas
                            SectionPecasAnexasTA(
                              data: _formData,
                              isEditable: !widget.readOnly,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            const SizedBox(height: 12),

                            // 5) Decisão da Autoridade
                            SectionDecisaoAutoridadeTA(
                              data: _formData,
                              isEditable: !widget.readOnly,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            const SizedBox(height: 12),

                            // 6) Reabertura
                            SectionReaberturaTA(
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
                        title: 'Termo de Arquivamento',
                        icon: Icons.archive_outlined,
                        busy: state.saving,
                        approved: pstate.approved,
                        onSave: _saveOnly,
                        onSaveAndNext: () async {
                          await _saveOnly();

                          final taId =
                              context.read<TermoArquivamentoCubit>().state.taId;
                          if (taId == null || taId.isEmpty) {
                            NotificationCenter.instance.show(
                              AppNotification(
                                title: const Text('Termo de Arquivamento'),
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
                              collectionName: 'arquivamento',
                              approverUid: uid,
                              approverName: nameOrEmail,
                            );

                            await repo.setCompleted(
                              contractId: widget.contractId,
                              collectionName: 'arquivamento',
                              completed: true,
                            );

                            // Última etapa (ajuste se quiser liberar algo depois)
                            final pipeline =
                            context.read<PipelineProgressCubit>();
                            pipeline.setStageEnabled(
                              HiringStageKey.arquivamento,
                              true,
                            );
                            unawaited(pipeline.refresh());

                            final controller =
                            DefaultTabController.of(context);
                            controller?.animateTo(
                              (controller.index + 1)
                                  .clamp(0, controller.length - 1),
                            );

                            NotificationCenter.instance.show(
                              AppNotification(
                                title: const Text('Termo de Arquivamento'),
                                subtitle: const Text(
                                  'Aprovado e etapa concluída.',
                                ),
                                type: AppNotificationType.success,
                              ),
                            );
                          } catch (e) {
                            NotificationCenter.instance.show(
                              AppNotification(
                                title: const Text('Termo de Arquivamento'),
                                subtitle: const Text('Erro ao aprovar.'),
                                details: Text('$e'),
                                type: AppNotificationType.error,
                              ),
                            );
                          }
                        },
                        onUpdateApproved: () async {
                          await _saveOnly();

                          final taId =
                              context.read<TermoArquivamentoCubit>().state.taId;
                          if (taId == null || taId.isEmpty) {
                            NotificationCenter.instance.show(
                              AppNotification(
                                title: const Text('Termo de Arquivamento'),
                                subtitle: const Text(
                                  'Documento não encontrado para atualizar.',
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
                            await repo.touchApproval(
                              contractId: widget.contractId,
                              collectionName: 'arquivamento',
                              updatedByUid: uid,
                              updatedByName: nameOrEmail,
                            );

                            NotificationCenter.instance.show(
                              AppNotification(
                                title: const Text('Termo de Arquivamento'),
                                subtitle: const Text(
                                  'Aprovação atualizada.',
                                ),
                                type: AppNotificationType.success,
                              ),
                            );
                          } catch (e) {
                            NotificationCenter.instance.show(
                              AppNotification(
                                title: const Text('Termo de Arquivamento'),
                                subtitle: const Text(
                                  'Erro ao atualizar aprovação.',
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
