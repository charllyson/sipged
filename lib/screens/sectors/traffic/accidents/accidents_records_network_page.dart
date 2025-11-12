// lib/screens/sectors/traffic/accidents/accidents_records_network_page.dart
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:siged/_services/print/label_print_service.dart';

import 'package:siged/_widgets/background/background_cleaner.dart';
import 'package:siged/_widgets/footBar/foot_bar.dart';
import 'package:siged/_widgets/texts/divider_text.dart';
import 'package:siged/_widgets/upBar/up_bar.dart';
import 'package:siged/_widgets/map/map_interactive.dart';
import 'package:siged/_widgets/toolBox/tool_widget.dart';
import 'package:siged/_widgets/layout/responsive_split_view.dart';

// Bloc
import 'package:siged/_blocs/sectors/transit/accidents/accidents_bloc.dart';
import 'package:siged/_blocs/sectors/transit/accidents/accidents_event.dart';
import 'package:siged/_blocs/sectors/transit/accidents/accidents_state.dart';
import 'package:siged/_blocs/sectors/transit/accidents/accidents_data.dart';

// Utils
import 'package:siged/_utils/formats/format_field.dart';

// SEÇÕES
import '../../../../_services/print/label_bitmap.dart';
import '../../../../_widgets/bluetooth/bitmap/ble_client.dart';
import 'accidents_form_section.dart';
import 'accidents_selector_dates_section.dart';
import 'accidents_table_section.dart';

// Notificações
import 'package:siged/_widgets/notification/app_notification.dart';
import 'package:siged/_widgets/notification/notification_center.dart';

class AccidentsRecordsNetworkPage extends StatefulWidget {
  const AccidentsRecordsNetworkPage({super.key});

  @override
  State<AccidentsRecordsNetworkPage> createState() => _AccidentsRecordsNetworkPageState();
}

class _AccidentsRecordsNetworkPageState extends State<AccidentsRecordsNetworkPage> {
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

  // ===== Visibilidade (toggles) =====
  bool _showForm = true;
  bool _showTable = true;
  bool _showMap = true;

  // ===== Scroll controllers da TABELA =====
  final ScrollController _tableHCtrl = ScrollController();
  final ScrollController _tableVCtrl = ScrollController();

  // ===== Mapa: controller externo + buffer de centralização =====
  MapController? _mapController;
  LatLng? _pendingCenter;

  // setter do pin que vem do MapInteractivePage
  void Function(LatLng p)? _setMapPin;

