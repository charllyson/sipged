// lib/screens/process/measurement/report/report_measurement.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Cubit + Estado + Repo
import 'package:siged/_blocs/process/measurement/report/report_measurement_cubit.dart';
import 'package:siged/_blocs/process/measurement/report/report_measurement_state.dart';
import 'package:siged/_blocs/process/measurement/report/report_measurement_data.dart';

// DFD
import 'package:siged/_blocs/process/hiring/1Dfd/dfd_cubit.dart';
import 'package:siged/_blocs/process/hiring/1Dfd/dfd_data.dart';

// Aditivos (novo padrão: usar Repository, não mais Bloc)
import 'package:siged/_blocs/process/additives/additives_repository.dart';

// Contrato
import 'package:siged/_blocs/_process/process_data.dart';

// UI e helpers
import 'package:siged/_widgets/menu/footBar/foot_bar.dart';
import 'package:siged/_widgets/notification/app_notification.dart';
import 'package:siged/_widgets/notification/notification_center.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/windows/show_window_dialog.dart';
import 'package:siged/_widgets/list/files/attachment.dart';
import 'package:siged/_widgets/pdf/pdf_preview.dart';

// Seções da página
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
      // Se o ReportMeasurementCubit já segue o padrão novo com repo/contract,
      // você pode ajustar o construtor aqui depois.
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

    // ============================
    // Valor Demanda (DFD)
    // ============================
    try {
      final dfdCubit = DfdCubit();
      final DfdData? dfd = await dfdCubit.getDataForContract(cid);
      _valorDemanda = dfd?.valorDemanda ?? 0.0;
    } catch (_) {
      _valorDemanda = 0.0;
    }

    // ============================
    // Total de Aditivos (novo padrão: Repository)
    // ============================
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

    if (mounted) {
      setState(() {});
    }
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
      _sideItems = <Attachment>[];
      _selectedSideIndex = null;
    } else {
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
      _sideItems = List<Attachment>.from(atts);
      _selectedSideIndex = atts.isNotEmpty ? 0 : null;
    }

    _validateForm();
  }

  Future<void> _openAttachment(BuildContext context, int index) async {
    if (index < 0 || index >= _sideItems.length) return;
    final att = _sideItems[index];
    if (att.url.isEmpty) return;

    setState(() => _selectedSideIndex = index);

    await showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.all(16),
        child: PdfPreview(pdfUrl: att.url),
      ),
    );
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
            final idx =
            list.indexWhere((e) => e.id == _selectedMeasurement!.id);
            if (idx >= 0) {
              _fillFieldsFromMeasurement(list, list[idx], idx);
            } else {
              _fillFieldsFromMeasurement(list, null, null);
            }
          }
        }
      },
      builder: (context, state) {
        final measurements = state.measurements;
        final cubit = context.read<ReportMeasurementCubit>();

        final labels =
        measurements.map((m) => (m.order ?? 0).toString()).toList();
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
                              _fillFieldsFromMeasurement(
                                measurements,
                                null,
                                null,
                              );
                            } else {
                              final m = measurements[i];
                              setState(() {
                                _selectedIndex = i;
                                _selectedMeasurement = m;
                              });
                              _fillFieldsFromMeasurement(
                                measurements,
                                m,
                                i,
                              );
                            }
                          },
                        ),
                        const SectionTitle(
                          text: 'Cadastrar medições no sistema',
                        ),
                        Padding(
                          padding:
                          const EdgeInsets.symmetric(horizontal: 12),
                          child: ReportMeasurementFormSection(
                            isEditable: true,
                            formValidated: formValidated,
                            selectedReportMeasurement: _selectedMeasurement,
                            currentReportMeasurementId:
                            _selectedMeasurement?.id,
                            contractData: widget.contractData,
                            orderController: orderCtrl,
                            processNumberController: processCtrl,
                            dateController: dateCtrl,
                            valueController: valueCtrl,
                            onClear: () {
                              setState(() {
                                _selectedIndex = null;
                                _selectedMeasurement = null;
                              });
                              _fillFieldsFromMeasurement(
                                measurements,
                                null,
                                null,
                              );
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
                                    title: const Text(
                                      'Data da medição inválida',
                                    ),
                                    subtitle: const Text(
                                      'Use o formato dd/MM/aaaa.',
                                    ),
                                  ),
                                );
                                return;
                              }

                              setState(() => _isSaving = true);

                              final isNew =
                                  _selectedMeasurement?.id == null;

                              final data = ReportMeasurementData(
                                id: _selectedMeasurement?.id,
                                contractId: contractId,
                                order: int.tryParse(orderCtrl.text),
                                numberprocess: processCtrl.text,
                                value: _parseCurrency(valueCtrl.text),
                                date: date,
                                attachments:
                                _selectedMeasurement?.attachments,
                              );

                              try {
                                await cubit.saveOrUpdate(data);

                                NotificationCenter.instance.show(
                                  AppNotification(
                                    type: AppNotificationType.success,
                                    title: Text(isNew
                                        ? 'Medição criada'
                                        : 'Medição atualizada'),
                                    subtitle: Text(
                                      'Boletim ${data.order ?? '-'} salvo com sucesso.',
                                    ),
                                  ),
                                );
                              } catch (e) {
                                NotificationCenter.instance.show(
                                  AppNotification(
                                    type: AppNotificationType.error,
                                    title: const Text(
                                      'Erro ao salvar medição',
                                    ),
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
                            onOpenBoletimDeMedicao: () {},
                            sideItems: _sideItems,
                            selectedSideIndex: _selectedSideIndex,
                            onAddSideItem: null,
                            onTapSideItem: (i) =>
                                _openAttachment(context, i),
                            onDeleteSideItem: null,
                            onEditLabelSideItem: null,
                          ),
                        ),
                        const SectionTitle(
                          text: 'Medições cadastradas no sistema',
                        ),
                        ReportMeasurementTableSection(
                          onTapItem: (ReportMeasurementData data) {
                            final idx = measurements
                                .indexWhere((e) => e.id == data.id);
                            if (idx >= 0) {
                              setState(() {
                                _selectedIndex = idx;
                                _selectedMeasurement = data;
                              });
                              _fillFieldsFromMeasurement(
                                measurements,
                                data,
                                idx,
                              );
                            }
                          },
                          onDelete: (id) async {
                            final ok = await confirmDialog(
                              context,
                              'Deseja realmente apagar esta medição?',
                            );
                            if (!ok) return;

                            setState(() => _isSaving = true);

                            try {
                              await cubit.delete(
                                contractId: contractId,
                                measurementId: id,
                              );

                              NotificationCenter.instance.show(
                                AppNotification(
                                  type: AppNotificationType.warning,
                                  title:
                                  const Text('Medição apagada'),
                                  subtitle: Text(
                                    'O boletim foi removido com sucesso.',
                                  ),
                                ),
                              );
                            } catch (e) {
                              NotificationCenter.instance.show(
                                AppNotification(
                                  type: AppNotificationType.error,
                                  title: const Text(
                                    'Erro ao apagar medição',
                                  ),
                                  subtitle: Text('$e'),
                                ),
                              );
                            } finally {
                              if (mounted) {
                                setState(() => _isSaving = false);
                              }
                            }

                            if (_selectedMeasurement?.id == id) {
                              setState(() {
                                _selectedIndex = null;
                                _selectedMeasurement = null;
                              });
                              _fillFieldsFromMeasurement(
                                measurements,
                                null,
                                null,
                              );
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

            // --------------------------
            //  🔥 LOADING OVERLAY GLOBAL
            // --------------------------
            if (_isSaving)
              Stack(
                children: [
                  ModalBarrier(
                    dismissible: false,
                    color: Colors.black.withOpacity(0.4),
                  ),
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }
}
