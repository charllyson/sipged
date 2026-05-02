import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';
import 'package:sipged/_blocs/modules/contracts/measurement/adjustment/adjustment_measurement_data.dart';
import 'package:sipged/_blocs/modules/contracts/measurement/adjustment/adjustments_measurement_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/measurement/adjustment/adjustments_measurement_repository.dart';
import 'package:sipged/_blocs/modules/contracts/measurement/adjustment/adjustments_measurement_state.dart';

import 'package:sipged/_blocs/system/notification/helpers/notification_measurements.dart';
import 'package:sipged/_blocs/system/notification/notification_type.dart';

import 'package:sipged/_utils/formatters/sipged_format_money.dart';

import 'package:sipged/_widgets/dialog/show_dialogs/show_window_dialog.dart';
import 'package:sipged/_widgets/list/files/attachment.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots.dart';
import 'package:sipged/_widgets/menu/footBar/foot_bar.dart';
import 'package:sipged/_widgets/texts/section_text_name.dart';

import 'adjustment_measurement_form_section.dart';
import 'adjustment_measurement_graph_section.dart';
import 'adjustment_measurement_table_section.dart';

class AdjustmentMeasurement extends StatelessWidget {
  const AdjustmentMeasurement({
    super.key,
    required this.contractData,
  });

  final ProcessData contractData;

  @override
  Widget build(BuildContext context) {
    final contractId = contractData.id?.toString().trim();

    if (contractId == null || contractId.isEmpty) {
      return const Center(
        child: Text('Contrato inválido para reajustes.'),
      );
    }

    return BlocProvider(
      create: (_) => AdjustmentMeasurementCubit(
        repository: AdjustmentMeasurementRepository(),
      )..loadByContract(contractId),
      child: _AdjustmentMeasurementView(contractData: contractData),
    );
  }
}

class _AdjustmentMeasurementView extends StatefulWidget {
  const _AdjustmentMeasurementView({
    required this.contractData,
  });

  final ProcessData contractData;

  @override
  State<_AdjustmentMeasurementView> createState() =>
      _AdjustmentMeasurementViewState();
}

