// lib/screens/sectors/traffic/accidents/accidents_records_page.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:siged/_widgets/background/background_cleaner.dart';
import 'package:siged/_widgets/footBar/foot_bar.dart';
import 'package:siged/_widgets/texts/divider_text.dart';
import 'package:siged/_widgets/upBar/up_bar.dart';
import 'package:siged/_widgets/map/map_interactive.dart';
import 'package:siged/_widgets/toolBox/tool_widget.dart';

// Bloc
import 'package:siged/_blocs/sectors/transit/accidents/accidents_bloc.dart';
import 'package:siged/_blocs/sectors/transit/accidents/accidents_event.dart';
import 'package:siged/_blocs/sectors/transit/accidents/accidents_state.dart';
import 'package:siged/_blocs/sectors/transit/accidents/accidents_data.dart';

// Utils
import 'package:siged/_utils/formats/format_field.dart';

// SEÇÕES
import 'accidents_form_section.dart';
import 'accidents_selector_dates_section.dart';
import 'accidents_table_section.dart';

// Notificações
import 'package:siged/_widgets/notification/app_notification.dart';
import 'package:siged/_widgets/notification/notification_center.dart';

// Removemos LeftPanelMode e passamos a usar toggles independentes.

class AccidentsRecordsPage extends StatefulWidget {
  const AccidentsRecordsPage({super.key});

  @override
  State<AccidentsRecordsPage> createState() => _AccidentsRecordsPageState();
}

class _AccidentsRecordsPageState extends State<AccidentsRecordsPage> {
  bool _inited = false;

  // ====== Form controllers ======
  final orderCtrl = TextEditingController();
  final dateCtrl = TextEditingController();
  final highwayCtrl = TextEditingController();
  final cityCtrl = TextEditingController(); // descrição
  final typeOfAccidentCtrl = TextEditingController();
  final deathCtrl = TextEditingController();
  final scoresVictimsCtrl = TextEditingController();
  final transportInvolvedCtrl = TextEditingController();

  final latitudeCtrl = TextEditingController();
  final longitudeCtrl = TextEditingController();
  final postalCodeCtrl = TextEditingController();
  final streetCtrl = TextEditingController();
  final city2Ctrl = TextEditingController(); // endereço
  final subLocalityCtrl = TextEditingController();
  final administrativeAreaCtrl = TextEditingController();
  final countryCtrl = TextEditingController();
  final isoCountryCodeCtrl = TextEditingController();

  bool formValidated = false;
  AccidentsData? selectedAccident;
  String? currentAccidentId;

  // ===== Splitters =====
  double _splitH = 0.49; // fração da largura do MAPA (wide)
  double _splitVSmall = 0.38; // fração da altura do MAPA (mobile)
  double _splitVWide = 0.46; // fração da altura do MAPA (wide)

  // ===== Visibilidade (toggles independentes) =====
  bool _showForm = true;
  bool _showTable = true;
  bool _showMap = true;

  // ===== Scroll controllers da TABELA =====
  final ScrollController _tableHCtrl = ScrollController();
  final ScrollController _tableVCtrl = ScrollController();

  // ===== Mapa: controller externo + buffer de centralização =====
  MapController? _mapController;
  LatLng? _pendingCenter;

  // ✅ Novo: setter do pin que vem do MapInteractivePage
  void Function(LatLng p)? _setMapPin;

  // ===== Helpers =====
  void _validateForm() {
    final ok = (cityCtrl.text.trim().isNotEmpty || city2Ctrl.text.trim().isNotEmpty) &&
        dateCtrl.text.trim().isNotEmpty &&
        highwayCtrl.text.trim().isNotEmpty &&
        typeOfAccidentCtrl.text.trim().isNotEmpty;
    if (formValidated != ok) setState(() => formValidated = ok);
  }

  void _syncCities() {
    if (city2Ctrl.text.isNotEmpty && city2Ctrl.text != cityCtrl.text) {
      cityCtrl.text = city2Ctrl.text;
    } else if (cityCtrl.text.isNotEmpty && cityCtrl.text != city2Ctrl.text) {
      city2Ctrl.text = cityCtrl.text;
    }
  }

