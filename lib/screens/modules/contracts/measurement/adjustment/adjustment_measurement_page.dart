// lib/screens/modules/contracts/measurement/adjustment/adjustment_measurement.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_blocs/modules/contracts/_process/process_data.dart';
import 'package:siged/_blocs/modules/contracts/measurement/adjustment/adjustment_measurement_data.dart';
import 'package:siged/_blocs/modules/contracts/measurement/adjustment/adjustments_measurement_cubit.dart';
import 'package:siged/_blocs/modules/contracts/measurement/adjustment/adjustments_measurement_repository.dart';
import 'package:siged/_blocs/modules/contracts/measurement/adjustment/adjustments_measurement_state.dart';

import 'package:siged/_widgets/menu/footBar/foot_bar.dart';
import 'package:siged/_widgets/notification/app_notification.dart';
import 'package:siged/_widgets/notification/notification_center.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/windows/show_window_dialog.dart';

import 'package:siged/_widgets/list/files/attachment.dart';

import 'adjustment_measurement_form_section.dart';
import 'adjustment_measurement_graph_section.dart';
import 'adjustment_measurement_table_section.dart';

class AdjustmentMeasurement extends StatelessWidget {
  const AdjustmentMeasurement({super.key, required this.contractData});
  final ProcessData contractData;

