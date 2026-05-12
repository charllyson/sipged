// lib/screens/modules/contracts/hiring/4Cotacao/cotacao_page.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/0Progress/progress_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Progress/progress_repository.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Progress/progress_state.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Progress/progress_data.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_data.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_repository.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/4Cotacao/cotacao_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/4Cotacao/cotacao_data.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/4Cotacao/cotacao_state.dart';

import 'package:sipged/_blocs/system/notification/notification_delivery.dart';
import 'package:sipged/_blocs/system/notification/notification_type.dart';
import 'package:sipged/_blocs/system/notification/helpers/notification_hiring.dart';

import 'package:sipged/_blocs/system/permission/permission_cubit.dart';
import 'package:sipged/_blocs/system/permission/permission_state.dart';
import 'package:sipged/_blocs/system/user/user_cubit.dart';

import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/screens/modules/contracts/hiring/0Progress/progress_stage.dart';
import 'package:sipged/_widgets/menu/tab/stage_progress.dart';
import 'package:sipged/_widgets/overlays/screen_lock.dart';

import 'package:sipged/screens/modules/contracts/hiring/4Cotacao/section_1_metadados.dart';
import 'package:sipged/screens/modules/contracts/hiring/4Cotacao/section_2_objeto_itens.dart';
import 'package:sipged/screens/modules/contracts/hiring/4Cotacao/section_3_convite_divulgacao.dart';
import 'package:sipged/screens/modules/contracts/hiring/4Cotacao/section_4_respostas_fornecedores.dart';
import 'package:sipged/screens/modules/contracts/hiring/4Cotacao/section_5_vencedora.dart';
import 'package:sipged/screens/modules/contracts/hiring/4Cotacao/section_6_consolidacao_resultado.dart';
import 'package:sipged/screens/modules/contracts/hiring/4Cotacao/section_7_anexos.dart';

import 'package:sipged/_utils/validates/sipged_validation.dart';

class CotacaoPage extends StatefulWidget {
  const CotacaoPage({
    super.key,
    required this.contractId,
    this.readOnly = false,
  });

  final String contractId;
  final bool readOnly;

  @override
  State<CotacaoPage> createState() => _CotacaoPageState();
}

