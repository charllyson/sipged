// lib/screens/modules/contracts/hiring/5Edital/edital_julgamento_page.dart
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Layout / Overlays / Notificações
import 'package:siged/_widgets/background/background_cleaner.dart';
import 'package:siged/_widgets/overlays/screen_lock.dart';
import 'package:siged/_widgets/menu/tab/stage_progress.dart';
import 'package:siged/_widgets/notification/app_notification.dart';
import 'package:siged/_widgets/notification/notification_center.dart';
import 'package:siged/_widgets/menu/tab/stage_gate.dart';

// Pipeline / Progress
import 'package:siged/_blocs/modules/contracts/hiring/0Stages/progress_bloc.dart';
import 'package:siged/_blocs/modules/contracts/hiring/0Stages/progress_repository.dart';
import 'package:siged/_blocs/modules/contracts/hiring/0Stages/progress_state.dart';
import 'package:siged/_blocs/modules/contracts/hiring/0Stages/pipeline_progress_cubit.dart';
import 'package:siged/_blocs/modules/contracts/hiring/0Stages/hiring_stages.dart';

// Edital (Cubit + Data + State)
import 'package:siged/_blocs/modules/contracts/hiring/5Edital/edital_cubit.dart';
import 'package:siged/_blocs/modules/contracts/hiring/5Edital/edital_data.dart';
import 'package:siged/_blocs/modules/contracts/hiring/5Edital/edital_state.dart';

// Seções
import 'package:siged/screens/modules/contracts/hiring/5Edital/section_1_divulgacao_recebimento.dart';
import 'package:siged/screens/modules/contracts/hiring/5Edital/section_2_sessao_julgamento.dart';
import 'package:siged/screens/modules/contracts/hiring/5Edital/section_3_propostas.dart';
import 'package:siged/screens/modules/contracts/hiring/5Edital/section_4_lances.dart';
import 'package:siged/screens/modules/contracts/hiring/5Edital/section_5_parecer_recursos.dart';
import 'package:siged/screens/modules/contracts/hiring/5Edital/section_6_resultado.dart';

class EditalJulgamentoPage extends StatefulWidget {
  final String contractId;
  final bool readOnly;

  const EditalJulgamentoPage({
    super.key,
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

  late final ProgressCubit _progressCubit;

  EditalData _formData = const EditalData.empty();
  bool _hydrated = false;
  String? _currentEditalId;

  final _scrollCtrl = ScrollController();
  final _resultadoKey = GlobalKey();

  bool get _isEditable => !widget.readOnly;

  @override
  void initState() {
    super.initState();
    _progressCubit = ProgressCubit(repo: ProgressRepository());

    // Dispara o load inicial via Cubit
    context.read<EditalCubit>().load(widget.contractId);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _progressCubit.close();
    super.dispose();
  }

  /// Validação rápida (igual quickValidate antigo do controller)
  String? _quickValidate(EditalData d) {
    if (d.numero.trim().isEmpty) {
      return 'Informe o número do edital/processo.';
    }
    if (d.modalidade.trim().isEmpty) {
      return 'Selecione a modalidade.';
    }
    if (d.criterio.trim().isEmpty) {
      return 'Selecione o critério de julgamento.';
    }
    return null;
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

  /// Define vencedor a partir da proposta e rola até a seção Resultado
  void _definirVencedorEIr(int index) {
    final propostas = _formData.propostasItems;
    if (index < 0 || index >= propostas.length) return;

    final p = propostas[index];
    final licitante = (p['licitante'] ?? '').toString();
    final cnpj = (p['cnpj'] ?? '').toString();
    final valor = (p['valor'] ?? '').toString();

    setState(() {
      _formData = _formData.copyWith(
        vencedor: licitante,
        vencedorCnpj: cnpj,
        valorVencedor: valor,
        highlightWinner: true,
      );
    });

    _scrollToResultado();
  }

  Future<void> _saveOnly() async {
    final cubit = context.read<EditalCubit>();

    // Validação rápida
    final quick = _quickValidate(_formData);
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
            title: const Text('Edital'),
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
          title: const Text('Edital'),
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
      value: _progressCubit,
      child: BlocListener<EditalCubit, EditalState>(
        listenWhen: (prev, curr) =>
        (prev.loading && !curr.loading) || (prev.editalId != curr.editalId),
        listener: (context, state) {
          if (!mounted || state.loading || !state.hasValidPath) return;

          final incomingId = state.editalId;
          final needsHydrate = !_hydrated || _currentEditalId != incomingId;

          if (needsHydrate) {
            final data = EditalData.fromSectionsMap(state.sectionsData);

            setState(() {
              _formData = data;
              _hydrated = true;
              _currentEditalId = incomingId;
            });

            if (incomingId != null && incomingId.isNotEmpty) {
              _progressCubit.bindToStage(
                contractId: widget.contractId,
                collectionName: 'edital',
              );
            }
          }
        },
        child: BlocBuilder<EditalCubit, EditalState>(
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
                stageKey: HiringStageKey.edital,
                child: Scaffold(
                  body: Stack(
                    children: [
                      const BackgroundClean(),
                      SingleChildScrollView(
                        key: const PageStorageKey('edital-scroll'),
                        controller: _scrollCtrl,
                        padding:
                        const EdgeInsets.fromLTRB(12, 12, 12, 120), // margem p/ bottom bar
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SectionDivulgacaoRecebimento(
                              isEditable: _isEditable,
                              data: _formData,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            const SizedBox(height: 12),
                            SectionSessaoJulgamento(
                              isEditable: _isEditable,
                              data: _formData,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            const SizedBox(height: 12),
                            SectionPropostas(
                              isEditable: _isEditable,
                              data: _formData,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                              onDefinirVencedorEIr: _definirVencedorEIr,
                            ),
                            const SizedBox(height: 12),
                            SectionLances(
                              isEditable: _isEditable,
                              data: _formData,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            const SizedBox(height: 12),
                            SectionParecerRecursos(
                              isEditable: _isEditable,
                              data: _formData,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            const SizedBox(height: 12),
                            SectionResultado(
                              isEditable: _isEditable,
                              data: _formData,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                              keyResultado: _resultadoKey,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  bottomNavigationBar:
                  BlocBuilder<ProgressCubit, ProgressState>(
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
                              context.read<EditalCubit>().state.editalId;
                          if (editalId == null || editalId.isEmpty) {
                            NotificationCenter.instance.show(
                              AppNotification(
                                title: const Text('Edital'),
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

                          final repo = _progressCubit.repo;
                          try {
                            await repo.approveStage(
                              contractId: widget.contractId,
                              collectionName: 'edital',
                              approverUid: uid,
                              approverName: nameOrEmail,
                            );
                            await repo.setCompleted(
                              contractId: widget.contractId,
                              collectionName: 'edital',
                              completed: true,
                            );

                            final pipeline =
                            context.read<PipelineProgressCubit>();
                            pipeline.setStageEnabled(
                              HiringStageKey.habilitacao,
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
                                title: const Text('Edital'),
                                subtitle: const Text(
                                  'Aprovado e etapa concluída.',
                                ),
                                type: AppNotificationType.success,
                              ),
                            );
                          } catch (e) {
                            NotificationCenter.instance.show(
                              AppNotification(
                                title: const Text('Edital'),
                                subtitle: const Text(
                                  'Erro ao aprovar a etapa.',
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
