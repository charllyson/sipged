// lib/screens/modules/contracts/additives/additive_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';
import 'package:sipged/_blocs/modules/contracts/additives/additives_data.dart';
import 'package:sipged/_blocs/modules/contracts/additives/additives_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/additives/additives_state.dart';
import 'package:sipged/_blocs/modules/contracts/additives/additives_repository.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_data.dart';

import 'package:sipged/_blocs/system/notification/helpers/notification_additive.dart';
import 'package:sipged/_blocs/system/notification/notification_delivery.dart';
import 'package:sipged/_blocs/system/notification/notification_type.dart';

import 'package:sipged/_blocs/system/permission/permission_cubit.dart';
import 'package:sipged/_blocs/system/permission/permission_state.dart';

import 'package:sipged/_utils/formatters/sipged_format_dates.dart';
import 'package:sipged/_utils/formatters/sipged_format_money.dart';

import 'package:sipged/_widgets/list/files/attachment.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots.dart';
import 'package:sipged/_widgets/menu/footBar/foot_bar.dart';
import 'package:sipged/_widgets/texts/section_text_name.dart';

import 'additive_form_section.dart';
import 'additive_graph_section.dart';
import 'additive_table_section.dart';

class AdditivePage extends StatefulWidget {
  const AdditivePage({
    super.key,
    required this.contractData,
  });

  final ProcessData contractData;

  @override
  State<AdditivePage> createState() => _AdditivePageState();
}

class _AdditivePageState extends State<AdditivePage> {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _route = 'contracts_additives';
  static const String _notificationSource = 'contracts_additives';
  static const String _source = 'additive_notification';

  final TextEditingController _orderCtrl = TextEditingController();
  final TextEditingController _processCtrl = TextEditingController();
  final TextEditingController _dateCtrl = TextEditingController();
  final TextEditingController _typeCtrl = TextEditingController();
  final TextEditingController _valueCtrl = TextEditingController();
  final TextEditingController _addDaysExecCtrl = TextEditingController();
  final TextEditingController _addDaysContractCtrl = TextEditingController();

  late final AdditivesCubit _cubit;

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

    final permissionState = context.read<PermissionCubit>().state;

    _cubit = AdditivesCubit(
      contract: widget.contractData,
      repository: AdditivesRepository(),
      initialPermissions: permissionState.current,
      tenantId: permissionState.activeTenantId,
      moduleId: _route,
    );

    void recomputeValidity() {
      _cubit.updateFormValidity(
        typeText: _typeCtrl.text,
        dateText: _dateCtrl.text,
        processText: _processCtrl.text,
        valueText: _valueCtrl.text,
        addExecText: _addDaysExecCtrl.text,
        addContractText: _addDaysContractCtrl.text,
      );
    }

    _orderCtrl.addListener(recomputeValidity);
    _processCtrl.addListener(recomputeValidity);
    _dateCtrl.addListener(recomputeValidity);
    _typeCtrl.addListener(recomputeValidity);
    _valueCtrl.addListener(recomputeValidity);
    _addDaysExecCtrl.addListener(recomputeValidity);
    _addDaysContractCtrl.addListener(recomputeValidity);

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
    _typeCtrl.dispose();
    _valueCtrl.dispose();
    _addDaysExecCtrl.dispose();
    _addDaysContractCtrl.dispose();

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

  int? _parseIntFromExtra(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();

    final text = value.toString().trim();

    if (text.isEmpty) return null;

    return int.tryParse(text.replaceAll(RegExp(r'[^0-9-]'), ''));
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

    await NotificationAdditive.show(
      context: context,
      contract: widget.contractData,
      title: title,
      subtitle: subtitle,
      details: details ?? _contractSummary,
      leadingLabel: 'Aditivo',
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
      additiveId: extra['additiveId']?.toString(),
      additiveNumber: extra['additiveNumber']?.toString() ??
          extra['additiveProcess']?.toString(),
      additiveOrder: extra['additiveOrder']?.toString(),
      additiveType: extra['additiveType']?.toString(),
      additiveDate: _parseDateTimeFromExtra(extra['additiveDate']),
      additiveValue: _parseNumFromExtra(extra['additiveValue']),
      additiveValidityExecutionDays: _parseIntFromExtra(
        extra['additiveValidityExecutionDays'],
      ),
      additiveValidityContractDays: _parseIntFromExtra(
        extra['additiveValidityContractDays'],
      ),
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
      debugPrint('Falha ao enviar notificação de aditivo: $e');
      debugPrintStack(stackTrace: stack);
    }
  }

