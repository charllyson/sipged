import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';
import 'package:sipged/_blocs/modules/contracts/measurement/revision/revision_measurement_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/measurement/revision/revision_measurement_data.dart';
import 'package:sipged/_blocs/modules/contracts/measurement/revision/revision_measurement_repository.dart';
import 'package:sipged/_blocs/modules/contracts/measurement/revision/revision_measurement_state.dart';

import 'package:sipged/_blocs/system/notification/notification_cubit.dart';
import 'package:sipged/_blocs/system/notification/notification_data.dart';
import 'package:sipged/_blocs/system/notification/notification_type.dart';

import 'package:sipged/_utils/formatters/sipged_format_money.dart';

import 'package:sipged/_widgets/dialog/show_dialogs/show_window_dialog.dart';
import 'package:sipged/_widgets/list/files/attachment.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots_grey.dart';
import 'package:sipged/_widgets/menu/footBar/foot_bar.dart';
import 'package:sipged/_widgets/texts/divider_text.dart';
import 'package:sipged/_widgets/texts/section_text_name.dart';

import 'revision_measurement_form_section.dart';
import 'revision_measurement_graph_section.dart';
import 'revision_measurement_table_section.dart';

class RevisionMeasurement extends StatelessWidget {
  const RevisionMeasurement({
    super.key,
    required this.contractData,
  });

  final ProcessData contractData;

  @override
  Widget build(BuildContext context) {
    final contractId = contractData.id?.toString();

    if (contractId == null || contractId.isEmpty) {
      return const Center(
        child: Text('Contrato inválido para revisões.'),
      );
    }

    return BlocProvider(
      create: (_) => RevisionMeasurementCubit(
        repository: RevisionMeasurementRepository(),
      )..loadByContract(contractId),
      child: _RevisionMeasurementView(contractData: contractData),
    );
  }
}

class _RevisionMeasurementView extends StatefulWidget {
  const _RevisionMeasurementView({
    required this.contractData,
  });

  final ProcessData contractData;

  @override
  State<_RevisionMeasurementView> createState() =>
      _RevisionMeasurementViewState();
}

class _RevisionMeasurementViewState extends State<_RevisionMeasurementView> {
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

