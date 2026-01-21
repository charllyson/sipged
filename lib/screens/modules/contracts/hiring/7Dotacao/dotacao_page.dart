import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Users / Utils
import 'package:siged/_utils/validates/form_validation_mixin.dart';

// Layout / Inputs / Widgets
import 'package:siged/_widgets/background/background_cleaner.dart';
import 'package:siged/_widgets/overlays/screen_lock.dart';
import 'package:siged/_widgets/menu/tab/stage_progress.dart';
import 'package:siged/_widgets/notification/app_notification.dart';
import 'package:siged/_widgets/notification/notification_center.dart';

// Pipeline / Progress
import 'package:siged/_blocs/modules/contracts/hiring/0Stages/progress_bloc.dart';
import 'package:siged/_blocs/modules/contracts/hiring/0Stages/progress_repository.dart';
import 'package:siged/_blocs/modules/contracts/hiring/0Stages/progress_state.dart';
import 'package:siged/_blocs/modules/contracts/hiring/0Stages/pipeline_progress_cubit.dart';
import 'package:siged/_widgets/menu/tab/stage_gate.dart';

import 'package:siged/_blocs/modules/contracts/hiring/0Stages/hiring_stages.dart';

// Dotação
import 'package:siged/_blocs/modules/contracts/hiring/7Dotacao/dotacao_cubit.dart';
import 'package:siged/_blocs/modules/contracts/hiring/7Dotacao/dotacao_data.dart';
import 'package:siged/_blocs/modules/contracts/hiring/7Dotacao/dotacao_state.dart';

// Seções
import 'package:siged/screens/modules/contracts/hiring/7Dotacao/section_1_identificacao.dart';
import 'package:siged/screens/modules/contracts/hiring/7Dotacao/section_2_vinculacao_programatica.dart';
import 'package:siged/screens/modules/contracts/hiring/7Dotacao/section_3_natureza_despesa.dart';
import 'package:siged/screens/modules/contracts/hiring/7Dotacao/section_4_reserva.dart';
import 'package:siged/screens/modules/contracts/hiring/7Dotacao/section_5_empenho.dart';
import 'package:siged/screens/modules/contracts/hiring/7Dotacao/section_6_cronograma.dart';
import 'package:siged/screens/modules/contracts/hiring/7Dotacao/section_7_documentos_links.dart';

class DotacaoPage extends StatefulWidget {
  final String contractId;
  final bool readOnly;

  const DotacaoPage({
    super.key,
    required this.contractId,
    this.readOnly = false,
  });

  @override
  State<DotacaoPage> createState() => _DotacaoPageState();
}

class _DotacaoPageState extends State<DotacaoPage>
    with FormValidationMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final ProgressCubit _progressBloc;

  DotacaoData _formData = const DotacaoData.empty();
  bool _hydrated = false;
  String? _currentDotId;

  final _scrollController = ScrollController();

  bool get _isEditable => !widget.readOnly;

  @override
  void initState() {
    super.initState();
    _progressBloc = ProgressCubit(repo: ProgressRepository());

    // Dispara o load inicial
    context.read<DotacaoCubit>().load(widget.contractId);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _progressBloc.close();
    super.dispose();
  }

  Future<void> _saveOnly() async {
    final cubit = context.read<DotacaoCubit>();

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
            title: const Text('Dotação'),
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
          title: const Text('Dotação'),
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
      child: BlocListener<DotacaoCubit, DotacaoState>(
        listenWhen: (prev, curr) =>
        (prev.loading && !curr.loading) || (prev.dotacaoId != curr.dotacaoId),
        listener: (context, state) {
          if (!mounted || state.loading || !state.hasValidPath) return;

          final incomingId = state.dotacaoId;
          final needsHydrate = !_hydrated || _currentDotId != incomingId;
          if (needsHydrate) {
            final data = DotacaoData.fromSectionsMap(state.sectionsData);

            setState(() {
              _formData = data;
            });

            _hydrated = true;
            _currentDotId = incomingId;

            if (incomingId != null && incomingId.isNotEmpty) {
              _progressBloc.bindToStage(
                contractId: widget.contractId,
                collectionName: 'dotacao',
              );
            }
          }
        },
        child: BlocBuilder<DotacaoCubit, DotacaoState>(
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
                stageKey: HiringStageKey.dotacao,
                child: Scaffold(
                  body: Stack(
                    children: [
                      const BackgroundClean(),
                      SingleChildScrollView(
                        key: const PageStorageKey('dotacao-scroll'),
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 120),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SectionIdentificacao(
                              data: _formData,
                              isEditable: _isEditable,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            SectionVinculacaoProgramatica(
                              data: _formData,
                              isEditable: _isEditable,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            SectionNaturezaDespesa(
                              data: _formData,
                              isEditable: _isEditable,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            SectionReserva(
                              data: _formData,
                              isEditable: _isEditable,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            SectionEmpenho(
                              data: _formData,
                              isEditable: _isEditable,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            SectionCronograma(
                              data: _formData,
                              isEditable: _isEditable,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            SectionDocumentosLinks(
                              data: _formData,
                              isEditable: _isEditable,
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
                        title: 'Dotação Orçamentária',
                        icon: Icons.account_balance_wallet_outlined,
                        busy: state.saving,
                        approved: pstate.approved,
                        onSave: _saveOnly,
                        onSaveAndNext: () async {
                          await _saveOnly();

                          final dotId =
                              context.read<DotacaoCubit>().state.dotacaoId;
                          if (dotId == null || dotId.isEmpty) {
                            NotificationCenter.instance.show(
                              AppNotification(
                                title: const Text('Dotação'),
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
                              collectionName: 'dotacao',
                              approverUid: uid,
                              approverName: nameOrEmail,
                            );

                            await repo.setCompleted(
                              contractId: widget.contractId,
                              collectionName: 'dotacao',
                              completed: true,
                            );

                            // Libera MINUTA (próxima etapa)
                            final pipeline =
                            context.read<PipelineProgressCubit>();
                            pipeline.setStageEnabled(
                              HiringStageKey.minuta,
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
                                title: const Text('Dotação'),
                                subtitle: const Text(
                                  'Aprovado e etapa concluída.',
                                ),
                                type: AppNotificationType.success,
                              ),
                            );
                          } catch (e) {
                            NotificationCenter.instance.show(
                              AppNotification(
                                title: const Text('Dotação'),
                                subtitle:
                                const Text('Erro ao aprovar.'),
                                details: Text('$e'),
                                type: AppNotificationType.error,
                              ),
                            );
                          }
                        },
                        onUpdateApproved: () async {
                          await _saveOnly();

                          final dotId =
                              context.read<DotacaoCubit>().state.dotacaoId;
                          if (dotId == null || dotId.isEmpty) {
                            NotificationCenter.instance.show(
                              AppNotification(
                                title: const Text('Dotação'),
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
                              collectionName: 'dotacao',
                              updatedByUid: uid,
                              updatedByName: nameOrEmail,
                            );

                            NotificationCenter.instance.show(
                              AppNotification(
                                title: const Text('Dotação'),
                                subtitle: const Text(
                                  'Aprovação atualizada.',
                                ),
                                type: AppNotificationType.success,
                              ),
                            );
                          } catch (e) {
                            NotificationCenter.instance.show(
                              AppNotification(
                                title: const Text('Dotação'),
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
