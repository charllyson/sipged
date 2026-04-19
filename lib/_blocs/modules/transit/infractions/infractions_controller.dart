import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';

import 'infractions_bloc.dart';
import 'infractions_data.dart';

import 'package:sipged/_widgets/notification/app_notification.dart';
import 'package:sipged/_widgets/notification/notification_center.dart';

class InfractionsController extends ChangeNotifier {
  InfractionsController({required InfractionsBloc bloc}) : _bloc = bloc;

  InfractionsBloc _bloc;
  void updateDeps(InfractionsBloc b) {
    _bloc = b;
  }

  bool initRan = false;
  bool isEditable = true;
  bool isSaving = false;
  bool formValidated = false;
  bool _loading = false;
  bool get loading => _loading;

  String? currentInfractionId;
  InfractionsData? selectedInfraction;

  int? selectedYear;
  int? selectedMonth;

  final int _itemsPerPage = 50;
  int currentPage = 1;
  int totalPages = 1;
  bool isFiltering = false;
  bool isPaging = false;

  List<InfractionsData> _allUniverse = [];
  List<InfractionsData> get selectorUniverseAll => _allUniverse;
  List<InfractionsData> _filtered = [];
  List<InfractionsData> pageItems = [];

  final orderCtrl = TextEditingController();
  final aitNumberCtrl = TextEditingController();
  final dateCtrl = TextEditingController();
  final timeCtrl = TextEditingController();
  final codeCtrl = TextEditingController();
  final descriptionCtrl = TextEditingController();
  final organCodeCtrl = TextEditingController();
  final organAuthorityCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final bairroCtrl = TextEditingController();
  final latitudeCtrl = TextEditingController();
  final longitudeCtrl = TextEditingController();

  DateTime? _dateValue;

