import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';

import 'infractions_data.dart';
import 'infractions_repository.dart';
import 'infractions_state.dart';

class InfractionsCubit extends Cubit<InfractionsState> {
  InfractionsCubit({
    InfractionsRepository? repository,
  })  : _repository = repository ?? InfractionsRepository(),
        super(InfractionsState.initial()) {
    _attachValidation();
  }

  final InfractionsRepository _repository;

  bool get hasTenant => _repository.hasTenant;

  final TextEditingController orderCtrl = TextEditingController();
  final TextEditingController aitNumberCtrl = TextEditingController();
  final TextEditingController dateCtrl = TextEditingController();
  final TextEditingController timeCtrl = TextEditingController();
  final TextEditingController codeCtrl = TextEditingController();
  final TextEditingController descriptionCtrl = TextEditingController();
  final TextEditingController organCodeCtrl = TextEditingController();
  final TextEditingController organAuthorityCtrl = TextEditingController();
  final TextEditingController addressCtrl = TextEditingController();
  final TextEditingController bairroCtrl = TextEditingController();
  final TextEditingController latitudeCtrl = TextEditingController();
  final TextEditingController longitudeCtrl = TextEditingController();

  DateTime? _dateValue;

  void setActiveTenantId(String? tenantId) {
    _repository.setActiveTenantId(tenantId);

    if (!_repository.hasTenant) {
      _dateValue = null;

      for (final controller in _controllers) {
        controller.clear();
      }

      emit(
        InfractionsState.initial().copyWith(
          initRan: false,
          loading: false,
          isSaving: false,
          isFiltering: false,
          isPaging: false,
          clearErrorMessage: true,
          clearCurrentInfractionId: true,
          clearSelectedInfraction: true,
          clearSelectedYear: true,
          clearSelectedMonth: true,
          selectorUniverseAll: const <InfractionsData>[],
          filtered: const <InfractionsData>[],
          pageItems: const <InfractionsData>[],
        ),
      );
    }
  }

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

  Future<void> postFrameInit({bool forceReload = false}) async {
    if (!_repository.hasTenant) {
      emit(
        state.copyWith(
          initRan: false,
          loading: false,
          clearErrorMessage: true,
          selectorUniverseAll: const <InfractionsData>[],
          filtered: const <InfractionsData>[],
          pageItems: const <InfractionsData>[],
          clearSelectedInfraction: true,
          clearCurrentInfractionId: true,
          clearSelectedYear: true,
          clearSelectedMonth: true,
        ),
      );

      return;
    }

    if (state.initRan && !forceReload) return;

    emit(
      state.copyWith(
        initRan: true,
        loading: true,
        clearErrorMessage: true,
      ),
    );

    try {
      final universe = await _loadAllYearsUniverse();

      final yearsInData = universe
          .map((item) => item.dateInfraction?.year)
          .whereType<int>()
          .toSet()
          .toList()
        ..sort((a, b) => b.compareTo(a));

      final int selectedYear =
      yearsInData.isNotEmpty ? yearsInData.first : DateTime.now().year;

      emit(
        state.copyWith(
          selectorUniverseAll: universe,
          selectedYear: selectedYear,
          clearSelectedMonth: true,
        ),
      );

      await applyDateFilter(
        year: selectedYear,
        month: null,
        resetToFirstPage: true,
        source: 'init',
      );
    } catch (e) {
      emit(
        state.copyWith(
          errorMessage: 'Erro ao carregar infrações: $e',
        ),
      );
    } finally {
      emit(
        state.copyWith(
          loading: false,
        ),
      );
    }
  }

  Future<void> refresh({bool forceReload = true}) async {
    if (!_repository.hasTenant) return;

    if (!forceReload && state.initRan) {
      await applyDateFilter(
        year: state.selectedYear,
        month: state.selectedMonth,
        resetToFirstPage: false,
        source: 'refresh',
      );
      return;
    }

    await postFrameInit(forceReload: true);
  }

  Future<List<InfractionsData>> _loadAllYearsUniverse() async {
    final years = await _repository.listAvailableYears();

    if (years.isEmpty) return const <InfractionsData>[];

    final lists = await Future.wait(
      years.map(_repository.getInfractionsByYear),
    );

    return lists.expand((list) => list).toList();
  }

  Future<void> _reloadAllUniverse() async {
    final universe = await _loadAllYearsUniverse();

    emit(
      state.copyWith(
        selectorUniverseAll: universe,
      ),
    );
  }