class _CotacaoPageState extends State<CotacaoPage>
    with SipGedValidation, AutomaticKeepAliveClientMixin {
  static const String _notificationSource = 'contracts_hiring_cotacao';
  static const String _route = 'contracts_hiring_cotacao';

  late final String _tenantId;
  late final DfdRepository _dfdRepository;
  late final ProgressCubit _progressBloc;

  ProgressCubit? _pipelineProgressCubit;

  CotacaoData _formData = const CotacaoData.empty();
  ContractData _contract = ContractData.empty();
  DfdData? _dfdData;

  bool _hydrated = false;
  bool _loadingContract = false;

  String? _currentCotacaoId;

  final ScrollController _scrollController = ScrollController();

  int _fornCount = 1;

  @override
  bool get wantKeepAlive => true;

  bool get _isEditable => !widget.readOnly;

  String get _contractId => widget.contractId.trim();

  ContractData get _effectiveContract {
    if ((_contract.id ?? '').trim().isNotEmpty) return _contract;
    if (_contractId.isNotEmpty) return _contract.copyWith(id: _contractId);
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
        context.read<CotacaoCubit>().load(_contractId);

        unawaited(_loadContract(_contractId));
        unawaited(_loadDfdData(_contractId));

        unawaited(
          _progressBloc.bindToStage(
            contractId: _contractId,
            collectionName: ProgressData.cotacao,
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
        'Tenant ativo não encontrado para carregar a Cotação.',
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

      setState(() {
        _contract = snapshot.exists
            ? ContractData.fromDocument(snapshot: snapshot)
            : ContractData.empty().copyWith(id: cid);

        _loadingContract = false;
      });
    } catch (e, stack) {
      debugPrint('[CotacaoPage] Erro ao carregar contrato $cid: $e');
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
      debugPrint('[CotacaoPage] Falha ao carregar DFD do contrato: $e');
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
      source: 'cotacao_notification',
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
        'source': 'cotacao_notification',
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

  void _inferFornCountFromData(CotacaoData data) {
    int count = 1;

    if ((data.f2Nome ?? '').trim().isNotEmpty ||
        (data.f2Valor ?? '').trim().isNotEmpty) {
      count = 2;
    }

    if ((data.f3Nome ?? '').trim().isNotEmpty ||
        (data.f3Valor ?? '').trim().isNotEmpty) {
      count = 3;
    }

    _fornCount = count.clamp(1, 3);
  }

  void _removeFornecedor() {
    if (_fornCount <= 1) return;

    setState(() {
      _fornCount = (_fornCount - 1).clamp(1, 3);
    });
  }

  void _addFornecedor() {
    setState(() {
      _fornCount = (_fornCount + 1).clamp(1, 3);
    });
  }

  Future<bool> _saveOnly({
    bool notifySuccess = true,
  }) async {
    if (widget.readOnly) {
      await _notify(
        title: 'Cotação',
        subtitle: 'Esta etapa está em modo somente leitura.',
        status: NotificationStatus.info,
      );
      return false;
    }

    final cubit = context.read<CotacaoCubit>();

    try {
      await cubit.saveAll(
        contractId: _contractId,
        sectionsData: _formData.toSectionsMap(),
      );

      if (!mounted) return false;

      if (!cubit.state.saveSuccess) {
        final err = cubit.state.error ?? 'Falha ao salvar';

        await _notify(
          title: 'Cotação',
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
          collectionName: ProgressData.cotacao,
        ),
      );

      if (notifySuccess) {
        await _notify(
          title: 'Cotação atualizada',
          subtitle: _notificationDemandName,
          details: 'Alterado por ${_currentActorName()}.',
          status: NotificationStatus.success,
          saveInBell: true,
          sendPush: true,
          targetUserIds: const <String>[],
          extra: <String, dynamic>{
            'action': 'cotacao_saved',
            'cotacaoId': cubit.state.cotacaoId,
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
        title: 'Cotação',
        subtitle: 'Erro ao salvar.',
        details: '$e',
        status: NotificationStatus.error,
        duration: const Duration(seconds: 6),
      );

      return false;
    }
  }

  Future<void> _saveApproveAndNext() async {
    final cotacaoCubit = context.read<CotacaoCubit>();
    final controller = DefaultTabController.of(context);
    final repo = _progressBloc.repo;

    final saved = await _saveOnly(
      notifySuccess: false,
    );

    if (!mounted || !saved) return;

    final cotacaoId = cotacaoCubit.state.cotacaoId;

    if (cotacaoId == null || cotacaoId.isEmpty) {
      await _notify(
        title: 'Cotação',
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
        collectionName: ProgressData.cotacao,
        approverUid: uid,
        approverName: actorName,
      );

      await repo.setCompleted(
        contractId: _contractId,
        collectionName: ProgressData.cotacao,
        completed: true,
      );

      if (!mounted) return;

      unawaited(
        _progressBloc.bindToStage(
          contractId: _contractId,
          collectionName: ProgressData.cotacao,
        ),
      );

      _pipelineProgressCubit?.setStageEnabled(ProgressData.edital, true);
      unawaited(_pipelineProgressCubit?.refreshPipeline());

      controller.animateTo(
        (controller.index + 1).clamp(0, controller.length - 1),
      );

      await _notify(
        title: 'Cotação aprovada',
        subtitle: _notificationDemandName,
        details: 'Aprovado por $actorName.',
        status: NotificationStatus.success,
        saveInBell: true,
        sendPush: true,
        targetUserIds: const <String>[],
        extra: <String, dynamic>{
          'action': 'cotacao_approved',
          'cotacaoId': cotacaoId,
          'contractId': _contractId,
          'route': _route,
          'notificationSource': _notificationSource,
          'nextStage': ProgressData.edital,
        },
      );
    } catch (e) {
      if (!mounted) return;

      await _notify(
        title: 'Cotação',
        subtitle: 'Erro ao aprovar.',
        details: '$e',
        status: NotificationStatus.error,
        duration: const Duration(seconds: 6),
      );
    }
  }

  Future<void> _updateApproved() async {
    final cotacaoCubit = context.read<CotacaoCubit>();
    final repo = _progressBloc.repo;

    final saved = await _saveOnly(
      notifySuccess: false,
    );

    if (!mounted || !saved) return;

    final cotacaoId = cotacaoCubit.state.cotacaoId;

    if (cotacaoId == null || cotacaoId.isEmpty) {
      await _notify(
        title: 'Cotação',
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
        collectionName: ProgressData.cotacao,
        updatedByUid: uid,
        updatedByName: actorName,
      );

      if (!mounted) return;

      unawaited(
        _progressBloc.bindToStage(
          contractId: _contractId,
          collectionName: ProgressData.cotacao,
        ),
      );

      unawaited(_pipelineProgressCubit?.refreshPipeline());

      await _notify(
        title: 'Aprovação da Cotação atualizada',
        subtitle: _notificationDemandName,
        details: 'Atualizado por $actorName.',
        status: NotificationStatus.success,
        saveInBell: true,
        sendPush: true,
        targetUserIds: const <String>[],
        extra: <String, dynamic>{
          'action': 'cotacao_approval_updated',
          'cotacaoId': cotacaoId,
          'contractId': _contractId,
          'route': _route,
          'notificationSource': _notificationSource,
        },
      );
    } catch (e) {
      if (!mounted) return;

      await _notify(
        title: 'Cotação',
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
      child: BlocListener<CotacaoCubit, CotacaoState>(
        listenWhen: (prev, curr) {
          return (prev.loading && !curr.loading) ||
              prev.cotacaoId != curr.cotacaoId;
        },
        listener: (context, state) {
          if (!mounted || state.loading || !state.hasValidPath) return;

          final incomingId = state.cotacaoId;
          final needsHydrate = !_hydrated || _currentCotacaoId != incomingId;

          if (needsHydrate) {
            final data = CotacaoData.fromSectionsMap(state.sectionsData);

            setState(() {
              _formData = data;
              _inferFornCountFromData(data);
              _hydrated = true;
              _currentCotacaoId = incomingId;
            });
          }

          if ((incomingId ?? '').isNotEmpty) {
            unawaited(
              _progressBloc.bindToStage(
                contractId: _contractId,
                collectionName: ProgressData.cotacao,
              ),
            );

            if ((_contract.id ?? '') != _contractId) {
              unawaited(_loadContract(_contractId));
              unawaited(_loadDfdData(_contractId));
            }
          }
        },
        child: BlocBuilder<CotacaoCubit, CotacaoState>(
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
                      key: const PageStorageKey<String>('cotacao-scroll'),
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          SectionMetadados(
                            data: _formData,
                            isEditable: _isEditable,
                            onChanged: (updated) {
                              setState(() => _formData = updated);
                            },
                          ),
                          const SizedBox(height: 12),
                          SectionObjetoItens(
                            data: _formData,
                            isEditable: _isEditable,
                            onChanged: (updated) {
                              setState(() => _formData = updated);
                            },
                          ),
                          const SizedBox(height: 12),
                          SectionConviteDivulgacao(
                            data: _formData,
                            isEditable: _isEditable,
                            onChanged: (updated) {
                              setState(() => _formData = updated);
                            },
                          ),
                          const SizedBox(height: 12),
                          SectionRespostasFornecedores(
                            data: _formData,
                            isEditable: _isEditable,
                            fornCount: _fornCount,
                            onChanged: (updated) {
                              setState(() => _formData = updated);
                            },
                            onAdd: _isEditable && _fornCount < 3
                                ? _addFornecedor
                                : null,
                            onRemoveOne: _isEditable && _fornCount > 1
                                ? _removeFornecedor
                                : null,
                          ),
                          const SizedBox(height: 12),
                          SectionVencedora(
                            data: _formData,
                            isEditable: _isEditable,
                            onChanged: (updated) {
                              setState(() => _formData = updated);
                            },
                          ),
                          const SizedBox(height: 12),
                          SectionConsolidacaoResultado(
                            data: _formData,
                            isEditable: _isEditable,
                            onChanged: (updated) {
                              setState(() => _formData = updated);
                            },
                          ),
                          const SizedBox(height: 12),
                          SectionAnexos(
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
                  builder: (context, progressState) {
                    return StageProgress(
                      title: 'Cotação de preços',
                      icon: Icons.request_quote_outlined,
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
        stageKey: ProgressData.cotacao,
        child: content,
      ),
    );
  }
}