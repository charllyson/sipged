// lib/_widgets/dates/selector/selectorDates.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sipged/_widgets/cards/basic/basic_card.dart';

class SelectorDates<T> extends StatefulWidget {
  final List<T> items;
  final DateTime? Function(T item) getDate;
  final String? Function(T item)? getLabel;
  final int? initialYear;
  final int? initialMonth;

  final void Function(List<T> filteredItems)? onFilterChanged;
  final void Function({
  required List<T> filteredItems,
  int? selectedYear,
  int? selectedMonth,
  int? selectedDay,
  })? onSelectionChanged;

  /// Controla a ordenação dos itens filtrados
  final bool sortByDate;     // ordena por data?
  final bool sortDescending; // true = mais recente primeiro

  /// Se false, não escolhe ano/mês sozinho nem aplica filtro no init.
  final bool autoSelectInitial;

  /// Se true, exibe a 3ª linha com os dias do mês selecionado.
  final bool enableDaySelection;

  const SelectorDates({
    super.key,
    required this.items,
    required this.getDate,
    this.getLabel,
    this.onFilterChanged,
    this.onSelectionChanged,
    this.initialYear,
    this.initialMonth,
    this.sortByDate = true,
    this.sortDescending = false,
    this.autoSelectInitial = true,
    this.enableDaySelection = false,
  });

  @override
  State<SelectorDates<T>> createState() => _SelectorDatesState<T>();
}

class _SelectorDatesState<T> extends State<SelectorDates<T>> {
  final selectedYearNotifier  = ValueNotifier<int?>(null);
  final selectedMonthNotifier = ValueNotifier<int?>(null);
  final selectedDayNotifier   = ValueNotifier<int?>(null);

  /// ano -> lista de meses com dados
  Map<int, List<int>> availableMonthsByYear = {};

  /// ano -> (mês -> lista de dias com dados)
  Map<int, Map<int, List<int>>> availableDaysByYearMonth = {};

  Timer? _applyDebounce;

  /// Saber se antes havia dados; usado para detectar a 1ª chegada (vazio → não-vazio)
  bool _hadData = false;

  void _scheduleApply() {
    _applyDebounce?.cancel();
    _applyDebounce = Timer(const Duration(milliseconds: 0), _aplicarFiltro);
  }

  @override
  void initState() {
    super.initState();
    _hadData = widget.items.isNotEmpty;
    _calcularMesesEDiasDisponiveis();

    if (widget.autoSelectInitial) {
      _initSelection();
    } else {
      selectedYearNotifier.value  = widget.initialYear;
      selectedMonthNotifier.value = widget.initialMonth;
      selectedDayNotifier.value   = null;
    }
  }

