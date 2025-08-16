import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';

import '../../../../_blocs/sectors/transit/infractions/infractions_bloc.dart';
import '../../../../_datas/sectors/transit/infractions/infractions_data.dart';

class InfractionsController extends ChangeNotifier {
  final bloc = InfractionsBloc();

  // ---- ESTADO BASE ----
  bool isEditable = true;
  bool formValidated = false;
  bool isSaving = false;

  String? currentInfractionId;
  InfractionsData? selectedInfraction;

  // ---- FILTROS (SelectorDates) ----
  int? selectedYear;   // null = todos os anos
  int? selectedMonth;  // 1..12 ou null (todos)

  // ---- PAGINAÇÃO ----
  final int _itemsPerPage = 50;
  int currentPage = 1;
  int totalPages = 1;

  // ---- DADOS ----
  List<InfractionsData> _allUniverse = []; // universo completo (todos os anos)
  List<InfractionsData> get selectorUniverseAll => _allUniverse; // usar no SelectorDates
  List<InfractionsData> _filtered = [];     // após filtros (ano/mês)
  List<InfractionsData> pageItems = [];     // fatia da página atual

  // ---- FLAGS ----
  bool isFiltering = false; // evita concorrência ao filtrar
  bool isPaging = false;    // evita “passa e volta”
  bool _didInit = false;    // evita init duplicado

  // ---- CONTROLLERS (FORM) ----
  final orderCtrl = TextEditingController();
  final aitNumberCtrl = TextEditingController();
  final dateCtrl = TextEditingController(); // dd/MM/yyyy
  final timeCtrl = TextEditingController(); // HH:mm
  final codeCtrl = TextEditingController();
  final descriptionCtrl = TextEditingController();
  final organCodeCtrl = TextEditingController();
  final organAuthorityCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final bairroCtrl = TextEditingController();
  final latitudeCtrl = TextEditingController();
  final longitudeCtrl = TextEditingController();

  DateTime? _dateValue; // valor real de data/hora

  // ====================== LIFECYCLE ======================
  Future<void> postFrameInit(BuildContext context) async {
    if (_didInit) return;
    _didInit = true;

    // Carrega universo completo (todos os anos) uma única vez
    await _loadAllYearsUniverse();

    // Define filtros iniciais: ano mais recente existente (ou ano atual)
    final yearsInData = _allUniverse
        .map((e) => e.dateInfraction?.year)
        .whereType<int>()
        .toList()
      ..sort((a, b) => b.compareTo(a)); // desc
    selectedYear = yearsInData.isNotEmpty ? yearsInData.first : DateTime.now().year;
    selectedMonth = null;

    // Aplica filtro inicial (resetando para pág. 1)
    await applyDateFilter(
      year: selectedYear,
      month: selectedMonth,
      resetToFirstPage: true,
      source: 'init',
    );
  }

  Future<void> _loadAllYearsUniverse() async {
    final containers = await bloc.listYearContainers();
    final years = containers
        .map((c) => (c.data()['year'] ?? 0) as int)
        .where((y) => y > 0)
        .toList()
      ..sort(); // ordem crescente; a ordenação final virá depois
    final lists = await Future.wait(years.map((y) => bloc.getInfractionsByYear(y)));
    _allUniverse = lists.expand((l) => l).toList();
  }

  Future<void> _reloadAllUniverse() async {
    await _loadAllYearsUniverse();
  }

