import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/progress_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/progress_data.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/progress_repository.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/progress_state.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_data.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_repository.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/10Publicacao/publicacao_extrato_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/10Publicacao/publicacao_extrato_data.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/10Publicacao/publicacao_extrato_state.dart';
import 'package:sipged/_blocs/system/notification/helpers/notification_hiring.dart';
import 'package:sipged/_blocs/system/notification/notification_delivery.dart';
import 'package:sipged/_blocs/system/notification/notification_type.dart';
import 'package:sipged/_blocs/system/user/user_cubit.dart';

import 'package:sipged/_utils/validates/sipged_validation.dart';

import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/screens/modules/contracts/hiring/progress_stage.dart';
import 'package:sipged/_widgets/menu/tab/stage_progress.dart';
import 'package:sipged/_widgets/overlays/screen_lock.dart';

import 'package:sipged/screens/modules/contracts/hiring/10Publicacao/section_1_metadados.dart';
import 'package:sipged/screens/modules/contracts/hiring/10Publicacao/section_2_partes_valores.dart';
import 'package:sipged/screens/modules/contracts/hiring/10Publicacao/section_3_veiculo.dart';
import 'package:sipged/screens/modules/contracts/hiring/10Publicacao/section_4_status_prazos.dart';
import 'package:sipged/screens/modules/contracts/hiring/10Publicacao/section_5_responsavel.dart';

class PublicacaoExtratoPage extends StatefulWidget {
  const PublicacaoExtratoPage({
    super.key,
    required this.contractId,
    this.readOnly = false,
  });

  final String contractId;
  final bool readOnly;

  @override
  State<PublicacaoExtratoPage> createState() => _PublicacaoExtratoPageState();
}

