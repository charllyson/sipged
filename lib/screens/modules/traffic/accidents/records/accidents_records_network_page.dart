// lib/screens/modules/traffic/accidents/records/accidents_records_network_page.dart
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/_widgets/print/label_bitmap.dart';
import 'package:sipged/_widgets/layout/split_layout/split_layout.dart';
import 'package:sipged/_widgets/menu/upBar/up_bar.dart';

// Notificações / dialogs
import 'package:sipged/_widgets/notification/app_notification.dart';
import 'package:sipged/_widgets/notification/notification_center.dart';
import 'package:sipged/_widgets/windows/show_window_dialog.dart';

// ✅ BLE + Bitmap
import 'package:sipged/_services/bluetooth/ble_client.dart';
import 'package:sipged/_services/bluetooth/ble_client_iface.dart';

// Cubit do módulo
import 'package:sipged/_blocs/modules/transit/accidents/accidents_cubit.dart';
import 'package:sipged/_blocs/modules/transit/accidents/accidents_state.dart';
import 'package:sipged/_blocs/modules/transit/accidents/accidents_data.dart';

// SEÇÕES
import 'accidents_form_section.dart';
import 'accidents_selector_dates_section.dart';
import 'accidents_table_section.dart';
import 'accidents_map_section.dart';

class AccidentsRecordsNetworkPage extends StatelessWidget {
  const AccidentsRecordsNetworkPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _AccidentsRecordsNetworkPageInner();
  }
}

class _AccidentsRecordsNetworkPageInner extends StatefulWidget {
  const _AccidentsRecordsNetworkPageInner();

  @override
  State<_AccidentsRecordsNetworkPageInner> createState() =>
      _AccidentsRecordsNetworkPageInnerState();
}