  void _notify({
    required String title,
    String? subtitle,
    String? details,
    NotificationType type = NotificationType.info,
    Duration duration = const Duration(seconds: 4),
  }) {
    context.read<NotificationCubit>().show(
      NotificationData(
        title: title,
        subtitle: subtitle,
        details: details,
        leadingLabel: 'Revisão',
        type: type,
        duration: duration,
      ),
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

  int _computeNextOrder(RevisionMeasurementState state) {
    if (state.revisions.isEmpty) return 1;

    final maxOrder = state.revisions
        .map((e) => e.order ?? 0)
        .fold<int>(0, (prev, curr) => math.max(prev, curr));

    return maxOrder + 1;
  }

  void _fillFieldsFromSelected(RevisionMeasurementState state) {
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

  Future<bool> _persistRename({
    required RevisionMeasurementCubit cubit,
    required List<Attachment> current,
    required int index,
    required Attachment oldItem,
    required Attachment newItem,
  }) async {
    try {
      if (index < 0 || index >= current.length) return false;

      final next = List<Attachment>.from(current);
      next[index] = newItem;

      await cubit.updateAttachments(next);

      _notify(
        title: 'Anexo renomeado',
        subtitle: newItem.label,
        type: NotificationType.success,
      );

      return true;
    } catch (e) {
      _notify(
        title: 'Falha ao renomear anexo',
        subtitle: '$e',
        type: NotificationType.error,
        duration: const Duration(seconds: 6),
      );

      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RevisionMeasurementCubit>();
    final contractId = widget.contractData.id?.toString();

    return BlocConsumer<RevisionMeasurementCubit, RevisionMeasurementState>(
      listener: (context, state) {
        _fillFieldsFromSelected(state);
      },
      builder: (context, state) {
        if (state.status == RevisionMeasurementStatus.loading &&
            state.revisions.isEmpty) {
          return const Center(
            child: LoadingTreeDots(size: 110),
          );
        }

        if (state.status == RevisionMeasurementStatus.error) {
          return Center(
            child: Text(
              state.errorMessage ?? 'Erro ao carregar revisões',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final revisions = state.revisions;

        final labels = revisions
            .map((measurement) => (measurement.order ?? 0).toString())
            .toList();

        final values = revisions
            .map((measurement) => measurement.value ?? 0.0)
            .toList();

        final total = cubit.sum(revisions);

        final double totalApostilles = 0.0;
        final double totalAdditives = 0.0;
        final double valorTotalDisponivel = totalApostilles + totalAdditives;
        final double saldo = valorTotalDisponivel - total;

        final selectedIndex = state.selectedIndex;

        final nextOrder = _computeNextOrder(state);

        final usedOrders = revisions
            .map((measurement) => measurement.order)
            .whereType<int>()
            .toSet()
            .toList()
          ..sort();

        final orderOptions = <String>[
          ...usedOrders.map((order) => order.toString()),
          if (!usedOrders.contains(nextOrder)) nextOrder.toString(),
        ];

        final greyOrderItems = usedOrders.map((order) => order.toString()).toSet();

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
                        const SectionTitle(
                          text: 'Gráfico das revisões de medição',
                        ),
                        RevisionMeasurementGraphSection(
                          labels: labels,
                          values: values,
                          valorTotal: valorTotalDisponivel,
                          totalMedicoes: total,
                          selectedIndex: selectedIndex,
                          onSelectIndex: (index) {
                            cubit.selectByIndex(index);
                          },
                        ),
                        const DividerText(
                          text: 'Cadastrar revisões de medição',
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: RevisionMeasurementFormSection(
                            isEditable: true,
                            formValidated: formValidated,
                            selectedRevisionMeasurement: state.selected,
                            currentRevisionMeasurementId: state.selected?.id,
                            contractData: widget.contractData,
                            orderRevisionController: orderCtrl,
                            processNumberRevisionController: processCtrl,
                            dateRevisionController: dateCtrl,
                            valueRevisionController: valueCtrl,
                            onSave: () async {
                              final ok = await confirmDialog(
                                context,
                                'Deseja salvar esta medição de revisão?',
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
                                _notify(
                                  title: 'Data da revisão inválida',
                                  subtitle: 'Use o formato dd/MM/aaaa.',
                                  type: NotificationType.error,
                                );
                                return;
                              }

                              if (contractId == null || contractId.isEmpty) {
                                _notify(
                                  title: 'Contrato inválido',
                                  subtitle:
                                  'Não foi possível identificar o contrato.',
                                  type: NotificationType.error,
                                );
                                return;
                              }

                              final isNew = state.selected?.id == null;
                              final base =
                                  state.selected ?? RevisionMeasurementData();

                              final id = base.id ??
                                  DateTime.now()
                                      .millisecondsSinceEpoch
                                      .toString();

                              final data = base.copyWith(
                                id: id,
                                contractId: contractId,
                                order: effectiveOrder,
                                numberprocess: processCtrl.text.trim(),
                                value: value,
                                date: date,
                                attachments: state.selected?.attachments,
                                pdfUrl: state.selected?.pdfUrl,
                              );

                              try {
                                await cubit.saveOrUpdate(
                                  contractId: contractId,
                                  revisionMeasurementId: id,
                                  data: data,
                                );

                                _notify(
                                  title: isNew
                                      ? 'Revisão criada'
                                      : 'Revisão atualizada',
                                  subtitle:
                                  'Revisão da medição ${data.order} salva com sucesso.',
                                  type: NotificationType.success,
                                );
                              } catch (e) {
                                _notify(
                                  title: 'Erro ao salvar revisão',
                                  subtitle: '$e',
                                  type: NotificationType.error,
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
                            onAddSideItem: state.selected != null
                                ? () async {
                              try {
                                await cubit.addAttachmentWithPicker(
                                  contract: widget.contractData,
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

                                _notify(
                                  title: 'Arquivo anexado',
                                  subtitle: 'Upload concluído.',
                                  type: NotificationType.success,
                                );
                              } catch (e) {
                                _notify(
                                  title: 'Erro ao anexar arquivo',
                                  subtitle: '$e',
                                  type: NotificationType.error,
                                  duration: const Duration(seconds: 6),
                                );
                              }
                            }
                                : null,
                            onTapSideItem: (index) {
                              setState(() => _selectedSideIndex = index);
                            },
                            onDeleteSideItem: (index) async {
                              final ok = await confirmDialog(
                                context,
                                'Remover este anexo?',
                              );

                              if (!ok) return;

                              try {
                                await cubit.deleteAttachmentAt(index);

                                if (mounted) {
                                  setState(() => _selectedSideIndex = null);
                                }

                                _notify(
                                  title: 'Anexo removido',
                                  subtitle:
                                  'O anexo foi removido com sucesso.',
                                  type: NotificationType.warning,
                                );
                              } catch (e) {
                                _notify(
                                  title: 'Erro ao remover anexo',
                                  subtitle: '$e',
                                  type: NotificationType.error,
                                  duration: const Duration(seconds: 6),
                                );
                              }
                            },
                            onRenamePersist: ({
                              required int index,
                              required Attachment oldItem,
                              required Attachment newItem,
                            }) async {
                              return _persistRename(
                                cubit: cubit,
                                current: List<Attachment>.from(attachments),
                                index: index,
                                oldItem: oldItem,
                                newItem: newItem,
                              );
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

                              final index = revisions.indexWhere(
                                    (measurement) =>
                                (measurement.order ?? -1) == picked,
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
                          text: 'Revisões cadastradas no sistema',
                        ),
                        RevisionMeasurementTableSection(
                          onTapItem: (RevisionMeasurementData data) {
                            final index = revisions.indexWhere(
                                  (item) => item.id == data.id,
                            );

                            if (index >= 0) {
                              cubit.selectByIndex(index);
                            }
                          },
                          onDelete: (id) async {
                            final ok = await confirmDialog(
                              context,
                              'Deseja realmente apagar esta medição de revisão?',
                            );

                            if (!ok) return;

                            if (contractId == null || contractId.isEmpty) {
                              return;
                            }

                            try {
                              await cubit.delete(
                                contractId: contractId,
                                revisionId: id,
                              );

                              _notify(
                                title: 'Revisão apagada',
                                subtitle:
                                'A revisão foi removida com sucesso.',
                                type: NotificationType.warning,
                              );
                            } catch (e) {
                              _notify(
                                title: 'Erro ao apagar revisão',
                                subtitle: '$e',
                                type: NotificationType.error,
                                duration: const Duration(seconds: 6),
                              );
                            }
                          },
                          measurementsData: revisions,
                          valorInicial: 0.0,
                          valorAditivos: 0.0,
                          valorTotal: valorTotalDisponivel,
                          saldo: saldo,
                          contractData: widget.contractData,
                          selectedMeasurement: state.selected,
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