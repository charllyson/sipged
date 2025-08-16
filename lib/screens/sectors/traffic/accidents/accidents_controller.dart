import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../../_blocs/sectors/transit/accidents/accidents_bloc.dart';
import '../../../../_blocs/system/system_bloc.dart';
import '../../../../_blocs/system/user_bloc.dart';
import '../../../../_datas/sectors/transit/accidents/accidents_data.dart';
import '../../../../_provider/user/user_provider.dart';
import '../../../../_widgets/formats/format_field.dart';

class AccidentsController extends ChangeNotifier {
  final AccidentsBloc _accidentsBloc = AccidentsBloc();
  final SystemBloc _systemBloc = SystemBloc();
  final UserBloc _userBloc = UserBloc();

  // ---- ESTADO BASE ----
  bool isEditable = false;
  bool isSaving = false;
  bool formValidated = false;

  // ---- FILTROS (SelectorDates) ----
  int? selectedYear;
  int? selectedMonth;

  // ---- PAGINAÇÃO ----
  int currentPage = 1;
  int totalPages = 1;
  final int limitPerPage = 15;

  // ---- SELEÇÃO ----
  int? selectedLine;
  String? currentAccidentId;
  AccidentsData? selectedAccident;

  // ---- DADOS ----
  List<AccidentsData> selectorUniverse = [];   // universo para o seletor (exibição)
  List<AccidentsData> _allUniverse = [];       // universo completo (cache local)
  List<AccidentsData> _filtered = [];          // após filtros ano/mês
  List<AccidentsData> pageItems = [];          // fatia da página atual
  List<AccidentsData> allCached = [];          // compatibilidade p/ cálculo de 'order'

  // ---- FLAGS DE FLUXO ----
  bool isFiltering = false;  // carregando/filtrando
  bool isPaging = false;     // trocando de página
  bool _didInit = false;     // guard init

  // ---- CONTROLLERS ----
  final orderCtrl = TextEditingController();
  final dateCtrl = TextEditingController();
  final highwayCtrl = TextEditingController();
  final cityCtrl = TextEditingController();
  final typeOfAccidentCtrl = TextEditingController();
  final deathCtrl = TextEditingController();
  final scoresVictimsCtrl = TextEditingController();
  final transportInvolvedCtrl = TextEditingController();

  final latitudeCtrl = TextEditingController();
  final longitudeCtrl = TextEditingController();
  final postalCodeCtrl = TextEditingController();
  final streetCtrl = TextEditingController();
  final city2Ctrl = TextEditingController();
  final subLocalityCtrl = TextEditingController();
  final administrativeAreaCtrl = TextEditingController();
  final countryCtrl = TextEditingController();
  final isoCountryCodeCtrl = TextEditingController();

  // ====================== LIFECYCLE ======================
  Future<void> postFrameInit(BuildContext context) async {
    if (_didInit) return;
    _didInit = true;

    final user = Provider.of<UserProvider>(context, listen: false).userData;
    if (user != null) {
      isEditable = _userBloc.getUserCreateEditPermissions(userData: user);
    }

    // Carrega universo local uma única vez
    selectorUniverse = await _accidentsBloc.getAllAccidents();
    _allUniverse = List<AccidentsData>.from(selectorUniverse);

    // Filtros iniciais
    selectedYear = DateTime.now().year;
    selectedMonth = null;

    await applyDateFilter(
      year: selectedYear,
      month: selectedMonth,
      resetToFirstPage: true,
      source: 'init',
    );

    _attachValidation();
    notifyListeners();
  }

