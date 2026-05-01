import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';

import 'package:sipged/_blocs/modules/contracts/apostilles/apostilles_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/apostilles/apostilles_state.dart';
import 'package:sipged/_blocs/modules/contracts/apostilles/apostilles_repository.dart';

import 'package:sipged/_blocs/system/notification/helpers/notification_contract.dart';
import 'package:sipged/_blocs/system/notification/local/notification_type.dart';

import 'package:sipged/_utils/formatters/sipged_format_dates.dart';
import 'package:sipged/_utils/formatters/sipged_format_money.dart';

import 'package:sipged/_widgets/menu/footBar/foot_bar.dart';
import 'package:sipged/_widgets/texts/section_text_name.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots.dart';

import 'package:sipged/_widgets/list/files/attachment.dart';

import 'apostilles_form_section.dart';
import 'apostilles_graph_section.dart';
import 'apostilles_table_section.dart';

class ApostillesPage extends StatefulWidget {
  final ProcessData contractData;

  const ApostillesPage({
    super.key,
    required this.contractData,
  });

  @override
  State<ApostillesPage> createState() => _ApostillesPageState();
}

class _ApostillesPageState extends State<ApostillesPage> {
  final TextEditingController _orderCtrl = TextEditingController();
  final TextEditingController _processCtrl = TextEditingController();
  final TextEditingController _dateCtrl = TextEditingController();
  final TextEditingController _valueCtrl = TextEditingController();

  late final ApostillesCubit _cubit;

  String? _lastFilledId;
  int? _selectedAttachmentIndex;
  bool _initialNextOrderApplied = false;

  String get _contractId => widget.contractData.id?.trim() ?? '';

  String get _contractSummary {
    final data = widget.contractData;

    final summary = data.summarySubjectContract?.trim() ?? '';
    if (summary.isNotEmpty) return summary;

    final number = data.contractNumber?.trim() ?? '';
    if (number.isNotEmpty) return 'Contrato $number';

    final process = data.processNumber?.trim() ?? '';
    if (process.isNotEmpty) return 'Processo $process';

    if (_contractId.isNotEmpty) return 'Contrato $_contractId';

    return 'Contrato sem identificação';
  }

  String get _contractNumber {
    final data = widget.contractData;

    final number = data.contractNumber?.trim() ?? '';
    if (number.isNotEmpty) return number;

    final process = data.processNumber?.trim() ?? '';
    if (process.isNotEmpty) return process;

    return _contractId;
  }

