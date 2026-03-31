// lib/screens/modules/contracts/hiring/10Publicacao/publicacao_extrato_page.dart
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ===== Progress (etapas) =====
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/progress_bloc.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/progress_repository.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/progress_state.dart';

// ===== Publicação / Extrato =====
import 'package:sipged/_blocs/modules/contracts/hiring/10Publicacao/publicacao_extrato_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/10Publicacao/publicacao_extrato_data.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/hiring_stages.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/10Publicacao/publicacao_extrato_state.dart';

// ===== Widgets / UI =====
import 'package:sipged/_widgets/background/background_change.dart';
import 'package:sipged/_widgets/menu/tab/stage_progress.dart';

// ===== Seções =====
import 'package:sipged/screens/modules/contracts/hiring/10Publicacao/section_1_metadados.dart';
import 'package:sipged/screens/modules/contracts/hiring/10Publicacao/section_2_partes_valores.dart';
import 'package:sipged/screens/modules/contracts/hiring/10Publicacao/section_3_veiculo.dart';
import 'package:sipged/screens/modules/contracts/hiring/10Publicacao/section_4_status_prazos.dart';
import 'package:sipged/screens/modules/contracts/hiring/10Publicacao/section_5_responsavel.dart';

// ===== Utils =====
import 'package:sipged/_utils/validates/sipged_validation.dart';

// ===== Overlay leve =====
import 'package:sipged/_widgets/overlays/screen_lock.dart';

// ===== Notificações =====
import 'package:sipged/_widgets/notification/app_notification.dart';
import 'package:sipged/_widgets/notification/notification_center.dart';

// ===== Pipeline (habilitação dinâmica das abas) =====
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/pipeline_progress_cubit.dart';

// ===== Stage Gate (habilitação por etapa) =====
import 'package:sipged/_widgets/menu/tab/stage_gate.dart';

class PublicacaoExtratoPage extends StatefulWidget {
  final String contractId;
  final bool readOnly;

  const PublicacaoExtratoPage({
    super.key,
    required this.contractId,
    this.readOnly = false,
  });

  @override
  State<PublicacaoExtratoPage> createState() => _PublicacaoExtratoPageState();
}