  void _fillForm(AdditivesData additive) {
    _lastFilledId = additive.id;

    _orderCtrl.text = (additive.additiveOrder ?? '').toString();
    _processCtrl.text = additive.additiveNumberProcess ?? '';
    _dateCtrl.text = additive.additiveDate != null
        ? SipGedFormatDates.dateToDdMMyyyy(additive.additiveDate!)
        : '';
    _typeCtrl.text = additive.typeOfAdditive ?? '';

    _valueCtrl.text = additive.additiveValue != null
        ? SipGedFormatMoney.brlNoSymbol(additive.additiveValue)
        : '';

    _addDaysExecCtrl.text =
        additive.additiveValidityExecutionDays?.toString() ?? '';
    _addDaysContractCtrl.text =
        additive.additiveValidityContractDays?.toString() ?? '';

    _cubit.updateFormValidity(
      typeText: _typeCtrl.text,
      dateText: _dateCtrl.text,
      processText: _processCtrl.text,
      valueText: _valueCtrl.text,
      addExecText: _addDaysExecCtrl.text,
      addContractText: _addDaysContractCtrl.text,
    );
  }

  void _clearForm({bool keepOrder = false}) {
    _lastFilledId = null;

    if (!keepOrder) {
      _orderCtrl.clear();
    }

    _processCtrl.clear();
    _dateCtrl.clear();
    _typeCtrl.clear();
    _valueCtrl.clear();
    _addDaysExecCtrl.clear();
    _addDaysContractCtrl.clear();

    _selectedAttachmentIndex = null;

    _cubit.updateFormValidity(
      typeText: _typeCtrl.text,
      dateText: _dateCtrl.text,
      processText: _processCtrl.text,
      valueText: _valueCtrl.text,
      addExecText: _addDaysExecCtrl.text,
      addContractText: _addDaysContractCtrl.text,
    );
  }

  Future<void> _save() async {
    try {
      final result = await _cubit.saveOrUpdate(
        orderText: _orderCtrl.text,
        dateText: _dateCtrl.text,
        valueText: _valueCtrl.text,
        addDaysExecText: _addDaysExecCtrl.text,
        addDaysContractText: _addDaysContractCtrl.text,
        processText: _processCtrl.text,
        typeText: _typeCtrl.text,
      );

      final actorName = _resolveActorName(
        FirebaseAuth.instance.currentUser?.uid,
      );

      await _safeNotify(
        title: result.created ? 'Aditivo criado' : 'Aditivo atualizado',
        subtitle: result.created
            ? 'Aditivo ${_orderCtrl.text.trim()} salvo por $actorName.'
            : 'Aditivo ${_orderCtrl.text.trim()} atualizado por $actorName.',
        status: NotificationStatus.success,
        saveInBell: true,
        sendPush: true,
        extra: <String, dynamic>{
          'action': result.created ? 'additive_created' : 'additive_updated',
          'additiveId': result.additiveId,
          'additiveOrder': result.order,
          'additiveProcess': _processCtrl.text.trim(),
          'additiveType': _typeCtrl.text.trim(),
          'additiveValue': SipGedFormatMoney.parseBrl(_valueCtrl.text),
          'additiveDate': _dateCtrl.text.trim(),
          'additiveValidityExecutionDays':
          int.tryParse(_addDaysExecCtrl.text.trim()),
          'additiveValidityContractDays':
          int.tryParse(_addDaysContractCtrl.text.trim()),
        },
      );
    } catch (e) {
      await _safeNotify(
        title: 'Erro ao salvar aditivo',
        subtitle: e.toString(),
        status: NotificationStatus.error,
        duration: const Duration(seconds: 6),
        extra: <String, dynamic>{
          'action': 'additive_save_error',
          'error': e.toString(),
        },
      );
    }
  }

  void _applyInitialNextOrderOnce(AdditivesState state) {
    if (_initialNextOrderApplied) return;

    if (state.status != AdditivesStatus.loaded) return;
    if (state.selected != null) return;
    if (_orderCtrl.text.trim().isNotEmpty) return;
    if (state.nextAvailableOrder <= 0) return;

    _initialNextOrderApplied = true;
    _orderCtrl.text = state.nextAvailableOrder.toString();

    _cubit.createNewAdditive();

    _cubit.updateFormValidity(
      typeText: _typeCtrl.text,
      dateText: _dateCtrl.text,
      processText: _processCtrl.text,
      valueText: _valueCtrl.text,
      addExecText: _addDaysExecCtrl.text,
      addContractText: _addDaysContractCtrl.text,
    );
  }

