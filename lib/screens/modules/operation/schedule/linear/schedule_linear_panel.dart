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
  bool _accumulated = false;

  int? _selectedYear;
  int? _selectedMonth;
  int? _selectedDay;

  bool _isDoneOrInProgress(ScheduleLinearCellData cell) {
    return cell.isConcluido || cell.isEmAndamento;
  }

  List<ScheduleLinearCellData> _cellsWithDate(ScheduleLinearState state) {
    final cells = state.execucoes
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

  List<ScheduleLinearCellData> _activeFilteredCells(
      ScheduleLinearState state,
      ) {
    if (!state.dateFilterActive) {
      return const <ScheduleLinearCellData>[];
    }

    return state.execucoes
        .where(_isDoneOrInProgress)
        .where((cell) => state.dateFilterCellKeys.contains(cell.cellKey))
        .toList(growable: false);
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _sameMonth(DateTime date, int year, int month) {
    return date.year == year && date.month == month;
  }

  bool _sameYear(DateTime date, int year) {
    return date.year == year;
  }

  DateTime _endOfSelectedPeriod({
    required int year,
    int? month,
    int? day,
  }) {
    if (month == null) {
      return DateTime(year, 12, 31, 23, 59, 59, 999);
    }

    if (day == null) {
      return DateTime(year, month + 1, 0, 23, 59, 59, 999);
    }

    return DateTime(year, month, day, 23, 59, 59, 999);
  }

  bool _matchesExactPeriod({
    required DateTime date,
    required int year,
    int? month,
    int? day,
  }) {
    if (month == null) {
      return _sameYear(date, year);
    }

    if (day == null) {
      return _sameMonth(date, year, month);
    }

    return _sameDay(date, DateTime(year, month, day));
  }

  List<ScheduleLinearCellData> _filterCellsForCurrentSelection({
    required ScheduleLinearState state,
  }) {
    final year = _selectedYear;

    if (year == null) {
      return const <ScheduleLinearCellData>[];
    }

    final source = _cellsWithDate(state);

    if (_accumulated) {
      final end = _endOfSelectedPeriod(
        year: year,
        month: _selectedMonth,
        day: _selectedDay,
      );

      return source.where((cell) {
        final date = cell.primaryDate;
        if (date == null) return false;

        return !date.isAfter(end);
      }).toList(growable: false);
    }

    return source.where((cell) {
      final date = cell.primaryDate;
      if (date == null) return false;

      return _matchesExactPeriod(
        date: date,
        year: year,
        month: _selectedMonth,
        day: _selectedDay,
      );
    }).toList(growable: false);
  }

  _SchedulePercentValues _calculatePartialPercentagesFromCells({
    required ScheduleLinearState state,
    required List<ScheduleLinearCellData> cells,
  }) {
    final totalEsperado = state.totalEsperado;

    if (totalEsperado <= 0) {
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

    final pctConcluido = (concluido * 100.0 / totalEsperado).clamp(0.0, 100.0);
    final pctAndamento = (andamento * 100.0 / totalEsperado).clamp(0.0, 100.0);
    final pctAIniciar =
    (100.0 - pctConcluido - pctAndamento).clamp(0.0, 100.0);

    return _SchedulePercentValues(
      concluido: pctConcluido,
      andamento: pctAndamento,
      aIniciar: pctAIniciar,
    );
  }

  _SchedulePercentValues _valuesForState({
    required ScheduleLinearState state,
  }) {
    if (state.dateFilterActive) {
      final filtered = _activeFilteredCells(state);

      if (_accumulated) {
        return _calculateAccumulatedPercentagesFromCells(
          state: state,
          cells: filtered,
        );
      }

      return _calculatePartialPercentagesFromCells(
        state: state,
        cells: filtered,
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

  _SchedulePercentValues _calculateAccumulatedPercentagesFromCells({
    required ScheduleLinearState state,
    required List<ScheduleLinearCellData> cells,
  }) {
    final totalEsperado = state.totalEsperado;

    if (totalEsperado <= 0) {
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

    final pctConcluido = (concluido * 100.0 / totalEsperado).clamp(0.0, 100.0);
    final pctAndamento = (andamento * 100.0 / totalEsperado).clamp(0.0, 100.0);
    final pctAIniciar = (100.0 - pctConcluido - pctAndamento).clamp(0.0, 100.0);

    return _SchedulePercentValues(
      concluido: pctConcluido,
      andamento: pctAndamento,
      aIniciar: pctAIniciar,
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
    required bool accumulated,
    int? selectedYear,
    int? selectedMonth,
    int? selectedDay,
  }) {
    if (selectedYear == null) return null;

    String periodLabel;

    if (selectedMonth == null) {
      periodLabel = '$selectedYear';
    } else {
      final month = selectedMonth.toString().padLeft(2, '0');

      if (selectedDay == null) {
        periodLabel = '$month/$selectedYear';
      } else {
        final day = selectedDay.toString().padLeft(2, '0');

        periodLabel = '$day/$month/$selectedYear';
      }
    }

    if (accumulated) {
      return 'Acumulado até $periodLabel';
    }

    return periodLabel;
  }

  void _applyCurrentDateFilterOnCubit({
    required BuildContext context,
    required ScheduleLinearState state,
  }) {
    final cubit = context.read<ScheduleLinearCubit>();

    if (_selectedYear == null) {
      cubit.clearDateFilter();
      return;
    }

    final filtered = _filterCellsForCurrentSelection(
      state: state,
    );

    cubit.setDateFilter(
      cells: filtered,
      label: _dateFilterLabel(
        accumulated: _accumulated,
        selectedYear: _selectedYear,
        selectedMonth: _selectedMonth,
        selectedDay: _selectedDay,
      ),
    );
  }

  @override
  void dispose() {
    try {
      final cubit = context.read<ScheduleLinearCubit>();

      if (cubit.state.dateFilterActive) {
        cubit.clearDateFilter();
      }
    } catch (_) {
      // Evita falha caso o provider já tenha sido desmontado.
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const BackgroundChange(),
        BlocBuilder<ScheduleLinearCubit, ScheduleLinearState>(
          builder: (context, state) {
            final dateCells = _cellsWithDate(state);

            final valuesByDate = _valuesForState(
              state: state,
            );

            const labels = <String>[
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

            final fallbackTitle =
            state.summarySubjectContract?.trim().isNotEmpty == true
                ? state.summarySubjectContract!.trim()
                : widget.contract.displaySummary;

            final title = state.titleForHeader.trim().isEmpty
                ? fallbackTitle
                : state.titleForHeader;

            final activeFilteredCells = _activeFilteredCells(state);

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
                    _FilterModeBox(
                      accumulated: _accumulated,
                      enabled: widget.enabled,
                      onChanged: (value) {
                        if (!widget.enabled) return;

                        setState(() {
                          _accumulated = value;
                        });

                        _applyCurrentDateFilterOnCubit(
                          context: context,
                          state: state,
                        );
                      },
                    ),
                    const SizedBox(height: 8.0),
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

                          setState(() {
                            _selectedYear = selectedYear;
                            _selectedMonth = selectedMonth;
                            _selectedDay = selectedDay;
                          });

                          _applyCurrentDateFilterOnCubit(
                            context: context,
                            state: state,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    if (state.dateFilterActive)
                      _InfoBox(
                        message: state.dateFilterLabel == null
                            ? 'Filtro de data aplicado.'
                            : _accumulated
                            ? 'Filtro aplicado: ${state.dateFilterLabel}. ${activeFilteredCells.length} trecho(s) acumulado(s). O percentual considera o total esperado do cronograma.'
                            : 'Filtro aplicado: ${state.dateFilterLabel}. ${activeFilteredCells.length} trecho(s) encontrado(s). O percentual é parcial, considerando somente o período selecionado.',
                      ),
                  ],
                  if (dateCells.isEmpty) ...[
                    const SizedBox(height: 8.0),
                    const _InfoBox(
                      message:
                      'Nenhuma estaca concluída ou em andamento possui data registrada. O gráfico está exibindo o percentual geral do cronograma.',
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

class _FilterModeBox extends StatelessWidget {
  const _FilterModeBox({
    required this.accumulated,
    required this.enabled,
    required this.onChanged,
  });

  final bool accumulated;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: CheckboxListTile(
        value: accumulated,
        onChanged: enabled
            ? (value) {
          onChanged(value ?? false);
        }
            : null,
        dense: true,
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10.0,
          vertical: 2.0,
        ),
        title: const Text(
          'Percentual acumulado',
          style: TextStyle(
            fontSize: 13.0,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        subtitle: const Text(
          'Quando marcado, o filtro soma tudo até o período selecionado.',
          style: TextStyle(
            fontSize: 12.0,
            color: Colors.black54,
          ),
        ),
      ),
    );
  }
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
              'Atualizando dados do cronograma...',
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