  Future<void> applyDateFilter({
    int? year,
    int? month,
    bool resetToFirstPage = false,
    String source = '?',
  }) async {
    if (!_repository.hasTenant) return;
    if (state.isFiltering) return;

    final bool sameFilters =
        year == state.selectedYear && month == state.selectedMonth;

    const trustedResetSources = <String>{
      'init',
      'selector',
      'changeYear',
      'changeMonth',
    };

    bool allowReset = resetToFirstPage && trustedResetSources.contains(source);

    if (state.isPaging) {
      allowReset = false;
    }

    if (!allowReset && sameFilters && source != 'save' && source != 'delete') {
      return;
    }

    emit(
      state.copyWith(
        isFiltering: true,
        clearErrorMessage: true,
      ),
    );

    try {
      final List<InfractionsData> filtered =
      state.selectorUniverseAll.where((item) {
        final DateTime? date = item.dateInfraction;

        if (date == null) return false;
        if (year != null && date.year != year) return false;
        if (month != null && date.month != month) return false;

        return true;
      }).toList();

      filtered.sort((a, b) {
        final int orderA = a.orderInfraction ?? 0;
        final int orderB = b.orderInfraction ?? 0;

        if (orderA != orderB) {
          return orderA.compareTo(orderB);
        }

        final int dateA = a.dateInfraction?.millisecondsSinceEpoch ?? 0;
        final int dateB = b.dateInfraction?.millisecondsSinceEpoch ?? 0;

        return dateA.compareTo(dateB);
      });

      final int totalDocs = filtered.length;
      final int totalPages =
      totalDocs == 0 ? 1 : ((totalDocs + state.itemsPerPage - 1) ~/ state.itemsPerPage);

      int currentPage = state.currentPage;

      if (allowReset) {
        currentPage = 1;
      } else {
        if (currentPage > totalPages) currentPage = totalPages;
        if (currentPage < 1) currentPage = 1;
      }

      final List<InfractionsData> pageItems = _slicePage(
        filtered: filtered,
        currentPage: currentPage,
        itemsPerPage: state.itemsPerPage,
      );

      emit(
        state.copyWith(
          selectedYear: year,
          clearSelectedYear: year == null,
          selectedMonth: month,
          clearSelectedMonth: month == null,
          filtered: filtered,
          totalPages: totalPages,
          currentPage: currentPage,
          pageItems: pageItems,
        ),
      );

      if (allowReset) {
        orderCtrl.text = _calcNextOrder(filtered).toString();

        final DateTime now = DateTime.now();

        dateCtrl.text = _formatDateUI(now);
        timeCtrl.text = _formatTimeUI(now);

        _dateValue = now;
        _validateForm();
      }
    } catch (e) {
      emit(
        state.copyWith(
          errorMessage: 'Erro ao aplicar filtro: $e',
        ),
      );
    } finally {
      emit(
        state.copyWith(
          isFiltering: false,
        ),
      );
    }
  }

  List<InfractionsData> _slicePage({
    required List<InfractionsData> filtered,
    required int currentPage,
    required int itemsPerPage,
  }) {
    if (filtered.isEmpty) return const <InfractionsData>[];

    final int start = (currentPage - 1) * itemsPerPage;

    if (start >= filtered.length) return const <InfractionsData>[];

    final int end =
    (start + itemsPerPage) > filtered.length ? filtered.length : start + itemsPerPage;

    return filtered.sublist(start, end);
  }

  Future<void> loadPage(int page) async {
    if (state.isPaging) return;
    if (page < 1 || page > state.totalPages) return;

    emit(
      state.copyWith(
        isPaging: true,
      ),
    );

    try {
      final pageItems = _slicePage(
        filtered: state.filtered,
        currentPage: page,
        itemsPerPage: state.itemsPerPage,
      );

      emit(
        state.copyWith(
          currentPage: page,
          pageItems: pageItems,
        ),
      );
    } finally {
      emit(
        state.copyWith(
          isPaging: false,
        ),
      );
    }
  }

  Future<void> changeYear(int? year) async {
    await applyDateFilter(
      year: year,
      month: state.selectedMonth,
      resetToFirstPage: true,
      source: 'changeYear',
    );
  }

  Future<void> changeMonth(int? month) async {
    await applyDateFilter(
      year: state.selectedYear,
      month: month,
      resetToFirstPage: true,
      source: 'changeMonth',
    );
  }

  int _calcNextOrder(List<InfractionsData> list) {
    return list
        .map((item) => item.orderInfraction ?? 0)
        .fold<int>(0, (a, b) => a > b ? a : b) +
        1;
  }