class _PublicacaoExtratoPageState extends State<PublicacaoExtratoPage>
    with SipGedValidation, AutomaticKeepAliveClientMixin {
  static const String _route = 'contracts_hiring_publicacao';
  static const String _notificationSource = 'contracts_hiring_publicacao';

  final DfdRepository _dfdRepository = DfdRepository();

  late final ProgressCubit _progressBloc;

  ProgressCubit? _pipelineProgressCubit;

  PublicacaoExtratoData _formData = const PublicacaoExtratoData.empty();
  ContractData _contract = ContractData.empty();
  DfdData? _dfdData;

  bool _hydrated = false;
  bool _loadingContract = false;

  String? _currentPubId;

  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  bool get _isEditable => !widget.readOnly;

  String get _contractId => widget.contractId.trim();

  ContractData get _effectiveContract {
    final currentId = (_contract.id ?? '').trim();

    if (currentId.isNotEmpty) return _contract;
    if (_contractId.isNotEmpty) return _contract.copyWith(id: _contractId);

    return _contract;
  }

  String get _notificationDemandName {
    final descricaoObjeto = _dfdData?.descricaoObjeto?.trim();

    if (descricaoObjeto != null && descricaoObjeto.isNotEmpty) {
      return descricaoObjeto;
    }

    final objetoResumo = _formData.objetoResumo?.trim();

    if (objetoResumo != null && objetoResumo.isNotEmpty) {
      return objetoResumo;
    }

    final displaySummary = _contract.displaySummary.trim();

    if (displaySummary.isNotEmpty &&
        displaySummary != 'Contrato $_contractId' &&
        !displaySummary.startsWith('Contrato ')) {
      return displaySummary;
    }

    return 'Demanda sem identificação';
  }

  String get _processNumber {
    final processoAdministrativo = _dfdData?.processoAdministrativo?.trim();

    if (processoAdministrativo != null && processoAdministrativo.isNotEmpty) {
      return processoAdministrativo;
    }

    final processo = _formData.processo?.trim();

    if (processo != null && processo.isNotEmpty) {
      return processo;
    }

    return _contractId;
  }

  String get _contractNumber {
    final numeroContrato = _formData.numeroContrato?.trim();

    if (numeroContrato != null && numeroContrato.isNotEmpty) {
      return numeroContrato;
    }

    return _processNumber;
  }

  @override
  void initState() {
    super.initState();

    _progressBloc = ProgressCubit(repo: ProgressRepository());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final contractId = _contractId;
      if (contractId.isEmpty) return;

      context.read<PublicacaoExtratoCubit>().load(contractId);
      unawaited(_loadContract(contractId));
      unawaited(_loadDfdData(contractId));
      unawaited(
        _progressBloc.bindToStage(
          contractId: contractId,
          collectionName: ProgressData.publicacao,
        ),
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_pipelineProgressCubit != null) return;

    try {
      _pipelineProgressCubit = context.read<ProgressCubit>();
    } catch (_) {
      _pipelineProgressCubit = null;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _progressBloc.close();
    super.dispose();
  }

  Future<void> _loadContract(String contractId) async {
    final cid = contractId.trim();
    if (cid.isEmpty) return;

    if (mounted) {
      setState(() => _loadingContract = true);
    }

    try {
      final snapshot =
      await FirebaseFirestore.instance.collection('contracts').doc(cid).get();

      if (!mounted) return;

      setState(() {
        _contract = snapshot.exists
            ? ContractData.fromDocument(snapshot: snapshot)
            : ContractData.empty().copyWith(id: cid);

        _loadingContract = false;
      });
    } catch (e, stack) {
      debugPrint('[PublicacaoExtratoPage] Erro ao carregar contrato $cid: $e');
      debugPrintStack(stackTrace: stack);

      if (!mounted) return;

      setState(() {
        _contract = ContractData.empty().copyWith(id: cid);
        _loadingContract = false;
      });
    }
  }

  Future<void> _loadDfdData(String contractId) async {
    final cid = contractId.trim();
    if (cid.isEmpty) return;

    try {
      final data = await _dfdRepository.readDataForContract(cid);

      if (!mounted) return;

      setState(() {
        _dfdData = data;
      });
    } catch (e, stack) {
      debugPrint('[PublicacaoExtratoPage] Falha ao carregar DFD: $e');
      debugPrintStack(stackTrace: stack);
    }
  }

  String _currentActorName() {
    final user = FirebaseAuth.instance.currentUser;

    final displayName = user?.displayName?.trim() ?? '';
    if (displayName.isNotEmpty) return displayName;

    final email = user?.email?.trim() ?? '';
    if (email.isNotEmpty) return email;

    return 'Usuário';
  }

  String _currentActorPhotoUrl() {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid.trim() ?? '';

    if (uid.isNotEmpty) {
      final users = context.read<UserCubit>().state.all;

      for (final item in users) {
        if ((item.uid ?? '').trim() == uid) {
          final photo = item.urlPhoto?.trim() ?? '';
          if (photo.isNotEmpty) return photo;
        }
      }
    }

    final firebasePhoto = user?.photoURL?.trim() ?? '';
    if (firebasePhoto.isNotEmpty) return firebasePhoto;

    return '';
  }

  Future<void> _notify({
    required String title,
    String? subtitle,
    String? details,
    NotificationStatus status = NotificationStatus.info,
    NotificationStatus? type,
    Duration duration = const Duration(seconds: 4),
    bool saveInBell = false,
    bool sendPush = false,
    Iterable<String> targetUserIds = const <String>[],
    Map<String, dynamic> extra = const <String, dynamic>{},
  }) async {
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    final actorId = user?.uid.trim();
    final actorName = _currentActorName();
    final actorPhotoUrl = _currentActorPhotoUrl();

    final effectiveContract = _effectiveContract;
    final effectiveContractId = (effectiveContract.id ?? _contractId).trim();
    final demandName = _notificationDemandName;

    await NotificationHiring.show(
      context: context,
      contract: effectiveContract,
      title: title,
      subtitle: subtitle,
      details: details,
      module: _route,
      notificationSource: _notificationSource,
      source: 'publicacao_notification',
      status: type ?? status,
      duration: duration,
      saveInBell: saveInBell,
      sendPush: sendPush,
      delivery: NotificationDelivery.localBellAndPush,
      targetUserIds: targetUserIds,
      actorId: actorId,
      actorName: actorName,
      extra: <String, dynamic>{
        ...extra,
        'route': extra['route'] ?? _route,
        'module': _route,
        'source': 'publicacao_notification',
        'sourceKey': _notificationSource,
        'subSource': _notificationSource,
        'notificationSource': _notificationSource,
        'actorId': actorId,
        'actorName': actorName,
        if (actorPhotoUrl.isNotEmpty) 'actorPhotoUrl': actorPhotoUrl,
        if (actorPhotoUrl.isNotEmpty) 'photoUrl': actorPhotoUrl,
        if (actorPhotoUrl.isNotEmpty) 'photoURL': actorPhotoUrl,
        if (actorPhotoUrl.isNotEmpty) 'profilePhotoUrl': actorPhotoUrl,
        if (effectiveContractId.isNotEmpty) 'contractId': effectiveContractId,
        'contractTitle': demandName,
        'contractSummary': demandName,
        'descricaoObjeto': demandName,
        'nomeDemanda': demandName,
        if (_contractNumber.trim().isNotEmpty) 'contractNumber': _contractNumber,
        if (_processNumber.trim().isNotEmpty) 'processNumber': _processNumber,
        if (_processNumber.trim().isNotEmpty)
          'processoAdministrativo': _processNumber,
        if (_formData.numeroContrato?.trim().isNotEmpty == true)
          'numeroContrato': _formData.numeroContrato,
      },
    );
  }

  Future<bool> _saveOnly({
    bool notifySuccess = true,
  }) async {
    if (widget.readOnly) {
      await _notify(
        title: 'Publicação / Extrato',
        subtitle: 'Esta etapa está em modo somente leitura.',
        status: NotificationStatus.info,
      );
      return false;
    }

    final contractId = _contractId;

    if (contractId.isEmpty) {
      await _notify(
        title: 'Publicação / Extrato',
        subtitle: 'Contrato não identificado para salvar.',
        status: NotificationStatus.error,
      );
      return false;
    }

    final cubit = context.read<PublicacaoExtratoCubit>();

    try {
      await cubit.saveAll(
        contractId: contractId,
        sectionsData: _formData.toSectionsMap(),
      );

      if (!mounted) return false;

      if (!cubit.state.saveSuccess) {
        await _notify(
          title: 'Publicação / Extrato',
          subtitle: 'Erro ao salvar.',
          details: cubit.state.error ?? 'Falha ao salvar',
          status: NotificationStatus.error,
          duration: const Duration(seconds: 6),
        );

        return false;
      }

      await _loadContract(contractId);
      await _loadDfdData(contractId);

      if (!mounted) return false;

      unawaited(
        _progressBloc.bindToStage(
          contractId: contractId,
          collectionName: ProgressData.publicacao,
        ),
      );

      if (notifySuccess) {
        final actorName = _currentActorName();

        await _notify(
          title: 'Publicação / Extrato atualizada',
          subtitle: _notificationDemandName,
          details: 'Alterado por $actorName.',
          status: NotificationStatus.success,
          saveInBell: true,
          sendPush: true,
          targetUserIds: const <String>[],
          extra: <String, dynamic>{
            'action': 'publicacao_saved',
            'pubId': cubit.state.pubId,
            'contractId': contractId,
            'route': _route,
            'notificationSource': _notificationSource,
          },
        );
      }

      return true;
    } catch (e) {
      if (!mounted) return false;

      await _notify(
        title: 'Publicação / Extrato',
        subtitle: 'Erro ao salvar.',
        details: '$e',
        status: NotificationStatus.error,
        duration: const Duration(seconds: 6),
      );

      return false;
    }
  }

  Future<void> _saveApproveAndNext() async {
    final pubCubit = context.read<PublicacaoExtratoCubit>();
    final tabController = DefaultTabController.of(context);
    final repo = _progressBloc.repo;

    final saved = await _saveOnly(notifySuccess: false);

    if (!mounted || !saved) return;

    final contractId = _contractId;
    final pubId = pubCubit.state.pubId;

    if (contractId.isEmpty) {
      await _notify(
        title: 'Publicação / Extrato',
        subtitle: 'Contrato não identificado para aprovar.',
        status: NotificationStatus.error,
      );
      return;
    }

    if (pubId == null || pubId.isEmpty) {
      await _notify(
        title: 'Publicação / Extrato',
        subtitle: 'Documento não encontrado para aprovar.',
        status: NotificationStatus.error,
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    final actorName = _currentActorName();

    try {
      await repo.approveStage(
        contractId: contractId,
        collectionName: ProgressData.publicacao,
        approverUid: user?.uid ?? '',
        approverName: actorName,
      );

      await repo.setCompleted(
        contractId: contractId,
        collectionName: ProgressData.publicacao,
        completed: true,
      );

      if (!mounted) return;

      unawaited(
        _progressBloc.bindToStage(
          contractId: contractId,
          collectionName: ProgressData.publicacao,
        ),
      );

      _pipelineProgressCubit?.setStageEnabled(ProgressData.arquivamento, true);
      unawaited(_pipelineProgressCubit?.refreshPipeline());

      tabController.animateTo(
        (tabController.index + 1).clamp(0, tabController.length - 1),
      );

      await _notify(
        title: 'Publicação / Extrato aprovada',
        subtitle: _notificationDemandName,
        details: 'Aprovado por $actorName.',
        status: NotificationStatus.success,
        saveInBell: true,
        sendPush: true,
        targetUserIds: const <String>[],
        extra: <String, dynamic>{
          'action': 'publicacao_approved',
          'pubId': pubId,
          'contractId': contractId,
          'route': _route,
          'notificationSource': _notificationSource,
          'nextStage': ProgressData.arquivamento,
        },
      );
    } catch (e) {
      if (!mounted) return;

      await _notify(
        title: 'Publicação / Extrato',
        subtitle: 'Erro ao aprovar a etapa.',
        details: '$e',
        status: NotificationStatus.error,
        duration: const Duration(seconds: 6),
      );
    }
  }

  Future<void> _updateApproved() async {
    final pubCubit = context.read<PublicacaoExtratoCubit>();
    final repo = _progressBloc.repo;

    final saved = await _saveOnly(notifySuccess: false);

    if (!mounted || !saved) return;

    final contractId = _contractId;
    final pubId = pubCubit.state.pubId;

    if (contractId.isEmpty) {
      await _notify(
        title: 'Publicação / Extrato',
        subtitle: 'Contrato não identificado para atualizar.',
        status: NotificationStatus.error,
      );
      return;
    }

    if (pubId == null || pubId.isEmpty) {
      await _notify(
        title: 'Publicação / Extrato',
        subtitle: 'Documento não encontrado para atualizar aprovação.',
        status: NotificationStatus.error,
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    final actorName = _currentActorName();

    try {
      await repo.touchApproval(
        contractId: contractId,
        collectionName: ProgressData.publicacao,
        updatedByUid: user?.uid ?? '',
        updatedByName: actorName,
      );

      if (!mounted) return;

      unawaited(
        _progressBloc.bindToStage(
          contractId: contractId,
          collectionName: ProgressData.publicacao,
        ),
      );

      unawaited(_pipelineProgressCubit?.refreshPipeline());

      await _notify(
        title: 'Aprovação da Publicação / Extrato atualizada',
        subtitle: _notificationDemandName,
        details: 'Atualizado por $actorName.',
        status: NotificationStatus.success,
        saveInBell: true,
        sendPush: true,
        targetUserIds: const <String>[],
        extra: <String, dynamic>{
          'action': 'publicacao_approval_updated',
          'pubId': pubId,
          'contractId': contractId,
          'route': _route,
          'notificationSource': _notificationSource,
        },
      );
    } catch (e) {
      if (!mounted) return;

      await _notify(
        title: 'Publicação / Extrato',
        subtitle: 'Erro ao atualizar aprovação.',
        details: '$e',
        status: NotificationStatus.error,
        duration: const Duration(seconds: 6),
      );
    }
  }

  Widget _buildContent() {
    return BlocProvider<ProgressCubit>.value(
      value: _progressBloc,
      child: BlocListener<PublicacaoExtratoCubit, PublicacaoExtratoState>(
        listenWhen: (prev, curr) {
          return (prev.loading && !curr.loading) || prev.pubId != curr.pubId;
        },
        listener: (context, state) {
          if (!mounted || state.loading || !state.hasValidPath) return;

          final incomingId = state.pubId;
          final needsHydrate = !_hydrated || _currentPubId != incomingId;

          if (needsHydrate) {
            final data = PublicacaoExtratoData.fromSectionsMap(
              state.sectionsData,
            );

            setState(() {
              _formData = data;
              _hydrated = true;
              _currentPubId = incomingId;
            });
          }

          final contractId = _contractId;

          if ((incomingId ?? '').isNotEmpty && contractId.isNotEmpty) {
            unawaited(
              _progressBloc.bindToStage(
                contractId: contractId,
                collectionName: ProgressData.publicacao,
              ),
            );

            if ((_contract.id ?? '') != contractId) {
              unawaited(_loadContract(contractId));
              unawaited(_loadDfdData(contractId));
            }
          }
        },
        child: BlocBuilder<PublicacaoExtratoCubit, PublicacaoExtratoState>(
          builder: (context, state) {
            final pstate = context.watch<ProgressCubit>().state;

            final locked = state.loading ||
                state.saving ||
                pstate.loading ||
                _loadingContract;

            final msg = state.loading
                ? 'Sincronizando os dados...'
                : state.saving
                ? 'Salvando os dados...'
                : pstate.loading
                ? 'Atualizando aprovação...'
                : _loadingContract
                ? 'Carregando dados do contrato...'
                : null;

            return ScreenLock(
              locked: locked,
              message: msg,
              details: locked ? 'Por favor, aguarde.' : null,
              keepAppBarUndimmed: true,
              child: Scaffold(
                body: Stack(
                  children: <Widget>[
                    const BackgroundChange(),
                    SingleChildScrollView(
                      key: const PageStorageKey<String>(
                        'publicacao-extrato-scroll',
                      ),
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          SectionMetadadosExtrato(
                            data: _formData,
                            isEditable: _isEditable,
                            onChanged: (updated) {
                              setState(() => _formData = updated);
                            },
                          ),
                          const SizedBox(height: 12),
                          SectionPartesValoresVigencia(
                            data: _formData,
                            isEditable: _isEditable,
                            onChanged: (updated) {
                              setState(() => _formData = updated);
                            },
                          ),
                          const SizedBox(height: 12),
                          SectionVeiculoPublicacao(
                            data: _formData,
                            isEditable: _isEditable,
                            onChanged: (updated) {
                              setState(() => _formData = updated);
                            },
                          ),
                          const SizedBox(height: 12),
                          SectionStatusPrazos(
                            data: _formData,
                            isEditable: _isEditable,
                            onChanged: (updated) {
                              setState(() => _formData = updated);
                            },
                          ),
                          const SizedBox(height: 12),
                          SectionResponsavel(
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
                bottomNavigationBar: BlocBuilder<ProgressCubit, ProgressState>(
                  builder: (context, progressState) {
                    return StageProgress(
                      title: 'Publicação / Extrato',
                      icon: Icons.campaign_outlined,
                      busy: state.saving || progressState.loading,
                      approved: progressState.approved,
                      onSave: _saveOnly,
                      onSaveAndNext: _saveApproveAndNext,
                      onUpdateApproved: _updateApproved,
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

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final content = _buildContent();
    final pipelineCubit = _pipelineProgressCubit;

    if (pipelineCubit == null) {
      return content;
    }

    return BlocProvider<ProgressCubit>.value(
      value: pipelineCubit,
      child: ProgressStage(
        stageKey: ProgressData.publicacao,
        child: content,
      ),
    );
  }
}