// lib/screens/modules/contracts/apostilles/apostilles_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';

import 'package:sipged/_blocs/modules/contracts/apostilles/apostilles_data.dart';
import 'package:sipged/_blocs/modules/contracts/apostilles/apostilles_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/apostilles/apostilles_state.dart';
import 'package:sipged/_blocs/modules/contracts/apostilles/apostilles_repository.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_data.dart';

import 'package:sipged/_blocs/system/notification/helpers/notification_apostilles.dart';
import 'package:sipged/_blocs/system/notification/notification_delivery.dart';
import 'package:sipged/_blocs/system/notification/notification_type.dart';

import 'package:sipged/_utils/formatters/sipged_format_dates.dart';
import 'package:sipged/_utils/formatters/sipged_format_money.dart';

import 'package:sipged/_widgets/list/files/attachment.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots.dart';
import 'package:sipged/_widgets/menu/footBar/foot_bar.dart';
import 'package:sipged/_widgets/texts/section_text_name.dart';

import 'apostilles_form_section.dart';
import 'apostilles_graph_section.dart';
import 'apostilles_table_section.dart';

class ApostillesPage extends StatefulWidget {
  const ApostillesPage({
    super.key,
    required this.contractData,
  });

  final ProcessData contractData;

  @override
  State<ApostillesPage> createState() => _ApostillesPageState();
}

class _ApostillesPageState extends State<ApostillesPage> {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _route = 'contracts_apostilles';
  static const String _notificationSource = 'contracts_apostilles';
  static const String _source = 'apostille_notification';

  final TextEditingController _orderCtrl = TextEditingController();
  final TextEditingController _processCtrl = TextEditingController();
  final TextEditingController _dateCtrl = TextEditingController();
  final TextEditingController _valueCtrl = TextEditingController();

  late final ApostillesCubit _cubit;

  String? _lastFilledId;
  int? _selectedAttachmentIndex;
  bool _initialNextOrderApplied = false;

  DfdData? _dfdData;
  bool _loadingContractDisplay = false;

  String get _contractId => widget.contractData.id?.trim() ?? '';

  String get _contractSummary {
    final descricaoObjeto = _dfdData?.descricaoObjeto?.trim();

    if (descricaoObjeto != null && descricaoObjeto.isNotEmpty) {
      return descricaoObjeto;
    }

    if (_contractId.isNotEmpty) {
      return 'Contrato $_contractId';
    }

    return 'Contrato sem identificação';
  }

  String get _contractNumber {
    final processoAdministrativo = _dfdData?.processoAdministrativo?.trim();

    if (processoAdministrativo != null && processoAdministrativo.isNotEmpty) {
      return processoAdministrativo;
    }

    return _contractId;
  }