  void _ensureSelectedAttachmentIndexValid(int newLen) {
    if (_selectedAttachmentIndex == null) return;

    if (newLen <= 0) {
      setState(() => _selectedAttachmentIndex = null);
      return;
    }

    if (_selectedAttachmentIndex! >= newLen) {
      setState(() => _selectedAttachmentIndex = newLen - 1);
    }
  }

  Future<void> _addAttachment() async {
    try {
      final result = await _cubit.addAttachmentWithPicker(context);

      final actorName = _resolveActorName(
        FirebaseAuth.instance.currentUser?.uid,
      );

      await _safeNotify(
        title: 'Arquivo anexado ao aditivo',
        subtitle: '${result.attachment.label} enviado por $actorName.',
        status: NotificationStatus.success,
        saveInBell: true,
        sendPush: true,
        extra: <String, dynamic>{
          'action': 'additive_attachment_added',
          'additiveId': result.additiveId,
          'additiveOrder': result.additiveOrder,
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
          'action': 'additive_attachment_add_error',
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
        title: 'Arquivo removido do aditivo',
        subtitle: result.attachment != null
            ? '${result.attachment!.label} removido por $actorName.'
            : 'Arquivo removido por $actorName.',
        status: NotificationStatus.warning,
        saveInBell: true,
        sendPush: true,
        extra: <String, dynamic>{
          'action': 'additive_attachment_deleted',
          'additiveId': result.additiveId,
          'additiveOrder': result.additiveOrder,
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
          'action': 'additive_attachment_delete_error',
          'error': e.toString(),
        },
      );
    }
  }

  Future<bool> _renameAttachment({
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
        title: 'Anexo de aditivo renomeado',
        subtitle: '${result.newAttachment.label} renomeado por $actorName.',
        status: NotificationStatus.success,
        saveInBell: true,
        sendPush: true,
        extra: <String, dynamic>{
          'action': 'additive_attachment_renamed',
          'additiveId': result.additiveId,
          'additiveOrder': result.additiveOrder,
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
          'action': 'additive_attachment_rename_error',
          'error': e.toString(),
        },
      );

      return false;
    }
  }

