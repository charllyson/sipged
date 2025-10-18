import 'dart:async';
import 'package:flutter/material.dart';

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
  })? onSelectionChanged;

  /// Controla a ordenação dos itens filtrados
  final bool sortByDate;          // ordena por data?
  final bool sortDescending;      // true = mais recente primeiro

  const SelectorDates({
    super.key,
    required this.items,
    required this.getDate,
    this.getLabel,
    this.onFilterChanged,
    this.onSelectionChanged,
    this.initialYear,
    this.initialMonth,
    this.sortByDate = true,        // padrão: ordenar
    this.sortDescending = false,   // padrão: cronológico (antigo → recente)
  });

  @override
  State<SelectorDates<T>> createState() => _SelectorDatesState<T>();
}

class _SelectorDatesState<T> extends State<SelectorDates<T>> {
  final selectedYearNotifier  = ValueNotifier<int?>(null);
  final selectedMonthNotifier = ValueNotifier<int?>(null);

  Map<int, List<int>> availableMonthsByYear = {};
  Timer? _applyDebounce;

  /// Saber se antes havia dados; usado para detectar a 1ª chegada (vazio → não-vazio)
  bool _hadData = false;

  void _scheduleApply() {
    _applyDebounce?.cancel();
    // Executa no mesmo ciclo de eventos, coalescendo múltiplas mudanças
    _applyDebounce = Timer(const Duration(milliseconds: 0), _aplicarFiltro);
  }

