// lib/screens/modules/operation/schedule/horizontal/schedule_linear_panel.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';
import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_linear_cell_data.dart';
import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_linear_cubit.dart';
import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_linear_state.dart';
import 'package:sipged/_widgets/DataTime/selector/selector_dates.dart';

import 'package:sipged/_widgets/charts/donut/donut_chart_changed.dart';
import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots.dart';

import 'package:sipged/screens/modules/operation/schedule/common/header/schedule_header.dart';

class ScheduleLinearPanel extends StatefulWidget {
  const ScheduleLinearPanel({
    super.key,
    required this.contract,
    this.enabled = true,
    this.onSaved,
  });

  final ContractData contract;
  final bool enabled;
  final VoidCallback? onSaved;

  @override
  State<ScheduleLinearPanel> createState() => _ScheduleLinearPanelState();
}

class _ScheduleLinearPanelState extends State<ScheduleLinearPanel> {
  List<ScheduleLinearCellData>? _filteredByDate;
  bool _dateFilterActive = false;
  int? _lastExecSignature;

  int _makeExecSignature(Map<String, ScheduleLinearCellData> execIndex) {
    final orderedEntries = execIndex.entries.toList(growable: false)
      ..sort((a, b) => a.key.compareTo(b.key));

    return Object.hash(
      execIndex.length,
      Object.hashAll(
        orderedEntries.map((entry) {
          final cell = entry.value;

          return Object.hash(
            entry.key,
            cell.status.name,
            cell.primaryDate?.millisecondsSinceEpoch,
            cell.updatedAt?.millisecondsSinceEpoch,
            cell.createdAt?.millisecondsSinceEpoch,
            cell.takenAtMs,
            cell.fotos.length,
            cell.comentario,
          );
        }),
      ),
    );
  }

  bool _isDoneOrInProgress(ScheduleLinearCellData cell) {
    return cell.isConcluido || cell.isEmAndamento;
  }

  List<ScheduleLinearCellData> _cellsWithDate(ScheduleLinearState state) {
    final cells = state.execIndex.values
        .where((cell) => cell.primaryDate != null)
        .where(_isDoneOrInProgress)
        .toList(growable: false);

    cells.sort((a, b) {
      final da = a.primaryDate;
      final db = b.primaryDate;

      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;

      return da.compareTo(db);
    });

    return cells;
  }

  _SchedulePercentValues _calculatePercentagesFromCells(
      List<ScheduleLinearCellData> cells,
      ) {
    if (cells.isEmpty) {
      return const _SchedulePercentValues(
        concluido: 0.0,
        andamento: 0.0,
        aIniciar: 0.0,
      );
    }

    var concluido = 0;
    var andamento = 0;

    for (final cell in cells) {
      switch (cell.status) {
        case ScheduleLinearCellStatus.concluido:
          concluido++;
          break;

        case ScheduleLinearCellStatus.emAndamento:
          andamento++;
          break;

        case ScheduleLinearCellStatus.aIniciar:
          break;
      }
    }

    final total = cells.length;

    return _SchedulePercentValues(
      concluido: concluido * 100.0 / total,
      andamento: andamento * 100.0 / total,
      aIniciar: 0.0,
    );
  }

  _SchedulePercentValues _valuesForState({
    required ScheduleLinearState state,
  }) {
    if (_dateFilterActive) {
      return _calculatePercentagesFromCells(
        _filteredByDate ?? const <ScheduleLinearCellData>[],
      );
    }

    final concluido = state.pctConcluido.isFinite ? state.pctConcluido : 0.0;
    final andamento = state.pctAndamento.isFinite ? state.pctAndamento : 0.0;
    final aIniciar = state.pctAIniciar.isFinite ? state.pctAIniciar : 0.0;

    return _SchedulePercentValues(
      concluido: concluido,
      andamento: andamento,
      aIniciar: aIniciar,
    );
  }

