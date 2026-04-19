import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/measurement/report/report_measurement_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/measurement/report/report_measurement_state.dart';
import 'package:sipged/_blocs/modules/contracts/measurement/report/report_measurement_data.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_data.dart';

import 'package:sipged/_blocs/modules/contracts/additives/additives_repository.dart';
import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';

import 'package:sipged/_widgets/menu/footBar/foot_bar.dart';
import 'package:sipged/_widgets/notification/app_notification.dart';
import 'package:sipged/_widgets/notification/notification_center.dart';
import 'package:sipged/_widgets/texts/section_text_name.dart';
import 'package:sipged/_widgets/windows/show_window_dialog.dart';
import 'package:sipged/_widgets/list/files/attachment.dart';

import '../create/create_detailed_reports_page.dart';
import 'report_measurement_form_section.dart';
import 'report_measurement_graph_section.dart';
import 'report_measurement_table_section.dart';

class ReportMeasurement extends StatelessWidget {
  const ReportMeasurement({super.key, required this.contractData});
  final ProcessData contractData;

  @override
  Widget build(BuildContext context) {
    final contractId = contractData.id;

    if (contractId == null) {
      return const Center(
        child: Text(
          'Salve o contrato antes de cadastrar medições.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return BlocProvider(
      create: (_) => ReportMeasurementCubit()..loadByContract(contractId),
      child: _ReportMeasurementView(contractData: contractData),
    );
  }
}

class _ReportMeasurementView extends StatefulWidget {
  const _ReportMeasurementView({required this.contractData});
  final ProcessData contractData;

  @override
  State<_ReportMeasurementView> createState() => _ReportMeasurementViewState();
}

class _ReportMeasurementViewState extends State<_ReportMeasurementView> {
  double _valorDemanda = 0.0;
  double _totalAditivos = 0.0;

  int? _selectedIndex;
  ReportMeasurementData? _selectedMeasurement;

  bool _isSaving = false;

  List<Attachment> _sideItems = <Attachment>[];
  int? _selectedSideIndex;

  final orderCtrl = TextEditingController();
  final processCtrl = TextEditingController();
  final valueCtrl = TextEditingController();
  final dateCtrl = TextEditingController();

  bool formValidated = false;

  @override
  void initState() {
    super.initState();
    _loadAggregates();
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

  Future<void> _loadAggregates() async {
    final cid = widget.contractData.id;
    if (cid == null) return;

    DfdCubit? dfdCubit;
    try {
      dfdCubit = DfdCubit();
      final DfdData? dfd = await dfdCubit.getDataForContract(cid);
      _valorDemanda = dfd?.valorDemanda ?? 0.0;
    } catch (_) {
      _valorDemanda = 0.0;
    } finally {
      try {
        await dfdCubit?.close();
      } catch (_) {}
    }

    try {
      final additivesRepo = AdditivesRepository();
      final list = await additivesRepo.ensureForContract(cid);
      _totalAditivos = list.fold<double>(
        0.0,
            (prev, item) => prev + (item.additiveValue ?? 0.0),
      );
    } catch (_) {
      _totalAditivos = 0.0;
    }

    if (mounted) setState(() {});
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
    if (m < 1 || m > 12) return null;
    if (d < 1 || d > 31) return null;
    return DateTime(y, m, d);
  }

  int _nextAvailableOrder(List<ReportMeasurementData> list) {
    final existing = list.map((e) => e.order ?? 0).where((e) => e > 0).toSet();
    if (existing.isEmpty) return 1;

    for (int i = 1; i <= existing.length + 1; i++) {
      if (!existing.contains(i)) return i;
    }

    final max = existing.reduce((a, b) => a > b ? a : b);
    return max + 1;
  }

  void _fillFieldsFromMeasurement(
      List<ReportMeasurementData> all,
      ReportMeasurementData? m,
      int? index,
      ) {
    _selectedMeasurement = m;
    _selectedIndex = index;

    if (m == null) {
      final next = _nextAvailableOrder(all);
      orderCtrl.text = next.toString();
      processCtrl.clear();
      valueCtrl.clear();
      dateCtrl.clear();

      setState(() {
        _sideItems = <Attachment>[];
        _selectedSideIndex = null;
      });

      _validateForm();
      return;
    }

    orderCtrl.text = (m.order ?? '').toString();
    processCtrl.text = m.numberprocess ?? '';
    valueCtrl.text = (m.value ?? 0.0).toStringAsFixed(2);

    if (m.date != null) {
      final d = m.date!;
      dateCtrl.text =
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } else {
      dateCtrl.clear();
    }

    final atts = m.attachments ?? <Attachment>[];
    setState(() {
      _sideItems = List<Attachment>.from(atts);
      _selectedSideIndex = atts.isNotEmpty ? 0 : null;
    });

    _validateForm();
  }

  void _applySideItemsFromWidget(List<dynamic> newItems) {
    final onlyAtt = newItems.whereType<Attachment>().toList();

    setState(() {
      _sideItems = List<Attachment>.from(onlyAtt);

      if (_sideItems.isEmpty) {
        _selectedSideIndex = null;
      } else {
        final i = _selectedSideIndex ?? 0;
        _selectedSideIndex = i.clamp(0, _sideItems.length - 1);
      }

      if (_selectedMeasurement != null) {
        _selectedMeasurement!.attachments =
        _sideItems.isEmpty ? null : List<Attachment>.from(_sideItems);
      }
    });
  }

  Future<void> _removeAttachmentAt(int index) async {
    if (index < 0 || index >= _sideItems.length) return;

    final cubit = context.read<ReportMeasurementCubit>();
    final ok = await confirmDialog(context, 'Remover este arquivo?');
    if (!ok) return;

    final m = _selectedMeasurement;
    if (m == null || (m.id == null || m.id!.isEmpty)) return;

    final att = _sideItems[index];

    try {
      await cubit.deleteAttachment(
        contractId: widget.contractData.id!,
        measurementId: m.id!,
        attachment: att,
      );

      if (!mounted) return;

      setState(() {
        _sideItems.removeAt(index);

        if (_sideItems.isEmpty) {
          _selectedSideIndex = null;
        } else {
          _selectedSideIndex = index.clamp(0, _sideItems.length - 1);
        }

        _selectedMeasurement!.attachments =
        _sideItems.isEmpty ? null : List<Attachment>.from(_sideItems);
      });

      NotificationCenter.instance.show(
        AppNotification(
          type: AppNotificationType.warning,
          title: const Text('Arquivo removido'),
          subtitle: Text(att.label),
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
  }

  @override
  Widget build(BuildContext context) {
    final contractId = widget.contractData.id!;

    return BlocConsumer<ReportMeasurementCubit, ReportMeasurementState>(
      listener: (context, state) {
        if (state.status == ReportMeasurementStatus.success) {
          final list = state.measurements;

          if (_selectedMeasurement == null) {
            _fillFieldsFromMeasurement(list, null, null);
          } else {
            final idx = list.indexWhere((e) => e.id == _selectedMeasurement!.id);
            if (idx >= 0) {
              _fillFieldsFromMeasurement(list, list[idx], idx);
            } else {
              _fillFieldsFromMeasurement(list, null, null);
            }
          }
        }
      },
      builder: (context, state) {
        final cubit = context.read<ReportMeasurementCubit>();
        final navigator = Navigator.of(context);

        final measurements = state.measurements;
        final uploading = state.uploading;
        final uploadProgress = state.uploadProgress;

        final labels = measurements.map((m) => (m.order ?? 0).toString()).toList();
        final values = measurements.map((m) => m.value ?? 0.0).toList();

        final totalMedicoes = cubit.sum(measurements);
        final totalDisponivel = _valorDemanda + _totalAditivos;
        final saldo = totalDisponivel - totalMedicoes;
        final selectedIndex = _selectedIndex;

        return Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionTitle(text: 'Gráfico das medições'),
                        ReportMeasurementGraphSection(
                          labels: labels,
                          values: values,
                          valorTotal: totalDisponivel,
                          totalMedicoes: totalMedicoes,
                          selectedIndex: selectedIndex,
                          onSelectIndex: (i) {
                            if (i < 0 || i >= measurements.length) {
                              setState(() {
                                _selectedIndex = null;
                                _selectedMeasurement = null;
                              });
                              _fillFieldsFromMeasurement(measurements, null, null);
                              return;
                            }

                            final m = measurements[i];
                            setState(() {
                              _selectedIndex = i;
                              _selectedMeasurement = m;
                            });
                            _fillFieldsFromMeasurement(measurements, m, i);
                          },
                        ),
                        const SectionTitle(
                          text: 'Cadastrar medições no sistema',
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: ReportMeasurementFormSection(
                            isEditable: true,
                            formValidated: formValidated,
                            selectedReportMeasurement: _selectedMeasurement,
                            currentReportMeasurementId: _selectedMeasurement?.id,
                            contractData: widget.contractData,
                            orderController: orderCtrl,
                            processNumberController: processCtrl,
                            dateController: dateCtrl,
                            valueController: valueCtrl,
                            sideLoading: uploading,
                            sideUploadProgress: uploadProgress,
                            onClear: () {
                              setState(() {
                                _selectedIndex = null;
                                _selectedMeasurement = null;
                              });
                              _fillFieldsFromMeasurement(measurements, null, null);
                            },
                            onAddSideItem: () async {
                              final m = _selectedMeasurement;

                              if (m == null || (m.id == null || m.id!.isEmpty)) {
                                NotificationCenter.instance.show(
                                  AppNotification(
                                    type: AppNotificationType.info,
                                    title: const Text('Salve a medição primeiro'),
                                    subtitle: const Text(
                                      'Depois você poderá anexar arquivos.',
                                    ),
                                  ),
                                );
                                return;
                              }

                              try {
                                final att = await cubit.pickAndUploadAttachment(
                                  contractId: contractId,
                                  measurementId: m.id!,
                                );

                                if (!mounted) return;

                                setState(() {
                                  _sideItems = [..._sideItems, att];
                                  _selectedSideIndex = _sideItems.length - 1;
                                  _selectedMeasurement!.attachments =
                                  List<Attachment>.from(_sideItems);
                                });

                                NotificationCenter.instance.show(
                                  AppNotification(
                                    type: AppNotificationType.success,
                                    title: const Text('Arquivo anexado'),
                                    subtitle: Text(att.label),
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
                            },
                            onSave: () async {
                              final ok = await confirmDialog(
                                context,
                                'Deseja salvar esta medição?',
                              );
                              if (!ok) return;

                              final date = _parseDate(dateCtrl.text);
                              if (date == null) {
                                NotificationCenter.instance.show(
                                  AppNotification(
                                    type: AppNotificationType.error,
                                    title: const Text('Data da medição inválida'),
                                    subtitle:
                                    const Text('Use o formato dd/MM/aaaa.'),
                                  ),
                                );
                                return;
                              }

                              if (!mounted) return;
                              setState(() => _isSaving = true);

                              final isNew = _selectedMeasurement?.id == null;

                              final data = ReportMeasurementData(
                                id: _selectedMeasurement?.id,
                                contractId: contractId,
                                order: int.tryParse(orderCtrl.text),
                                numberprocess: processCtrl.text,
                                value: _parseCurrency(valueCtrl.text),
                                date: date,
                                attachments: _sideItems.isEmpty
                                    ? null
                                    : List<Attachment>.from(_sideItems),
                              );

                              try {
                                await cubit.saveOrUpdate(data);

                                NotificationCenter.instance.show(
                                  AppNotification(
                                    type: AppNotificationType.success,
                                    title: Text(
                                      isNew
                                          ? 'Medição criada'
                                          : 'Medição atualizada',
                                    ),
                                    subtitle: Text(
                                      'Boletim ${data.order ?? '-'} salvo com sucesso.',
                                    ),
                                  ),
                                );
                              } catch (e) {
                                NotificationCenter.instance.show(
                                  AppNotification(
                                    type: AppNotificationType.error,
                                    title: const Text('Erro ao salvar medição'),
                                    subtitle: Text('$e'),
                                  ),
                                );
                              } finally {
                                if (mounted) {
                                  setState(() => _isSaving = false);
                                }
                              }
                            },
                            onOpenMemoDeCalculo: null,
                            onOpenBoletimDeMedicao: () async {
                              final m = _selectedMeasurement;

                              if (m == null || (m.id == null || m.id!.isEmpty)) {
                                NotificationCenter.instance.show(
                                  AppNotification(
                                    type: AppNotificationType.info,
                                    title: const Text('Selecione uma medição'),
                                    subtitle: const Text(
                                      'Selecione (ou salve) uma medição para abrir o boletim.',
                                    ),
                                  ),
                                );
                                return;
                              }

                              await navigator.push(
                                MaterialPageRoute(
                                  builder: (_) => CreateDetailedReportPage(
                                    titulo: 'Boletim ${m.order ?? '-'}',
                                    contractData: widget.contractData,
                                    measurement: m,
                                  ),
                                ),
                              );
                            },
                            sideItems: _sideItems,
                            selectedSideIndex: _selectedSideIndex,
                            onTapSideItem: (i) =>
                                setState(() => _selectedSideIndex = i),
                            onDeleteSideItem: (i) => _removeAttachmentAt(i),
                            onSideItemsChanged: _applySideItemsFromWidget,
                            onRenamePersist: ({
                              required int index,
                              required Attachment oldItem,
                              required Attachment newItem,
                            }) async {
                              final m = _selectedMeasurement;
                              if (m == null || (m.id == null || m.id!.isEmpty)) {
                                return false;
                              }

                              try {
                                await cubit.renameAttachmentLabel(
                                  contractId: contractId,
                                  measurementId: m.id!,
                                  oldItem: oldItem,
                                  newItem: newItem,
                                );

                                NotificationCenter.instance.show(
                                  AppNotification(
                                    type: AppNotificationType.success,
                                    title: const Text('Anexo renomeado'),
                                    subtitle: Text(newItem.label),
                                  ),
                                );
                                return true;
                              } catch (e) {
                                NotificationCenter.instance.show(
                                  AppNotification(
                                    type: AppNotificationType.error,
                                    title: const Text('Falha ao renomear anexo'),
                                    subtitle: Text('$e'),
                                  ),
                                );
                                return false;
                              }
                            },
                          ),
                        ),
                        const SectionTitle(text: 'Medições cadastradas no sistema'),
                        ReportMeasurementTableSection(
                          onTapItem: (ReportMeasurementData data) {
                            final idx = measurements.indexWhere((e) => e.id == data.id);
                            if (idx >= 0) {
                              setState(() {
                                _selectedIndex = idx;
                                _selectedMeasurement = data;
                              });
                              _fillFieldsFromMeasurement(measurements, data, idx);
                            }
                          },
                          onDelete: (id) async {
                            final ok = await confirmDialog(
                              context,
                              'Deseja realmente apagar esta medição?',
                            );
                            if (!ok) return;

                            if (!mounted) return;
                            setState(() => _isSaving = true);

                            try {
                              await cubit.delete(
                                contractId: contractId,
                                measurementId: id,
                              );

                              NotificationCenter.instance.show(
                                AppNotification(
                                  type: AppNotificationType.warning,
                                  title: const Text('Medição apagada'),
                                  subtitle: const Text(
                                    'O boletim foi removido com sucesso.',
                                  ),
                                ),
                              );
                            } catch (e) {
                              NotificationCenter.instance.show(
                                AppNotification(
                                  type: AppNotificationType.error,
                                  title: const Text('Erro ao apagar medição'),
                                  subtitle: Text('$e'),
                                ),
                              );
                            } finally {
                              if (mounted) {
                                setState(() => _isSaving = false);
                              }
                            }

                            if (!mounted) return;
                            if (_selectedMeasurement?.id == id) {
                              setState(() {
                                _selectedIndex = null;
                                _selectedMeasurement = null;
                              });
                              _fillFieldsFromMeasurement(measurements, null, null);
                            }
                          },
                          measurementsData: measurements,
                          valorInicial: _valorDemanda,
                          valorAditivos: _totalAditivos,
                          valorTotal: totalDisponivel,
                          saldo: saldo,
                          contractData: widget.contractData,
                          selectedMeasurement: _selectedMeasurement,
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                const FootBar(),
              ],
            ),
            if (_isSaving)
              Stack(
                children: [
                  ModalBarrier(
                    dismissible: false,
                    color: Colors.black.withValues(alpha: 0.4),
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