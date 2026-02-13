import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_widgets/menu/footBar/foot_bar.dart';
import 'package:sipged/_widgets/notification/app_notification.dart';
import 'package:sipged/_widgets/notification/notification_center.dart';
import 'package:sipged/_widgets/texts/divider_text.dart';
import 'package:sipged/_widgets/texts/section_text_name.dart';
import 'package:sipged/_widgets/windows/show_window_dialog.dart';

import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';
import 'package:sipged/_widgets/list/files/attachment.dart';

import 'package:sipged/_blocs/modules/contracts/measurement/revision/revision_measurement_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/measurement/revision/revision_measurement_state.dart';
import 'package:sipged/_blocs/modules/contracts/measurement/revision/revision_measurement_data.dart';
import 'package:sipged/_blocs/modules/contracts/measurement/revision/revision_measurement_repository.dart';

import 'revision_measurement_form_section.dart';
import 'revision_measurement_graph_section.dart';
import 'revision_measurement_table_section.dart';

class RevisionMeasurement extends StatelessWidget {
  const RevisionMeasurement({super.key, required this.contractData});
  final ProcessData contractData;

  @override
  Widget build(BuildContext context) {
    final contractId = contractData.id?.toString();
    if (contractId == null || contractId.isEmpty) {
      return const Center(child: Text('Contrato inválido para revisões.'));
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
  const _RevisionMeasurementView({required this.contractData});
  final ProcessData contractData;

  @override
  State<_RevisionMeasurementView> createState() => _RevisionMeasurementViewState();
}

class _RevisionMeasurementViewState extends State<_RevisionMeasurementView> {
  final orderCtrl = TextEditingController();
  final processCtrl = TextEditingController();
  final valueCtrl = TextEditingController();
  final dateCtrl = TextEditingController();

  bool formValidated = false;

  // ✅ seleção do SideListBox fica local
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

    if (formValidated != ok) {
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

    // ao trocar seleção, reseta seleção do side
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

  // =============================================================================
  // SideListBox helpers
  // =============================================================================

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
      return true;
    } catch (_) {
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
        if (state.status == RevisionMeasurementStatus.loading && state.revisions.isEmpty) {
          return const Center(child: CircularProgressIndicator());
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

        final labels = revisions.map((m) => (m.order ?? 0).toString()).toList();
        final values = revisions.map((m) => m.value ?? 0.0).toList();

        final total = cubit.sum(revisions);

        final double totalApostilles = 0.0;
        final double totalAdditives = 0.0;
        final double valorTotalDisponivel = totalApostilles + totalAdditives;
        final double saldo = valorTotalDisponivel - total;

        final selectedIndex = state.selectedIndex;

        final nextOrder = _computeNextOrder(state);
        final usedOrders = revisions.map((m) => m.order).whereType<int>().toSet().toList()..sort();

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
                        const SectionTitle(text: 'Gráfico das revisões de medição'),
                        RevisionMeasurementGraphSection(
                          labels: labels,
                          values: values,
                          valorTotal: valorTotalDisponivel,
                          totalMedicoes: total,
                          selectedIndex: selectedIndex,
                          onSelectIndex: (i) => cubit.selectByIndex(i),
                        ),
                        const DividerText(text: 'Cadastrar revisões de medição'),
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
                              (parsedOrder == null || parsedOrder <= 0) ? _computeNextOrder(state) : parsedOrder;

                              final value = _parseCurrency(valueCtrl.text);
                              final date = _parseDate(dateCtrl.text);

                              if (date == null) {
                                NotificationCenter.instance.show(
                                  AppNotification(
                                    type: AppNotificationType.error,
                                    title: const Text('Data da revisão inválida'),
                                    subtitle: const Text('Use o formato dd/MM/aaaa.'),
                                  ),
                                );
                                return;
                              }

                              if (contractId == null || contractId.isEmpty) return;

                              final isNew = state.selected?.id == null;
                              final base = state.selected ?? RevisionMeasurementData();

                              final id = base.id ?? DateTime.now().millisecondsSinceEpoch.toString();

                              final data = base.copyWith(
                                id: id,
                                contractId: contractId,
                                order: effectiveOrder,
                                numberprocess: processCtrl.text.trim(),
                                value: value,
                                date: date,
                                attachments: (state.selected?.attachments),
                                pdfUrl: state.selected?.pdfUrl,
                              );

                              try {
                                await cubit.saveOrUpdate(
                                  contractId: contractId,
                                  revisionMeasurementId: id,
                                  data: data,
                                );

                                NotificationCenter.instance.show(
                                  AppNotification(
                                    type: AppNotificationType.success,
                                    title: Text(isNew ? 'Revisão criada' : 'Revisão atualizada'),
                                    subtitle: Text('Revisão da medição ${data.order} salva com sucesso.'),
                                  ),
                                );
                              } catch (e) {
                                NotificationCenter.instance.show(
                                  AppNotification(
                                    type: AppNotificationType.error,
                                    title: const Text('Erro ao salvar revisão'),
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
                            // ✅ SideListBox (multi-anexos)
                            // ==========================
                            sideItems: attachments,
                            selectedSideIndex: _selectedSideIndex,
                            onAddSideItem: (state.selected != null)
                                ? () async {
                              try {
                                await cubit.addAttachmentWithPicker(
                                  contract: widget.contractData,
                                );
                              } catch (e) {
                                NotificationCenter.instance.show(
                                  AppNotification(
                                    type: AppNotificationType.error,
                                    title: const Text('Erro ao anexar arquivo'),
                                    subtitle: Text('$e'),
                                  ),
                                );
                              }
                            }
                                : null,
                            onTapSideItem: (i) {
                              setState(() => _selectedSideIndex = i);
                              // Se você já tem um padrão para abrir URL/arquivo (web/desktop/mobile),
                              // plugue aqui. Ex.: abrir o attachments[i].url em um viewer do seu app.
                            },
                            onDeleteSideItem: (i) async {
                              try {
                                await cubit.deleteAttachmentAt(i);
                                setState(() => _selectedSideIndex = null);
                              } catch (e) {
                                NotificationCenter.instance.show(
                                  AppNotification(
                                    type: AppNotificationType.error,
                                    title: const Text('Erro ao remover anexo'),
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
                            },

                            // dropdown
                            orderOptions: orderOptions,
                            greyOrderItems: greyOrderItems,
                            onChangedOrder: (value) {
                              final picked = int.tryParse(value ?? '');
                              if (picked == null || picked <= 0) return;

                              final idx = revisions.indexWhere((m) => (m.order ?? -1) == picked);

                              if (idx >= 0) {
                                cubit.selectByIndex(idx);
                              } else {
                                cubit.clearSelection();
                                orderCtrl.text = picked.toString();
                              }
                            },
                          ),
                        ),
                        const SectionTitle(text: 'Revisões cadastradas no sistema'),
                        RevisionMeasurementTableSection(
                          onTapItem: (RevisionMeasurementData data) {
                            final idx = revisions.indexWhere((e) => e.id == data.id);
                            if (idx >= 0) cubit.selectByIndex(idx);
                          },
                          onDelete: (id) async {
                            final ok = await confirmDialog(
                              context,
                              'Deseja realmente apagar esta medição de revisão?',
                            );
                            if (!ok) return;
                            if (contractId == null || contractId.isEmpty) return;

                            try {
                              await cubit.delete(contractId: contractId, revisionId: id);

                              NotificationCenter.instance.show(
                                AppNotification(
                                  type: AppNotificationType.warning,
                                  title: const Text('Revisão apagada'),
                                  subtitle: const Text('A revisão foi removida com sucesso.'),
                                ),
                              );
                            } catch (e) {
                              NotificationCenter.instance.show(
                                AppNotification(
                                  type: AppNotificationType.error,
                                  title: const Text('Erro ao apagar revisão'),
                                  subtitle: Text('$e'),
                                ),
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
                  ModalBarrier(dismissible: false, color: Colors.black.withValues(alpha: 0.4)),
                  const Center(child: CircularProgressIndicator()),
                ],
              ),
          ],
        );
      },
    );
  }
}