  void selectFromTable(InfractionsData item) {
    _dateValue = item.dateInfraction;

    orderCtrl.text = (item.orderInfraction ?? '').toString();
    aitNumberCtrl.text = item.aitNumber ?? '';
    dateCtrl.text = _formatDateUI(_dateValue);
    timeCtrl.text = _formatTimeUI(_dateValue);
    codeCtrl.text = item.codeInfraction ?? '';
    descriptionCtrl.text = item.descriptionInfraction ?? '';
    organCodeCtrl.text = item.organCode ?? '';
    organAuthorityCtrl.text = item.organAuthority ?? '';
    addressCtrl.text = item.addressInfraction ?? '';
    bairroCtrl.text = item.bairro ?? '';
    latitudeCtrl.text = item.latitude?.toString() ?? '';
    longitudeCtrl.text = item.longitude?.toString() ?? '';

    _validateForm();

    emit(
      state.copyWith(
        selectedInfraction: item,
        currentInfractionId: item.id,
      ),
    );
  }

  Future<void> createNew() async {
    _dateValue = null;

    for (final controller in _controllers) {
      controller.clear();
    }

    final int nextOrder = _calcNextOrder(state.filtered);
    final DateTime now = DateTime.now();

    _dateValue = now;

    orderCtrl.text = nextOrder.toString();
    dateCtrl.text = _formatDateUI(now);
    timeCtrl.text = _formatTimeUI(now);

    _validateForm();

    emit(
      state.copyWith(
        clearSelectedInfraction: true,
        clearCurrentInfractionId: true,
      ),
    );
  }

  Future<void> saveOrUpdate() async {
    if (!_repository.hasTenant) {
      emit(
        state.copyWith(
          errorMessage: 'Nenhuma empresa selecionada para salvar infrações.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        isSaving: true,
        clearErrorMessage: true,
      ),
    );

    try {
      final InfractionsData data = _formToModel();
      data.id = state.currentInfractionId;

      final int? targetYear = data.dateInfraction?.year;

      if (targetYear == null) {
        throw Exception('Ano da infração ausente.');
      }

      await _repository.salvarOuAtualizarInfracao(
        year: targetYear,
        data: data,
      );

      await _reloadAllUniverse();

      await applyDateFilter(
        year: state.selectedYear,
        month: state.selectedMonth,
        resetToFirstPage: false,
        source: 'save',
      );

      await createNew();
    } catch (e) {
      emit(
        state.copyWith(
          errorMessage: 'Erro ao salvar infração: $e',
        ),
      );
    } finally {
      emit(
        state.copyWith(
          isSaving: false,
        ),
      );
    }
  }

  Future<void> deleteInfraction(String id) async {
    if (!_repository.hasTenant) {
      emit(
        state.copyWith(
          errorMessage: 'Nenhuma empresa selecionada para excluir infrações.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        isSaving: true,
        clearErrorMessage: true,
      ),
    );

    try {
      final InfractionsData item = state.selectorUniverseAll.firstWhere(
            (item) => item.id == id,
        orElse: () => InfractionsData(id: id),
      );

      final int? targetYear = item.dateInfraction?.year ?? state.selectedYear;

      if (targetYear == null) {
        throw Exception('Ano do registro ausente.');
      }

      await _repository.deleteInfraction(
        year: targetYear,
        recordId: id,
      );

      await _reloadAllUniverse();

      await applyDateFilter(
        year: state.selectedYear,
        month: state.selectedMonth,
        resetToFirstPage: false,
        source: 'delete',
      );

      if (state.currentInfractionId == id) {
        await createNew();
      }
    } catch (e) {
      emit(
        state.copyWith(
          errorMessage: 'Erro ao remover infração: $e',
        ),
      );
    } finally {
      emit(
        state.copyWith(
          isSaving: false,
        ),
      );
    }
  }

  InfractionsData _formToModel() {
    DateTime? baseDate = _dateValue ?? _parseDate(dateCtrl.text);
    final TimeOfDay? timeOfDay = _parseTimeOfDay(timeCtrl.text);

    if (baseDate != null && timeOfDay != null) {
      baseDate = DateTime(
        baseDate.year,
        baseDate.month,
        baseDate.day,
        timeOfDay.hour,
        timeOfDay.minute,
      );
    }

    return InfractionsData(
      id: state.currentInfractionId,
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
    for (final controller in <TextEditingController>[
      dateCtrl,
      timeCtrl,
      aitNumberCtrl,
      codeCtrl,
    ]) {
      controller.addListener(_validateForm);
    }

    _validateForm();
  }

  void _validateForm() {
    final bool valid = dateCtrl.text.trim().isNotEmpty &&
        timeCtrl.text.trim().isNotEmpty &&
        aitNumberCtrl.text.trim().isNotEmpty &&
        codeCtrl.text.trim().isNotEmpty;

    if (state.formValidated != valid) {
      emit(
        state.copyWith(
          formValidated: valid,
        ),
      );
    }
  }

  Future<void> fillFromUserLocation() async {
    emit(
      state.copyWith(
        clearErrorMessage: true,
      ),
    );

    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();

        if (permission == LocationPermission.denied) {
          throw Exception('Permissão de localização negada.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Permissão de localização negada permanentemente.');
      }

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: _locationSettings(
          accuracy: LocationAccuracy.best,
        ),
      );

      latitudeCtrl.text = position.latitude.toStringAsFixed(6);
      longitudeCtrl.text = position.longitude.toStringAsFixed(6);

      final geo.Geocoding geocoding = geo.Geocoding();

      final List<geo.Placemark> placemarks =
      await geocoding.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        addressCtrl.text = <String>[
          if ((place.street ?? '').isNotEmpty) place.street!,
          if ((place.subLocality ?? '').isNotEmpty) place.subLocality!,
          if ((place.locality ?? '').isNotEmpty) place.locality!,
          if ((place.administrativeArea ?? '').isNotEmpty)
            place.administrativeArea!,
        ].join(', ');

        bairroCtrl.text = place.subLocality ?? '';
      }

      _validateForm();
    } catch (e) {
      emit(
        state.copyWith(
          errorMessage: 'Falha ao obter localização: $e',
        ),
      );
    }
  }

