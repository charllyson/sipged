import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';
import 'package:sipged/_blocs/modules/contracts/additives/additives_data.dart';
import 'package:sipged/_blocs/modules/contracts/additives/additives_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/additives/additives_state.dart';
import 'package:sipged/_blocs/modules/contracts/additives/additives_repository.dart';

import 'package:sipged/_blocs/system/notification/helpers/notification_contract.dart';
import 'package:sipged/_blocs/system/notification/local/notification_type.dart';

import 'package:sipged/_utils/formatters/sipged_format_dates.dart';
import 'package:sipged/_utils/formatters/sipged_format_money.dart';

import 'package:sipged/_widgets/menu/footBar/foot_bar.dart';
import 'package:sipged/_widgets/texts/section_text_name.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots.dart';

import 'package:sipged/_widgets/list/files/attachment.dart';

import 'additive_form_section.dart';
import 'additive_graph_section.dart';
import 'additive_table_section.dart';

class AdditivePage extends StatefulWidget {
  final ProcessData contractData;

  const AdditivePage({
    super.key,
    required this.contractData,
  });

  @override
  State<AdditivePage> createState() => _AdditivePageState();
}

class _AdditivePageState extends State<AdditivePage> {
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

    _cubit = AdditivesCubit(
      contract: widget.contractData,
      repository: AdditivesRepository(),
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
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
      leadingLabel: 'Aditivo',
      module: 'contracts_additives',
      type: type,
      duration: duration,
      saveInBell: saveInBell,
      sendPush: sendPush,
      actorId: currentUserId,
      actorName: actorName,
      includeCurrentUser: true,
      extra: <String, dynamic>{
        'route': 'contracts_additives',
        'contractId': _contractId,
        'contractNumber': _contractNumber,
        'contractTitle': _contractSummary,
        'contractSummary': _contractSummary,
        ...extra,
      },
    );
  }

  void _fillForm(AdditivesData a) {
    _lastFilledId = a.id;

    _orderCtrl.text = (a.additiveOrder ?? '').toString();
    _processCtrl.text = a.additiveNumberProcess ?? '';
    _dateCtrl.text = a.additiveDate != null
        ? SipGedFormatDates.dateToDdMMyyyy(a.additiveDate!)
        : '';
    _typeCtrl.text = a.typeOfAdditive ?? '';

    _valueCtrl.text = a.additiveValue != null
        ? SipGedFormatMoney.brlNoSymbol(a.additiveValue)
        : '';

    _addDaysExecCtrl.text = a.additiveValidityExecutionDays?.toString() ?? '';
    _addDaysContractCtrl.text = a.additiveValidityContractDays?.toString() ?? '';

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
    final selectedBeforeSave = _cubit.state.selected;
    final isNew = selectedBeforeSave?.id == null;

    await _cubit.saveOrUpdate(
      orderText: _orderCtrl.text,
      dateText: _dateCtrl.text,
      valueText: _valueCtrl.text,
      addDaysExecText: _addDaysExecCtrl.text,
      addDaysContractText: _addDaysContractCtrl.text,
      processText: _processCtrl.text,
      typeText: _typeCtrl.text,
    );

    final selectedAfterSave = _cubit.state.selected;
    final actorName = _resolveActorName(
      FirebaseAuth.instance.currentUser?.uid,
    );

    await _notify(
      title: isNew ? 'Aditivo criado' : 'Aditivo atualizado',
      subtitle: isNew
          ? 'Aditivo ${_orderCtrl.text.trim()} salvo por $actorName.'
          : 'Aditivo ${_orderCtrl.text.trim()} atualizado por $actorName.',
      type: NotificationType.success,
      saveInBell: true,
      sendPush: true,
      extra: <String, dynamic>{
        'action': isNew ? 'additive_created' : 'additive_updated',
        'additiveId': selectedAfterSave?.id ?? selectedBeforeSave?.id,
        'additiveOrder': int.tryParse(_orderCtrl.text.trim()),
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
    final selectedBeforeUpload = _cubit.state.selected;

    await _cubit.addAttachmentWithPicker(context);

    final selectedAfterUpload = _cubit.state.selected;
    final actorName = _resolveActorName(
      FirebaseAuth.instance.currentUser?.uid,
    );

    await _notify(
      title: 'Arquivo anexado ao aditivo',
      subtitle: 'Upload concluído por $actorName.',
      type: NotificationType.success,
      saveInBell: true,
      sendPush: true,
      extra: <String, dynamic>{
        'action': 'additive_attachment_added',
        'additiveId': selectedAfterUpload?.id ?? selectedBeforeUpload?.id,
        'additiveOrder': selectedAfterUpload?.additiveOrder ??
            selectedBeforeUpload?.additiveOrder,
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
      title: 'Arquivo removido do aditivo',
      subtitle: '${attachment.label} removido por $actorName.',
      type: NotificationType.warning,
      saveInBell: true,
      sendPush: true,
      extra: <String, dynamic>{
        'action': 'additive_attachment_deleted',
        'additiveId': selected?.id,
        'additiveOrder': selected?.additiveOrder,
        'attachmentLabel': attachment.label,
        'attachmentUrl': attachment.url,
      },
    );
  }

  Future<bool> _renameAttachment({
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
        title: 'Anexo de aditivo renomeado',
        subtitle: '${newItem.label} renomeado por $actorName.',
        type: NotificationType.success,
        saveInBell: true,
        sendPush: true,
        extra: <String, dynamic>{
          'action': 'additive_attachment_renamed',
          'oldAttachmentLabel': oldItem.label,
          'newAttachmentLabel': newItem.label,
          'attachmentUrl': newItem.url,
          'additiveId': _cubit.state.selected?.id,
          'additiveOrder': _cubit.state.selected?.additiveOrder,
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

  Future<void> _deleteAdditive(AdditivesData a) async {
    _cubit.selectAdditive(a);

    await _cubit.deleteSelectedAdditive();

    final actorName = _resolveActorName(
      FirebaseAuth.instance.currentUser?.uid,
    );

    await _notify(
      title: 'Aditivo apagado',
      subtitle: a.additiveOrder != null
          ? 'Aditivo ${a.additiveOrder} removido por $actorName.'
          : 'O aditivo foi removido por $actorName.',
      type: NotificationType.warning,
      saveInBell: true,
      sendPush: true,
      extra: <String, dynamic>{
        'action': 'additive_deleted',
        'additiveId': a.id,
        'additiveOrder': a.additiveOrder,
        'additiveProcess': a.additiveNumberProcess,
        'additiveType': a.typeOfAdditive,
        'additiveValue': a.additiveValue,
        'additiveDate': a.additiveDate?.toIso8601String(),
        'additiveValidityExecutionDays': a.additiveValidityExecutionDays,
        'additiveValidityContractDays': a.additiveValidityContractDays,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AdditivesCubit>.value(
      value: _cubit,
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
              .map((e) => (e.additiveOrder ?? '').toString())
              .toList();

          final values = state.additives
              .map((e) => (e.additiveValue ?? 0.0).toDouble())
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
                                    onChangedOrder: (v) {
                                      if (v == null) return;

                                      _orderCtrl.text = v;

                                      final ord = int.tryParse(v.trim()) ?? 0;

                                      _cubit.selectAdditiveByOrder(ord);
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
                                    onTapSideItem: (i) {
                                      setState(() {
                                        _selectedAttachmentIndex = i;
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

                                        _orderCtrl.text =
                                            state.nextAvailableOrder.toString();

                                        return;
                                      }

                                      _cubit.selectAdditiveByIndex(index);
                                      _cubit.reloadAttachments();

                                      final sel = _cubit.state.selected;
                                      if (sel?.additiveOrder != null) {
                                        _orderCtrl.text =
                                            sel!.additiveOrder.toString();
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
                                  onTapItem: (a) {
                                    _cubit.selectAdditive(a);
                                    _cubit.reloadAttachments();

                                    if (a.additiveOrder != null) {
                                      _orderCtrl.text =
                                          a.additiveOrder.toString();
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