class _PublicacaoExtratoPageState extends State<PublicacaoExtratoPage>
    with SipGedValidation, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final ProgressCubit _progressBloc;

  PublicacaoExtratoData _formData = const PublicacaoExtratoData.empty();
  bool _hydrated = false;
  String? _currentPubId;

  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _progressBloc = ProgressCubit(repo: ProgressRepository());

    // Dispara o load inicial da Publicação/Extrato
    context.read<PublicacaoExtratoCubit>().load(widget.contractId);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _progressBloc.close();
    super.dispose();
  }

  Future<void> _saveOnly() async {
    final cubit = context.read<PublicacaoExtratoCubit>();

    final completer = Completer<void>();
    late final StreamSubscription sub;

    sub = cubit.stream.listen((state) {
      if (!state.saving) {
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
            title: const Text('Publicação / Extrato'),
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
          title: const Text('Publicação / Extrato'),
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
      child: BlocListener<PublicacaoExtratoCubit, PublicacaoExtratoState>(
        listenWhen: (prev, curr) =>
        (prev.loading && !curr.loading) || prev.pubId != curr.pubId,
        listener: (context, state) {
          if (!mounted) return;
          if (state.loading || !state.hasValidPath) return;

          final incomingId = state.pubId;
          final needsHydrate = !_hydrated || incomingId != _currentPubId;

          if (needsHydrate) {
            final data =
            PublicacaoExtratoData.fromSectionsMap(state.sectionsData);

            setState(() {
              _formData = data;
            });

            _hydrated = true;
            _currentPubId = incomingId;

            if (incomingId != null && incomingId.isNotEmpty) {
              _progressBloc.bindToStage(
                contractId: widget.contractId,
                collectionName: 'publicacao',
              );
            }
          }
        },
        child: BlocBuilder<PublicacaoExtratoCubit, PublicacaoExtratoState>(
          builder: (context, state) {
            final pstate = context.watch<ProgressCubit>().state;

            final locked = state.loading || state.saving || pstate.loading;

            final msg = state.loading
                ? 'Carregando dados...'
                : state.saving
                ? 'Salvando...'
                : pstate.loading
                ? 'Atualizando aprovação...'
                : null;

            return ScreenLock(
              locked: locked,
              message: msg,
              details: locked ? 'Aguarde...' : null,
              keepAppBarUndimmed: true,
              child: StageGate(
                stageKey: HiringStageKey.publicacao, // ajuste o enum se for outro nome
                child: Scaffold(
                  body: Stack(
                    children: [
                      const BackgroundChange(),
                      SingleChildScrollView(
                        key: const PageStorageKey('publicacao-extrato-scroll'),
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 120),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1) Metadados
                            SectionMetadadosExtrato(
                              data: _formData,
                              isEditable: !widget.readOnly,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            const SizedBox(height: 12),

                            // 2) Partes / Valores / Vigência
                            SectionPartesValoresVigencia(
                              data: _formData,
                              isEditable: !widget.readOnly,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            const SizedBox(height: 12),

                            // 3) Veículo
                            SectionVeiculoPublicacao(
                              data: _formData,
                              isEditable: !widget.readOnly,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            const SizedBox(height: 12),

                            // 4) Status / Prazos
                            SectionStatusPrazos(
                              data: _formData,
                              isEditable: !widget.readOnly,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            const SizedBox(height: 12),

                            // 5) Responsável
                            SectionResponsavel(
                              data: _formData,
                              isEditable: !widget.readOnly,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  bottomNavigationBar:
                  BlocBuilder<ProgressCubit, ProgressState>(
                    builder: (context, pstate) {
                      return StageProgress(
                        title: 'Publicação / Extrato',
                        icon: Icons.campaign_outlined,
                        busy: state.saving,
                        approved: pstate.approved,
                        onSave: _saveOnly,
                        onSaveAndNext: () async {
                          await _saveOnly();

                          final pubId = context
                              .read<PublicacaoExtratoCubit>()
                              .state
                              .pubId;
                          if (pubId == null || pubId.isEmpty) {
                            NotificationCenter.instance.show(
                              AppNotification(
                                title: const Text('Publicação / Extrato'),
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
                              collectionName: 'publicacao',
                              approverUid: uid,
                              approverName: nameOrEmail,
                            );

                            await repo.setCompleted(
                              contractId: widget.contractId,
                              collectionName: 'publicacao',
                              completed: true,
                            );

                            // Libera ARQUIVAMENTO (última etapa do pipeline)
                            final pipeline =
                            context.read<PipelineProgressCubit>();
                            pipeline.setStageEnabled(
                              HiringStageKey.arquivamento,
                              true,
                            );
                            unawaited(pipeline.refresh());

                            final controller =
                            DefaultTabController.of(context);
                            controller.animateTo(
                              (controller.index + 1)
                                  .clamp(0, controller.length - 1),
                            );

                            NotificationCenter.instance.show(
                              AppNotification(
                                title: const Text('Publicação / Extrato'),
                                subtitle: const Text(
                                  'Aprovado e etapa concluída.',
                                ),
                                type: AppNotificationType.success,
                              ),
                            );
                          } catch (e) {
                            NotificationCenter.instance.show(
                              AppNotification(
                                title: const Text('Publicação / Extrato'),
                                subtitle:
                                const Text('Erro ao aprovar a etapa.'),
                                details: Text('$e'),
                                type: AppNotificationType.error,
                              ),
                            );
                          }
                        },
                        onUpdateApproved: () async {
                          await _saveOnly();

                          final pubId = context
                              .read<PublicacaoExtratoCubit>()
                              .state
                              .pubId;
                          if (pubId == null || pubId.isEmpty) {
                            NotificationCenter.instance.show(
                              AppNotification(
                                title: const Text('Publicação / Extrato'),
                                subtitle: const Text(
                                  'Documento não encontrado para atualizar aprovação.',
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
                              collectionName: 'publicacao',
                              updatedByUid: uid,
                              updatedByName: nameOrEmail,
                            );

                            NotificationCenter.instance.show(
                              AppNotification(
                                title: const Text('Publicação / Extrato'),
                                subtitle: const Text(
                                  'Aprovação atualizada com sucesso.',
                                ),
                                type: AppNotificationType.success,
                              ),
                            );
                          } catch (e) {
                            NotificationCenter.instance.show(
                              AppNotification(
                                title: const Text('Publicação / Extrato'),
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