  Future<void> _deleteAdditive(AdditivesData additive) async {
    try {
      _cubit.selectAdditive(additive);

      final result = await _cubit.deleteSelectedAdditive();

      final actorName = _resolveActorName(
        FirebaseAuth.instance.currentUser?.uid,
      );

      await _safeNotify(
        title: 'Aditivo apagado',
        subtitle: result.order != null
            ? 'Aditivo ${result.order} removido por $actorName.'
            : 'O aditivo foi removido por $actorName.',
        status: NotificationStatus.warning,
        saveInBell: true,
        sendPush: true,
        extra: <String, dynamic>{
          'action': 'additive_deleted',
          'additiveId': result.additiveId,
          'additiveOrder': result.order,
          'additiveProcess': result.process,
          'additiveType': result.type,
          'additiveValue': result.value,
          'additiveDate': result.date?.toIso8601String(),
          'additiveValidityExecutionDays': result.validityExecutionDays,
          'additiveValidityContractDays': result.validityContractDays,
        },
      );
    } catch (e) {
      await _safeNotify(
        title: 'Erro ao apagar aditivo',
        subtitle: e.toString(),
        status: NotificationStatus.error,
        duration: const Duration(seconds: 6),
        extra: <String, dynamic>{
          'action': 'additive_delete_error',
          'error': e.toString(),
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AdditivesCubit>.value(
      value: _cubit,
      child: BlocListener<PermissionCubit, PermissionState>(
        listenWhen: (previous, current) {
          return previous.current != current.current ||
              previous.activeTenantId != current.activeTenantId;
        },
        listener: (context, permissionState) {
          _cubit.updateUser(
            null,
            permissions: permissionState.current,
            tenantId: permissionState.activeTenantId,
          );
        },
        child: BlocBuilder<AdditivesCubit, AdditivesState>(
          builder: (context, state) {
            _applyInitialNextOrderOnce(state);

            if (state.selected == null && _lastFilledId != null) {
              _clearForm(keepOrder: true);
            }

            if (state.selected != null && state.selected!.id != _lastFilledId) {
              _fillForm(state.selected!);
              _cubit.reloadAttachments();
            }

            final bool isLoading = state.status == AdditivesStatus.loading;

            final labels = state.additives
                .map((item) => (item.additiveOrder ?? '').toString())
                .toList();

            final values = state.additives
                .map((item) => (item.additiveValue ?? 0.0).toDouble())
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
                                    text: 'Cadastrar aditivos no sistema',
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: AdditiveFormSection(
                                      isEditable: state.isEditable,
                                      editingMode: state.editingMode,
                                      formValidated: state.formValid,
                                      selectedAdditive: state.selected,
                                      currentAdditiveId: state.selected?.id,
                                      contractData: widget.contractData,
                                      orderController: _orderCtrl,
                                      processController: _processCtrl,
                                      dateController: _dateCtrl,
                                      typeOfAdditiveCtrl: _typeCtrl,
                                      valueController: _valueCtrl,
                                      additionalDaysExecutionController:
                                      _addDaysExecCtrl,
                                      additionalDaysContractController:
                                      _addDaysContractCtrl,
                                      sideLoading: state.sideLoading,
                                      uploadProgress: state.uploadProgress,
                                      onSave: _save,
                                      onClear: () {
                                        _cubit.createNewAdditive();
                                        _clearForm();

                                        _orderCtrl.text =
                                            state.nextAvailableOrder.toString();

                                        _cubit.updateFormValidity(
                                          typeText: _typeCtrl.text,
                                          dateText: _dateCtrl.text,
                                          processText: _processCtrl.text,
                                          valueText: _valueCtrl.text,
                                          addExecText: _addDaysExecCtrl.text,
                                          addContractText:
                                          _addDaysContractCtrl.text,
                                        );
                                      },
                                      orderOptions: state.orderOptions,
                                      greyOrderItems: state.greyOrderItems,
                                      onChangedOrder: (value) {
                                        if (value == null) return;

                                        _orderCtrl.text = value;

                                        final order =
                                            int.tryParse(value.trim()) ?? 0;

                                        _cubit.selectAdditiveByOrder(order);
                                        _cubit.reloadAttachments();

                                        if (_cubit.state.selected == null) {
                                          _clearForm(keepOrder: true);
                                        } else {
                                          _fillForm(_cubit.state.selected!);
                                        }

                                        _cubit.updateFormValidity(
                                          typeText: _typeCtrl.text,
                                          dateText: _dateCtrl.text,
                                          processText: _processCtrl.text,
                                          valueText: _valueCtrl.text,
                                          addExecText: _addDaysExecCtrl.text,
                                          addContractText:
                                          _addDaysContractCtrl.text,
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
                                      onSideItemsChanged: (newItems) {
                                        _ensureSelectedAttachmentIndexValid(
                                          newItems.length,
                                        );
                                      },
                                      onRenamePersistSideItem:
                                      _renameAttachment,
                                    ),
                                  ),
                                  const SectionTitle(
                                    text: 'Gráfico dos aditivos',
                                  ),
                                  if (!isLoading && state.additives.isEmpty)
                                    const Padding(
                                      padding: EdgeInsets.all(24),
                                      child: Text(
                                        'Nenhum aditivo cadastrado para exibir no gráfico.',
                                      ),
                                    )
                                  else
                                    AdditiveGraphSection(
                                      labels: labels,
                                      values: values,
                                      selectedIndex: state.selectedIndex,
                                      onSelectIndex: (index) {
                                        if (index < 0) {
                                          _cubit.createNewAdditive();
                                          _clearForm();

                                          _orderCtrl.text = state
                                              .nextAvailableOrder
                                              .toString();

                                          return;
                                        }

                                        _cubit.selectAdditiveByIndex(index);
                                        _cubit.reloadAttachments();

                                        final selected =
                                            _cubit.state.selected;

                                        if (selected?.additiveOrder != null) {
                                          _orderCtrl.text = selected!
                                              .additiveOrder
                                              .toString();
                                        }
                                      },
                                    ),
                                  const SectionTitle(
                                    text: 'Aditivos cadastrados no sistema',
                                  ),
                                  AdditiveTableSection(
                                    additives: state.additives,
                                    isLoading: isLoading,
                                    selectedItem: state.selected,
                                    onTapItem: (additive) {
                                      _cubit.selectAdditive(additive);
                                      _cubit.reloadAttachments();

                                      if (additive.additiveOrder != null) {
                                        _orderCtrl.text = additive.additiveOrder
                                            .toString();
                                      }
                                    },
                                    onDelete: _deleteAdditive,
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
                if (state.isSaving || _loadingContractDisplay)
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
      ),
    );
  }
}