  // ===== Helpers =====
  void _validateForm() {
    final ok =
        (cityCtrl.text.trim().isNotEmpty || city2Ctrl.text.trim().isNotEmpty) &&
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
    _setMapPin?.call(p);
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

    final nextOrder =
    ((st.view.map((e) => e.order ?? 0).fold<int>(0, (a, b) => a > b ? a : b)) + 1);
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

  // aplica sugestão de endereço vinda do Bloc (View-only)
  void _applyLocationSuggestion(AddressSuggestion s) {
    if (s.latitude != null) latitudeCtrl.text = s.latitude!.toStringAsFixed(6);
    if (s.longitude != null) longitudeCtrl.text = s.longitude!.toStringAsFixed(6);

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
  }) {
    final tableCore = AccidentsTableSection(
      /*onPrint: (item) => LabelPrintService.printAccident(
        context,
        item,
        presetIndex: 0, // 14×30, 14×40, 14×50
        gapMm: 10, // padrão 10mm
      ),*/
      onPrint: (a){

      },
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

  // ===== Painel esquerdo (form + filtros + tabela), adaptando itens/linha pela largura =====
  Widget _buildLeftPanel(AccidentsState state) {
    final pageItems = state.pageItems;

    final zeroTableGapsTheme = Theme.of(context).copyWith(
      dataTableTheme: const DataTableThemeData(
        horizontalMargin: 0,
        columnSpacing: 20,
        dividerThickness: 1,
      ),
    );

    return Theme(
      data: zeroTableGapsTheme,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 12.0, bottom: 12.0, right: 8.0),
        child: LayoutBuilder(
          builder: (context, c) {
            final bool narrow = c.maxWidth < 700; // define itens por linha no form
            final int itemsPerLine = narrow ? 1 : 2;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_showForm) ...[
                  const DividerText(title: 'Cadastrar acidentes'),
                  const SizedBox(height: 8),
                  AccidentsFormSection(
                    itemsPerLineOverride: itemsPerLine,
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
                    onUpdateMapFromLatLng: (lat, lon) => _updateMapFromLatLng(lat, lon, zoom: 18),
                    onUpdateMapFromCep: (cep) => _updateMapFromCep(cep),
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
                    ),
                ],
                if (!_showForm && !_showTable)
                  const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text('Nenhum painel selecionado. Ative Formulário e/ou Tabela.'),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ===== Painel direito (mapa) =====
  Widget _buildRightMap() {
    return MapInteractivePage(
      key: const ValueKey('accidents-map'),
      dropPinOnTap: true,
      activeMap: true,
      showLegend: true,
      showSearch: true,
      onControllerReady: (ctrl) {
        _mapController = ctrl;
        if (_pendingCenter != null) {
          _mapController!.move(_pendingCenter!, 16);
          _setMapPin?.call(_pendingCenter!);
          _pendingCenter = null;
        }
      },
      onBindSetActivePoint: (setter) => _setMapPin = setter,
      onMapTap: (lat, lon) {
        context.read<AccidentsBloc>().add(AccidentsReverseGeocodeRequested(lat, lon));
      },
      /*overlayBuilder: (mapController, _) => ToolBoxWidget(
        mapController: mapController,
        onStrokesChanged: (_) {},
        onExportPng: (_) async {},
      ),*/
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

        // Aplicar sugestão de endereço + centralizar mapa + pin
        if (state.locationSuggestion != null) {
          final s = state.locationSuggestion!;
          _applyLocationSuggestion(s);

          final p =
          (s.latitude != null && s.longitude != null) ? LatLng(s.latitude!, s.longitude!) : null;

          if (p != null) {
            if (_mapController != null) {
              _mapController!.move(p, 16);
            } else {
              _pendingCenter = p;
            }
            _setMapPin?.call(p);
          }
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(74),
            child: UpBar(
              showPhotoMenu: true,
              actions: [
                /*FilledButton(
                  onPressed: () async {
                    final ble = createBleClient();
                    await ble.connect();

                    // Tamanho da etiqueta (14×30 mm)
                    const larguraMm = 14.0;
                    const alturaMm = 30.0;
                    const dpi = 203;

                    // Converte mm → px (com múltiplo de 8)
                    int _mmToPx(double mm) {
                      final px = (mm * dpi / 25.4).round();
                      return px + (8 - px % 8) % 8; // força múltiplo de 8
                    }

                    final width = _mmToPx(larguraMm);
                    final height = _mmToPx(alturaMm);
                    final bytesPerRow = (width + 7) >> 3;
                    final totalBytes = bytesPerRow * height;

                    // Cria imagem preta sólida
                    final blackData = Uint8List.fromList(List.generate(totalBytes, (_) => 0xFF));
                    //final mono = MonoBitmap(blackData, width, height);

                    // Monta ESC/POS job simples com GAP + Feed
                    final job = BytesBuilder();

                    // ESC @ init
                    job.add([0x1B, 0x40]);

                    // Alinhamento: left
                    job.add([0x1B, 0x61, 0x00]);

                    // Bold ON
                    job.add([0x1B, 0x45, 1]);

                    // GS v 0 m xL xH yL yH {data}
                    final xL = bytesPerRow & 0xFF;
                    final xH = (bytesPerRow >> 8) & 0xFF;
                    final yL = height & 0xFF;
                    final yH = (height >> 8) & 0xFF;
                    job.add([0x1D, 0x76, 0x30, 0x00, xL, xH, yL, yH]);
                    job.add(blackData);

                    // GAP: avança papel ~10 mm (80 dots)
                    job.add([0x1B, 0x4A, 80]);

                    // Feed final (reforço)
                    job.add([0x0A]);

                    final bytes = job.toBytes();

                    // Envia com chunk de 12 e delay maior
                    await ble.writeAll(bytes, chunk: 12);
                    await Future.delayed(const Duration(milliseconds: 30));
                    await ble.disconnect();
                    await ble.writeAll(bytes, chunk: 12);

                    // Feedback
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Etiqueta preta enviada para a impressora.')),
                      );
                    }
                  },
                  child: const Text('Teste etiqueta preta'),
                ),*/
                IconButton(
                  tooltip: 'Formulário',
                  icon: Icon(
                    _showForm ? Icons.description : Icons.description_outlined,
                    color: Colors.white,
                  ),
                  onPressed: () => setState(() => _showForm = !_showForm),
                ),
                IconButton(
                  tooltip: 'Tabela',
                  icon: Icon(
                    _showTable ? Icons.table_chart : Icons.table_chart_outlined,
                    color: Colors.white,
                  ),
                  onPressed: () => setState(() => _showTable = !_showTable),
                ),
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
              // Usamos LayoutBuilder para passar rightPanelWidth/bottomPanelHeight = 50% (inicial 50/50)
              LayoutBuilder(
                builder: (context, c) {
                  final left = _buildLeftPanel(state);
                  final right = _buildRightMap();

                  final double rightHalf = (c.maxWidth.isFinite ? c.maxWidth : 1200.0) / 2;
                  final double bottomHalf = (c.maxHeight.isFinite ? c.maxHeight : 800.0) / 2;

                  return ResponsiveSplitView(
                    left: left,
                    right: right,
                    showRightPanel: _showMap,
                    breakpoint: 1060.0,
                    rightPanelWidth: rightHalf,       // inicia 50% no wide
                    bottomPanelHeight: bottomHalf,    // inicia 50% no stacked
                    showDividers: true,
                    dividerThickness: 12.0,
                    dividerBackgroundColor: Colors.white,
                    dividerBorderColor: Colors.grey.shade300,
                    gripColor: const Color(0xFFB0B0B0),
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
