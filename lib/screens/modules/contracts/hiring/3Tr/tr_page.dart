// lib/screens/modules/contracts/hiring/3Tr/termo_referencia_page.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';
import 'package:sipged/screens/modules/contracts/hiring/0Progress/progress_stage.dart';

import 'package:sipged/_widgets/overlays/screen_lock.dart';
import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/_widgets/menu/tab/stage_progress.dart';

import 'package:sipged/_blocs/system/notification/notification_delivery.dart';
import 'package:sipged/_blocs/system/notification/notification_type.dart';
import 'package:sipged/_blocs/system/notification/helpers/notification_hiring.dart';

import 'package:sipged/_blocs/system/permission/permission_cubit.dart';
import 'package:sipged/_blocs/system/permission/permission_state.dart';
import 'package:sipged/_blocs/system/user/user_cubit.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/0Progress/progress_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Progress/progress_repository.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Progress/progress_state.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Progress/progress_data.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_data.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_repository.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/3Tr/tr_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/3Tr/tr_state.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/3Tr/tr_data.dart';

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
  const TermoReferenciaPage({
    super.key,
    required this.contractId,
    this.readOnly = false,
  });

  final String contractId;
  final bool readOnly;

  @override
  State<TermoReferenciaPage> createState() => _TermoReferenciaPageState();
}