class _AdjustmentMeasurementViewState
    extends State<_AdjustmentMeasurementView> {
  final orderCtrl = TextEditingController();
  final processCtrl = TextEditingController();
  final valueCtrl = TextEditingController();
  final dateCtrl = TextEditingController();

  bool formValidated = false;

  int? _selectedSideIndex;

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

    orderCtrl.addListener(_validateForm);
    processCtrl.addListener(_validateForm);
    valueCtrl.addListener(_validateForm);
    dateCtrl.addListener(_validateForm);
  }

  @override
  void dispose() {
    orderCtrl
      ..removeListener(_validateForm)
      ..dispose();

    processCtrl
      ..removeListener(_validateForm)
      ..dispose();

    valueCtrl
      ..removeListener(_validateForm)
      ..dispose();

    dateCtrl
      ..removeListener(_validateForm)
      ..dispose();

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

  DateTime? _parseDateTimeFromExtra(dynamic value) {
    if (value == null) return null;

    if (value is DateTime) {
      return value;
    }

    final text = value.toString().trim();

    if (text.isEmpty) return null;

    final iso = DateTime.tryParse(text);

    if (iso != null) {
      return iso;
    }

    final parts = text.split('/');

    if (parts.length == 3) {
      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);

      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }

    return null;
  }

  num? _parseNumFromExtra(dynamic value) {
    if (value == null) return null;

    if (value is num) {
      return value;
    }

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
    NotificationStatus type = NotificationStatus.info,
    Duration duration = const Duration(seconds: 4),
    bool saveInBell = false,
    bool sendPush = false,
    Map<String, dynamic> extra = const <String, dynamic>{},
  }) async {
    if (!mounted) return;

    final currentUserId = FirebaseAuth.instance.currentUser?.uid.trim();
    final actorName = _resolveActorName(currentUserId);

    await NotificationMeasurements.show(
      context: context,
      contract: widget.contractData,
      title: title,
      subtitle: subtitle,
      details: details ?? _contractSummary,
      leadingLabel: 'Reajuste',
      module: 'contracts_adjustment_measurement',
      kind: NotificationMeasurementKind.adjustment,
      status: type,
      duration: duration,
      saveInBell: saveInBell,
      sendPush: sendPush,
      actorId: currentUserId,
      actorName: actorName,
      includeCurrentUser: true,

      measurementId: extra['adjustmentId']?.toString(),
      measurementNumber: extra['adjustmentProcess']?.toString(),
      measurementOrder: extra['adjustmentOrder']?.toString(),
      measurementDate: _parseDateTimeFromExtra(extra['adjustmentDate']),
      adjustmentValue: _parseNumFromExtra(extra['adjustmentValue']),

      extra: <String, dynamic>{
        'route': 'contracts_adjustment_measurement',
        'module': 'contracts_adjustment_measurement',
        'contractId': _contractId,
        'contractNumber': _contractNumber,
        'contractTitle': _contractSummary,
        'contractSummary': _contractSummary,
        'measurementKind': NotificationMeasurementKind.adjustment.name,
        ...extra,
      },
    );
  }

  void _validateForm() {
    final ok = orderCtrl.text.trim().isNotEmpty &&
        processCtrl.text.trim().isNotEmpty &&
        valueCtrl.text.trim().isNotEmpty &&
        dateCtrl.text.trim().isNotEmpty;

    if (formValidated != ok && mounted) {
      setState(() => formValidated = ok);
    }
  }

  int _computeNextOrder(AdjustmentMeasurementState state) {
    if (state.adjustments.isEmpty) return 1;

    final maxOrder = state.adjustments
        .map((item) => item.order ?? 0)
        .fold<int>(0, (prev, curr) => math.max(prev, curr));

    return maxOrder + 1;
  }

  void _fillFieldsFromSelected(AdjustmentMeasurementState state) {
    final sel = state.selected;
    _selectedSideIndex = null;

    if (sel == null) {
      orderCtrl.text = _computeNextOrder(state).toString();
      processCtrl.clear();
      valueCtrl.clear();
      dateCtrl.clear();
      _validateForm();
      return;
    }

    orderCtrl.text = (sel.order ?? '').toString();
    processCtrl.text = sel.numberprocess ?? '';
    valueCtrl.text = SipGedFormatMoney.brlNoSymbol(sel.value);

    if (sel.date != null) {
      final d = sel.date!;
      dateCtrl.text =
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } else {
      dateCtrl.clear();
    }

    _validateForm();
  }

  int? _parseInt(String text) {
    return int.tryParse(text.replaceAll(RegExp(r'[^0-9]'), ''));
  }

  double _parseCurrency(String text) {
    return SipGedFormatMoney.parseBrl(text) ?? 0.0;
  }

  DateTime? _parseDate(String text) {
    final parts = text.split('/');

    if (parts.length != 3) return null;

    final d = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final y = int.tryParse(parts[2]);

    if (d == null || m == null || y == null) return null;
    if (m < 1 || m > 12) return null;
    if (d < 1 || d > 31) return null;

    final date = DateTime(y, m, d);

    if (date.day != d || date.month != m || date.year != y) {
      return null;
    }

    return date;
  }

  List<Attachment> _onlyAttachments(List<dynamic> items) {
    return items.whereType<Attachment>().toList();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AdjustmentMeasurementCubit>();
    final contractId = widget.contractData.id?.toString().trim();

    return BlocConsumer<AdjustmentMeasurementCubit, AdjustmentMeasurementState>(
      listener: (context, state) {
        _fillFieldsFromSelected(state);
      },
      builder: (context, state) {
        if (state.status == AdjustmentMeasurementStatus.loading &&
            state.adjustments.isEmpty) {
          return const Center(
            child: LoadingTreeDots(size: 110),
          );
        }

        final labels = state.adjustments
            .map((item) => (item.order ?? 0).toString())
            .toList();

        final values = state.adjustments
            .map((item) => item.value ?? 0.0)
            .toList();

        final total = state.adjustments.fold<double>(
          0.0,
              (sum, item) => sum + (item.value ?? 0.0),
        );

        final double totalApostilles = 0.0;
        final double totalAdditives = 0.0;
        final double valorTotalDisponivel = totalApostilles + totalAdditives;
        final double saldo = valorTotalDisponivel - total;

        final selectedIndex = state.selectedIndex;

        final nextOrder = _computeNextOrder(state);

        final usedOrders = state.adjustments
            .map((item) => item.order)
            .whereType<int>()
            .toSet()
            .toList()
          ..sort();

        final orderOptions = <String>[
          ...usedOrders.map((order) => order.toString()),
          if (!usedOrders.contains(nextOrder)) nextOrder.toString(),
        ];

        final greyOrderItems =
        usedOrders.map((order) => order.toString()).toSet();

        final attachments = state.attachments;

        return Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionTitle(text: 'Gráfico dos reajustes'),
                        AdjustmentMeasurementGraphSection(
                          labels: labels,
                          values: values,
                          valorTotal: valorTotalDisponivel,
                          totalMedicoes: total,
                          selectedIndex: selectedIndex,
                          onSelectIndex: cubit.selectByIndex,
                        ),
                        const SectionTitle(
                          text: 'Cadastrar reajuste no sistema',
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: AdjustmentMeasurementFormSection(
                            isEditable: true,
                            formValidated: formValidated,
                            selectedAdjustmentMeasurement: state.selected,
                            currentAdjustmentMeasurementId: state.selected?.id,
                            contractData: widget.contractData,
                            orderAdjustmentController: orderCtrl,
                            processNumberAdjustmentController: processCtrl,
                            dateAdjustmentController: dateCtrl,
                            valueAdjustmentController: valueCtrl,
                            sideLoading: state.uploading,
                            sideUploadProgress: state.uploadProgress,
                            onSave: () async {
                              final ok = await confirmDialog(
                                context,
                                'Deseja salvar este reajuste?',
                              );

                              if (!ok) return;

                              final parsedOrder = _parseInt(orderCtrl.text);
                              final effectiveOrder =
                              (parsedOrder == null || parsedOrder <= 0)
                                  ? _computeNextOrder(state)
                                  : parsedOrder;

                              final value = _parseCurrency(valueCtrl.text);
                              final date = _parseDate(dateCtrl.text);

                              if (date == null) {
                                await _notify(
                                  title: 'Data do reajuste inválida',
                                  subtitle: 'Use o formato dd/MM/aaaa.',
                                  type: NotificationStatus.error,
                                );
                                return;
                              }

                              if (contractId == null || contractId.isEmpty) {
                                await _notify(
                                  title: 'Contrato inválido',
                                  subtitle:
                                  'Não foi possível identificar o contrato.',
                                  type: NotificationStatus.error,
                                );
                                return;
                              }

                              final isNew = state.selected?.id == null;

                              final data = AdjustmentMeasurementData(
                                id: state.selected?.id,
                                contractId: contractId,
                                order: effectiveOrder,
                                numberprocess: processCtrl.text.trim(),
                                value: value,
                                date: date,
                                attachments: state.selected?.attachments,
                                pdfUrl: state.selected?.pdfUrl,
                              );

                              try {
                                await cubit.saveOrUpdate(data);

                                final actorName = _resolveActorName(
                                  FirebaseAuth.instance.currentUser?.uid,
                                );

                                await _notify(
                                  title: isNew
                                      ? 'Reajuste criado'
                                      : 'Reajuste atualizado',
                                  subtitle:
                                  'Reajuste ${data.order ?? '-'} salvo por $actorName.',
                                  type: NotificationStatus.success,
                                  saveInBell: true,
                                  sendPush: true,
                                  extra: <String, dynamic>{
                                    'action': isNew
                                        ? 'adjustment_created'
                                        : 'adjustment_updated',
                                    'adjustmentId': data.id,
                                    'adjustmentOrder': data.order,
                                    'adjustmentProcess': data.numberprocess,
                                    'adjustmentValue': data.value,
                                    'adjustmentDate':
                                    data.date?.toIso8601String(),
                                  },
                                );
                              } catch (e) {
                                await _notify(
                                  title: 'Erro ao salvar reajuste',
                                  subtitle: '$e',
                                  type: NotificationStatus.error,
                                  duration: const Duration(seconds: 6),
                                );
                              }
                            },
                            onClear: () {
                              cubit.clearSelection();
                              setState(() => _selectedSideIndex = null);
                            },
                            sideItems: attachments,
                            selectedSideIndex: _selectedSideIndex,
                            onAddSideItem: (state.selected != null &&
                                state.selected?.id != null &&
                                contractId != null &&
                                contractId.isNotEmpty)
                                ? () async {
                              try {
                                await cubit.pickAndUploadAttachment(
                                  contract: widget.contractData,
                                  contractId: contractId,
                                  adjustmentId: state.selected!.id!,
                                );

                                if (!mounted) return;

                                setState(() {
                                  _selectedSideIndex =
                                  cubit.state.attachments.isNotEmpty
                                      ? cubit.state.attachments
                                      .length -
                                      1
                                      : null;
                                });

                                final actorName = _resolveActorName(
                                  FirebaseAuth.instance.currentUser?.uid,
                                );

                                await _notify(
                                  title: 'Arquivo anexado ao reajuste',
                                  subtitle:
                                  'Upload concluído por $actorName.',
                                  type: NotificationStatus.success,
                                  saveInBell: true,
                                  sendPush: true,
                                  extra: <String, dynamic>{
                                    'action':
                                    'adjustment_attachment_added',
                                    'adjustmentId': state.selected!.id,
                                    'adjustmentOrder':
                                    state.selected!.order,
                                  },
                                );
                              } catch (e) {
                                await _notify(
                                  title: 'Falha ao anexar arquivo',
                                  subtitle: '$e',
                                  type: NotificationStatus.error,
                                  duration: const Duration(seconds: 6),
                                );
                              }
                            }
                                : null,
                            onTapSideItem: (index) {
                              setState(() => _selectedSideIndex = index);
                            },
                            onDeleteSideItem: (index) async {
                              if (contractId == null || contractId.isEmpty) {
                                return;
                              }

                              final sel = state.selected;

                              if (sel?.id == null) return;
                              if (index < 0 || index >= attachments.length) {
                                return;
                              }

                              final attachment = attachments[index];

                              final ok = await confirmDialog(
                                context,
                                'Remover este arquivo?',
                              );

                              if (!ok) return;

                              try {
                                await cubit.deleteAttachment(
                                  contractId: contractId,
                                  adjustmentId: sel!.id!,
                                  attachment: attachment,
                                );

                                if (mounted) {
                                  setState(() => _selectedSideIndex = null);
                                }

                                final actorName = _resolveActorName(
                                  FirebaseAuth.instance.currentUser?.uid,
                                );

                                await _notify(
                                  title: 'Arquivo removido do reajuste',
                                  subtitle:
                                  '${attachment.label} removido por $actorName.',
                                  type: NotificationStatus.warning,
                                  saveInBell: true,
                                  sendPush: true,
                                  extra: <String, dynamic>{
                                    'action':
                                    'adjustment_attachment_deleted',
                                    'adjustmentId': sel.id,
                                    'adjustmentOrder': sel.order,
                                    'attachmentLabel': attachment.label,
                                    'attachmentUrl': attachment.url,
                                  },
                                );
                              } catch (e) {
                                await _notify(
                                  title: 'Erro ao remover arquivo',
                                  subtitle: '$e',
                                  type: NotificationStatus.error,
                                  duration: const Duration(seconds: 6),
                                );
                              }
                            },
                            onRenamePersist: ({
                              required int index,
                              required Attachment oldItem,
                              required Attachment newItem,
                            }) async {
                              if (contractId == null || contractId.isEmpty) {
                                return false;
                              }

                              final sel = state.selected;

                              if (sel?.id == null) return false;

                              try {
                                await cubit.renameAttachmentLabel(
                                  contractId: contractId,
                                  adjustmentId: sel!.id!,
                                  oldItem: oldItem,
                                  newItem: newItem,
                                );

                                final actorName = _resolveActorName(
                                  FirebaseAuth.instance.currentUser?.uid,
                                );

                                await _notify(
                                  title: 'Anexo de reajuste renomeado',
                                  subtitle:
                                  '${newItem.label} renomeado por $actorName.',
                                  type: NotificationStatus.success,
                                  saveInBell: true,
                                  sendPush: true,
                                  extra: <String, dynamic>{
                                    'action':
                                    'adjustment_attachment_renamed',
                                    'adjustmentId': sel.id,
                                    'adjustmentOrder': sel.order,
                                    'oldAttachmentLabel': oldItem.label,
                                    'newAttachmentLabel': newItem.label,
                                    'attachmentUrl': newItem.url,
                                  },
                                );

                                return true;
                              } catch (e) {
                                await _notify(
                                  title: 'Falha ao renomear anexo',
                                  subtitle: '$e',
                                  type: NotificationStatus.error,
                                  duration: const Duration(seconds: 6),
                                );

                                return false;
                              }
                            },
                            onSideItemsChanged: (newItems) async {
                              final next = _onlyAttachments(newItems);

                              await cubit.updateAttachments(next);

                              if (!mounted) return;

                              setState(() {
                                if (next.isEmpty) {
                                  _selectedSideIndex = null;
                                } else {
                                  _selectedSideIndex =
                                      (_selectedSideIndex ?? 0).clamp(
                                        0,
                                        next.length - 1,
                                      );
                                }
                              });
                            },
                            orderOptions: orderOptions,
                            greyOrderItems: greyOrderItems,
                            onChangedOrder: (value) {
                              final picked = int.tryParse(value ?? '');

                              if (picked == null || picked <= 0) return;

                              final index = state.adjustments.indexWhere(
                                    (item) => (item.order ?? -1) == picked,
                              );

                              if (index >= 0) {
                                cubit.selectByIndex(index);
                              } else {
                                cubit.clearSelection();
                                orderCtrl.text = picked.toString();
                              }
                            },
                          ),
                        ),
                        const SectionTitle(
                          text: 'Reajustes cadastrados no sistema',
                        ),
                        AdjustmentMeasurementTableSection(
                          onTapItem: (AdjustmentMeasurementData data) {
                            final index = state.adjustments.indexWhere(
                                  (item) => item.id == data.id,
                            );

                            if (index >= 0) {
                              cubit.selectByIndex(index);
                            }
                          },
                          onDelete: (id) async {
                            final ok = await confirmDialog(
                              context,
                              'Deseja realmente apagar este reajuste?',
                            );

                            if (!ok) return;

                            if (contractId == null || contractId.isEmpty) {
                              return;
                            }

                            final deleted = state.adjustments.firstWhere(
                                  (item) => item.id == id,
                              orElse: () => AdjustmentMeasurementData(id: id),
                            );

                            try {
                              await cubit.delete(
                                contractId: contractId,
                                adjustmentId: id,
                              );

                              final actorName = _resolveActorName(
                                FirebaseAuth.instance.currentUser?.uid,
                              );

                              await _notify(
                                title: 'Reajuste apagado',
                                subtitle: deleted.order != null
                                    ? 'Reajuste ${deleted.order} removido por $actorName.'
                                    : 'O reajuste foi removido por $actorName.',
                                type: NotificationStatus.warning,
                                saveInBell: true,
                                sendPush: true,
                                extra: <String, dynamic>{
                                  'action': 'adjustment_deleted',
                                  'adjustmentId': id,
                                  'adjustmentOrder': deleted.order,
                                  'adjustmentProcess': deleted.numberprocess,
                                  'adjustmentValue': deleted.value,
                                  'adjustmentDate':
                                  deleted.date?.toIso8601String(),
                                },
                              );
                            } catch (e) {
                              await _notify(
                                title: 'Erro ao apagar reajuste',
                                subtitle: '$e',
                                type: NotificationStatus.error,
                                duration: const Duration(seconds: 6),
                              );
                            }
                          },
                          adjustmentMeasurementsData: state.adjustments,
                          valueApostilles: totalApostilles,
                          valueRevisions: totalAdditives,
                          valorTotal: valorTotalDisponivel,
                          balance: saldo,
                          contractData: widget.contractData,
                          selectedAdjustmentMeasurement: state.selected,
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
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
    );
  }
}