  @override
  void dispose() {
    for (final c in [
      orderCtrl, dateCtrl, highwayCtrl, cityCtrl, typeOfAccidentCtrl,
      deathCtrl, scoresVictimsCtrl, transportInvolvedCtrl,
      latitudeCtrl, longitudeCtrl, postalCodeCtrl, streetCtrl, city2Ctrl,
      subLocalityCtrl, administrativeAreaCtrl, countryCtrl, isoCountryCodeCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ================= FILTRO + PAGINAÇÃO =================
  Future<void> applyDateFilter({
    int? year,
    int? month,
    bool resetToFirstPage = false,
    String source = '?',
  }) async {
    if (isFiltering) return;

    // alvo EXATO que veio do seletor (pode ser null)
    final targetYear = year;
    final targetMonth = month;

    if (isPaging) resetToFirstPage = false;

    const trustedResetSources = {'init', 'selector', 'changeYear', 'changeMonth'};
    final allowReset = resetToFirstPage && trustedResetSources.contains(source);

    final sameFilters = (targetYear == selectedYear) && (targetMonth == selectedMonth);
    if (sameFilters && !allowReset) {
      return;
    }

    isFiltering = true;
    notifyListeners();

    try {
      final oldPage = currentPage;

      // >>> ACEITA NULL (Todos os anos / Todos os meses)
      selectedYear = targetYear;
      selectedMonth = targetMonth;

      // Filtra em memória
      _filtered = _allUniverse.where((a) {
        final dt = a.date;
        if (dt == null) return false;
        if (selectedYear != null && dt.year != selectedYear) return false;
        if (selectedMonth != null && dt.month != selectedMonth) return false;
        return true;
      }).toList();

      // Ordena desc por data
      _filtered.sort((a, b) {
        final ad = a.date ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bd = b.date ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bd.compareTo(ad);
      });

      allCached = _filtered;

      // Paginação
      final totalDocs = _filtered.length;
      totalPages = totalDocs == 0 ? 1 : ((totalDocs + limitPerPage - 1) ~/ limitPerPage);

      if (allowReset) {
        currentPage = 1;
      } else {
        if (currentPage > totalPages) currentPage = totalPages;
        if (currentPage < 1) currentPage = 1;
      }

      _slicePage();

      if (allowReset) {
        orderCtrl.text = _calcNextOrder(allCached).toString();
        dateCtrl.text = dateToString(DateTime.now());
      }

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
    final start = (currentPage - 1) * limitPerPage;
    final end = (start + limitPerPage) > _filtered.length ? _filtered.length : (start + limitPerPage);
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
    } finally {
      isPaging = false;
      notifyListeners();
    }
  }

  // Helpers para UI (troca de filtros pelo usuário)
  Future<void> changeYear(int? year) async {
    await applyDateFilter(year: year, month: selectedMonth, resetToFirstPage: true, source: 'changeYear');
  }

  Future<void> changeMonth(int? month) async {
    await applyDateFilter(year: selectedYear, month: month, resetToFirstPage: true, source: 'changeMonth');
  }

  int _calcNextOrder(List<AccidentsData> list) {
    return (list.map((e) => e.order ?? 0).fold(0, (a, b) => a > b ? a : b)) + 1;
    // ou: list.fold<int>(0, (acc, e) => max(acc, e.order ?? 0)) + 1;
  }

  // ===================== FORM =====================
  void _attachValidation() {
    for (final c in [cityCtrl, dateCtrl, highwayCtrl, typeOfAccidentCtrl]) {
      c.addListener(_validateForm);
    }
    _validateForm();
  }

  void _validateForm() {
    final ok = cityCtrl.text.trim().isNotEmpty &&
        dateCtrl.text.trim().isNotEmpty &&
        highwayCtrl.text.trim().isNotEmpty &&
        typeOfAccidentCtrl.text.trim().isNotEmpty;
    if (formValidated != ok) {
      formValidated = ok;
      notifyListeners();
    }
  }

  void fillFields(AccidentsData data) {
    selectedAccident = data;
    currentAccidentId = data.id;

    cityCtrl.text = data.city ?? '';
    dateCtrl.text = data.date != null ? dateToString(data.date!) : '';
    deathCtrl.text = (data.death ?? 0).toString();
    highwayCtrl.text = data.highway ?? '';
    scoresVictimsCtrl.text = (data.scoresVictims ?? 0).toString();
    transportInvolvedCtrl.text = data.transportInvolved ?? '';
    typeOfAccidentCtrl.text = data.typeOfAccident ?? '';

    latitudeCtrl.text = data.latLng?.latitude.toString() ?? '';
    longitudeCtrl.text = data.latLng?.longitude.toString() ?? '';
    postalCodeCtrl.text = data.postalCode ?? '';
    streetCtrl.text = data.street ?? '';
    city2Ctrl.text = data.city ?? '';
    subLocalityCtrl.text = data.subLocality ?? '';
    administrativeAreaCtrl.text = data.administrativeArea ?? '';
    countryCtrl.text = data.country ?? '';
    isoCountryCodeCtrl.text = data.isoCountryCode ?? '';

    orderCtrl.text = (data.order ?? '').toString();

    _validateForm();
    notifyListeners();
  }

  Future<void> createNew() async {
    selectedLine = null;
    currentAccidentId = null;
    selectedAccident = null;

    orderCtrl.text = _calcNextOrder(allCached).toString();

    for (final c in [
      dateCtrl, deathCtrl, highwayCtrl, scoresVictimsCtrl, transportInvolvedCtrl,
      typeOfAccidentCtrl, latitudeCtrl, longitudeCtrl, postalCodeCtrl, streetCtrl,
      cityCtrl, city2Ctrl, subLocalityCtrl, administrativeAreaCtrl, countryCtrl, isoCountryCodeCtrl,
    ]) {
      c.clear();
    }
    dateCtrl.text = dateToString(DateTime.now());

    _validateForm();
    notifyListeners();
  }

  // ================== SAVE / DELETE ==================
  Future<void> saveOrUpdate(BuildContext context) async {
    isSaving = true;
    notifyListeners();

    final newAccident = AccidentsData(
      id: currentAccidentId,
      date: stringToDate(dateCtrl.text),
      death: int.tryParse(deathCtrl.text),
      highway: highwayCtrl.text,
      scoresVictims: int.tryParse(scoresVictimsCtrl.text),
      transportInvolved: transportInvolvedCtrl.text,
      typeOfAccident: typeOfAccidentCtrl.text,
      latLng: LatLng(
        double.tryParse(latitudeCtrl.text) ?? 0,
        double.tryParse(longitudeCtrl.text) ?? 0,
      ),
      postalCode: postalCodeCtrl.text,
      street: streetCtrl.text,
      city: city2Ctrl.text.isNotEmpty ? city2Ctrl.text : cityCtrl.text,
      subLocality: subLocalityCtrl.text,
      administrativeArea: administrativeAreaCtrl.text,
      country: countryCtrl.text,
      isoCountryCode: isoCountryCodeCtrl.text,
      order: int.tryParse(orderCtrl.text),
    );

    await _accidentsBloc.saveOrUpdateAccident(newAccident);

    // Recarrega universo do Firestore e mantém página
    selectorUniverse = await _accidentsBloc.getAllAccidents();
    _allUniverse = List<AccidentsData>.from(selectorUniverse);

    await applyDateFilter(
      year: selectedYear,
      month: selectedMonth,
      resetToFirstPage: false,
      source: 'save',
    );

    await createNew();

    isSaving = false;
    notifyListeners();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Acidente salvo com sucesso!'), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> deleteAccident(BuildContext context, String id) async {
    // Descobre ano rapidamente
    final AccidentsData? item = _allUniverse.firstWhere(
          (e) => e.id == id,
      orElse: () => AccidentsData(id: id),
    );
    final int year = item?.date?.year ?? selectedYear ?? DateTime.now().year;

    await _accidentsBloc.deletarAccident(id: id, year: year);

    // Recarrega universo e mantém página (reencaixa se necessário)
    selectorUniverse = await _accidentsBloc.getAllAccidents();
    _allUniverse = List<AccidentsData>.from(selectorUniverse);

    await applyDateFilter(
      year: selectedYear,
      month: selectedMonth,
      resetToFirstPage: false,
      source: 'delete',
    );

    selectedLine = null;
    notifyListeners();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Acidente apagado com sucesso.'), backgroundColor: Colors.red),
      );
    }
  }

  // ================ SELEÇÃO NA TABELA ================
  void selectFromTable(AccidentsData data, int index) {
    selectedLine = index;
    fillFields(data);
  }

  // ============ GEOLOCALIZAÇÃO / ENDEREÇO ============
  Future<void> fillFromUserLocation(BuildContext context) async {
    final coords = await _systemBloc.getUserCurrentLocation();
    if (coords == null) return;

    latitudeCtrl.text = coords.latitude.toStringAsFixed(6);
    longitudeCtrl.text = coords.longitude.toStringAsFixed(6);

    final placemark = await _systemBloc.getPlaceMarkAdapted(coords);
    if (placemark != null) {
      postalCodeCtrl.text = placemark.postalCode ?? '';
      streetCtrl.text = placemark.street ?? '';
      cityCtrl.text = placemark.locality ?? '';
      subLocalityCtrl.text = placemark.subLocality ?? '';
      administrativeAreaCtrl.text = placemark.administrativeArea ?? '';
      countryCtrl.text = placemark.country ?? '';
      isoCountryCodeCtrl.text = placemark.isoCountryCode ?? '';
    }

    notifyListeners();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(placemark != null
              ? 'Endereço preenchido com sucesso.'
              : 'Coordenadas obtidas, mas endereço não encontrado.'),
          backgroundColor: placemark != null ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  // =================== AUXILIARES ===================
  Future<bool> confirm(BuildContext context, String msg) async {
    return await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmação'),
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar')),
        ],
      ),
    ) ??
        false;
  }
}