  LatLng? _tryParseLatLng(String lat, String lng) {
    final la = double.tryParse(lat.replaceAll(',', '.'));
    final lo = double.tryParse(lng.replaceAll(',', '.'));
    if (la == null || lo == null) return null;
    if (la < -90 || la > 90 || lo < -180 || lo > 180) return null;
    return LatLng(la, lo);
  }

  // === sincronizadores formulário → mapa
  void _updateMapFromLatLng(double lat, double lon, {double zoom = 18}) {
    final p = LatLng(lat, lon);
    if (_mapController != null) {
      _mapController!.move(p, zoom);
    } else {
      _pendingCenter = p;
    }
    _setMapPin?.call(p); // ✅ garante o pin
    context.read<AccidentsBloc>().add(AccidentsReverseGeocodeRequested(lat, lon));
  }

  Future<void> _updateMapFromCep(String cep) async {
    context.read<AccidentsBloc>().add(AccidentsGeocodeCepRequested(cep));
  }

  @override
  void initState() {
    super.initState();
    for (final c in [cityCtrl, city2Ctrl, dateCtrl, highwayCtrl, typeOfAccidentCtrl]) {
      c.addListener(_validateForm);
    }
    cityCtrl.addListener(_syncCities);
    city2Ctrl.addListener(_syncCities);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _inited) return;
      context.read<AccidentsBloc>().add(
        AccidentsWarmupRequested(initialYear: DateTime.now().year),
      );
      _inited = true;
    });
  }

  @override
  void dispose() {
    for (final c in [
      orderCtrl,
      dateCtrl,
      highwayCtrl,
      cityCtrl,
      typeOfAccidentCtrl,
      deathCtrl,
      scoresVictimsCtrl,
      transportInvolvedCtrl,
      latitudeCtrl,
      longitudeCtrl,
      postalCodeCtrl,
      streetCtrl,
      city2Ctrl,
      subLocalityCtrl,
      administrativeAreaCtrl,
      countryCtrl,
      isoCountryCodeCtrl,
    ]) {
      c.dispose();
    }
    _tableHCtrl.dispose();
    _tableVCtrl.dispose();
    super.dispose();
  }

  void _fillFields(AccidentsData data) {
    selectedAccident = data;
    currentAccidentId = data.id;

    cityCtrl.text = data.city ?? '';
    city2Ctrl.text = data.city ?? '';
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
    subLocalityCtrl.text = data.subLocality ?? '';
    administrativeAreaCtrl.text = data.administrativeArea ?? '';
    countryCtrl.text = data.country ?? '';
    isoCountryCodeCtrl.text = data.isoCountryCode ?? '';

    orderCtrl.text = (data.order ?? '').toString();

    _validateForm();
    setState(() {});
  }

  Future<void> _createNew(AccidentsState st) async {
    selectedAccident = null;
    currentAccidentId = null;

    final nextOrder = ((st.view.map((e) => e.order ?? 0).fold<int>(0, (a, b) => a > b ? a : b)) + 1);
    orderCtrl.text = nextOrder.toString();

    for (final c in [
      dateCtrl,
      deathCtrl,
      highwayCtrl,
      scoresVictimsCtrl,
      transportInvolvedCtrl,
      typeOfAccidentCtrl,
      latitudeCtrl,
      longitudeCtrl,
      postalCodeCtrl,
      streetCtrl,
      cityCtrl,
      city2Ctrl,
      subLocalityCtrl,
      administrativeAreaCtrl,
      countryCtrl,
      isoCountryCodeCtrl,
    ]) {
      c.clear();
    }
    dateCtrl.text = dateToString(DateTime.now());
    _validateForm();
    setState(() {});
  }

  Future<void> _save(AccidentsState st) async {
    final data = AccidentsData(
      id: currentAccidentId,
      date: stringToDate(dateCtrl.text),
      death: int.tryParse(deathCtrl.text),
      highway: highwayCtrl.text,
      scoresVictims: int.tryParse(scoresVictimsCtrl.text),
      transportInvolved: transportInvolvedCtrl.text,
      typeOfAccident: typeOfAccidentCtrl.text,
      latLng: _tryParseLatLng(latitudeCtrl.text, longitudeCtrl.text),
      postalCode: postalCodeCtrl.text,
      street: streetCtrl.text,
      city: (city2Ctrl.text.isNotEmpty ? city2Ctrl.text : cityCtrl.text).trim(),
      subLocality: subLocalityCtrl.text,
      administrativeArea: administrativeAreaCtrl.text,
      country: countryCtrl.text,
      isoCountryCode: isoCountryCodeCtrl.text,
      order: int.tryParse(orderCtrl.text),
    );

    context.read<AccidentsBloc>().add(AccidentsSaveRequested(data));
  }

  Future<void> _delete(String id, {int? yearHint}) async {
    context.read<AccidentsBloc>().add(
      AccidentsDeleteRequested(id: id, yearHint: yearHint),
    );
  }

  Future<bool> _confirm(BuildContext ctx, String msg) async {
    return await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Confirmação'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    ) ??
        false;
  }

  // ===== aplica uma sugestão de endereço vinda do Bloc (View-only) =====
  void _applyLocationSuggestion(AddressSuggestion s) {
    if (s.latitude != null) {
      latitudeCtrl.text = s.latitude!.toStringAsFixed(6);
    }
    if (s.longitude != null) {
      longitudeCtrl.text = s.longitude!.toStringAsFixed(6);
    }

    streetCtrl.text = s.street;
    subLocalityCtrl.text = s.subLocality;
    administrativeAreaCtrl.text = s.administrativeArea;
    postalCodeCtrl.text = s.postalCode;
    countryCtrl.text = s.country;
    isoCountryCodeCtrl.text = s.isoCountryCode;
    city2Ctrl.text = s.city;
    cityCtrl.text = s.city;

    _validateForm();
    setState(() {});
  }

  // ===== Wrapper: Tabela com scroll H + V, sem gaps laterais =====
  Widget _buildScrollableTable({
    required BuildContext context,
    required List<AccidentsData> pageItems,
    required AccidentsState state,
    required bool isWide,
  }) {
    // altura “base” apenas para referência visual (não fixa layout)
    final double tableHeight = isWide ? 420 : 360;

    final tableCore = AccidentsTableSection(
      listData: pageItems,
      selectedItem: selectedAccident,
      currentPage: state.currentPage,
      totalPages: state.totalPages,
      onPageChange: (p) async => context.read<AccidentsBloc>().add(AccidentsPageRequested(p)),
      onTapItem: (item) {
        final idx = pageItems.indexOf(item);
        if (idx != -1) _fillFields(item);
      },
      onDelete: (id) async {
        final toDelete = state.view.firstWhere(
              (e) => e.id == id,
          orElse: () => AccidentsData(id: id),
        );
        final ok = await _confirm(context, 'Deseja apagar este acidente?');
        if (ok) await _delete(id, yearHint: toDelete.date?.year);
      },
    );

    // 🔧 ADAPTATIVO: a tabela usa toda a largura disponível do painel.
    // Se a largura disponível for menor que 1200, mantemos minWidth=1200 e ativamos scroll horizontal.
    return LayoutBuilder(
      builder: (ctx, c) {
        final available = c.maxWidth.isFinite ? c.maxWidth : 1200.0;
        final double minWidth = math.max(1200.0, available);

        return Scrollbar(
          controller: _tableHCtrl,
          thumbVisibility: true,
          notificationPredicate: (notif) => notif.metrics.axis == Axis.horizontal,
          child: SingleChildScrollView(
            controller: _tableHCtrl,
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: minWidth),
              child: SizedBox(
                width: minWidth,
                child: Scrollbar(
                  controller: _tableVCtrl,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _tableVCtrl,
                    padding: EdgeInsets.zero,
                    child: tableCore,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ==================== DIVISORES ARRASTÁVEIS ====================

  // Wide: arrasta divisor vertical para alterar _splitH
  Widget _buildDraggableVerticalDivider(BoxConstraints constraints) {
    final totalW = constraints.maxWidth;
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragUpdate: (details) {
          final delta = details.delta.dx;
          setState(() {
            _splitH = (_splitH + (delta / totalW)).clamp(0.22, 0.80);
          });
        },
        child: Container(
          width: 10,
          color: Colors.white,
          child: Center(
            child: Container(width: 1, height: double.infinity, color: Colors.blue),
          ),
        ),
      ),
    );
  }

  // Mobile: arrasta divisor horizontal para alterar _splitVSmall
  Widget _buildDraggableHorizontalDivider(double totalH) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeRow,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragUpdate: (details) {
          final delta = details.delta.dy;
          setState(() {
            final currentMapH = _splitVSmall * totalH;
            final newMapH = (currentMapH + delta).clamp(220.0, totalH * 0.9);
            _splitVSmall = (newMapH / totalH).clamp(0.2, 0.9);
          });
        },
        child: Container(
          height: 10,
          color: Colors.white,
          child: Center(
            child: Container(width: double.infinity, height: 1, color: Colors.blue),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AccidentsBloc, AccidentsState>(
      listenWhen: (prev, curr) =>
      prev.error != curr.error ||
          prev.success != curr.success ||
          prev.locationError != curr.locationError ||
          prev.locationSuggestion != curr.locationSuggestion,
      listener: (context, state) async {
        // Notificações gerais
        if (state.error != null && state.error!.trim().isNotEmpty) {
          NotificationCenter.instance.show(
            AppNotification(
              title: const Text('Falha na operação'),
              subtitle: Text(state.error!),
              type: AppNotificationType.error,
              leadingLabel: const Text('Acidentes'),
              duration: const Duration(seconds: 6),
            ),
          );
        }
        if (state.success != null && state.success!.trim().isNotEmpty) {
          NotificationCenter.instance.show(
            AppNotification(
              title: const Text('Operação concluída'),
              subtitle: Text(state.success!),
              type: AppNotificationType.success,
              leadingLabel: const Text('Acidentes'),
              duration: const Duration(seconds: 4),
            ),
          );
          await _createNew(state);
        }

        // Notificações de localização
        if (state.locationError != null && state.locationError!.trim().isNotEmpty) {
          NotificationCenter.instance.show(
            AppNotification(
              title: const Text('Falha ao obter endereço'),
              subtitle: Text(state.locationError!),
              type: AppNotificationType.error,
              leadingLabel: const Text('Localização'),
              duration: const Duration(seconds: 6),
            ),
          );
        }

        // Aplicar sugestão de endereço (preenche os controllers) + centralizar mapa + pin
        if (state.locationSuggestion != null) {
          final s = state.locationSuggestion!;
          _applyLocationSuggestion(s);

          final p = (s.latitude != null && s.longitude != null)
              ? LatLng(s.latitude!, s.longitude!)
              : null;

          if (p != null) {
            if (_mapController != null) {
              _mapController!.move(p, 16);
            } else {
              _pendingCenter = p;
            }
            _setMapPin?.call(p); // ✅ garante o pin
          }
        }
      },
      builder: (context, state) {
        final pageItems = state.pageItems;

        final zeroTableGapsTheme = Theme.of(context).copyWith(
          dataTableTheme: const DataTableThemeData(
            horizontalMargin: 0,
            columnSpacing: 20, // ↑ mais respiro para colunas
            dividerThickness: 1,
          ),
        );

        return Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(74),
            child: UpBar(
              showPhotoMenu: true,
              actions: [
                // Toggle Form
                IconButton(
                  tooltip: 'Formulário',
                  icon: Icon(
                    _showForm ? Icons.description : Icons.description_outlined,
                    color: Colors.white,
                  ),
                  onPressed: () => setState(() => _showForm = !_showForm),
                ),
                // Toggle Tabela
                IconButton(
                  tooltip: 'Tabela',
                  icon: Icon(
                    _showTable ? Icons.table_chart : Icons.table_chart_outlined,
                    color: Colors.white,
                  ),
                  onPressed: () => setState(() => _showTable = !_showTable),
                ),
                // Toggle Mapa
                IconButton(
                  tooltip: 'Mapa',
                  icon: Icon(
                    _showMap ? Icons.map : Icons.map_outlined,
                    color: Colors.white,
                  ),
                  onPressed: () => setState(() => _showMap = !_showMap),
                ),
              ],
            ),
          ),
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              const BackgroundClean(),
              LayoutBuilder(
                builder: (context, constraints) {
                  final bool isWide = constraints.maxWidth >= 1060;

                  // =============== MOBILE / SMALL ===============
                  if (!isWide) {
                    final double totalH = constraints.maxHeight;

                    const double minMapH = 220.0;
                    final double maxMapH = (totalH * 0.9).clamp(260.0, totalH);

                    double mapH = (_splitVSmall * totalH).clamp(minMapH, maxMapH);
                    final double clampedV = mapH / totalH;
                    if (clampedV != _splitVSmall) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) setState(() => _splitVSmall = clampedV);
                      });
                    }

                    final Widget contentPanel = Theme(
                      data: zeroTableGapsTheme,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(left: 12, bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_showForm) ...[
                              const DividerText(title: 'Cadastrar acidentes'),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.only(right: 12.0),
                                child: AccidentsFormSection(
                                  itemsPerLineOverride: 1,
                                  isEditable: true,
                                  formValidated: formValidated,
                                  currentAccidentId: currentAccidentId,
                                  orderCtrl: orderCtrl,
                                  dateCtrl: dateCtrl,
                                  highwayCtrl: highwayCtrl,
                                  cityCtrl: cityCtrl,
                                  typeOfAccidentCtrl: typeOfAccidentCtrl,
                                  deathCtrl: deathCtrl,
                                  scoresVictimsCtrl: scoresVictimsCtrl,
                                  transportInvolvedCtrl: transportInvolvedCtrl,
                                  latitudeCtrl: latitudeCtrl,
                                  longitudeCtrl: longitudeCtrl,
                                  postalCodeCtrl: postalCodeCtrl,
                                  streetCtrl: streetCtrl,
                                  city2Ctrl: city2Ctrl,
                                  subLocalityCtrl: subLocalityCtrl,
                                  administrativeAreaCtrl: administrativeAreaCtrl,
                                  countryCtrl: countryCtrl,
                                  isoCountryCodeCtrl: isoCountryCodeCtrl,
                                  onSave: () async {
                                    final ok = await _confirm(context, 'Deseja salvar este acidente?');
                                    if (ok) await _save(state);
                                  },
                                  onClear: () => _createNew(state),
                                  onGetLocation: () {
                                    context.read<AccidentsBloc>().add(const AccidentsGetLocationRequested());
                                  },
                                  // 🔄 integração form → mapa
                                  onUpdateMapFromLatLng: (lat, lon) => _updateMapFromLatLng(lat, lon, zoom: 18),
                                  onUpdateMapFromCep: (cep) => _updateMapFromCep(cep),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            if (_showTable) ...[
                              const DividerText(title: 'Filtrar por datas'),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: AccidentsSelectorDatesSection(
                                  allAccidents: state.universe,
                                  initialYear: state.year,
                                  initialMonth: state.month,
                                  onSelectionChanged: (res) async {
                                    final y = res.selectedYear, m = res.selectedMonth;
                                    if (y == state.year && m == state.month) return;
                                    context.read<AccidentsBloc>().add(
                                      AccidentsFilterChanged(year: y, month: m),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 8),
                              const DividerText(title: 'Acidentes cadastrados no sistema'),
                              if (pageItems.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: Text('Nenhum acidente encontrado'),
                                )
                              else
                                _buildScrollableTable(
                                  context: context,
                                  pageItems: pageItems,
                                  state: state,
                                  isWide: false,
                                ),
                            ],
                          ],
                        ),
                      ),
                    );

                    // Mapa (acima, se ligado)
                    final topMap = !_showMap
                        ? const SizedBox.shrink()
                        : SizedBox(
                      width: double.infinity,
                      height: mapH,
                      child: Card(
                        elevation: 6,
                        margin: EdgeInsets.zero,
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        clipBehavior: Clip.antiAlias,
                        child: MapInteractivePage(
                          key: const ValueKey('accidents-map-mobile'),
                          initialZoom: 9,
                          activeMap: true,
                          showLegend: true,
                          showSearch: true,
                          onControllerReady: (ctrl) {
                            _mapController = ctrl;
                            if (_pendingCenter != null) {
                              _mapController!.move(_pendingCenter!, 16);
                              _setMapPin?.call(_pendingCenter!); // ✅ pin mesmo após defer
                              _pendingCenter = null;
                            }
                          },
                          onBindSetActivePoint: (setter) => _setMapPin = setter, // ✅ binder
                          onMapTap: (lat, lon) {
                            context.read<AccidentsBloc>().add(
                              AccidentsReverseGeocodeRequested(lat, lon),
                            );
                          },
                          /*overlayBuilder: (mapController, _) => ToolBoxWidget(
                                  mapController: mapController,
                                  onStrokesChanged: (_) {},
                                  onExportPng: (_) async {},
                                ),*/
                        ),
                      ),
                    );

                    return Column(
                      children: [
                        if (_showMap) topMap,
                        if (_showMap) _buildDraggableHorizontalDivider(totalH),
                        Expanded(
                          child: (_showForm || _showTable)
                              ? contentPanel
                              : const Center(child: Text('Selecione um painel para exibir (Formulário/Tabela/Mapa).')),
                        ),
                      ],
                    );
                  }

                  // ================== WIDE ==================
                  final double totalH = constraints.maxHeight;
                  final double minMapH = 320.0;
                  final double maxMapH = (totalH * 0.95).clamp(minMapH, totalH);
                  double mapH = (_splitVWide * totalH).clamp(minMapH, maxMapH);
                  final double clampedV = mapH / totalH;
                  if (clampedV != _splitVWide) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _splitVWide = clampedV);
                    });
                  }

                  // 👉 mínimo de largura para o painel ESQUERDO (tabela/form)
                  const double minLeft = 860.0; // ajuste conforme seu layout

                  // limites padrão do mapa
                  const double minRight = 420.0;
                  final double maxRight = constraints.maxWidth * 0.80;

                  // quanto podemos dar ao mapa sem violar minLeft
                  final double maxRightByLeft = math.max(minRight, constraints.maxWidth - minLeft);

                  // largura desejada do mapa pela fração _splitH
                  final double desiredRight = _splitH * constraints.maxWidth;

                  // largura final do mapa (clamp considerando os dois limites)
                  final double currentRightWidth =
                  _showMap ? desiredRight.clamp(minRight, math.min(maxRight, maxRightByLeft)) : 0.0;

                  // re-normaliza _splitH se passou do permitido (mantém o arraste “consistente”)
                  final double safeH = constraints.maxWidth == 0
                      ? _splitH
                      : (currentRightWidth / (constraints.maxWidth == 0 ? 1 : constraints.maxWidth));
                  if (_showMap && safeH != _splitH) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _splitH = safeH);
                    });
                  }

                  final leftPanel = Theme(
                    data: zeroTableGapsTheme,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(left: 12.0, bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_showForm) ...[
                            const DividerText(title: 'Cadastrar acidentes'),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0), // ↓ menos padding para ganhar largura
                              child: AccidentsFormSection(
                                itemsPerLineOverride: 2,
                                isEditable: true,
                                formValidated: formValidated,
                                currentAccidentId: currentAccidentId,
                                orderCtrl: orderCtrl,
                                dateCtrl: dateCtrl,
                                highwayCtrl: highwayCtrl,
                                cityCtrl: cityCtrl,
                                typeOfAccidentCtrl: typeOfAccidentCtrl,
                                deathCtrl: deathCtrl,
                                scoresVictimsCtrl: scoresVictimsCtrl,
                                transportInvolvedCtrl: transportInvolvedCtrl,
                                latitudeCtrl: latitudeCtrl,
                                longitudeCtrl: longitudeCtrl,
                                postalCodeCtrl: postalCodeCtrl,
                                streetCtrl: streetCtrl,
                                city2Ctrl: city2Ctrl,
                                subLocalityCtrl: subLocalityCtrl,
                                administrativeAreaCtrl: administrativeAreaCtrl,
                                countryCtrl: countryCtrl,
                                isoCountryCodeCtrl: isoCountryCodeCtrl,
                                onSave: () async {
                                  final ok = await _confirm(context, 'Deseja salvar este acidente?');
                                  if (ok) await _save(state);
                                },
                                onClear: () => _createNew(state),
                                onGetLocation: () {
                                  context.read<AccidentsBloc>().add(const AccidentsGetLocationRequested());
                                },
                                // 🔄 integração form → mapa
                                onUpdateMapFromLatLng: (lat, lon) => _updateMapFromLatLng(lat, lon, zoom: 18),
                                onUpdateMapFromCep: (cep) => _updateMapFromCep(cep),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          if (_showTable) ...[
                            const DividerText(title: 'Filtrar por datas'),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: AccidentsSelectorDatesSection(
                                allAccidents: state.universe,
                                initialYear: state.year,
                                initialMonth: state.month,
                                onSelectionChanged: (res) async {
                                  final y = res.selectedYear, m = res.selectedMonth;
                                  if (y == state.year && m == state.month) return;
                                  context.read<AccidentsBloc>().add(
                                    AccidentsFilterChanged(year: y, month: m),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                            const DividerText(title: 'Acidentes cadastrados no sistema'),
                            if (pageItems.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: Text('Nenhum acidente encontrado'),
                              )
                            else
                              _buildScrollableTable(
                                context: context,
                                pageItems: pageItems,
                                state: state,
                                isWide: true,
                              ),
                          ],
                          if (!_showForm && !_showTable)
                            const Padding(
                              padding: EdgeInsets.all(24.0),
                              child:
                              Text('Nenhum painel selecionado na coluna esquerda. Ative Formulário e/ou Tabela.'),
                            ),
                        ],
                      ),
                    ),
                  );

                  final rightMap = !_showMap
                      ? const SizedBox.shrink()
                      : AnimatedContainer(
                    duration: const Duration(milliseconds: 80),
                    curve: Curves.easeOut,
                    width: currentRightWidth,
                    child: MapInteractivePage(
                      key: const ValueKey('accidents-map-wide'),
                      dropPinOnTap: true, // habilita o marcador no tap
                      activeMap: true,
                      showLegend: true,
                      showSearch: true,
                      onControllerReady: (ctrl) {
                        _mapController = ctrl;
                        if (_pendingCenter != null) {
                          _mapController!.move(_pendingCenter!, 16);
                          _setMapPin?.call(_pendingCenter!); // ✅ pin mesmo após defer
                          _pendingCenter = null;
                        }
                      },
                      onBindSetActivePoint: (setter) => _setMapPin = setter, // ✅ binder
                      onMapTap: (lat, lon) {
                        context.read<AccidentsBloc>().add(
                          AccidentsReverseGeocodeRequested(lat, lon),
                        );
                      },
                      /*overlayBuilder: (mapController, _) => ToolBoxWidget(
                              mapController: mapController,
                              onStrokesChanged: (_) {},
                              onExportPng: (_) async {},
                            ),*/
                    ),
                  );

                  return Row(
                    children: [
                      // Se mapa desligado, a esquerda ocupa tudo
                      Expanded(child: leftPanel),
                      if (_showMap) _buildDraggableVerticalDivider(constraints),
                      if (_showMap) rightMap,
                    ],
                  );
                },
              ),

              if (state.saving || state.gettingLocation)
                Stack(
                  children: [
                    ModalBarrier(dismissible: false, color: Colors.black.withOpacity(0.25)),
                    const Center(child: CircularProgressIndicator()),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}
