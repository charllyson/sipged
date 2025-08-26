import 'package:flutter/material.dart';

class SelectorDates<T> extends StatefulWidget {
  final List<T> items;
  final DateTime? Function(T item) getDate;
  final String? Function(T item)? getLabel;
  final int? initialYear;
  final int? initialMonth;

  final void Function(List<T> filteredItems)? onFilterChanged;
  final void Function({
  List<T> filteredItems,
  int? selectedYear,
  int? selectedMonth,
  })? onSelectionChanged;

  const SelectorDates({
    super.key,
    required this.items,
    required this.getDate,
    this.getLabel,
    this.onFilterChanged,
    this.onSelectionChanged,
    this.initialYear,
    this.initialMonth,
  });

  @override
  State<SelectorDates<T>> createState() => _SelectorDatesState<T>();
}

class _SelectorDatesState<T> extends State<SelectorDates<T>> {
  final selectedYearNotifier = ValueNotifier<int?>(null);
  final selectedMonthNotifier = ValueNotifier<int?>(null);

  Map<int, List<int>> availableMonthsByYear = {};

  @override
  void initState() {
    super.initState();
    selectedYearNotifier.addListener(_aplicarFiltro);
    selectedMonthNotifier.addListener(_aplicarFiltro);

    _calcularMesesDisponiveis();
    _initSelection(); // <- define ano/mês iniciais
  }

  @override
  void didUpdateWidget(covariant SelectorDates<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    final itemsChanged = !identical(widget.items, oldWidget.items);
    final initChanged  = widget.initialYear != oldWidget.initialYear ||
        widget.initialMonth != oldWidget.initialMonth;

    if (itemsChanged) {
      _calcularMesesDisponiveis();
    }

    if (initChanged) {
      // AQUI: aplica exatamente o que veio do pai (pode ser null => "Todos")
      selectedYearNotifier.value  = widget.initialYear;
      selectedMonthNotifier.value = widget.initialMonth;
      // _aplicarFiltro será chamado pelos listeners dos notifiers
      return;
    }

    if (itemsChanged) {
      // itens mudaram mas ano/mês não; reexecuta filtro com seleção atual
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _aplicarFiltro();
      });
    }
  }


  @override
  void dispose() {
    selectedYearNotifier.dispose();
    selectedMonthNotifier.dispose();
    super.dispose();
  }

  void _calcularMesesDisponiveis() {
    availableMonthsByYear = {};
    for (final item in widget.items) {
      final date = widget.getDate(item);
      if (date != null) {
        final y = date.year, m = date.month;
        final list = availableMonthsByYear.putIfAbsent(y, () => <int>[]);
        if (!list.contains(m)) list.add(m);
      }
    }
    // meses em ordem DESC (Dez..Jan) para mostrar os mais recentes primeiro
    for (final y in availableMonthsByYear.keys) {
      availableMonthsByYear[y]!.sort((a, b) => b.compareTo(a));
    }
  }

  void _initSelection() {
    final years = availableMonthsByYear.keys.toList()..sort((a, b) => b.compareTo(a)); // DESC
    int? year = widget.initialYear;
    int? month = widget.initialMonth;

    // fallback do ano: atual se existir, senão o mais recente disponível
    final nowYear = DateTime.now().year;
    if (year == null) {
      if (availableMonthsByYear.containsKey(nowYear)) {
        year = nowYear;
      } else if (years.isNotEmpty) {
        year = years.first; // maior ano disponível
      }
    } else if (!availableMonthsByYear.containsKey(year)) {
      // inicial inválido -> mesmo fallback
      if (availableMonthsByYear.containsKey(nowYear)) {
        year = nowYear;
      } else if (years.isNotEmpty) {
        year = years.first;
      } else {
        year = null; // sem dados
      }
    }

    // fallback do mês: só se o ano for válido e o mês existir
    if (year != null) {
      final months = availableMonthsByYear[year] ?? const <int>[];
      if (month == null || !months.contains(month)) {
        month = null; // começa em "Todos os meses" para o ano escolhido
      }
    } else {
      month = null;
    }

    selectedYearNotifier.value = year;
    selectedMonthNotifier.value = month;
  }

  void _aplicarFiltro() {
    final selectedYear = selectedYearNotifier.value;
    final selectedMonth = selectedMonthNotifier.value;

    final filtered = widget.items.where((item) {
      final date = widget.getDate(item);
      if (date == null) return false;
      final matchYear = selectedYear == null || date.year == selectedYear;
      final matchMonth = selectedMonth == null || date.month == selectedMonth;
      return matchYear && matchMonth;
    }).toList();

    widget.onFilterChanged?.call(filtered);
    widget.onSelectionChanged?.call(
      selectedYear: selectedYear,
      selectedMonth: selectedMonth,
      filteredItems: filtered,
    );
  }

  @override
  Widget build(BuildContext context) {
    final years = availableMonthsByYear.keys.toList()..sort((a, b) => b.compareTo(a));
    final selectedYear = selectedYearNotifier.value;
    final selectedMonth = selectedMonthNotifier.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // anos
        Row(
          children: [
            _buildSelectorAllDatesButton(
              label: 'Todos os anos',
              selected: selectedYear == null,
              onTap: () {
                selectedYearNotifier.value = null;
                selectedMonthNotifier.value = null;
              },
            ),
            ...years.map((y) => _buildSelectorButton(
              label: y.toString(),
              selected: y == selectedYear,
              onTap: () {
                selectedYearNotifier.value = y;
                selectedMonthNotifier.value = null;
              },
            )),
          ],
        ),
        const SizedBox(height: 8),
        // meses
        if (selectedYear != null)
          Row(
            children: [
              _buildSelectorAllDatesButton(
                label: 'Todos os meses',
                selected: selectedMonth == null,
                onTap: () => selectedMonthNotifier.value = null,
              ),
              ...?availableMonthsByYear[selectedYear]?.map(
                    (month) => _buildSelectorButton(
                  label: _nomeMes(month),
                  selected: month == selectedMonth,
                  onTap: () => selectedMonthNotifier.value = month,
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