  @override
  Widget build(BuildContext context) {
    final contractId = contractData.id?.toString();
    if (contractId == null || contractId.isEmpty) {
      return const Center(child: Text('Contrato inválido para reajustes.'));
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
  const _AdjustmentMeasurementView({required this.contractData});
  final ProcessData contractData;

  @override
  State<_AdjustmentMeasurementView> createState() => _AdjustmentMeasurementViewState();
}

class _AdjustmentMeasurementViewState extends State<_AdjustmentMeasurementView> {
  final orderCtrl = TextEditingController();
  final processCtrl = TextEditingController();
  final valueCtrl = TextEditingController();
  final dateCtrl = TextEditingController();

  bool formValidated = false;

  int? _selectedSideIndex;

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

  void _validateForm() {
    final ok = orderCtrl.text.trim().isNotEmpty &&
        processCtrl.text.trim().isNotEmpty &&
        valueCtrl.text.trim().isNotEmpty &&
        dateCtrl.text.trim().isNotEmpty;
    if (formValidated != ok) setState(() => formValidated = ok);
  }

  int _computeNextOrder(AdjustmentMeasurementState state) {
    if (state.adjustments.isEmpty) return 1;
    final maxOrder = state.adjustments
        .map((e) => e.order ?? 0)
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
      return;
    }

    orderCtrl.text = (sel.order ?? '').toString();
    processCtrl.text = sel.numberprocess ?? '';
    valueCtrl.text = (sel.value ?? 0.0).toStringAsFixed(2);

    if (sel.date != null) {
      final d = sel.date!;
      dateCtrl.text =
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } else {
      dateCtrl.clear();
    }
  }

  int? _parseInt(String text) => int.tryParse(text.replaceAll(RegExp(r'[^0-9]'), ''));

  double _parseCurrency(String text) {
    final cleaned = text
        .replaceAll('R\$', '')
        .replaceAll('.', '')
        .replaceAll(' ', '')
        .replaceAll(',', '.')
        .trim();
    return double.tryParse(cleaned) ?? 0.0;
  }

  DateTime? _parseDate(String text) {
    final parts = text.split('/');
    if (parts.length != 3) return null;
    final d = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final y = int.tryParse(parts[2]);
    if (d == null || m == null || y == null) return null;
    return DateTime(y, m, d);
  }

  List<Attachment> _onlyAttachments(List<dynamic> items) {
    return items.whereType<Attachment>().toList();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AdjustmentMeasurementCubit>();
    final contractId = widget.contractData.id?.toString();

    return BlocConsumer<AdjustmentMeasurementCubit, AdjustmentMeasurementState>(
      listener: (context, state) => _fillFieldsFromSelected(state),
      builder: (context, state) {
        if (state.status == AdjustmentMeasurementStatus.loading &&
            state.adjustments.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final labels = state.adjustments.map((m) => (m.order ?? 0).toString()).toList();
        final values = state.adjustments.map((m) => m.value ?? 0.0).toList();
        final total = state.adjustments.fold<double>(0.0, (s, m) => s + (m.value ?? 0.0));

        // (aqui você depois pluga apostilas/aditivos se quiser)
        final double totalApostilles = 0.0;
        final double totalAdditives = 0.0;
        final double valorTotalDisponivel = totalApostilles + totalAdditives;
        final double saldo = valorTotalDisponivel - total;

        final selectedIndex = state.selectedIndex;

        final nextOrder = _computeNextOrder(state);
        final usedOrders = state.adjustments.map((m) => m.order).whereType<int>().toSet().toList()
          ..sort();

        final orderOptions = <String>[
          ...usedOrders.map((o) => o.toString()),
          if (!usedOrders.contains(nextOrder)) nextOrder.toString(),
        ];

        final Set<String> greyOrderItems = usedOrders.map((o) => o.toString()).toSet();

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
                          onSelectIndex: (i) => cubit.selectByIndex(i),
                        ),
                        const SectionTitle(text: 'Cadastrar reajuste no sistema'),
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

                            // ✅ overlay upload
                            sideLoading: state.uploading,
                            sideUploadProgress: state.uploadProgress,

                            onSave: () async {
                              final ok = await confirmDialog(
                                context,
                                'Deseja salvar este reajuste?',
                              );
                              if (!ok) return;

                              final parsedOrder = _parseInt(orderCtrl.text);
                              final effectiveOrder = (parsedOrder == null || parsedOrder <= 0)
                                  ? _computeNextOrder(state)
                                  : parsedOrder;

                              final value = _parseCurrency(valueCtrl.text);
                              final date = _parseDate(dateCtrl.text);

                              if (date == null) {
                                NotificationCenter.instance.show(
                                  AppNotification(
                                    type: AppNotificationType.error,
                                    title: const Text('Data do reajuste inválida'),
                                    subtitle: const Text('Use o formato dd/MM/aaaa.'),
                                  ),
                                );
                                return;
                              }

                              if (contractId == null || contractId.isEmpty) return;

                              final isNew = state.selected?.id == null;

                              final data = AdjustmentMeasurementData(
                                id: state.selected?.id,
                                contractId: contractId,
                                order: effectiveOrder,
                                numberprocess: processCtrl.text,
                                value: value,
                                date: date,
                                attachments: state.selected?.attachments,
                                pdfUrl: state.selected?.pdfUrl,
                              );

                              try {
                                await cubit.saveOrUpdate(data);

                                NotificationCenter.instance.show(
                                  AppNotification(
                                    type: AppNotificationType.success,
                                    title: Text(isNew ? 'Reajuste criado' : 'Reajuste atualizado'),
                                    subtitle: Text(
                                      'Reajuste da medição ${data.order} salvo com sucesso.',
                                    ),
                                  ),
                                );
                              } catch (e) {
                                NotificationCenter.instance.show(
                                  AppNotification(
                                    type: AppNotificationType.error,
                                    title: const Text('Erro ao salvar reajuste'),
                                    subtitle: Text('$e'),
                                  ),
                                );
                              }
                            },

                            onClear: () {
                              cubit.clearSelection();
                              setState(() => _selectedSideIndex = null);
                            },

                            // ==========================
                            // ✅ SideListBox – upload/delete/rename real
                            // ==========================
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

                                // seleciona o último item anexado
                                if (mounted) {
                                  setState(() {
                                    _selectedSideIndex =
                                    (cubit.state.attachments.isNotEmpty)
                                        ? cubit.state.attachments.length - 1
                                        : null;
                                  });
                                }

                                NotificationCenter.instance.show(
                                  AppNotification(
                                    type: AppNotificationType.success,
                                    title: Text('Arquivo anexado'),
                                    subtitle: Text('Upload concluído.'),
                                  ),
                                );
                              } catch (e) {
                                NotificationCenter.instance.show(
                                  AppNotification(
                                    type: AppNotificationType.error,
                                    title: const Text('Falha ao anexar arquivo'),
                                    subtitle: Text('$e'),
                                  ),
                                );
                              }
                            }
                                : null,

                            onTapSideItem: (i) => setState(() => _selectedSideIndex = i),

                            onDeleteSideItem: (i) async {
                              if (contractId == null || contractId.isEmpty) return;
                              final sel = state.selected;
                              if (sel?.id == null) return;
                              if (i < 0 || i >= attachments.length) return;

                              final ok = await confirmDialog(context, 'Remover este arquivo?');
                              if (!ok) return;

                              try {
                                await cubit.deleteAttachment(
                                  contractId: contractId,
                                  adjustmentId: sel!.id!,
                                  attachment: attachments[i],
                                );

                                if (mounted) setState(() => _selectedSideIndex = null);

                                NotificationCenter.instance.show(
                                  AppNotification(
                                    type: AppNotificationType.warning,
                                    title: Text('Arquivo removido'),
                                    subtitle: Text('O anexo foi apagado com sucesso.'),
                                  ),
                                );
                              } catch (e) {
                                NotificationCenter.instance.show(
                                  AppNotification(
                                    type: AppNotificationType.error,
                                    title: const Text('Erro ao remover arquivo'),
                                    subtitle: Text('$e'),
                                  ),
                                );
                              }
                            },

                            onRenamePersist: ({
                              required int index,
                              required Attachment oldItem,
                              required Attachment newItem,
                            }) async {
                              if (contractId == null || contractId.isEmpty) return false;
                              final sel = state.selected;
                              if (sel?.id == null) return false;

                              try {
                                await cubit.renameAttachmentLabel(
                                  contractId: contractId,
                                  adjustmentId: sel!.id!,
                                  oldItem: oldItem,
                                  newItem: newItem,
                                );
                                return true;
                              } catch (_) {
                                return false;
                              }
                            },

                            onSideItemsChanged: (newItems) async {
                              final next = _onlyAttachments(newItems);
                              await cubit.updateAttachments(next);

                              if (mounted) {
                                setState(() {
                                  if (next.isEmpty) {
                                    _selectedSideIndex = null;
                                  } else {
                                    _selectedSideIndex =
                                        (_selectedSideIndex ?? 0).clamp(0, next.length - 1);
                                  }
                                });
                              }
                            },

                            // dropdown
                            orderOptions: orderOptions,
                            greyOrderItems: greyOrderItems,
                            onChangedOrder: (value) {
                              final picked = int.tryParse(value ?? '');
                              if (picked == null || picked <= 0) return;

                              final idx = state.adjustments.indexWhere(
                                    (m) => (m.order ?? -1) == picked,
                              );

                              if (idx >= 0) {
                                cubit.selectByIndex(idx);
                              } else {
                                cubit.clearSelection();
                                orderCtrl.text = picked.toString();
                              }
                            },
                          ),
                        ),
                        const SectionTitle(text: 'Reajustes cadastrados no sistema'),
                        AdjustmentMeasurementTableSection(
                          onTapItem: (AdjustmentMeasurementData data) {
                            final idx = state.adjustments.indexWhere((e) => e.id == data.id);
                            if (idx >= 0) cubit.selectByIndex(idx);
                          },
                          onDelete: (id) async {
                            final ok = await confirmDialog(
                              context,
                              'Deseja realmente apagar este reajuste?',
                            );
                            if (!ok) return;

                            if (contractId == null || contractId.isEmpty) return;

                            try {
                              await cubit.delete(
                                contractId: contractId,
                                adjustmentId: id,
                              );

                              NotificationCenter.instance.show(
                                AppNotification(
                                  type: AppNotificationType.warning,
                                  title: Text('Reajuste apagado'),
                                  subtitle: Text('O reajuste foi removido com sucesso.'),
                                ),
                              );
                            } catch (e) {
                              NotificationCenter.instance.show(
                                AppNotification(
                                  type: AppNotificationType.error,
                                  title: const Text('Erro ao apagar reajuste'),
                                  subtitle: Text('$e'),
                                ),
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

            // mantém teu loading geral (salvar/delete/rename etc.)
            if (state.isSaving)
              Stack(
                children: [
                  ModalBarrier(
                    dismissible: false,
                    color: Colors.black.withOpacity(0.4),
                  ),
                  const Center(child: CircularProgressIndicator()),
                ],
              ),
          ],
        );
      },
    );
  }
}