class _AccidentsRecordsNetworkPageInnerState
    extends State<_AccidentsRecordsNetworkPageInner> {
  bool _inited = false;

  AccidentsData _formData = const AccidentsData();
  AccidentsData? _selectedAccident;

  bool formValidated = false;

  bool _showForm = true;
  bool _showTable = true;
  bool _showMap = true;

  final ScrollController _tableHCtrl = ScrollController();
  final ScrollController _tableVCtrl = ScrollController();

  MapController? _mapController;
  void Function(LatLng)? _setActivePoint;

  static const double _labelWidthMm = 40.0;
  static const double _labelHeightMm = 30.0;
  static const int _dpi = 203;

  static const bool _useGap = true;
  static const double _gapMm = 2.0;

  static const int _density = 8;
  static const double _speed = 4.0;
  static const int _direction = 1;

  static const bool _invertBitmap = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _inited) return;
      context.read<AccidentsCubit>().warmup();
      _inited = true;
    });
  }

  @override
  void dispose() {
    _tableHCtrl.dispose();
    _tableVCtrl.dispose();
    super.dispose();
  }

  bool _isFormValid(AccidentsData d) {
    if (d.date == null) return false;
    final cityDesc = (d.city ?? '').trim();
    final cityAddr = (d.locality ?? '').trim();
    if (cityDesc.isEmpty && cityAddr.isEmpty) return false;
    if ((d.typeOfAccident ?? '').trim().isEmpty) return false;
    return true;
  }

  Future<void> _createNew(AccidentsState st) async {
    final maxOrder = st.universe
        .map((e) => e.order ?? 0)
        .fold<int>(0, (prev, val) => math.max(prev, val));

    final nextOrder = maxOrder + 1;

    setState(() {
      _selectedAccident = null;
      _formData = AccidentsData(
        order: nextOrder,
        date: DateTime.now(),
      );
      formValidated = _isFormValid(_formData);
    });
  }

  Future<void> _save(AccidentsState st) async {
    final dataToSave = _formData.copyWith(
      id: _selectedAccident?.id ?? _formData.id,
    );
    await context.read<AccidentsCubit>().saveAccident(dataToSave);
  }

  Future<void> _delete(String id, {int? yearHint}) async {
    await context.read<AccidentsCubit>().deleteAccident(
      id: id,
      yearHint: yearHint,
    );
  }

  void _fillFields(AccidentsData data) {
    setState(() {
      _selectedAccident = data;
      _formData = data;
      formValidated = _isFormValid(_formData);
    });
  }

  Future<void> _updateMapFromCep(String cep) async {
    await context.read<AccidentsCubit>().geocodeCep(cep);
  }

  void _applyLocationSuggestionToForm(AccidentsState state) {
    final suggestion = state.locationSuggestion;
    if (suggestion == null) return;

    final lat = suggestion.latitude;
    final lon = suggestion.longitude;

    LatLng? latLng;
    if (lat != null && lon != null) {
      latLng = LatLng(lat, lon);
    }

    setState(() {
      _formData = _formData.copyWith(
        latLng: latLng ?? _formData.latLng,
        street: suggestion.street.isNotEmpty ? suggestion.street : _formData.street,
        subLocality: suggestion.subLocality.isNotEmpty
            ? suggestion.subLocality
            : _formData.subLocality,
        locality: suggestion.city.isNotEmpty ? suggestion.city : _formData.locality,
        administrativeArea: suggestion.administrativeArea.isNotEmpty
            ? suggestion.administrativeArea
            : _formData.administrativeArea,
        postalCode: suggestion.postalCode.isNotEmpty
            ? suggestion.postalCode
            : _formData.postalCode,
        country: suggestion.country.isNotEmpty ? suggestion.country : _formData.country,
        isoCountryCode: suggestion.isoCountryCode.isNotEmpty
            ? suggestion.isoCountryCode
            : _formData.isoCountryCode,
        city: (_formData.city == null || _formData.city!.trim().isEmpty)
            ? suggestion.city
            : _formData.city,
      );

      formValidated = _isFormValid(_formData);
    });

    if (latLng != null) {
      _mapController?.move(latLng, 18);
      _setActivePoint?.call(latLng);
    }
  }

  // ===========================================================================
  // ✅ QR Público (gerar/mostrar)
  // ===========================================================================

  Future<void> _handlePublicReport(AccidentsData item) async {
    try {
      final url = await context.read<AccidentsCubit>().generatePublicReportLink(
        item,
        expiresIn: const Duration(days: 30),
      );

      if (!mounted) return;

      await showWindowDialog<void>(
        context: context,
        title: 'Boletim público (QR)',
        width: 520,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              QrImageView(
                data: url,
                version: QrVersions.auto,
                size: 260,
              ),
              const SizedBox(height: 12),
              SelectableText(
                url,
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.copy),
                      label: const Text('Copiar link'),
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: url));
                        if (!mounted) return;
                        NotificationCenter.instance.show(
                          AppNotification(
                            title: const Text('Copiado'),
                            subtitle: const Text('Link do boletim copiado.'),
                            type: AppNotificationType.success,
                            leadingLabel: const Text('QR'),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.block),
                      label: const Text('Revogar'),
                      onPressed: () async {
                        final ok = await confirmDialog(
                          context,
                          'Deseja revogar o link público deste boletim?',
                        );
                        if (!ok) return;
                        await context.read<AccidentsCubit>().revokePublicReportLink(item);
                        if (!mounted) return;
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Fechar'),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Falha ao gerar link'),
          subtitle: Text('$e'),
          type: AppNotificationType.error,
          leadingLabel: const Text('QR'),
          duration: const Duration(seconds: 7),
        ),
      );
    }
  }

  // ===========================================================================
  // ✅ PRINT (TSPL BITMAP via BLE)
  // ===========================================================================

  Future<void> _handlePrintLabel(AccidentsData item) async {
    // ✅ garante link público antes de imprimir (o QR vai ser o link público)
    String publicUrl = '';
    try {
      publicUrl = await context.read<AccidentsCubit>().generatePublicReportLink(
        item,
        expiresIn: const Duration(days: 30),
      );
    } catch (_) {
      // fallback: imprime com sipged://...
    }

    final texto = _buildLabelText(item);
    final qrData = _buildLabelQrData(item, publicUrlOverride: publicUrl);

    final confirm = await showWindowDialog<bool>(
      context: context,
      title: 'Prévia da print',
      width: 520,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  icon: const Icon(Icons.print),
                  label: const Text('Imprimir'),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (!mounted || confirm != true) return;

    try {
      await _printBitmapLabelTspl(
        texto: texto,
        qrData: qrData,
        larguraMm: _labelWidthMm,
        alturaMm: _labelHeightMm,
        dpi: _dpi,
      );

      if (!mounted) return;
      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Etiqueta enviada'),
          subtitle: Text(
            'TSPL BITMAP enviado via BLE. '
                'useGap=$_useGap gap=$_gapMm invert=$_invertBitmap density=$_density',
          ),
          type: AppNotificationType.success,
          leadingLabel: const Text('Impressão'),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Falha ao imprimir'),
          subtitle: Text('$e'),
          type: AppNotificationType.error,
          leadingLabel: const Text('Impressão'),
          duration: const Duration(seconds: 7),
        ),
      );
    }
  }

  Future<void> _printBitmapLabelTspl({
    required String texto,
    required String qrData,
    required double larguraMm,
    required double alturaMm,
    required int dpi,
  }) async {
    final ble = createBleClient();
    await ble.connect();

    try {
      final mono = await renderLabelMonoPackedRowAligned(
        larguraMm: larguraMm,
        alturaMm: alturaMm,
        texto: texto,
        qrData: qrData,
        dpi: dpi,
        threshold: 128,
        cfg: const LabelLayoutConfig(),
      );

      await _sendTsplBitmap(
        ble: ble,
        bmp: mono,
        larguraMm: larguraMm,
        alturaMm: alturaMm,
        gapMm: _gapMm,
        useGap: _useGap,
        density: _density,
        speed: _speed,
        direction: _direction,
        invertBitmap: _invertBitmap,
      );
    } finally {
      await ble.disconnect();
    }
  }

  Future<void> _sendTsplBitmap({
    required LabelBleClient ble,
    required MonoBitmap bmp,
    required double larguraMm,
    required double alturaMm,
    required double gapMm,
    required bool useGap,
    required int density,
    required double speed,
    required int direction,
    required bool invertBitmap,
  }) async {
    final widthPx = bmp.widthPx;
    final heightPx = bmp.heightPx;
    final bytesPerRow = (widthPx + 7) >> 3;

    final limitFeedMm = (alturaMm + (useGap ? gapMm : 0) + 20)
        .clamp(30, 120)
        .toInt();

    final setupLines = <String>[
      'SIZE $larguraMm mm,$alturaMm mm',
      useGap ? 'GAP $gapMm mm,0 mm' : 'GAP 0,0',
      'SPEED $speed',
      'DENSITY $density',
      'DIRECTION $direction',
      'REFERENCE 0,0',
      'OFFSET 0 mm',
      'SET TEAR OFF',
      'LIMITFEED $limitFeedMm mm',
      'CLS',
      'BITMAP 0,0,$bytesPerRow,$heightPx,0,',
    ];

    final bytes = invertBitmap
        ? Uint8List.fromList(bmp.bytes.map((b) => (~b) & 0xFF).toList())
        : bmp.bytes;

    final header = (setupLines.join('\r\n')).codeUnits;
    final tail = '\r\nPRINT 1,1\r\n'.codeUnits;

    final payload = BytesBuilder()
      ..add(Uint8List.fromList(header))
      ..add(bytes)
      ..add(Uint8List.fromList(tail));

    await ble.writeAll(payload.toBytes(), chunk: 180);
  }

  String _buildLabelText(AccidentsData d) {
    final ordem = (d.order ?? '-').toString();
    final cidade = (d.city ?? d.locality ?? '-').trim();
    final tipo = (d.typeOfAccident ?? '-').trim();
    final data = d.date?.toString().split(' ').first ?? '-';
    return 'ACIDENTE #$ordem • $data\n$cidade\n$tipo';
  }

  String _buildLabelQrData(
      AccidentsData d, {
        String? publicUrlOverride,
      }) {
    final override = (publicUrlOverride ?? '').trim();
    if (override.isNotEmpty) return override;

    // fallback antigo
    final id = (d.id ?? '').trim();
    if (id.isNotEmpty) return 'sipged://accidents/$id';
    final ordem = (d.order ?? '').toString();
    return 'sipged://accidents/order/$ordem';
  }

  Widget _buildScrollableTable({
    required BuildContext context,
    required List<AccidentsData> pageItems,
    required AccidentsState state,
  }) {
    final tableCore = AccidentsTableSection(
      onPublicLink: (item) async => _handlePublicReport(item),
      onPrint: (item) async => _handlePrintLabel(item),
      listData: pageItems,
      selectedItem: _selectedAccident,
      currentPage: state.currentPage,
      totalPages: state.totalPages,
      onPageChange: (p) async => context.read<AccidentsCubit>().changePage(p),
      onTapItem: (item) => _fillFields(item),
      onDelete: (id) async {
        final toDelete = state.view.firstWhere(
              (e) => e.id == id,
          orElse: () => AccidentsData(id: id),
        );
        final ok = await confirmDialog(context, 'Deseja apagar este acidente?');
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
                  notificationPredicate: (notif) =>
                  notif.metrics.axis == Axis.vertical,
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
            final bool narrow = c.maxWidth < 700;
            final int itemsPerLine = narrow ? 1 : 2;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_showForm) ...[
                  const Text(
                    'Cadastrar acidentes',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  AccidentsFormSection(
                    itemsPerLineOverride: itemsPerLine,
                    isEditable: true,
                    formValidated: formValidated,
                    currentAccidentId: _selectedAccident?.id,
                    data: _formData,
                    onChanged: (updated) {
                      setState(() {
                        _formData = updated;
                        formValidated = _isFormValid(updated);
                      });
                    },
                    onSave: () async {
                      final ok = await confirmDialog(
                        context,
                        'Deseja salvar este acidente?',
                      );
                      if (ok) await _save(state);
                    },
                    onClear: () => _createNew(state),
                    onGetLocation: () {
                      context.read<AccidentsCubit>().getCurrentLocation();
                    },
                    onUpdateMapFromLatLng: (lat, lon) {
                      final latLng = LatLng(lat, lon);
                      _mapController?.move(latLng, 18);
                      _setActivePoint?.call(latLng);

                      context.read<AccidentsCubit>().reverseGeocode(
                        latitude: lat,
                        longitude: lon,
                      );
                    },
                    onUpdateMapFromCep: (cep) => _updateMapFromCep(cep),
                  ),
                  const SizedBox(height: 8),
                ],
                if (_showTable) ...[
                  const Text(
                    'Filtrar por datas',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: AccidentsSelectorDatesSection(
                      allAccidents: state.universe,
                      initialYear: state.year,
                      initialMonth: state.month,
                      onSelectionChanged: (res) async {
                        final y = res.selectedYear;
                        final m = res.selectedMonth;
                        if (y == state.year && m == state.month) return;
                        context.read<AccidentsCubit>().changeFilter(year: y, month: m);
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Acidentes cadastrados no sistema',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
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
                    child: Text(
                      'Nenhum painel selecionado. Ative Formulário e/ou Tabela.',
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildRightMap() {
    return AccidentsMapSection(
      onControllerReady: (mc) => _mapController = mc,
      onBindSetActivePoint: (setPoint) => _setActivePoint = setPoint,
      onMapTap: (lat, lon) {
        context.read<AccidentsCubit>().reverseGeocode(
          latitude: lat,
          longitude: lon,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AccidentsCubit, AccidentsState>(
      listenWhen: (prev, curr) =>
      prev.error != curr.error ||
          prev.success != curr.success ||
          prev.locationError != curr.locationError ||
          prev.locationSuggestion != curr.locationSuggestion,
      listener: (context, state) async {
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

        if (state.locationError != null &&
            state.locationError!.trim().isNotEmpty) {
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

        if (state.locationSuggestion != null) {
          _applyLocationSuggestionToForm(state);
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(72),
            child: UpBar(
              actions: [
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
              const BackgroundChange(),
              LayoutBuilder(
                builder: (context, c) {
                  final left = _buildLeftPanel(state);
                  final right = _buildRightMap();

                  return SplitLayout(
                    left: left,
                    right: right,
                    showRightPanel: _showMap,
                    stackedRightOnTop: true,
                  );
                },
              ),
              if (state.saving || state.gettingLocation)
                Stack(
                  children: [
                    ModalBarrier(
                      dismissible: false,
                      color: Colors.black.withValues(alpha: 0.25),
                    ),
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