class _TermoReferenciaPageState extends State<TermoReferenciaPage>
    with SipGedValidation, AutomaticKeepAliveClientMixin {
  static const String _notificationSource = 'contracts_hiring_tr';
  static const String _route = 'contracts_hiring_tr';

  late final String _tenantId;
  late final DfdRepository _dfdRepository;
  late final ProgressCubit _progressBloc;

  ProgressCubit? _pipelineProgressCubit;

  TrData _formData = const TrData.empty();
  ContractData _contract = ContractData.empty();
  DfdData? _dfdData;

  bool _hydrated = false;
  bool _loadingContract = false;

  String? _currentTrId;

  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  bool get _isEditable => !widget.readOnly;

  String get _contractId => widget.contractId.trim();

  ContractData get _effectiveContract {
    if ((_contract.id ?? '').trim().isNotEmpty) return _contract;

    if (_contractId.isNotEmpty) {
      return _contract.copyWith(id: _contractId);
    }

    return _contract;
  }

  String get _notificationDemandName {
    final descricaoObjeto = _dfdData?.descricaoObjeto?.trim();

    if (descricaoObjeto != null && descricaoObjeto.isNotEmpty) {
      return descricaoObjeto;
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

    return _contractId;
  }

  @override
  void initState() {
    super.initState();

    final permissionState = context.read<PermissionCubit>().state;
    _tenantId = _resolveRequiredTenantId(permissionState);

    _dfdRepository = DfdRepository(
      tenantId: _tenantId,
    );

    _progressBloc = ProgressCubit(
      repo: ProgressRepository(
        //tenantId: _tenantId,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (_contractId.isNotEmpty) {
        context.read<TrCubit>().load(_contractId);

        unawaited(_loadContract(_contractId));
        unawaited(_loadDfdData(_contractId));

        unawaited(
          _progressBloc.bindToStage(
            contractId: _contractId,
            collectionName: ProgressData.tr,
          ),
        );
      }
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

  String _resolveRequiredTenantId(PermissionState permissionState) {
    final tenantId = permissionState.activeTenantId?.trim();

    if (tenantId == null || tenantId.isEmpty) {
      throw StateError(
        'Tenant ativo não encontrado para carregar o Termo de Referência.',
      );
    }

    return tenantId;
  }

  DocumentReference<Map<String, dynamic>> _contractDocRef(String contractId) {
    final cid = contractId.trim();

    if (cid.isEmpty) {
      throw ArgumentError('contractId obrigatório para carregar contrato.');
    }

    return FirebaseFirestore.instance
        .collection('tenants')
        .doc(_tenantId)
        .collection('contracts')
        .doc(cid);
  }

  Future<void> _loadContract(String contractId) async {
    final cid = contractId.trim();
    if (cid.isEmpty) return;

    if (mounted) {
      setState(() => _loadingContract = true);
    }

    try {
      final snapshot = await _contractDocRef(cid).get();

      if (!mounted) return;

      if (!snapshot.exists) {
        setState(() {
          _contract = ContractData.empty().copyWith(id: cid);
          _loadingContract = false;
        });
        return;
      }

      setState(() {
        _contract = ContractData.fromDocument(snapshot: snapshot);
        _loadingContract = false;
      });
    } catch (e, stack) {
      debugPrint('[TermoReferenciaPage] Erro ao carregar contrato $cid: $e');
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
      debugPrint('[TermoReferenciaPage] Falha ao carregar DFD do contrato: $e');
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
      source: 'tr_notification',
      status: type ?? status,
      duration: duration,
      saveInBell: saveInBell,
      sendPush: sendPush,
      delivery: saveInBell || sendPush
          ? NotificationDelivery.localBellAndPush
          : NotificationDelivery.localOnly,
      targetUserIds: targetUserIds,
      actorId: actorId,
      actorName: actorName,
      extra: <String, dynamic>{
        ...extra,
        'tenantId': _tenantId,
        'companyId': _tenantId,
        'route': extra['route'] ?? _route,
        'module': _route,
        'source': 'tr_notification',
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
        if (_processNumber.trim().isNotEmpty) 'contractNumber': _processNumber,
        if (_processNumber.trim().isNotEmpty) 'processNumber': _processNumber,
        if (_dfdData?.processoAdministrativo?.trim().isNotEmpty == true)
          'processoAdministrativo': _dfdData?.processoAdministrativo,
      },
    );
  }

  Future<bool> _saveOnly({
    bool notifySuccess = true,
  }) async {
    if (widget.readOnly) {
      await _notify(
        title: 'TR',
        subtitle: 'Esta etapa está em modo somente leitura.',
        status: NotificationStatus.info,
      );
      return false;
    }

    final cubit = context.read<TrCubit>();

    try {
      await cubit.saveAll(
        contractId: _contractId,
        sectionsData: _formData.toSectionsMap(),
      );

      if (!mounted) return false;

      if (!cubit.state.saveSuccess) {
        final err = cubit.state.error ?? 'Falha ao salvar';

        await _notify(
          title: 'TR',
          subtitle: 'Erro ao salvar.',
          details: err,
          status: NotificationStatus.error,
          duration: const Duration(seconds: 6),
        );

        return false;
      }

      await _loadContract(_contractId);
      await _loadDfdData(_contractId);

      if (!mounted) return false;

      unawaited(
        _progressBloc.bindToStage(
          contractId: _contractId,
          collectionName: ProgressData.tr,
        ),
      );

      if (notifySuccess) {
        await _notify(
          title: 'TR atualizado',
          subtitle: _notificationDemandName,
          details: 'Alterado por ${_currentActorName()}.',
          status: NotificationStatus.success,
          saveInBell: true,
          sendPush: true,
          targetUserIds: const <String>[],
          extra: <String, dynamic>{
            'action': 'tr_saved',
            'trId': cubit.state.trId,
            'contractId': _contractId,
            'route': _route,
            'notificationSource': _notificationSource,
          },
        );
      }

      return true;
    } catch (e) {
      if (!mounted) return false;

      await _notify(
        title: 'TR',
        subtitle: 'Erro ao salvar.',
        details: '$e',
        status: NotificationStatus.error,
        duration: const Duration(seconds: 6),
      );

      return false;
    }
  }

  Future<void> _saveApproveAndNext() async {
    final trCubit = context.read<TrCubit>();
    final tab = DefaultTabController.of(context);
    final repo = _progressBloc.repo;

    final saved = await _saveOnly(
      notifySuccess: false,
    );

    if (!mounted || !saved) return;

    final trId = trCubit.state.trId;

    if (trId == null || trId.isEmpty) {
      await _notify(
        title: 'TR',
        subtitle: 'Documento não encontrado para aprovar.',
        status: NotificationStatus.error,
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? '';
    final actorName = _currentActorName();

    try {
      await repo.approveStage(
        contractId: _contractId,
        collectionName: ProgressData.tr,
        approverUid: uid,
        approverName: actorName,
      );

      await repo.setCompleted(
        contractId: _contractId,
        collectionName: ProgressData.tr,
        completed: true,
      );

      if (!mounted) return;

      unawaited(
        _progressBloc.bindToStage(
          contractId: _contractId,
          collectionName: ProgressData.tr,
        ),
      );

      _pipelineProgressCubit?.setStageEnabled(ProgressData.cotacao, true);
      unawaited(_pipelineProgressCubit?.refreshPipeline());

      tab.animateTo(
        (tab.index + 1).clamp(0, tab.length - 1),
      );

      await _notify(
        title: 'TR aprovado',
        subtitle: _notificationDemandName,
        details: 'Aprovado por $actorName.',
        status: NotificationStatus.success,
        saveInBell: true,
        sendPush: true,
        targetUserIds: const <String>[],
        extra: <String, dynamic>{
          'action': 'tr_approved',
          'trId': trId,
          'contractId': _contractId,
          'route': _route,
          'notificationSource': _notificationSource,
          'nextStage': ProgressData.cotacao,
        },
      );
    } catch (e) {
      if (!mounted) return;

      await _notify(
        title: 'TR',
        subtitle: 'Erro ao aprovar.',
        details: '$e',
        status: NotificationStatus.error,
        duration: const Duration(seconds: 6),
      );
    }
  }

  Future<void> _updateApproved() async {
    final trCubit = context.read<TrCubit>();
    final repo = _progressBloc.repo;

    final saved = await _saveOnly(
      notifySuccess: false,
    );

    if (!mounted || !saved) return;

    final trId = trCubit.state.trId;

    if (trId == null || trId.isEmpty) {
      await _notify(
        title: 'TR',
        subtitle: 'Documento não encontrado para atualizar.',
        status: NotificationStatus.error,
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? '';
    final actorName = _currentActorName();

    try {
      await repo.touchApproval(
        contractId: _contractId,
        collectionName: ProgressData.tr,
        updatedByUid: uid,
        updatedByName: actorName,
      );

      if (!mounted) return;

      unawaited(
        _progressBloc.bindToStage(
          contractId: _contractId,
          collectionName: ProgressData.tr,
        ),
      );

      unawaited(_pipelineProgressCubit?.refreshPipeline());

      await _notify(
        title: 'Aprovação do TR atualizada',
        subtitle: _notificationDemandName,
        details: 'Atualizado por $actorName.',
        status: NotificationStatus.success,
        saveInBell: true,
        sendPush: true,
        targetUserIds: const <String>[],
        extra: <String, dynamic>{
          'action': 'tr_approval_updated',
          'trId': trId,
          'contractId': _contractId,
          'route': _route,
          'notificationSource': _notificationSource,
        },
      );
    } catch (e) {
      if (!mounted) return;

      await _notify(
        title: 'TR',
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
      child: BlocListener<TrCubit, TrState>(
        listenWhen: (prev, curr) {
          return (prev.loading && !curr.loading) || prev.trId != curr.trId;
        },
        listener: (context, state) {
          if (!mounted || state.loading || !state.hasValidPath) return;

          final incomingId = state.trId;
          final needsHydrate = !_hydrated || _currentTrId != incomingId;

          if (needsHydrate) {
            final data = TrData.fromSectionsMap(state.sectionsData);

            setState(() {
              _formData = data;
              _hydrated = true;
              _currentTrId = incomingId;
            });
          }

          if ((incomingId ?? '').isNotEmpty) {
            unawaited(
              _progressBloc.bindToStage(
                contractId: _contractId,
                collectionName: ProgressData.tr,
              ),
            );

            if ((_contract.id ?? '') != _contractId) {
              unawaited(_loadContract(_contractId));
              unawaited(_loadDfdData(_contractId));
            }
          }
        },
        child: BlocBuilder<TrCubit, TrState>(
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
                      key: const PageStorageKey<String>('tr-scroll'),
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          SectionObjetoFundamentacao(
                            data: _formData,
                            isEditable: _isEditable,
                            onChanged: (updated) {
                              setState(() => _formData = updated);
                            },
                          ),
                          const SizedBox(height: 12),
                          SectionEscopoRequisitos(
                            data: _formData,
                            isEditable: _isEditable,
                            onChanged: (updated) {
                              setState(() => _formData = updated);
                            },
                          ),
                          const SizedBox(height: 12),
                          SectionLocalPrazosCronograma(
                            data: _formData,
                            isEditable: _isEditable,
                            onChanged: (updated) {
                              setState(() => _formData = updated);
                            },
                          ),
                          const SizedBox(height: 12),
                          SectionMedicaoAceiteIndicadores(
                            data: _formData,
                            isEditable: _isEditable,
                            onChanged: (updated) {
                              setState(() => _formData = updated);
                            },
                          ),
                          const SizedBox(height: 12),
                          SectionObrigacoesEquipeGestao(
                            data: _formData,
                            isEditable: _isEditable,
                            onChanged: (updated) {
                              setState(() => _formData = updated);
                            },
                          ),
                          const SizedBox(height: 12),
                          SectionLicenciamentoSegurancaSustentabilidade(
                            data: _formData,
                            isEditable: _isEditable,
                            onChanged: (updated) {
                              setState(() => _formData = updated);
                            },
                          ),
                          const SizedBox(height: 12),
                          SectionPrecosPagamentoReajuste(
                            data: _formData,
                            isEditable: _isEditable,
                            onChanged: (updated) {
                              setState(() => _formData = updated);
                            },
                          ),
                          const SizedBox(height: 12),
                          SectionRiscosPenalidadesCondicoes(
                            data: _formData,
                            isEditable: _isEditable,
                            onChanged: (updated) {
                              setState(() => _formData = updated);
                            },
                          ),
                          const SizedBox(height: 12),
                          SectionDocumentosReferencias(
                            data: _formData,
                            isEditable: _isEditable,
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
                bottomNavigationBar: BlocBuilder<ProgressCubit, ProgressState>(
                  builder: (context, pstate) {
                    return StageProgress(
                      title: 'Termo de Referência',
                      icon: Icons.rule_folder_outlined,
                      busy: state.saving || pstate.loading,
                      approved: pstate.approved,
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
        stageKey: ProgressData.tr,
        child: content,
      ),
    );
  }
}