  @override
  void initState() {
    super.initState();

    _cubit = ApostillesCubit(
      contract: widget.contractData,
      repository: ApostillesRepository(),
      enforcePermissions: false,
    );

    void recomputeValidity() {
      _cubit.updateFormValidity(
        orderText: _orderCtrl.text,
        dateText: _dateCtrl.text,
        processText: _processCtrl.text,
        valueText: _valueCtrl.text,
      );
    }

    _orderCtrl.addListener(recomputeValidity);
    _processCtrl.addListener(recomputeValidity);
    _dateCtrl.addListener(recomputeValidity);
    _valueCtrl.addListener(recomputeValidity);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      await _loadContractDisplayData();

      if (!mounted) return;
      recomputeValidity();
    });
  }

  @override
  void dispose() {
    _orderCtrl.dispose();
    _processCtrl.dispose();
    _dateCtrl.dispose();
    _valueCtrl.dispose();

    _cubit.close();

    super.dispose();
  }

  Future<void> _loadContractDisplayData() async {
    if (_loadingContractDisplay) return;

    final contractId = _contractId;

    if (contractId.isEmpty) return;

    setState(() {
      _loadingContractDisplay = true;
    });

    try {
      final dfd = await _loadDfd(contractId);

      if (!mounted) return;

      setState(() {
        _dfdData = dfd;
        _loadingContractDisplay = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loadingContractDisplay = false;
      });
    }
  }

  Future<DfdData?> _loadDfd(String contractId) async {
    final candidatePaths = <String>[
      'contracts/$contractId/hiring/00Dfd',
      'contracts/$contractId/hiring/01Dfd',
      'contracts/$contractId/hiring/dfd',
      'contracts/$contractId/dfd/main',
      'contracts/$contractId/demand/dfd',
    ];

    for (final path in candidatePaths) {
      final data = await _tryReadDocument(path);

      if (data == null) continue;

      final parsed = _parseDfd(
        data,
        contractId: contractId,
      );

      if (parsed != null) return parsed;
    }

    return null;
  }

  DfdData? _parseDfd(
      Map<String, dynamic> data, {
        required String contractId,
      }) {
    final sectionsData = data['sectionsData'];
    final sections = data['sections'];

    if (sectionsData is Map) {
      return DfdData.fromSectionsMap(
        _toDynamicMap(sectionsData),
        contractId: contractId,
      );
    }

    if (sections is Map) {
      return DfdData.fromSectionsMap(
        _toDynamicMap(sections),
        contractId: contractId,
      );
    }

    return DfdData.fromMap(
      data,
      contractId: contractId,
    );
  }

  Future<Map<String, dynamic>?> _tryReadDocument(String path) async {
    try {
      final snapshot = await _firestore.doc(path).get();

      if (!snapshot.exists) return null;

      final data = snapshot.data();

      if (data == null || data.isEmpty) return null;

      return Map<String, dynamic>.from(data);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _toDynamicMap(Map raw) {
    return raw.map(
          (key, value) => MapEntry(
        key.toString(),
        value is Map ? _toDynamicMap(value) : value,
      ),
    );
  }

  String _resolveActorName(String? uid) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final cleanUid = uid?.trim();

    if (cleanUid != null && cleanUid.isNotEmpty) {
      final meta = widget.contractData.participantsInfo[cleanUid];

      if (meta != null) {
        final fullName = (meta['fullName'] ??
            meta['displayName'] ??
            meta['nameComplete'] ??
            meta['nomeCompleto'] ??
            meta['nome'] ??
            '')
            .toString()
            .trim();

        if (fullName.isNotEmpty) return fullName;

        final name = (meta['name'] ?? meta['nome'] ?? '').toString().trim();
        final surname =
        (meta['surname'] ?? meta['sobrenome'] ?? '').toString().trim();

        final composed = <String>[name, surname]
            .where((item) => item.trim().isNotEmpty)
            .join(' ')
            .trim();

        if (composed.isNotEmpty) return composed;

        final email = (meta['email'] ?? '').toString().trim();

        if (email.isNotEmpty) return email;
      }
    }

    final displayName = currentUser?.displayName?.trim() ?? '';

    if (displayName.isNotEmpty) return displayName;

    final email = currentUser?.email?.trim() ?? '';

    if (email.isNotEmpty) return email;

    return 'Usuário';
  }

  DateTime? _parseDateTimeFromExtra(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;

    final text = value.toString().trim();

    if (text.isEmpty) return null;

    final iso = DateTime.tryParse(text);

    if (iso != null) return iso;

    final parts = text.split('/');

    if (parts.length == 3) {
      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);

      if (day != null && month != null && year != null) {
        final parsed = DateTime(year, month, day);

        if (parsed.day == day &&
            parsed.month == month &&
            parsed.year == year) {
          return parsed;
        }
      }
    }

    return null;
  }

  num? _parseNumFromExtra(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;

    final text = value.toString().trim();

    if (text.isEmpty) return null;

    final normalized = text
        .replaceAll('R\$', '')
        .replaceAll('.', '')
        .replaceAll(',', '.')
        .trim();

    return num.tryParse(normalized);
  }

  Future<void> _notify({
    required String title,
    String? subtitle,
    String? details,
    NotificationStatus status = NotificationStatus.info,

    /// Compatibilidade temporária com chamadas antigas.
    NotificationStatus? type,

    Duration duration = const Duration(seconds: 4),
    bool saveInBell = false,
    bool sendPush = false,
    Map<String, dynamic> extra = const <String, dynamic>{},
  }) async {
    if (!mounted) return;

    final currentUserId = FirebaseAuth.instance.currentUser?.uid.trim();
    final actorName = _resolveActorName(currentUserId);

    final delivery = saveInBell || sendPush
        ? NotificationDelivery.localBellAndPush
        : NotificationDelivery.localOnly;

    await NotificationApostilles.show(
      context: context,
      contract: widget.contractData,
      title: title,
      subtitle: subtitle,
      details: details ?? _contractSummary,
      leadingLabel: 'Apostilamento',
      module: _route,
      source: _source,
      notificationSource: _notificationSource,
      status: type ?? status,
      duration: duration,
      saveInBell: saveInBell,
      sendPush: sendPush,
      actorId: currentUserId,
      actorName: actorName,
      includeCurrentUser: true,
      delivery: delivery,
      apostilleId: extra['apostilleId']?.toString(),
      apostilleNumber: extra['apostilleNumber']?.toString() ??
          extra['apostilleProcess']?.toString(),
      apostilleOrder: extra['apostilleOrder']?.toString(),
      apostilleType: extra['apostilleType']?.toString(),
      apostilleDate: _parseDateTimeFromExtra(extra['apostilleDate']),
      apostilleValue: _parseNumFromExtra(extra['apostilleValue']),
      extra: <String, dynamic>{
        'route': _route,
        'module': _route,
        'source': _source,
        'sourceKey': _notificationSource,
        'subSource': _notificationSource,
        'notificationSource': _notificationSource,

        /// Mantidos para o NotificationBell identificar usuário/foto.
        'actorId': currentUserId,
        'actorName': actorName,

        'contractId': _contractId,
        'contractNumber': _contractNumber,
        'processNumber': _contractNumber,
        'processoAdministrativo': _dfdData?.processoAdministrativo,
        'contractTitle': _contractSummary,
        'contractSummary': _contractSummary,
        'descricaoObjeto': _dfdData?.descricaoObjeto,
        ...extra,
      },
    );
  }

  Future<void> _safeNotify({
    required String title,
    String? subtitle,
    String? details,
    NotificationStatus status = NotificationStatus.info,

    /// Compatibilidade temporária com chamadas antigas.
    NotificationStatus? type,

    Duration duration = const Duration(seconds: 4),
    bool saveInBell = false,
    bool sendPush = false,
    Map<String, dynamic> extra = const <String, dynamic>{},
  }) async {
    try {
      await _notify(
        title: title,
        subtitle: subtitle,
        details: details,
        status: status,
        type: type,
        duration: duration,
        saveInBell: saveInBell,
        sendPush: sendPush,
        extra: extra,
      );
    } catch (e, stack) {
      debugPrint('Falha ao enviar notificação de apostilamento: $e');
      debugPrintStack(stackTrace: stack);
    }
  }

  void _fillForm(ApostillesData apostille) {
    _lastFilledId = apostille.id;

    _orderCtrl.text = (apostille.apostilleOrder ?? '').toString();
    _processCtrl.text = apostille.apostilleNumberProcess ?? '';
    _dateCtrl.text = apostille.apostilleData != null
        ? SipGedFormatDates.dateToDdMMyyyy(apostille.apostilleData!)
        : '';

    _valueCtrl.text = apostille.apostilleValue != null
        ? SipGedFormatMoney.brlNoSymbol(apostille.apostilleValue)
        : '';

    _cubit.updateFormValidity(
      orderText: _orderCtrl.text,
      dateText: _dateCtrl.text,
      processText: _processCtrl.text,
      valueText: _valueCtrl.text,
    );
  }

  void _clearForm({bool keepOrder = false}) {
    _lastFilledId = null;

    if (!keepOrder) {
      _orderCtrl.clear();
    }

    _processCtrl.clear();
    _dateCtrl.clear();
    _valueCtrl.clear();

    _selectedAttachmentIndex = null;

    _cubit.updateFormValidity(
      orderText: _orderCtrl.text,
      dateText: _dateCtrl.text,
      processText: _processCtrl.text,
      valueText: _valueCtrl.text,
    );
  }

  Future<void> _save() async {
    try {
      final result = await _cubit.saveOrUpdate(
        orderText: _orderCtrl.text,
        processText: _processCtrl.text,
        dateText: _dateCtrl.text,
        valueText: _valueCtrl.text,
      );

      final actorName = _resolveActorName(
        FirebaseAuth.instance.currentUser?.uid,
      );

      await _safeNotify(
        title:
        result.created ? 'Apostilamento criado' : 'Apostilamento atualizado',
        subtitle: result.created
            ? 'Apostilamento ${_orderCtrl.text.trim()} salvo por $actorName.'
            : 'Apostilamento ${_orderCtrl.text.trim()} atualizado por $actorName.',
        status: NotificationStatus.success,
        saveInBell: true,
        sendPush: true,
        extra: <String, dynamic>{
          'action': result.created ? 'apostille_created' : 'apostille_updated',
          'apostilleId': result.apostilleId,
          'apostilleOrder': result.order,
          'apostilleProcess': _processCtrl.text.trim(),
          'apostilleValue': SipGedFormatMoney.parseBrl(_valueCtrl.text),
          'apostilleDate': _dateCtrl.text.trim(),
        },
      );
    } catch (e) {
      await _safeNotify(
        title: 'Erro ao salvar apostilamento',
        subtitle: e.toString(),
        status: NotificationStatus.error,
        duration: const Duration(seconds: 6),
        extra: <String, dynamic>{
          'action': 'apostille_save_error',
          'error': e.toString(),
        },
      );
    }
  }

  void _applyInitialNextOrderOnce(ApostillesState state) {
    if (_initialNextOrderApplied) return;

    if (state.status != ApostillesStatus.loaded) return;
    if (state.selected != null) return;
    if (_orderCtrl.text.trim().isNotEmpty) return;
    if (state.nextAvailableOrder <= 0) return;

    _initialNextOrderApplied = true;
    _orderCtrl.text = state.nextAvailableOrder.toString();

    try {
      _cubit.createNewApostille();
    } catch (_) {}

    _cubit.updateFormValidity(
      orderText: _orderCtrl.text,
      dateText: _dateCtrl.text,
      processText: _processCtrl.text,
      valueText: _valueCtrl.text,
    );
  }

  Future<bool> _persistRenameAttachment({
    required int index,
    required Attachment oldItem,
    required Attachment newItem,
  }) async {
    try {
      final result = await _cubit.renameAttachment(
        index: index,
        newLabel: newItem.label,
      );

      final actorName = _resolveActorName(
        FirebaseAuth.instance.currentUser?.uid,
      );

      await _safeNotify(
        title: 'Anexo de apostilamento renomeado',
        subtitle: '${result.newAttachment.label} renomeado por $actorName.',
        status: NotificationStatus.success,
        saveInBell: true,
        sendPush: true,
        extra: <String, dynamic>{
          'action': 'apostille_attachment_renamed',
          'apostilleId': result.apostilleId,
          'apostilleOrder': result.apostilleOrder,
          'oldAttachmentId': result.oldAttachment.id,
          'oldAttachmentLabel': result.oldAttachment.label,
          'newAttachmentId': result.newAttachment.id,
          'newAttachmentLabel': result.newAttachment.label,
          'attachmentUrl': result.newAttachment.url,
          'attachmentPath': result.newAttachment.path,
        },
      );

      return true;
    } catch (e) {
      await _safeNotify(
        title: 'Falha ao renomear anexo',
        subtitle: e.toString(),
        status: NotificationStatus.error,
        duration: const Duration(seconds: 6),
        extra: <String, dynamic>{
          'action': 'apostille_attachment_rename_error',
          'error': e.toString(),
        },
      );

      return false;
    }
  }

  void _ensureSelectedAttachmentIndexValid(int len) {
    if (_selectedAttachmentIndex == null) return;

    if (len <= 0) {
      setState(() => _selectedAttachmentIndex = null);
      return;
    }

    if (_selectedAttachmentIndex! >= len) {
      setState(() => _selectedAttachmentIndex = len - 1);
    }
  }

  Future<void> _addAttachment() async {
    try {
      final result = await _cubit.addAttachmentWithPicker(context);

      final actorName = _resolveActorName(
        FirebaseAuth.instance.currentUser?.uid,
      );

      await _safeNotify(
        title: 'Arquivo anexado ao apostilamento',
        subtitle: '${result.attachment.label} enviado por $actorName.',
        status: NotificationStatus.success,
        saveInBell: true,
        sendPush: true,
        extra: <String, dynamic>{
          'action': 'apostille_attachment_added',
          'apostilleId': result.apostilleId,
          'apostilleOrder': result.apostilleOrder,
          'attachmentId': result.attachment.id,
          'attachmentLabel': result.attachment.label,
          'attachmentUrl': result.attachment.url,
          'attachmentPath': result.attachment.path,
        },
      );
    } catch (e) {
      await _safeNotify(
        title: 'Erro ao anexar arquivo',
        subtitle: e.toString(),
        status: NotificationStatus.error,
        duration: const Duration(seconds: 6),
        extra: <String, dynamic>{
          'action': 'apostille_attachment_add_error',
          'error': e.toString(),
        },
      );
    }
  }

  Future<void> _deleteAttachment(int index) async {
    try {
      final result = await _cubit.deleteAttachment(index);

      if (!mounted) return;

      setState(() {
        _selectedAttachmentIndex = null;
      });

      final actorName = _resolveActorName(
        FirebaseAuth.instance.currentUser?.uid,
      );

      await _safeNotify(
        title: 'Arquivo removido do apostilamento',
        subtitle: result.attachment != null
            ? '${result.attachment!.label} removido por $actorName.'
            : 'Arquivo removido por $actorName.',
        status: NotificationStatus.warning,
        saveInBell: true,
        sendPush: true,
        extra: <String, dynamic>{
          'action': 'apostille_attachment_deleted',
          'apostilleId': result.apostilleId,
          'apostilleOrder': result.apostilleOrder,
          'attachmentId': result.attachment?.id,
          'attachmentLabel': result.attachment?.label,
          'attachmentUrl': result.attachment?.url,
          'attachmentPath': result.attachment?.path,
        },
      );
    } catch (e) {
      await _safeNotify(
        title: 'Erro ao remover arquivo',
        subtitle: e.toString(),
        status: NotificationStatus.error,
        duration: const Duration(seconds: 6),
        extra: <String, dynamic>{
          'action': 'apostille_attachment_delete_error',
          'error': e.toString(),
        },
      );
    }
  }

  Future<void> _deleteApostille(ApostillesData apostille) async {
    try {
      _cubit.selectApostille(apostille);

      final result = await _cubit.deleteSelectedApostille();

      final actorName = _resolveActorName(
        FirebaseAuth.instance.currentUser?.uid,
      );

      await _safeNotify(
        title: 'Apostilamento apagado',
        subtitle: result.order != null
            ? 'Apostilamento ${result.order} removido por $actorName.'
            : 'O apostilamento foi removido por $actorName.',
        status: NotificationStatus.warning,
        saveInBell: true,
        sendPush: true,
        extra: <String, dynamic>{
          'action': 'apostille_deleted',
          'apostilleId': result.apostilleId,
          'apostilleOrder': result.order,
          'apostilleProcess': result.process,
          'apostilleValue': result.value,
          'apostilleDate': result.date?.toIso8601String(),
        },
      );
    } catch (e) {
      await _safeNotify(
        title: 'Erro ao apagar apostilamento',
        subtitle: e.toString(),
        status: NotificationStatus.error,
        duration: const Duration(seconds: 6),
        extra: <String, dynamic>{
          'action': 'apostille_delete_error',
          'error': e.toString(),
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ApostillesCubit>.value(
      value: _cubit,
      child: BlocBuilder<ApostillesCubit, ApostillesState>(
        builder: (context, state) {
          _applyInitialNextOrderOnce(state);

          if (state.selected == null && _lastFilledId != null) {
            _clearForm(keepOrder: true);
          }

          if (state.selected != null && state.selected!.id != _lastFilledId) {
            _fillForm(state.selected!);
            _cubit.reloadAttachments();
          }

          final isLoading = state.status == ApostillesStatus.loading;

          final labels = state.apostilles
              .map((item) => (item.apostilleOrder ?? '').toString())
              .toList();

          final values = state.apostilles
              .map((item) => (item.apostilleValue ?? 0.0).toDouble())
              .toList();

          return Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SectionTitle(
                                  text: 'Cadastrar apostilamentos no sistema',
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: ApostilleFormSection(
                                    isEditable: state.isEditable,
                                    editingMode: state.editingMode,
                                    formValidated: state.formValid,
                                    selectedApostille: state.selected,
                                    currentApostilleId: state.selected?.id,
                                    contractData: widget.contractData,
                                    orderController: _orderCtrl,
                                    processController: _processCtrl,
                                    dateController: _dateCtrl,
                                    valueController: _valueCtrl,
                                    onSave: _save,
                                    onClear: () {
                                      try {
                                        _cubit.createNewApostille();
                                      } catch (e) {
                                        _safeNotify(
                                          title: 'Sem permissão',
                                          subtitle: e.toString(),
                                          status: NotificationStatus.error,
                                        );
                                        return;
                                      }

                                      _clearForm();

                                      _orderCtrl.text =
                                          state.nextAvailableOrder.toString();

                                      _cubit.updateFormValidity(
                                        orderText: _orderCtrl.text,
                                        dateText: _dateCtrl.text,
                                        processText: _processCtrl.text,
                                        valueText: _valueCtrl.text,
                                      );
                                    },
                                    orderNumberOptions: state.orderOptions,
                                    greyOrderItems: state.greyOrderItems,
                                    onChangedOrderNumber: (value) {
                                      if (value == null) return;

                                      _orderCtrl.text = value;

                                      final order =
                                          int.tryParse(value.trim()) ?? 0;

                                      _cubit.selectApostilleByOrder(order);
                                      _cubit.reloadAttachments();

                                      if (_cubit.state.selected == null) {
                                        _clearForm(keepOrder: true);
                                      } else {
                                        _fillForm(_cubit.state.selected!);
                                      }

                                      _cubit.updateFormValidity(
                                        orderText: _orderCtrl.text,
                                        dateText: _dateCtrl.text,
                                        processText: _processCtrl.text,
                                        valueText: _valueCtrl.text,
                                      );
                                    },
                                    sideItems: state.sideAttachments,
                                    selectedSideIndex:
                                    _selectedAttachmentIndex,
                                    onAddSideItem:
                                    state.canAddFile ? _addAttachment : null,
                                    onTapSideItem: (index) {
                                      setState(() {
                                        _selectedAttachmentIndex = index;
                                      });
                                    },
                                    onDeleteSideItem: _deleteAttachment,
                                    onRenamePersist:
                                    _persistRenameAttachment,
                                    onItemsChanged: (newItems) {
                                      _ensureSelectedAttachmentIndexValid(
                                        newItems.length,
                                      );
                                    },
                                  ),
                                ),
                                const SectionTitle(
                                  text: 'Gráfico dos apostilamentos',
                                ),
                                if (!isLoading && state.apostilles.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.all(24),
                                    child: Text(
                                      'Nenhum apostilamento cadastrado para exibir no gráfico.',
                                    ),
                                  )
                                else
                                  ApostilleGraphSection(
                                    labels: labels,
                                    values: values,
                                    selectedIndex: state.selectedIndex,
                                    onSelectIndex: (index) {
                                      if (index < 0) {
                                        try {
                                          _cubit.createNewApostille();
                                        } catch (e) {
                                          _safeNotify(
                                            title: 'Sem permissão',
                                            subtitle: e.toString(),
                                            status: NotificationStatus.error,
                                          );
                                          return;
                                        }

                                        _clearForm();

                                        _orderCtrl.text =
                                            state.nextAvailableOrder.toString();

                                        return;
                                      }

                                      _cubit.selectApostilleByIndex(index);
                                      _cubit.reloadAttachments();

                                      final selected = _cubit.state.selected;

                                      if (selected?.apostilleOrder != null) {
                                        _orderCtrl.text = selected!
                                            .apostilleOrder
                                            .toString();
                                      }
                                    },
                                  ),
                                const SectionTitle(
                                  text: 'Apostilamentos cadastrados no sistema',
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: ApostilleTableSection(
                                    apostilles: state.apostilles,
                                    isLoading: isLoading,
                                    selectedItem: state.selected,
                                    onTapItem: (apostille) {
                                      _cubit.selectApostille(apostille);
                                      _cubit.reloadAttachments();

                                      if (apostille.apostilleOrder != null) {
                                        _orderCtrl.text = apostille
                                            .apostilleOrder
                                            .toString();
                                      }
                                    },
                                    onDelete: _deleteApostille,
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const FootBar(),
                ],
              ),
              if (state.isSaving || isLoading || _loadingContractDisplay)
                Stack(
                  children: [
                    ModalBarrier(
                      dismissible: false,
                      color: Colors.black.withValues(alpha: 0.4),
                    ),
                    const Center(
                      child: LoadingTreeDots(size: 120),
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}