  LocationSettings _locationSettings({
    LocationAccuracy accuracy = LocationAccuracy.best,
    Duration? timeLimit,
  }) {
    if (kIsWeb) {
      return WebSettings(
        accuracy: accuracy,
        timeLimit: timeLimit,
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return AndroidSettings(
          accuracy: accuracy,
          timeLimit: timeLimit,
          distanceFilter: 0,
          forceLocationManager: false,
        );
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return AppleSettings(
          accuracy: accuracy,
          timeLimit: timeLimit,
          distanceFilter: 0,
          pauseLocationUpdatesAutomatically: false,
        );
      default:
        return LocationSettings(
          accuracy: accuracy,
          timeLimit: timeLimit,
        );
    }
  }

  Future<void> postFrameInit(BuildContext context) async {
    if (initRan) return;
    initRan = true;

    _setLoading(true);
    try {
      await _loadAllYearsUniverse();

      final yearsInData = _allUniverse
          .map((e) => e.dateInfraction?.year)
          .whereType<int>()
          .toList()
        ..sort((a, b) => b.compareTo(a));
      selectedYear =
      yearsInData.isNotEmpty ? yearsInData.first : DateTime.now().year;
      selectedMonth = null;

      await applyDateFilter(
        year: selectedYear,
        month: selectedMonth,
        resetToFirstPage: true,
        source: 'init',
      );

      _attachValidation();
      _safeNotify();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loadAllYearsUniverse() async {
    final containers = await _bloc.listYearContainers();
    final years = containers
        .map((c) => (c.data()['year'] ?? 0) as int)
        .where((y) => y > 0)
        .toList()
      ..sort();
    final lists = await Future.wait(years.map((y) => _bloc.getInfractionsByYear(y)));
    _allUniverse = lists.expand((l) => l).toList();
  }

  Future<void> _reloadAllUniverse() async {
    await _loadAllYearsUniverse();
  }

  @override
  void dispose() {
    for (final c in [
      orderCtrl,
      aitNumberCtrl,
      dateCtrl,
      timeCtrl,
      codeCtrl,
      descriptionCtrl,
      organCodeCtrl,
      organAuthorityCtrl,
      addressCtrl,
      bairroCtrl,
      latitudeCtrl,
      longitudeCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> applyDateFilter({
    int? year,
    int? month,
    bool resetToFirstPage = false,
    String source = '?',
  }) async {
    if (isFiltering) return;

    final targetYear = year;
    final targetMonth = month;
    final sameFilters =
        (targetYear == selectedYear) && (targetMonth == selectedMonth);

    const trustedResetSources = {'init', 'selector', 'changeYear', 'changeMonth'};
    if (isPaging) resetToFirstPage = false;
    final allowReset = resetToFirstPage && trustedResetSources.contains(source);
    if (!allowReset && sameFilters) return;

    isFiltering = true;
    _safeNotify();

    try {
      selectedYear = targetYear;
      selectedMonth = targetMonth;

      _filtered = _allUniverse.where((i) {
        final d = i.dateInfraction;
        if (d == null) return false;
        if (selectedYear != null && d.year != selectedYear) return false;
        if (selectedMonth != null && d.month != selectedMonth) return false;
        return true;
      }).toList();

      _filtered.sort((a, b) {
        final ao = a.orderInfraction ?? 0;
        final bo = b.orderInfraction ?? 0;
        if (ao != bo) return ao.compareTo(bo);
        final ad = a.dateInfraction?.millisecondsSinceEpoch ?? 0;
        final bd = b.dateInfraction?.millisecondsSinceEpoch ?? 0;
        return ad.compareTo(bd);
      });

      final totalDocs = _filtered.length;
      totalPages = totalDocs == 0 ? 1 : ((totalDocs + _itemsPerPage - 1) ~/ _itemsPerPage);

      if (allowReset) {
        currentPage = 1;
      } else {
        if (currentPage > totalPages) currentPage = totalPages;
        if (currentPage < 1) currentPage = 1;
      }

      _slicePage();

      if (allowReset) {
        orderCtrl.text = _calcNextOrder(_filtered).toString();
        final now = DateTime.now();
        dateCtrl.text = _formatDateUI(now);
        timeCtrl.text = _formatTimeUI(now);
      }
    } finally {
      isFiltering = false;
      _safeNotify();
    }
  }

  void _slicePage() {
    if (_filtered.isEmpty) {
      pageItems = [];
      return;
    }
    final start = (currentPage - 1) * _itemsPerPage;
    final end = (start + _itemsPerPage) > _filtered.length
        ? _filtered.length
        : (start + _itemsPerPage);
    pageItems = _filtered.sublist(start, end);
  }

  Future<void> loadPage(int page) async {
    if (isPaging) return;
    if (page < 1 || page > totalPages) return;

    isPaging = true;
    _safeNotify();
    try {
      currentPage = page;
      _slicePage();
    } finally {
      isPaging = false;
      _safeNotify();
    }
  }

  Future<void> changeYear(int? year) async {
    await applyDateFilter(
      year: year,
      month: selectedMonth,
      resetToFirstPage: true,
      source: 'changeYear',
    );
  }

  Future<void> changeMonth(int? month) async {
    await applyDateFilter(
      year: selectedYear,
      month: month,
      resetToFirstPage: true,
      source: 'changeMonth',
    );
  }

  int _calcNextOrder(List<InfractionsData> list) {
    return (list.map((e) => e.orderInfraction ?? 0).fold(0, (a, b) => a > b ? a : b)) + 1;
  }

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

    _validateForm();
    _safeNotify();
  }

  Future<void> createNew() async {
    selectedInfraction = null;
    currentInfractionId = null;
    _dateValue = null;

    for (final c in [
      orderCtrl,
      aitNumberCtrl,
      dateCtrl,
      timeCtrl,
      codeCtrl,
      descriptionCtrl,
      organCodeCtrl,
      organAuthorityCtrl,
      addressCtrl,
      bairroCtrl,
      latitudeCtrl,
      longitudeCtrl,
    ]) {
      c.clear();
    }

    final nextOrder = _calcNextOrder(_filtered);
    orderCtrl.text = nextOrder.toString();

    final now = DateTime.now();
    dateCtrl.text = _formatDateUI(now);
    timeCtrl.text = _formatTimeUI(now);

    _validateForm();
    _safeNotify();
  }

  Future<void> saveOrUpdate(BuildContext context) async {
    isSaving = true;
    _safeNotify();

    try {
      final data = _formToModel();
      data.id = currentInfractionId;

      final targetYear = data.dateInfraction?.year;
      if (targetYear == null) {
        _notify(
          'Informe a data da infração',
          type: AppNotificationType.warning,
          subtitle: 'Não foi possível determinar o ano.',
        );
        return;
      }

      await _bloc.salvarOuAtualizarInfracao(year: targetYear, data: data);

      await _reloadAllUniverse();
      await applyDateFilter(
        year: selectedYear,
        month: selectedMonth,
        resetToFirstPage: false,
        source: 'save',
      );

      _notify('Infração salva com sucesso', type: AppNotificationType.success);
      await createNew();
    } catch (e) {
      _notify('Erro ao salvar', type: AppNotificationType.error, subtitle: '$e');
    } finally {
      isSaving = false;
      _safeNotify();
    }
  }

  Future<void> deleteInfraction(BuildContext context, String id) async {
    isSaving = true;
    _safeNotify();

    try {
      final item = _allUniverse.firstWhere(
            (e) => e.id == id,
        orElse: () => InfractionsData(id: id),
      );
      final targetYear = item.dateInfraction?.year ?? selectedYear;

      if (targetYear == null) {
        _notify(
          'Não foi possível determinar o ano do registro',
          type: AppNotificationType.warning,
          subtitle: 'Exclusão não executada.',
        );
        return;
      }

      await _bloc.deleteInfraction(year: targetYear, recordId: id);

      await _reloadAllUniverse();
      await applyDateFilter(
        year: selectedYear,
        month: selectedMonth,
        resetToFirstPage: false,
        source: 'delete',
      );

      _notify('Infração removida', type: AppNotificationType.success);
      if (currentInfractionId == id) await createNew();
    } catch (e) {
      _notify('Erro ao remover', type: AppNotificationType.error, subtitle: '$e');
    } finally {
      isSaving = false;
      _safeNotify();
    }
  }

  InfractionsData _formToModel() {
    DateTime? baseDate = _dateValue ?? _parseDate(dateCtrl.text);
    final tod = _parseTimeOfDay(timeCtrl.text);
    if (baseDate != null && tod != null) {
      baseDate = DateTime(
        baseDate.year,
        baseDate.month,
        baseDate.day,
        tod.hour,
        tod.minute,
      );
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

  void _attachValidation() {
    for (final c in [dateCtrl, timeCtrl, aitNumberCtrl, codeCtrl]) {
      c.addListener(_validateForm);
    }
    _validateForm();
  }

  void _validateForm() {
    final ok = dateCtrl.text.trim().isNotEmpty &&
        timeCtrl.text.trim().isNotEmpty &&
        aitNumberCtrl.text.trim().isNotEmpty &&
        codeCtrl.text.trim().isNotEmpty;
    if (formValidated != ok) {
      formValidated = ok;
      _safeNotify();
    }
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

    final m2 = RegExp(
      r'^(\d{4})-(\d{2})-(\d{2})(?:[ T](\d{2}):(\d{2})(?::(\d{2}))?)?$',
    ).firstMatch(s);
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
    final h = int.parse(m.group(1)!);
    final mi = int.parse(m.group(2)!);
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

  void _notify(
      String title, {
        AppNotificationType type = AppNotificationType.info,
        String? subtitle,
        String? id,
      }) {
    if (id != null) {
      NotificationCenter.instance.dismissById(id);
    }
    NotificationCenter.instance.show(
      AppNotification(
        id: id,
        title: Text(title),
        subtitle:
        (subtitle != null && subtitle.isNotEmpty) ? Text(subtitle) : null,
        type: type,
      ),
    );
  }

  Future<void> fillFromUserLocation(BuildContext context) async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _notify(
            'Permissão de localização negada.',
            type: AppNotificationType.warning,
          );
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _notify(
          'Permissão de localização negada permanentemente.',
          type: AppNotificationType.warning,
        );
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: _locationSettings(
          accuracy: LocationAccuracy.best,
        ),
      );
      latitudeCtrl.text = pos.latitude.toStringAsFixed(6);
      longitudeCtrl.text = pos.longitude.toStringAsFixed(6);

      final placemarks =
      await geo.placemarkFromCoordinates(pos.latitude, pos.longitude);
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

      _safeNotify();
    } catch (e) {
      _notify(
        'Falha ao obter localização',
        type: AppNotificationType.error,
        subtitle: '$e',
      );
    }
  }

  void _setLoading(bool v) {
    if (_loading == v) return;
    _loading = v;
    _safeNotify();
  }

  void _safeNotify() {
    if (!hasListeners) return;
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle) {
      notifyListeners();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (hasListeners) notifyListeners();
      });
    }
  }
}