  @override
  void didUpdateWidget(covariant SelectorDates<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    final itemsChanged =
        !identical(widget.items, oldWidget.items) ||
            widget.items.length != oldWidget.items.length;

    final initChanged =
        widget.initialYear  != oldWidget.initialYear ||
            widget.initialMonth != oldWidget.initialMonth;

    // Se não queremos auto-seleção, simplificamos bastante:
    if (!widget.autoSelectInitial) {
      if (itemsChanged) {
        _calcularMesesEDiasDisponiveis();
      }

      if (initChanged) {
        selectedYearNotifier.value  = widget.initialYear;
        selectedMonthNotifier.value = widget.initialMonth;
        selectedDayNotifier.value   = null;
      }
      return;
    }

    // === Fluxo antigo (autoSelectInitial = true) ===

    final had = _hadData;
    final has = widget.items.isNotEmpty;
    _hadData = has;

    if (itemsChanged) {
      _calcularMesesEDiasDisponiveis();
    }

    if (!had && has) {
      // Primeira chegada de dados: redecide seleção (preferir ano atual)
      _reinitSelectionAfterFirstData();
      return;
    }

    if (initChanged) {
      selectedYearNotifier.value  = widget.initialYear;
      selectedMonthNotifier.value = widget.initialMonth;
      selectedDayNotifier.value   = null;
      _scheduleApply();
      return;
    }

    if (itemsChanged) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _aplicarFiltro();
      });
    }
  }

  @override
  void dispose() {
    _applyDebounce?.cancel();
    selectedYearNotifier.dispose();
    selectedMonthNotifier.dispose();
    selectedDayNotifier.dispose();
    super.dispose();
  }

  void _calcularMesesEDiasDisponiveis() {
    availableMonthsByYear = {};
    availableDaysByYearMonth = {};

    for (final item in widget.items) {
      final date = widget.getDate(item);
      if (date == null) continue;

      final y = date.year;
      final m = date.month;
      final d = date.day;

      // Meses por ano
      final meses = availableMonthsByYear.putIfAbsent(y, () => <int>[]);
      if (!meses.contains(m)) meses.add(m);

      // Dias por ano/mês
      final mesesMap =
      availableDaysByYearMonth.putIfAbsent(y, () => <int, List<int>>{});
      final dias = mesesMap.putIfAbsent(m, () => <int>[]);
      if (!dias.contains(d)) dias.add(d);
    }

    for (final y in availableMonthsByYear.keys) {
      availableMonthsByYear[y]!.sort((a, b) => b.compareTo(a)); // meses desc
    }

    for (final entryYear in availableDaysByYearMonth.entries) {
      for (final entryMonth in entryYear.value.entries) {
        entryMonth.value.sort((a, b) => a.compareTo(b)); // dias asc
      }
    }
  }

  /// Primeira definição de seleção (modo auto)
  void _initSelection() {
    final now      = DateTime.now();
    final nowYear  = now.year;
    final nowMonth = now.month;
    final nowDay   = now.day;

    final allYearsDesc = availableMonthsByYear.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    int? year  = widget.initialYear ?? nowYear;
    int? month = widget.initialMonth ?? nowMonth;
    int? day;

    if (!availableMonthsByYear.containsKey(year)) {
      year = allYearsDesc.isNotEmpty ? allYearsDesc.first : null;
    }

    if (year != null) {
      final months = availableMonthsByYear[year] ?? const <int>[];
      if (!months.contains(month)) {
        // se não tiver mês inicial válido, deixa null
        month = null;
      }
    } else {
      month = null;
    }

    // Se habilitado dia, tenta selecionar o dia atual, se disponível
    if (widget.enableDaySelection && year != null && month != null) {
      final dias = availableDaysByYearMonth[year]?[month] ?? const <int>[];
      if (dias.contains(nowDay)) {
        day = nowDay;
      }
    }

    selectedYearNotifier.value  = year;
    selectedMonthNotifier.value = month;
    selectedDayNotifier.value   = day;
    _scheduleApply();
  }

  /// Recalcula a seleção preferindo o ano atual na 1ª chegada de dados (modo auto)
  void _reinitSelectionAfterFirstData() {
    final now      = DateTime.now();
    final nowYear  = now.year;
    final nowMonth = now.month;
    final nowDay   = now.day;

    final allYearsDesc = availableMonthsByYear.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    int? year  = widget.initialYear;
    int? month = widget.initialMonth;
    int? day;

    year ??= availableMonthsByYear.containsKey(nowYear) ? nowYear : null;

    if (year == null || !availableMonthsByYear.containsKey(year)) {
      year = allYearsDesc.isNotEmpty ? allYearsDesc.first : null;
    }

    if (year != null) {
      final months = availableMonthsByYear[year] ?? const <int>[];
      // se não tiver mês inicial válido, tenta mês atual, senão fica null
      if (month == null || !months.contains(month)) {
        month = months.contains(nowMonth) ? nowMonth : null;
      }
    } else {
      month = null;
    }

    if (widget.enableDaySelection && year != null && month != null) {
      final dias = availableDaysByYearMonth[year]?[month] ?? const <int>[];
      if (dias.contains(nowDay)) {
        day = nowDay;
      }
    }

    selectedYearNotifier.value  = year;
    selectedMonthNotifier.value = month;
    selectedDayNotifier.value   = day;
    _scheduleApply();
  }

  void _aplicarFiltro() {
    int? selectedYear  = selectedYearNotifier.value;
    int? selectedMonth = selectedMonthNotifier.value;
    int? selectedDay   = selectedDayNotifier.value;

    // Se ano selecionado ficou inválido após mudança dos itens, ajusta
    if (selectedYear != null &&
        !availableMonthsByYear.containsKey(selectedYear)) {
      final allYearsDesc = availableMonthsByYear.keys.toList()
        ..sort((a, b) => b.compareTo(a));
      selectedYear = allYearsDesc.isNotEmpty ? allYearsDesc.first : null;
      selectedYearNotifier.value  = selectedYear;
      selectedMonth               = null;
      selectedMonthNotifier.value = null;
      selectedDay                 = null;
      selectedDayNotifier.value   = null;
    }

    // Se mês ficou inválido para o ano, zera mês/dia
    if (selectedYear != null &&
        selectedMonth != null &&
        !(availableMonthsByYear[selectedYear]?.contains(selectedMonth) ?? false)) {
      selectedMonth = null;
      selectedMonthNotifier.value = null;
      selectedDay = null;
      selectedDayNotifier.value = null;
    }

    // Se dia ficou inválido para ano/mês, zera dia
    if (selectedYear != null &&
        selectedMonth != null &&
        selectedDay != null) {
      final dias = availableDaysByYearMonth[selectedYear]?[selectedMonth] ?? [];
      if (!dias.contains(selectedDay)) {
        selectedDay = null;
        selectedDayNotifier.value = null;
      }
    }

    final filtered = widget.items.where((item) {
      final date = widget.getDate(item);
      if (date == null) return false;
      final okYear  = selectedYear  == null || date.year  == selectedYear;
      final okMonth = selectedMonth == null || date.month == selectedMonth;
      final okDay   = !widget.enableDaySelection ||
          selectedDay == null ||
          date.day == selectedDay;
      return okYear && okMonth && okDay;
    }).toList();

    if (widget.sortByDate) {
      filtered.sort((a, b) {
        final da = widget.getDate(a);
        final db = widget.getDate(b);
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        final cmp = da.compareTo(db);
        return widget.sortDescending ? -cmp : cmp;
      });
    }

    widget.onFilterChanged?.call(filtered);
    widget.onSelectionChanged?.call(
      filteredItems: filtered,
      selectedYear: selectedYear,
      selectedMonth: selectedMonth,
      selectedDay: widget.enableDaySelection ? selectedDay : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final years         = availableMonthsByYear.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    final selectedYear  = selectedYearNotifier.value;
    final selectedMonth = selectedMonthNotifier.value;
    final selectedDay   = selectedDayNotifier.value;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final diasDisponiveis = (selectedYear != null && selectedMonth != null)
        ? (availableDaysByYearMonth[selectedYear]?[selectedMonth] ?? const <int>[])
        : const <int>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ===== ANOS =====
        Row(
          children: [
            _buildSelectorAllDatesButton(
              context: context,
              label: 'Todos os anos',
              selected: selectedYear == null,
              isDark: isDark,
              onTap: () {
                setState(() {
                  selectedYearNotifier.value  = null;
                  selectedMonthNotifier.value = null;
                  selectedDayNotifier.value   = null;
                });
                _scheduleApply();
              },
            ),
            ...years.map(
                  (y) => _buildSelectorButton(
                context: context,
                label: y.toString(),
                selected: y == selectedYear,
                isDark: isDark,
                onTap: () {
                  setState(() {
                    final currentYear  = selectedYearNotifier.value;
                    final currentMonth = selectedMonthNotifier.value;
                    final currentDay   = selectedDayNotifier.value;

                    // toggle: se só o ano está selecionado, desmarca
                    if (currentYear == y &&
                        currentMonth == null &&
                        currentDay == null) {
                      selectedYearNotifier.value  = null;
                      selectedMonthNotifier.value = null;
                      selectedDayNotifier.value   = null;
                    } else {
                      selectedYearNotifier.value  = y;
                      selectedMonthNotifier.value = null;
                      selectedDayNotifier.value   = null;
                    }
                  });
                  _scheduleApply();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // ===== MESES =====
        if (selectedYear != null)
          Row(
            children: [
              _buildSelectorAllDatesButton(
                context: context,
                label: 'Todos os meses',
                selected: selectedMonth == null,
                isDark: isDark,
                onTap: () {
                  setState(() {
                    selectedMonthNotifier.value = null;
                    selectedDayNotifier.value   = null;
                  });
                  _scheduleApply();
                },
              ),
              ...?availableMonthsByYear[selectedYear]?.map(
                    (month) => _buildSelectorButton(
                  context: context,
                  label: _nomeMes(month),
                  selected: month == selectedMonth,
                  isDark: isDark,
                  onTap: () {
                    setState(() {
                      final currentMonth = selectedMonthNotifier.value;
                      final currentDay   = selectedDayNotifier.value;

                      // toggle: se só mês está selecionado (sem dia), volta pra só ano
                      if (currentMonth == month && currentDay == null) {
                        selectedMonthNotifier.value = null;
                        selectedDayNotifier.value   = null;
                      } else {
                        selectedMonthNotifier.value = month;
                        selectedDayNotifier.value   = null;
                      }
                    });
                    _scheduleApply();
                  },
                ),
              ),
            ],
          ),
        const SizedBox(height: 8),
        // ===== DIAS =====
        if (widget.enableDaySelection &&
            selectedYear != null &&
            selectedMonth != null &&
            diasDisponiveis.isNotEmpty)
          Row(
            children: [
              _buildSelectorAllDatesButton(
                context: context,
                label: 'Todos os dias',
                selected: selectedDay == null,
                isDark: isDark,
                onTap: () {
                  setState(() {
                    selectedDayNotifier.value = null;
                  });
                  _scheduleApply();
                },
              ),
              ...diasDisponiveis.map(
                    (day) => _buildSelectorButton(
                  context: context,
                  label: day.toString().padLeft(2, '0'),
                  selected: day == selectedDay,
                  isDark: isDark,
                  onTap: () {
                    setState(() {
                      final currentDay = selectedDayNotifier.value;
                      // toggle: se o mesmo dia estiver selecionado, desmarca (volta pra só ano+mês)
                      if (currentDay == day) {
                        selectedDayNotifier.value = null;
                      } else {
                        selectedDayNotifier.value = day;
                      }
                    });
                    _scheduleApply();
                  },
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildSelectorButton({
    required BuildContext context,
    required String label,
    required bool selected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final Color selectedFg = selected
        ? (isDark ? const Color(0xFF90C2FF) : Colors.blue)
        : (isDark ? Colors.white : Colors.black);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 50,
          height: 40,
          child: BasicCard(
            isDark: isDark,
            borderRadius: 8,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            borderColor: selected
                ? (isDark ? Colors.blueAccent.withValues(alpha: 0.6) : Colors.blue)
                : null,
            enableShadow: false,
            child: Center(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: selectedFg,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectorAllDatesButton({
    required BuildContext context,
    required String label,
    required bool selected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final Color selectedFg = selected
        ? (isDark ? const Color(0xFF90C2FF) : Colors.blue)
        : (isDark ? Colors.white : Colors.black);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 110,
          height: 40,
          child: BasicCard(
            isDark: isDark,
            borderRadius: 8,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            borderColor: selected
                ? (isDark ? Colors.blueAccent.withValues(alpha: 0.6) : Colors.blue)
                : null,
            enableShadow: false,
            child: Center(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: selectedFg,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _nomeMes(int mes) {
    const nomes = [
      'Jan','Fev','Mar','Abr','Mai','Jun',
      'Jul','Ago','Set','Out','Nov','Dez'
    ];
    return nomes[mes - 1];
  }
}