  @override
  void initState() {
    super.initState();
    _hadData = widget.items.isNotEmpty;
    _calcularMesesDisponiveis();
    _initSelection(); // monta com o que tiver (pode estar vazio)
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

    // Detecta primeira carga (antes vazio, agora com dados)
    final had = _hadData;
    final has = widget.items.isNotEmpty;
    _hadData = has;

    if (itemsChanged) {
      _calcularMesesDisponiveis();
    }

    if (!had && has) {
      // Primeira chegada de dados: redecide seleção (preferir ano atual)
      _reinitSelectionAfterFirstData();
      return;
    }

    if (initChanged) {
      // Pai passou explicitamente novos iniciais — respeite
      selectedYearNotifier.value  = widget.initialYear;
      selectedMonthNotifier.value = widget.initialMonth;
      _scheduleApply();
      return;
    }

    if (itemsChanged) {
      // Reaplica com a seleção atual
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
    super.dispose();
  }

  void _calcularMesesDisponiveis() {
    availableMonthsByYear = {};
    for (final item in widget.items) {
      final date = widget.getDate(item);
      if (date == null) continue;
      final y = date.year, m = date.month;
      final list = availableMonthsByYear.putIfAbsent(y, () => <int>[]);
      if (!list.contains(m)) list.add(m);
    }
    // Meses em ordem DESC (Dez..Jan) para mostrar recentes primeiro
    for (final y in availableMonthsByYear.keys) {
      availableMonthsByYear[y]!.sort((a, b) => b.compareTo(a));
    }
  }

  /// Primeira definição de seleção (pode ainda não haver dados)
  void _initSelection() {
    final nowYear      = DateTime.now().year;
    final allYearsDesc = availableMonthsByYear.keys.toList()..sort((a, b) => b.compareTo(a));

    // 1) Começa pelo initialYear do pai, ou ano atual se nulo
    int? year  = widget.initialYear ?? nowYear;
    int? month = widget.initialMonth;

    // 2) Se o ano não possui dados (ou lista vazia), cai para o mais recente com dados
    if (!availableMonthsByYear.containsKey(year)) {
      year = allYearsDesc.isNotEmpty ? allYearsDesc.first : null;
    }

    // 3) Mês: válido ou "Todos os meses"
    if (year != null) {
      final months = availableMonthsByYear[year] ?? const <int>[];
      if (month == null || !months.contains(month)) {
        month = null;
      }
    } else {
      month = null;
    }

    selectedYearNotifier.value  = year;
    selectedMonthNotifier.value = month;
    _scheduleApply();
  }

  /// Recalcula a seleção preferindo o ano atual na 1ª chegada de dados
  void _reinitSelectionAfterFirstData() {
    final nowYear      = DateTime.now().year;
    final allYearsDesc = availableMonthsByYear.keys.toList()..sort((a, b) => b.compareTo(a));

    int? year  = widget.initialYear;
    int? month = widget.initialMonth;

    // Preferir agora o ano atual se não veio do pai
    year ??= availableMonthsByYear.containsKey(nowYear) ? nowYear : null;

    // Se continuar nulo/indisponível, cai para o mais recente com dados
    if (year == null || !availableMonthsByYear.containsKey(year)) {
      year = allYearsDesc.isNotEmpty ? allYearsDesc.first : null;
    }

    if (year != null) {
      final months = availableMonthsByYear[year] ?? const <int>[];
      if (month == null || !months.contains(month)) month = null;
    } else {
      month = null;
    }

    selectedYearNotifier.value  = year;
    selectedMonthNotifier.value = month;
    _scheduleApply();
  }

  void _aplicarFiltro() {
    int? selectedYear  = selectedYearNotifier.value;
    int? selectedMonth = selectedMonthNotifier.value;

    // Se ano selecionado ficou inválido após mudança dos itens, ajusta
    if (selectedYear != null && !availableMonthsByYear.containsKey(selectedYear)) {
      final allYearsDesc = availableMonthsByYear.keys.toList()..sort((a, b) => b.compareTo(a));
      selectedYear = allYearsDesc.isNotEmpty ? allYearsDesc.first : null;
      selectedYearNotifier.value  = selectedYear;
      selectedMonth               = null;
      selectedMonthNotifier.value = null;
    }

    final filtered = widget.items.where((item) {
      final date = widget.getDate(item);
      if (date == null) return false;
      final okYear  = selectedYear  == null || date.year  == selectedYear;
      final okMonth = selectedMonth == null || date.month == selectedMonth;
      return okYear && okMonth;
    }).toList();

    // Ordenação por data (cronológica por padrão)
    if (widget.sortByDate) {
      filtered.sort((a, b) {
        final da = widget.getDate(a);
        final db = widget.getDate(b);
        if (da == null && db == null) return 0;
        if (da == null) return 1;  // nulos por último
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final years         = availableMonthsByYear.keys.toList()..sort((a, b) => b.compareTo(a));
    final selectedYear  = selectedYearNotifier.value;
    final selectedMonth = selectedMonthNotifier.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ===== ANOS =====
        Row(
          children: [
            _buildSelectorAllDatesButton(
              label: 'Todos os anos',
              selected: selectedYear == null,
              onTap: () {
                selectedYearNotifier.value  = null;
                selectedMonthNotifier.value = null;
                _scheduleApply();
              },
            ),
            ...years.map(
                  (y) => _buildSelectorButton(
                label: y.toString(),
                selected: y == selectedYear,
                onTap: () {
                  selectedYearNotifier.value  = y;
                  selectedMonthNotifier.value = null;
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
                label: 'Todos os meses',
                selected: selectedMonth == null,
                onTap: () {
                  selectedMonthNotifier.value = null;
                  _scheduleApply();
                },
              ),
              ...?availableMonthsByYear[selectedYear]?.map(
                    (month) => _buildSelectorButton(
                  label: _nomeMes(month),
                  selected: month == selectedMonth,
                  onTap: () {
                    selectedMonthNotifier.value = month;
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
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 70,
          height: 54,
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            color: selected ? Colors.blue.shade100 : Colors.white,
            child: Center(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: selected ? Colors.blue : Colors.black,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectorAllDatesButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 130,
          height: 54,
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            color: selected ? Colors.blue.shade100 : Colors.white,
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: selected ? Colors.blue : Colors.black,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _nomeMes(int mes) {
    const nomes = ['Jan','Fev','Mar','Abr','Mai','Jun','Jul','Ago','Set','Out','Nov','Dez'];
    return nomes[mes - 1];
  }
}