  @override
  void dispose() {
    for (final c in [
      orderCtrl, aitNumberCtrl, dateCtrl, timeCtrl, codeCtrl, descriptionCtrl,
      organCodeCtrl, organAuthorityCtrl, addressCtrl, bairroCtrl,
      latitudeCtrl, longitudeCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ================= FILTRO + PAGINAÇÃO =================
  Future<void> applyDateFilter({
    int? year,
    int? month,
    bool resetToFirstPage = false, // padrão: manter página
    String source = '?',           // logs/controle
  }) async {
    if (isFiltering) return;

    final targetYear = year;   // aceita null (todos os anos)
    final targetMonth = month; // aceita null (todos os meses)
    final sameFilters = (targetYear == selectedYear) && (targetMonth == selectedMonth);

    const trustedResetSources = {'init', 'selector', 'changeYear', 'changeMonth'};
    if (isPaging) resetToFirstPage = false; // não reseta durante paginação
    final allowReset = resetToFirstPage && trustedResetSources.contains(source);
    if (!allowReset) resetToFirstPage = false;

    if (sameFilters && !allowReset) {
      debugPrint('[infractions/apply/$source] Ignorado: filtros iguais (y=$targetYear m=$targetMonth).');
      return;
    }

    isFiltering = true;
    notifyListeners();

    try {
      final oldPage = currentPage;
      selectedYear = targetYear;
      selectedMonth = targetMonth;

      debugPrint('[infractions/apply/$source] START y=$selectedYear m=$selectedMonth reset=$resetToFirstPage (isPaging=$isPaging) oldPage=$oldPage');

      // Filtra EM MEMÓRIA a partir do universo completo
      _filtered = _allUniverse.where((i) {
        final d = i.dateInfraction;
        if (d == null) return false;
        if (selectedYear != null && d.year != selectedYear) return false;
        if (selectedMonth != null && d.month != selectedMonth) return false;
        return true;
      }).toList();

      // Ordenação: orderInfraction asc, fallback por data asc
      _filtered.sort((a, b) {
        final ao = a.orderInfraction ?? 0;
        final bo = b.orderInfraction ?? 0;
        if (ao != bo) return ao.compareTo(bo);
        final ad = a.dateInfraction?.millisecondsSinceEpoch ?? 0;
        final bd = b.dateInfraction?.millisecondsSinceEpoch ?? 0;
        return ad.compareTo(bd);
      });

      // Recalcula total/página
      final totalDocs = _filtered.length;
      totalPages = totalDocs == 0 ? 1 : ((totalDocs + _itemsPerPage - 1) ~/ _itemsPerPage);

      if (allowReset) {
        currentPage = 1;
      } else {
        if (currentPage > totalPages) currentPage = totalPages;
        if (currentPage < 1) currentPage = 1;
      }

      _slicePage();

      // Sugestão de 'order' e data padrão apenas quando reseta
      if (allowReset) {
        final nextOrder = (_filtered.map((e) => e.orderInfraction ?? 0).fold<int>(0, (a, b) => a > b ? a : b)) + 1;
        orderCtrl.text = nextOrder.toString();
        dateCtrl.text = _formatDateUI(DateTime.now());
        timeCtrl.text = _formatTimeUI(DateTime.now());
      }

      debugPrint('[infractions/apply/$source] DONE -> page=$currentPage total=$totalPages items=${pageItems.length}');
    } finally {
      isFiltering = false;
      notifyListeners();
    }
  }

  void _slicePage() {
    if (_filtered.isEmpty) {
      pageItems = [];
      return;
    }
    final start = (currentPage - 1) * _itemsPerPage;
    final end = (start + _itemsPerPage) > _filtered.length ? _filtered.length : (start + _itemsPerPage);
    pageItems = _filtered.sublist(start, end);
  }

  Future<void> loadPage(int page) async {
    if (isPaging) return;
    if (page < 1 || page > totalPages) return;

    isPaging = true;
    notifyListeners();
    try {
      final prev = currentPage;
      currentPage = page;
      _slicePage();
      debugPrint('[infractions/page] $prev -> $currentPage (items=${pageItems.length})');
    } finally {
      isPaging = false;
      notifyListeners();
    }
  }

  // Helpers para UI (mudança de filtros pelo usuário)
  Future<void> changeYear(int? year) async {
    await applyDateFilter(year: year, month: selectedMonth, resetToFirstPage: true, source: 'changeYear');
  }

  Future<void> changeMonth(int? month) async {
    await applyDateFilter(year: selectedYear, month: month, resetToFirstPage: true, source: 'changeMonth');
  }

  // ===================== TABLE -> FORM =====================
  void selectFromTable(InfractionsData item, int indexInPage) {
    selectedInfraction = item;
    currentInfractionId = item.id;

    orderCtrl.text = (item.orderInfraction ?? '').toString();
    aitNumberCtrl.text = item.aitNumber ?? '';

    _dateValue = item.dateInfraction;
    dateCtrl.text = _formatDateUI(_dateValue);
    timeCtrl.text = _formatTimeUI(_dateValue);

    codeCtrl.text = item.codeInfraction ?? '';
    descriptionCtrl.text = item.descriptionInfraction ?? '';
    organCodeCtrl.text = item.organCode ?? '';
    organAuthorityCtrl.text = item.organAuthority ?? '';
    addressCtrl.text = item.addressInfraction ?? '';
    bairroCtrl.text = item.bairro ?? '';
    latitudeCtrl.text = (item.latitude?.toString() ?? '');
    longitudeCtrl.text = (item.longitude?.toString() ?? '');

    notifyListeners();
  }

  Future<void> createNew() async {
    selectedInfraction = null;
    currentInfractionId = null;
    _dateValue = null;

    for (final c in [
      orderCtrl, aitNumberCtrl, dateCtrl, timeCtrl, codeCtrl, descriptionCtrl,
      organCodeCtrl, organAuthorityCtrl, addressCtrl, bairroCtrl,
      latitudeCtrl, longitudeCtrl,
    ]) {
      c.clear();
    }

    final nextOrder = (_filtered.map((e) => e.orderInfraction ?? 0).fold<int>(0, (a, b) => a > b ? a : b)) + 1;
    orderCtrl.text = nextOrder.toString();
    dateCtrl.text = _formatDateUI(DateTime.now());
    timeCtrl.text = _formatTimeUI(DateTime.now());

    notifyListeners();
  }

  // ================== SAVE / DELETE ==================
  Future<void> saveOrUpdate(BuildContext context) async {
    isSaving = true;
    notifyListeners();

    try {
      final data = _formToModel();
      data.id = currentInfractionId;

      final targetYear = data.dateInfraction?.year;
      if (targetYear == null) {
        _snack(context, 'Informe a data da infração (não foi possível determinar o ano).');
        return;
      }

      await bloc.salvarOuAtualizarInfracao(year: targetYear, data: data);

      // Recarrega universo completo e mantém página/filtros
      await _reloadAllUniverse();
      await applyDateFilter(
        year: selectedYear,
        month: selectedMonth,
        resetToFirstPage: false,
        source: 'save',
      );

      _snack(context, 'Infração salva com sucesso.');
      formValidated = true;
      await createNew();
    } catch (e) {
      _snack(context, 'Erro ao salvar: $e');
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<void> deleteInfraction(BuildContext context, String id) async {
    isSaving = true;
    notifyListeners();

    try {
      // tenta descobrir o ano no universo completo (mais garantido)
      final item = _allUniverse.firstWhere(
            (e) => e.id == id,
        orElse: () => InfractionsData(id: id),
      );
      final targetYear = item.dateInfraction?.year ?? selectedYear;

      if (targetYear == null) {
        _snack(context, 'Não foi possível determinar o ano do registro para excluir.');
        return;
      }

      await bloc.deleteInfraction(year: targetYear, recordId: id);

      // Recarrega universo e reaplica filtro mantendo página
      await _reloadAllUniverse();
      await applyDateFilter(
        year: selectedYear,
        month: selectedMonth,
        resetToFirstPage: false,
        source: 'delete',
      );

      _snack(context, 'Infração removida.');
      if (currentInfractionId == id) await createNew();
    } catch (e) {
      _snack(context, 'Erro ao remover: $e');
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  // ===================== HELPERS =====================
  InfractionsData _formToModel() {
    DateTime? baseDate = _dateValue ?? _parseDate(dateCtrl.text);
    final tod = _parseTimeOfDay(timeCtrl.text);
    if (baseDate != null && tod != null) {
      baseDate = DateTime(baseDate.year, baseDate.month, baseDate.day, tod.hour, tod.minute);
    }

    return InfractionsData(
      id: currentInfractionId,
      orderInfraction: int.tryParse(orderCtrl.text.trim()),
      aitNumber: _emptyToNull(aitNumberCtrl.text),
      dateInfraction: baseDate,
      codeInfraction: _emptyToNull(codeCtrl.text),
      descriptionInfraction: _emptyToNull(descriptionCtrl.text),
      organCode: _emptyToNull(organCodeCtrl.text),
      organAuthority: _emptyToNull(organAuthorityCtrl.text),
      addressInfraction: _emptyToNull(addressCtrl.text),
      bairro: _emptyToNull(bairroCtrl.text),
      latitude: _parseDouble(latitudeCtrl.text),
      longitude: _parseDouble(longitudeCtrl.text),
    );
  }

  String _formatDateUI(DateTime? dt) {
    if (dt == null) return '';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)}/${two(dt.month)}/${dt.year}';
  }

  String _formatTimeUI(DateTime? dt) {
    if (dt == null) return '';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.hour)}:${two(dt.minute)}';
  }

  DateTime? _parseDate(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return null;

    final m1 = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(s);
    if (m1 != null) {
      final d = int.parse(m1.group(1)!);
      final mo = int.parse(m1.group(2)!);
      final y = int.parse(m1.group(3)!);
      return DateTime(y, mo, d);
    }

    final m2 = RegExp(r'^(\d{4})-(\d{2})-(\d{2})(?:[ T](\d{2}):(\d{2})(?::(\d{2}))?)?$').firstMatch(s);
    if (m2 != null) {
      final y = int.parse(m2.group(1)!);
      final mo = int.parse(m2.group(2)!);
      final d = int.parse(m2.group(3)!);
      if (m2.group(4) != null) {
        final h = int.parse(m2.group(4)!);
        final mi = int.parse(m2.group(5)!);
        final se = int.tryParse(m2.group(6) ?? '0') ?? 0;
        return DateTime(y, mo, d, h, mi, se);
      }
      return DateTime(y, mo, d);
    }

    return DateTime.tryParse(s);
  }

  TimeOfDay? _parseTimeOfDay(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return null;
    final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(s);
    if (m == null) return null;
    int h = int.parse(m.group(1)!);
    int mi = int.parse(m.group(2)!);
    if (h < 0 || h > 23 || mi < 0 || mi > 59) return null;
    return TimeOfDay(hour: h, minute: mi);
  }

  double? _parseDouble(String text) {
    final t = text.replaceAll(',', '.').trim();
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  String? _emptyToNull(String? s) {
    if (s == null) return null;
    final t = s.trim();
    return t.isEmpty ? null : t;
  }

  Future<bool> confirm(BuildContext context, String message) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmação'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Não')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sim')),
        ],
      ),
    );
    return res ?? false;
  }

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ========== GEOLOCALIZAÇÃO ==========
  Future<void> fillFromUserLocation(BuildContext context) async {
    try {
      // Permissões
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _snack(context, 'Permissão de localização negada.');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _snack(context, 'Permissão de localização negada permanentemente.');
        return;
      }

      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
      latitudeCtrl.text = pos.latitude.toStringAsFixed(6);
      longitudeCtrl.text = pos.longitude.toStringAsFixed(6);

      // Reverse geocoding
      final placemarks = await geo.placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        addressCtrl.text = [
          if ((p.street ?? '').isNotEmpty) p.street,
          if ((p.subLocality ?? '').isNotEmpty) p.subLocality,
          if ((p.locality ?? '').isNotEmpty) p.locality,
          if ((p.administrativeArea ?? '').isNotEmpty) p.administrativeArea,
        ].whereType<String>().join(', ');
        bairroCtrl.text = (p.subLocality ?? '');
      }

      notifyListeners();
    } catch (e) {
      _snack(context, 'Falha ao obter localização: $e');
    }
  }
}