  @override
  void initState() {
    super.initState();

    _cubit = ApostillesCubit(
      contract: widget.contractData,
      repository: ApostillesRepository(),
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
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

  String _resolveActorName(String? uid) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final cleanUid = uid?.trim();

    if (cleanUid != null && cleanUid.isNotEmpty) {
      final meta = widget.contractData.participantsInfo[cleanUid];

      if (meta != null) {
        final fullName = (meta['fullName'] ??
            meta['displayName'] ??
            meta['nameComplete'] ??
            '')
            .toString()
            .trim();

        if (fullName.isNotEmpty) return fullName;

        final name = (meta['name'] ?? '').toString().trim();
        final surname = (meta['surname'] ?? '').toString().trim();

        final composed = [name, surname]
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

  Future<void> _notify({
    required String title,
    String? subtitle,
    String? details,
    NotificationType type = NotificationType.info,
    Duration duration = const Duration(seconds: 4),
    bool saveInBell = false,
    bool sendPush = false,
    Map<String, dynamic> extra = const <String, dynamic>{},
  }) async {
    if (!mounted) return;

    final currentUserId = FirebaseAuth.instance.currentUser?.uid.trim();
    final actorName = _resolveActorName(currentUserId);

    await NotificationContract.show(
      context: context,
      contract: widget.contractData,
      title: title,
      subtitle: subtitle,
      details: details ?? _contractSummary,
      leadingLabel: 'Apostilamento',
      module: 'contracts_apostilles',
      type: type,
      duration: duration,
      saveInBell: saveInBell,
      sendPush: sendPush,
      actorId: currentUserId,
      actorName: actorName,
      includeCurrentUser: true,
      extra: <String, dynamic>{
        'route': 'contracts_apostilles',
        'contractId': _contractId,
        'contractNumber': _contractNumber,
        'contractTitle': _contractSummary,
        'contractSummary': _contractSummary,
        ...extra,
      },
    );
  }

  void _fillForm(dynamic a) {
    _lastFilledId = a.id;

    _orderCtrl.text = (a.apostilleOrder ?? '').toString();
    _processCtrl.text = a.apostilleNumberProcess ?? '';
    _dateCtrl.text = a.apostilleData != null
        ? SipGedFormatDates.dateToDdMMyyyy(a.apostilleData!)
        : '';

    _valueCtrl.text = a.apostilleValue != null
        ? SipGedFormatMoney.brlNoSymbol(a.apostilleValue)
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
    final selectedBeforeSave = _cubit.state.selected;
    final isNew = selectedBeforeSave?.id == null;

    await _cubit.saveOrUpdate(
      orderText: _orderCtrl.text,
      processText: _processCtrl.text,
      dateText: _dateCtrl.text,
      valueText: _valueCtrl.text,
    );

    final selectedAfterSave = _cubit.state.selected;
    final actorName = _resolveActorName(
      FirebaseAuth.instance.currentUser?.uid,
    );

    await _notify(
      title: isNew ? 'Apostilamento criado' : 'Apostilamento atualizado',
      subtitle: isNew
          ? 'Apostilamento ${_orderCtrl.text.trim()} salvo por $actorName.'
          : 'Apostilamento ${_orderCtrl.text.trim()} atualizado por $actorName.',
      type: NotificationType.success,
      saveInBell: true,
      sendPush: true,
      extra: <String, dynamic>{
        'action': isNew ? 'apostille_created' : 'apostille_updated',
        'apostilleId': selectedAfterSave?.id ?? selectedBeforeSave?.id,
        'apostilleOrder': int.tryParse(_orderCtrl.text.trim()),
        'apostilleProcess': _processCtrl.text.trim(),
        'apostilleValue': SipGedFormatMoney.parseBrl(_valueCtrl.text),
        'apostilleDate': _dateCtrl.text.trim(),
      },
    );
  }

  void _applyInitialNextOrderOnce(ApostillesState state) {
    if (_initialNextOrderApplied) return;

    if (state.status != ApostillesStatus.loaded) return;
    if (state.selected != null) return;
    if (_orderCtrl.text.trim().isNotEmpty) return;
    if (state.nextAvailableOrder <= 0) return;

    _initialNextOrderApplied = true;
    _orderCtrl.text = state.nextAvailableOrder.toString();

    _cubit.createNewApostille();

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
      await _cubit.renameAttachment(
        index: index,
        newLabel: newItem.label,
      );

      final actorName = _resolveActorName(
        FirebaseAuth.instance.currentUser?.uid,
      );

      await _notify(
        title: 'Anexo de apostilamento renomeado',
        subtitle: '${newItem.label} renomeado por $actorName.',
        type: NotificationType.success,
        saveInBell: true,
        sendPush: true,
        extra: <String, dynamic>{
          'action': 'apostille_attachment_renamed',
          'oldAttachmentLabel': oldItem.label,
          'newAttachmentLabel': newItem.label,
          'attachmentUrl': newItem.url,
          'apostilleId': _cubit.state.selected?.id,
          'apostilleOrder': _cubit.state.selected?.apostilleOrder,
        },
      );

      return true;
    } catch (e) {
      await _notify(
        title: 'Falha ao renomear anexo',
        subtitle: '$e',
        type: NotificationType.error,
        duration: const Duration(seconds: 6),
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
    final selectedBeforeUpload = _cubit.state.selected;

    await _cubit.addAttachmentWithPicker(context);

    final selectedAfterUpload = _cubit.state.selected;
    final actorName = _resolveActorName(
      FirebaseAuth.instance.currentUser?.uid,
    );

    await _notify(
      title: 'Arquivo anexado ao apostilamento',
      subtitle: 'Upload concluído por $actorName.',
      type: NotificationType.success,
      saveInBell: true,
      sendPush: true,
      extra: <String, dynamic>{
        'action': 'apostille_attachment_added',
        'apostilleId': selectedAfterUpload?.id ?? selectedBeforeUpload?.id,
        'apostilleOrder': selectedAfterUpload?.apostilleOrder ??
            selectedBeforeUpload?.apostilleOrder,
      },
    );
  }

  Future<void> _deleteAttachment(int index) async {
    final state = _cubit.state;

    if (index < 0 || index >= state.sideAttachments.length) return;

    final selected = state.selected;
    final attachment = state.sideAttachments[index];

    await _cubit.deleteAttachment(index);

    if (!mounted) return;

    setState(() {
      _selectedAttachmentIndex = null;
    });

    final actorName = _resolveActorName(
      FirebaseAuth.instance.currentUser?.uid,
    );

    await _notify(
      title: 'Arquivo removido do apostilamento',
      subtitle: '${attachment.label} removido por $actorName.',
      type: NotificationType.warning,
      saveInBell: true,
      sendPush: true,
      extra: <String, dynamic>{
        'action': 'apostille_attachment_deleted',
        'apostilleId': selected?.id,
        'apostilleOrder': selected?.apostilleOrder,
        'attachmentLabel': attachment.label,
        'attachmentUrl': attachment.url,
      },
    );
  }

  Future<void> _deleteApostille(dynamic a) async {
    _cubit.selectApostille(a);

    await _cubit.deleteSelectedApostille();

    final actorName = _resolveActorName(
      FirebaseAuth.instance.currentUser?.uid,
    );

    await _notify(
      title: 'Apostilamento apagado',
      subtitle: a.apostilleOrder != null
          ? 'Apostilamento ${a.apostilleOrder} removido por $actorName.'
          : 'O apostilamento foi removido por $actorName.',
      type: NotificationType.warning,
      saveInBell: true,
      sendPush: true,
      extra: <String, dynamic>{
        'action': 'apostille_deleted',
        'apostilleId': a.id,
        'apostilleOrder': a.apostilleOrder,
        'apostilleProcess': a.apostilleNumberProcess,
        'apostilleValue': a.apostilleValue,
        'apostilleDate': a.apostilleData?.toIso8601String(),
      },
    );
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

          final bool isLoading = state.status == ApostillesStatus.loading;

          final labels = state.apostilles
              .map((e) => (e.apostilleOrder ?? '').toString())
              .toList();

          final values = state.apostilles
              .map((e) => (e.apostilleValue ?? 0.0).toDouble())
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
                                      _cubit.createNewApostille();
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
                                    onChangedOrderNumber: (v) {
                                      if (v == null) return;

                                      _orderCtrl.text = v;

                                      final ord = int.tryParse(v.trim()) ?? 0;

                                      _cubit.selectApostilleByOrder(ord);
                                      _cubit.reloadAttachments();

                                      if (_cubit.state.selected == null) {
                                        _clearForm(keepOrder: true);
                                      } else {
                                        final sel = _cubit.state.selected!;
                                        _fillForm(sel);
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
                                    onTapSideItem: (i) {
                                      setState(() {
                                        _selectedAttachmentIndex = i;
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
                                        _cubit.createNewApostille();
                                        _clearForm();

                                        _orderCtrl.text =
                                            state.nextAvailableOrder.toString();

                                        return;
                                      }

                                      _cubit.selectApostilleByIndex(index);
                                      _cubit.reloadAttachments();

                                      final sel = _cubit.state.selected;
                                      if (sel?.apostilleOrder != null) {
                                        _orderCtrl.text =
                                            sel!.apostilleOrder.toString();
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
                                    onTapItem: (a) {
                                      _cubit.selectApostille(a);
                                      _cubit.reloadAttachments();

                                      if (a.apostilleOrder != null) {
                                        _orderCtrl.text =
                                            a.apostilleOrder.toString();
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
              if (state.isSaving)
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