  String _formatDateUI(DateTime? date) {
    if (date == null) return '';

    String two(int value) => value.toString().padLeft(2, '0');

    return '${two(date.day)}/${two(date.month)}/${date.year}';
  }

  String _formatTimeUI(DateTime? date) {
    if (date == null) return '';

    String two(int value) => value.toString().padLeft(2, '0');

    return '${two(date.hour)}:${two(date.minute)}';
  }

  DateTime? _parseDate(String raw) {
    final String value = raw.trim();

    if (value.isEmpty) return null;

    final matchBr = RegExp(
      r'^(\d{2})/(\d{2})/(\d{4})$',
    ).firstMatch(value);

    if (matchBr != null) {
      final int day = int.parse(matchBr.group(1)!);
      final int month = int.parse(matchBr.group(2)!);
      final int year = int.parse(matchBr.group(3)!);

      return DateTime(year, month, day);
    }

    final matchIso = RegExp(
      r'^(\d{4})-(\d{2})-(\d{2})(?:[ T](\d{2}):(\d{2})(?::(\d{2}))?)?$',
    ).firstMatch(value);

    if (matchIso != null) {
      final int year = int.parse(matchIso.group(1)!);
      final int month = int.parse(matchIso.group(2)!);
      final int day = int.parse(matchIso.group(3)!);

      if (matchIso.group(4) != null) {
        final int hour = int.parse(matchIso.group(4)!);
        final int minute = int.parse(matchIso.group(5)!);
        final int second = int.tryParse(matchIso.group(6) ?? '0') ?? 0;

        return DateTime(year, month, day, hour, minute, second);
      }

      return DateTime(year, month, day);
    }

    return DateTime.tryParse(value);
  }

  TimeOfDay? _parseTimeOfDay(String raw) {
    final String value = raw.trim();

    if (value.isEmpty) return null;

    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value);

    if (match == null) return null;

    final int hour = int.parse(match.group(1)!);
    final int minute = int.parse(match.group(2)!);

    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;

    return TimeOfDay(
      hour: hour,
      minute: minute,
    );
  }

  double? _parseDouble(String text) {
    final String value = text.replaceAll(',', '.').trim();

    if (value.isEmpty) return null;

    return double.tryParse(value);
  }

  String? _emptyToNull(String? value) {
    if (value == null) return null;

    final String trimmed = value.trim();

    return trimmed.isEmpty ? null : trimmed;
  }

  List<TextEditingController> get _controllers {
    return <TextEditingController>[
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
    ];
  }

  @override
  Future<void> close() {
    for (final controller in _controllers) {
      controller.dispose();
    }

    return super.close();
  }
}