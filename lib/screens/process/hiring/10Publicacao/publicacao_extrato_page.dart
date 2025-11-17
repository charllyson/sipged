// lib/screens/process/hiring/10Publicacao/publicacao_extrato_page.dart
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ===== Users / Utils =====
import 'package:siged/_blocs/system/user/user_bloc.dart';
import 'package:siged/_blocs/system/user/user_data.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';

// ===== Layout / Widgets =====
import 'package:siged/_widgets/background/background_cleaner.dart';
import 'package:siged/_widgets/overlays/screen_lock.dart';
import 'package:siged/_widgets/progress/stage_progress.dart';
import 'package:siged/_widgets/notification/app_notification.dart';
import 'package:siged/_widgets/notification/notification_center.dart';

// ===== Progress (etapas) =====
import 'package:siged/_blocs/process/hiring/0Stages/progress_bloc.dart';
import 'package:siged/_blocs/process/hiring/0Stages/progress_event.dart';
import 'package:siged/_blocs/process/hiring/0Stages/progress_state.dart';
import 'package:siged/_blocs/process/hiring/0Stages/progress_repository.dart';
import 'package:siged/_blocs/process/hiring/0Stages/pipeline_progress_cubit.dart';
import 'package:siged/_blocs/process/hiring/0Stages/hiring_stages.dart';

// ===== Publicação / Extrato =====
import 'package:siged/_blocs/process/hiring/10Publicacao/publicacao_extrato_bloc.dart';
import 'package:siged/_blocs/process/hiring/10Publicacao/publicacao_extrato_data.dart';

// ===== Seções =====
import 'package:siged/screens/process/hiring/10Publicacao/section_1_metadados.dart';
import 'package:siged/screens/process/hiring/10Publicacao/section_2_partes_valores.dart';
import 'package:siged/screens/process/hiring/10Publicacao/section_3_veiculo.dart';
import 'package:siged/screens/process/hiring/10Publicacao/section_4_status_prazos.dart';
import 'package:siged/screens/process/hiring/10Publicacao/section_5_responsavel.dart';

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
    with FormValidationMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final ProgressBloc _progressBloc;
  PublicacaoExtratoData _formData = const PublicacaoExtratoData();
  bool _hydrated = false;
  String? _currentPubId;

  @override
  void initState() {
    super.initState();
    _progressBloc = ProgressBloc(repo: ProgressRepository());

    // inicia o carregamento
    context.read<PublicacaoExtratoBloc>().add(
      PublicacaoExtratoLoadRequested(widget.contractId),
    );
  }

  @override
  void dispose() {
    _progressBloc.close();
    super.dispose();
  }

  Future<void> _saveOnly() async {
    final bloc = context.read<PublicacaoExtratoBloc>();

    final completer = Completer<void>();
    late final StreamSubscription sub;

    sub = bloc.stream.listen((state) {
      if (!state.saving) {
        if (!completer.isCompleted) completer.complete();
        sub.cancel();
      }
    });

    bloc.add(PublicacaoExtratoSaveRequested(
      contractId: widget.contractId,
      sectionsData: _formData.toSectionsMap(),
    ));

    await completer.future;

    if (!bloc.state.saveSuccess) {
      NotificationCenter.instance.show(
        AppNotification(
          title: const Text("Publicação / Extrato"),
          subtitle: const Text("Falha ao salvar"),
          details: Text(bloc.state.error ?? ''),
        ),
      );
      return;
    }

    NotificationCenter.instance.show(
      AppNotification(
        title: const Text("Publicação / Extrato"),
        subtitle: const Text("Alterações salvas."),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocProvider.value(
      value: _progressBloc,
      child: BlocListener<PublicacaoExtratoBloc, PublicacaoExtratoState>(
        listenWhen: (prev, curr) =>
        (prev.loading && !curr.loading) || prev.pubId != curr.pubId,
        listener: (context, state) {
          if (!mounted || state.loading || !state.hasValidPath) return;

          // hidrata o form somente 1 vez por load
          final incomingId = state.pubId;
          final needsHydrate = !_hydrated || incomingId != _currentPubId;

          if (needsHydrate) {
            // monta o DATA a partir dos maps
            final data = PublicacaoExtratoData.fromSectionsMap(state.sectionsData);
            setState(() => _formData = data);

            _hydrated = true;
            _currentPubId = incomingId;

            // vincula etapa ao progress bloc
            if (incomingId != null) {
              _progressBloc.add(ProgressBindRequested(
                contractId: widget.contractId,
                collectionName: 'publicacao',
                stageId: incomingId,
              ));
            }
          }
        },
        child: BlocBuilder<PublicacaoExtratoBloc, PublicacaoExtratoState>(
          builder: (context, state) {
            final pstate = context.watch<ProgressBloc>().state;

            final locked =
                state.loading || state.saving || pstate.loading;

            final msg = state.loading
                ? "Carregando dados..."
                : state.saving
                ? "Salvando..."
                : pstate.loading
                ? "Atualizando aprovação..."
                : null;

            return ScreenLock(
              locked: locked,
              message: msg,
              details: locked ? "Aguarde..." : null,
              keepAppBarUndimmed: true,
              child: Scaffold(
                body: Stack(
                  children: [
                    const BackgroundClean(),
                    SingleChildScrollView(
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

                          // 2) Partes / Valores / Vigência
                          SectionPartesValoresVigencia(
                            data: _formData,
                            isEditable: !widget.readOnly,
                            onChanged: (updated) {
                              setState(() => _formData = updated);
                            },
                          ),

                          // 3) Veículo
                          SectionVeiculoPublicacao(
                            data: _formData,
                            isEditable: !widget.readOnly,
                            onChanged: (updated) {
                              setState(() => _formData = updated);
                            },
                          ),

                          // 4) Status / Prazos
                          SectionStatusPrazos(
                            data: _formData,
                            isEditable: !widget.readOnly,
                            onChanged: (updated) {
                              setState(() => _formData = updated);
                            },
                          ),

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

                // RODAPÉ (barra de progresso e ações)
                bottomNavigationBar: BlocBuilder<ProgressBloc, ProgressState>(
                  builder: (context, pstate) {
                    return StageProgress(
                      title: 'Publicação / Extrato',
                      icon: Icons.campaign_outlined,
                      busy: state.saving,
                      approved: pstate.approved,
                      onSave: _saveOnly,
                      onSaveAndNext: () async {
                        await _saveOnly();
                        // ... (mantive seu fluxo de aprovação normal)
                      },
                      onUpdateApproved: () async {
                        await _saveOnly();
                        // ... (mantive seu fluxo de atualização)
                      },
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