  String _labelForCell(ScheduleLinearCellData cell) {
    final date = cell.primaryDate;

    if (date == null) {
      return 'Sem data';
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
  }

  String? _dateFilterLabel({
    int? selectedYear,
    int? selectedMonth,
    int? selectedDay,
  }) {
    if (selectedYear == null) return null;

    if (selectedMonth == null) {
      return '$selectedYear';
    }

    final month = selectedMonth.toString().padLeft(2, '0');

    if (selectedDay == null) {
      return '$month/$selectedYear';
    }

    final day = selectedDay.toString().padLeft(2, '0');

    return '$day/$month/$selectedYear';
  }

  void _applyDateFilterOnCubit({
    required BuildContext context,
    required List<ScheduleLinearCellData> filteredItems,
    required int? selectedYear,
    required int? selectedMonth,
    required int? selectedDay,
  }) {
    final hasSelection = selectedYear != null;

    if (!hasSelection) {
      context.read<ScheduleLinearCubit>().clearDateFilter();
      return;
    }

    context.read<ScheduleLinearCubit>().setDateFilter(
      cells: filteredItems.where(_isDoneOrInProgress).toList(
        growable: false,
      ),
      label: _dateFilterLabel(
        selectedYear: selectedYear,
        selectedMonth: selectedMonth,
        selectedDay: selectedDay,
      ),
    );
  }

  void _resetLocalDateFilter() {
    _filteredByDate = null;
    _dateFilterActive = false;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const BackgroundChange(),
        BlocBuilder<ScheduleLinearCubit, ScheduleLinearState>(
          builder: (context, state) {
            final execSignature = _makeExecSignature(state.execIndex);

            if (_lastExecSignature != execSignature) {
              _lastExecSignature = execSignature;
              _resetLocalDateFilter();

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;

                context.read<ScheduleLinearCubit>().clearDateFilter();
              });
            }

            final dateCells = _cellsWithDate(state);

            final valuesByDate = _valuesForState(
              state: state,
            );

            final labels = const <String>[
              'Concluído',
              'Em andamento',
              'A iniciar',
            ];

            final values = <double>[
              valuesByDate.concluido,
              valuesByDate.andamento,
              valuesByDate.aIniciar,
            ];

            final cores = <Color>[
              Colors.green.shade600,
              Colors.amber.shade700,
              Colors.blueGrey.shade400,
            ];

            final isWorking = state.loadingLanes ||
                state.loadingServices ||
                state.loadingExecucoes ||
                state.savingOrImporting;

            final fallbackTitle = state.summarySubjectContract?.trim().isNotEmpty == true
                ? state.summarySubjectContract!.trim()
                : widget.contract.displaySummary;

            final title = state.titleForHeader.trim().isEmpty
                ? fallbackTitle
                : state.titleForHeader;

            return Padding(
              padding: const EdgeInsets.all(12.0),
              child: ListView(
                children: [
                  ScheduleHeader(
                    title: title,
                    colorStripe: state.colorForHeader,
                    leftPadding: 0.0,
                  ),
                  const SizedBox(height: 12.0),
                  DonutChartChanged(
                    colorCard: Colors.white,
                    valueFormatType: ValueFormatType.decimal,
                    labels: labels,
                    values: values,
                    colorsSlices: cores,
                    selectedIndex: null,
                    heightGraphic: 220.0,
                  ),
                  const SizedBox(height: 12.0),
                  if (dateCells.isNotEmpty) ...[
                    _SelectorDatesBox(
                      child: SelectorDates<ScheduleLinearCellData>(
                        items: dateCells,
                        getDate: (cell) => cell.primaryDate,
                        getLabel: _labelForCell,
                        sortByDate: true,
                        sortDescending: false,
                        autoSelectInitial: false,
                        enableDaySelection: true,
                        onSelectionChanged: ({
                          required List<ScheduleLinearCellData> filteredItems,
                          int? selectedYear,
                          int? selectedMonth,
                          int? selectedDay,
                        }) {
                          if (!mounted) return;

                          final hasSelection = selectedYear != null;

                          final validFiltered = filteredItems
                              .where(_isDoneOrInProgress)
                              .toList(growable: false);

                          setState(() {
                            _dateFilterActive = hasSelection;
                            _filteredByDate =
                            hasSelection ? validFiltered : null;
                          });

                          _applyDateFilterOnCubit(
                            context: context,
                            filteredItems: validFiltered,
                            selectedYear: selectedYear,
                            selectedMonth: selectedMonth,
                            selectedDay: selectedDay,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    if (_dateFilterActive)
                      _InfoBox(
                        message: state.dateFilterLabel == null
                            ? 'Filtro de data aplicado. Exibindo somente trechos concluídos ou em andamento da seleção.'
                            : 'Filtro aplicado: ${state.dateFilterLabel}. Exibindo somente trechos concluídos ou em andamento.',
                      ),
                  ],
                  if (dateCells.isEmpty) ...[
                    const SizedBox(height: 8.0),
                    const _InfoBox(
                      message:
                      'Nenhuma estaca concluída ou em andamento possui data registrada. O gráfico está exibindo o percentual geral do gallery.',
                    ),
                  ],
                  if (isWorking) ...[
                    const SizedBox(height: 16.0),
                    const _PanelLoadingBox(),
                  ],
                  if (state.error != null && state.error!.trim().isNotEmpty) ...[
                    const SizedBox(height: 12.0),
                    _ErrorBox(
                      message: state.error!,
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SchedulePercentValues {
  const _SchedulePercentValues({
    required this.concluido,
    required this.andamento,
    required this.aIniciar,
  });

  final double concluido;
  final double andamento;
  final double aIniciar;
}

class _SelectorDatesBox extends StatelessWidget {
  const _SelectorDatesBox({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8.0,
            offset: const Offset(0.0, 2.0),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: child,
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            color: Colors.blue,
            size: 20.0,
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 13.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelLoadingBox extends StatelessWidget {
  const _PanelLoadingBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 12.0,
        vertical: 10.0,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8.0,
            offset: const Offset(0.0, 2.0),
          ),
        ],
      ),
      child: const Row(
        children: [
          LoadingTreeDots(
            size: 18.0,
            centered: false,
          ),
          SizedBox(width: 10.0),
          Expanded(
            child: Text(
              'Atualizando dados do gallery...',
              style: TextStyle(
                fontSize: 13.0,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 20.0,
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 13.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}