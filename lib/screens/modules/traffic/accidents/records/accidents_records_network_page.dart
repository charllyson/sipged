// lib/screens/modules/traffic/accidents/records/accidents_records_network_page.dart

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:sipged/_blocs/modules/transit/accidents/accidents_cubit.dart';
import 'package:sipged/_blocs/modules/transit/accidents/accidents_data.dart';
import 'package:sipged/_blocs/modules/transit/accidents/accidents_repository.dart';
import 'package:sipged/_blocs/modules/transit/accidents/accidents_state.dart';

import 'package:sipged/_blocs/system/notification/local/notification_local_cubit.dart';
import 'package:sipged/_blocs/system/notification/notification_data.dart';
import 'package:sipged/_blocs/system/notification/notification_type.dart';

import 'package:sipged/_blocs/system/tenant/tenant_cubit.dart';
import 'package:sipged/_blocs/system/tenant/tenant_state.dart';
import 'package:sipged/_blocs/system/user/user_cubit.dart';

import 'package:sipged/_services/bluetooth/ble_client.dart';
import 'package:sipged/_services/bluetooth/ble_client_iface.dart';

import 'package:sipged/_widgets/buttons/expanded_button_change.dart';
import 'package:sipged/_widgets/dialog/show_dialogs/show_window_dialog.dart';
import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/_widgets/layout/split_layout/split_layout.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots.dart';
import 'package:sipged/_widgets/menu/upBar/up_bar.dart';
import 'package:sipged/_widgets/print/label_bitmap.dart';

import 'accidents_form_section.dart';
import 'accidents_map_section.dart';
import 'accidents_selector_dates_section.dart';
import 'accidents_table_section.dart';

class AccidentsRecordsNetworkPage extends StatefulWidget {
  const AccidentsRecordsNetworkPage({super.key});

  @override
  State<AccidentsRecordsNetworkPage> createState() =>
      _AccidentsRecordsNetworkPageState();
}

class _AccidentsRecordsNetworkPageState
    extends State<AccidentsRecordsNetworkPage> {
  late final AccidentsCubit _cubit;

  AccidentsData _formData = const AccidentsData();
  AccidentsData? _selectedAccident;

  bool formValidated = false;

  bool _showForm = true;
  bool _showTable = true;
  bool _showMap = true;

  bool _firedUserWarmup = false;
  bool _didScheduleInitialLoad = false;
  bool _loadingLocal = false;

  String? _lastTenantId;
  String? _lastFailureMessage;

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

    _cubit = AccidentsCubit(
      repository: AccidentsRepository(),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_firedUserWarmup) {
      _firedUserWarmup = true;

      context.read<UserCubit>().warmup(
        listenRealtime: true,
        bindCurrentUser: true,
      );
    }

    final tenantState = context.read<TenantCubit>().state;
    final tenantId = _tenantIdFromTenantState(tenantState);

    _syncTenant(tenantId);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  String? _cleanId(dynamic value) {
    if (value == null) return null;

    final text = value.toString().trim();

    if (text.isEmpty) return null;
    if (text.toLowerCase() == 'null') return null;

    return text;
  }

  String? _idFromObject(dynamic object) {
    if (object == null) return null;

    try {
      final clean = _cleanId(object.id);
      if (clean != null) return clean;
    } catch (_) {}

    try {
      final clean = _cleanId(object.tenantId);
      if (clean != null) return clean;
    } catch (_) {}

    try {
      final clean = _cleanId(object.companyId);
      if (clean != null) return clean;
    } catch (_) {}

    try {
      final clean = _cleanId(object.uid);
      if (clean != null) return clean;
    } catch (_) {}

    return null;
  }

  String? _tenantIdFromTenantState(TenantState state) {
    final dynamic s = state;

    try {
      final clean = _cleanId(s.activeTenantId);
      if (clean != null) return clean;
    } catch (_) {}

    try {
      final clean = _cleanId(s.currentTenantId);
      if (clean != null) return clean;
    } catch (_) {}

    try {
      final clean = _cleanId(s.tenantId);
      if (clean != null) return clean;
    } catch (_) {}

    try {
      final clean = _cleanId(s.companyId);
      if (clean != null) return clean;
    } catch (_) {}

    try {
      final clean = _idFromObject(s.current);
      if (clean != null) return clean;
    } catch (_) {}

    try {
      final clean = _idFromObject(s.tenant);
      if (clean != null) return clean;
    } catch (_) {}

    try {
      final clean = _idFromObject(s.currentTenant);
      if (clean != null) return clean;
    } catch (_) {}

    try {
      final clean = _idFromObject(s.activeTenant);
      if (clean != null) return clean;
    } catch (_) {}

    try {
      final clean = _idFromObject(s.selectedTenant);
      if (clean != null) return clean;
    } catch (_) {}

    try {
      final clean = _idFromObject(s.company);
      if (clean != null) return clean;
    } catch (_) {}

    try {
      final clean = _idFromObject(s.selectedCompany);
      if (clean != null) return clean;
    } catch (_) {}

    return null;
  }

  void _syncTenant(String? tenantId) {
    final cleanTenantId = tenantId?.trim();

    if (_lastTenantId == cleanTenantId) return;

    _lastTenantId = cleanTenantId;
    _lastFailureMessage = null;
    _didScheduleInitialLoad = false;

    _selectedAccident = null;
    _formData = const AccidentsData();
    formValidated = false;

    _cubit.setActiveTenantId(cleanTenantId);

    if (cleanTenantId == null || cleanTenantId.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      unawaited(_refreshAccidents(forceReload: true));
    });
  }

  Future<void> _refreshAccidents({bool forceReload = true}) async {
    if (!_cubit.hasTenant) return;

    if (mounted) {
      setState(() {
        _loadingLocal = true;
      });
    }

    try {
      if (!_cubit.state.initialized) {
        await _cubit.warmup();
      } else {
        await _cubit.refresh(forceReload: forceReload);
      }

      if (!mounted) return;

      await _createNew(_cubit.state);
    } finally {
      if (mounted) {
        setState(() {
          _loadingLocal = false;
        });
      }
    }
  }

  void _notify({
    required String title,
    String? subtitle,
    NotificationStatus type = NotificationStatus.info,
    String leadingLabel = 'Acidentes',
    Duration duration = const Duration(seconds: 4),
  }) {
    if (!mounted) return;

    context.read<NotificationLocalCubit>().show(
      NotificationData(
        title: title,
        subtitle: subtitle,
        type: type,
        leadingLabel: leadingLabel,
        duration: duration,
      ),
    );
  }

  void _notifyFromContext(
      BuildContext context, {
        required String title,
        String? subtitle,
        NotificationStatus type = NotificationStatus.info,
        String leadingLabel = 'Acidentes',
        Duration duration = const Duration(seconds: 4),
      }) {
    context.read<NotificationLocalCubit>().show(
      NotificationData(
        title: title,
        subtitle: subtitle,
        type: type,
        leadingLabel: leadingLabel,
        duration: duration,
      ),
    );
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

    if (!mounted) return;

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

    await _cubit.saveAccident(dataToSave);
  }

  Future<void> _delete(String id, {int? yearHint}) async {
    await _cubit.deleteAccident(
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

    final point = data.latLng;
    if (point != null) {
      _mapController?.move(point, 18);
      _setActivePoint?.call(point);
    }
  }

  Future<void> _updateMapFromCep(String cep) async {
    await _cubit.geocodeCep(cep);
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
        street: suggestion.street.isNotEmpty
            ? suggestion.street
            : _formData.street,
        subLocality: suggestion.subLocality.isNotEmpty
            ? suggestion.subLocality
            : _formData.subLocality,
        locality: suggestion.city.isNotEmpty
            ? suggestion.city
            : _formData.locality,
        administrativeArea: suggestion.administrativeArea.isNotEmpty
            ? suggestion.administrativeArea
            : _formData.administrativeArea,
        postalCode: suggestion.postalCode.isNotEmpty
            ? suggestion.postalCode
            : _formData.postalCode,
        country: suggestion.country.isNotEmpty
            ? suggestion.country
            : _formData.country,
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

  Future<void> _handlePublicReport(AccidentsData item) async {
    try {
      final url = await _cubit.generatePublicReportLink(
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
                    child: Builder(
                      builder: (btnContext) {
                        return OutlinedButton.icon(
                          icon: const Icon(Icons.copy),
                          label: const Text('Copiar link'),
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(text: url),
                            );

                            if (!btnContext.mounted) return;

                            _notifyFromContext(
                              btnContext,
                              title: 'Copiado',
                              subtitle: 'Link do boletim copiado.',
                              type: NotificationStatus.success,
                              leadingLabel: 'QR',
                              duration: const Duration(seconds: 3),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Builder(
                      builder: (btnContext) {
                        return OutlinedButton.icon(
                          icon: const Icon(Icons.block),
                          label: const Text('Revogar'),
                          onPressed: () async {
                            final ok = await confirmDialog(
                              btnContext,
                              'Deseja revogar o link público deste boletim?',
                            );

                            if (!btnContext.mounted) return;
                            if (!ok) return;

                            await _cubit.revokePublicReportLink(item);

                            if (!btnContext.mounted) return;

                            Navigator.of(btnContext).pop();
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: Builder(
                  builder: (btnContext) {
                    return TextButton(
                      onPressed: () => Navigator.of(btnContext).pop(),
                      child: const Text('Fechar'),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      _notify(
        title: 'Falha ao gerar link',
        subtitle: '$e',
        type: NotificationStatus.error,
        leadingLabel: 'QR',
        duration: const Duration(seconds: 7),
      );
    }
  }

  Future<void> _handlePrintLabel(AccidentsData item) async {
    String publicUrl = '';

    try {
      publicUrl = await _cubit.generatePublicReportLink(
        item,
        expiresIn: const Duration(days: 30),
      );
    } catch (_) {}

    if (!mounted) return;

    final texto = _buildLabelText(item);
    final qrData = _buildLabelQrData(
      item,
      publicUrlOverride: publicUrl,
    );

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
            SelectableText(
              texto,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 180,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Builder(
                  builder: (btnContext) {
                    return TextButton(
                      onPressed: () => Navigator.of(btnContext).pop(false),
                      child: const Text('Cancelar'),
                    );
                  },
                ),
                const SizedBox(width: 8),
                Builder(
                  builder: (btnContext) {
                    return FilledButton.icon(
                      icon: const Icon(Icons.print),
                      label: const Text('Imprimir'),
                      onPressed: () => Navigator.of(btnContext).pop(true),
                    );
                  },
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

      _notify(
        title: 'Etiqueta enviada',
        subtitle:
        'TSPL BITMAP enviado via BLE. useGap=$_useGap gap=$_gapMm invert=$_invertBitmap density=$_density',
        type: NotificationStatus.success,
        leadingLabel: 'Impressão',
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      if (!mounted) return;

      _notify(
        title: 'Falha ao imprimir',
        subtitle: '$e',
        type: NotificationStatus.error,
        leadingLabel: 'Impressão',
        duration: const Duration(seconds: 7),
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

    final limitFeedMm =
    (alturaMm + (useGap ? gapMm : 0) + 20).clamp(30, 120).toInt();

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

    final header = setupLines.join('\r\n').codeUnits;
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

    final id = (d.id ?? '').trim();

    if (id.isNotEmpty) return 'sipged://accidents/$id';

    final ordem = (d.order ?? '').toString();

    return 'sipged://accidents/order/$ordem';
  }

  Widget _buildScrollableTable({
    required BuildContext context,
    required List<AccidentsData> items,
    required AccidentsState state,
  }) {
    return AccidentsTableSection(
      onPublicLink: (item) async => _handlePublicReport(item),
      onPrint: (item) async => _handlePrintLabel(item),
      listData: items,
      selectedItem: _selectedAccident,
      onTapItem: (item) => _fillFields(item),
      onDelete: (id) async {
        final toDelete = state.view.firstWhere(
              (e) => e.id == id,
          orElse: () => AccidentsData(id: id),
        );

        final ok = await confirmDialog(
          context,
          'Deseja apagar este acidente?',
        );

        if (!context.mounted) return;
        if (!ok) return;

        await _delete(
          id,
          yearHint: toDelete.date?.year,
        );
      },
    );
  }

  Widget _buildLeftPanel(AccidentsState state) {
    final items = state.view;

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
        padding: const EdgeInsets.only(
          left: 12,
          bottom: 12,
          right: 8,
        ),
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
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

                      if (!context.mounted) return;
                      if (!ok) return;

                      await _save(state);
                    },
                    onClear: () => _createNew(state),
                    onGetLocation: () {
                      _cubit.getCurrentLocation();
                    },
                    onUpdateMapFromLatLng: (lat, lon) {
                      final latLng = LatLng(lat, lon);

                      _mapController?.move(latLng, 18);
                      _setActivePoint?.call(latLng);

                      _cubit.reverseGeocode(
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
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

                        await _cubit.changeFilter(
                          year: y,
                          month: m,
                          city: state.city,
                          type: state.type,
                          severity: state.severity,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Acidentes cadastrados no sistema',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Nenhum acidente encontrado'),
                    )
                  else
                    _buildScrollableTable(
                      context: context,
                      items: items,
                      state: state,
                    ),
                ],
                if (!_showForm && !_showTable)
                  const Padding(
                    padding: EdgeInsets.all(24),
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
        _cubit.reverseGeocode(
          latitude: lat,
          longitude: lon,
        );
      },
    );
  }

  Widget _emptyState({
    required String title,
    required String subtitle,
    IconData icon = Icons.warning_amber_rounded,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 42,
              color: Colors.grey.shade500,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoTenantScaffold() {
    return Scaffold(
      appBar: const UpBar(
        titleWidgets: [
          Text('Acidentes'),
        ],
      ),
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const BackgroundChange(),
          _emptyState(
            title: 'Nenhuma empresa selecionada',
            subtitle: 'Selecione uma empresa para visualizar os acidentes.',
            icon: Icons.business_outlined,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocListener<TenantCubit, TenantState>(
        listener: (context, tenantState) {
          final tenantId = _tenantIdFromTenantState(tenantState);
          _syncTenant(tenantId);
        },
        child: Builder(
          builder: (context) {
            final tenantState = context.watch<TenantCubit>().state;
            final tenantId = _tenantIdFromTenantState(tenantState);

            if (tenantId == null || tenantId.isEmpty) {
              return _buildNoTenantScaffold();
            }

            return BlocConsumer<AccidentsCubit, AccidentsState>(
              listenWhen: (prev, curr) {
                return prev.error != curr.error ||
                    prev.success != curr.success ||
                    prev.locationError != curr.locationError ||
                    prev.locationSuggestion != curr.locationSuggestion;
              },
              listener: (context, state) async {
                if (state.error != null && state.error!.trim().isNotEmpty) {
                  if (_lastFailureMessage != state.error) {
                    _lastFailureMessage = state.error;

                    _notify(
                      title: 'Falha na operação',
                      subtitle: state.error!,
                      type: NotificationStatus.error,
                      leadingLabel: 'Acidentes',
                      duration: const Duration(seconds: 6),
                    );
                  }
                } else {
                  _lastFailureMessage = null;
                }

                if (state.success != null && state.success!.trim().isNotEmpty) {
                  _notify(
                    title: 'Operação concluída',
                    subtitle: state.success!,
                    type: NotificationStatus.success,
                    leadingLabel: 'Acidentes',
                    duration: const Duration(seconds: 4),
                  );

                  await _createNew(state);

                  if (!context.mounted) return;
                }

                if (state.locationError != null &&
                    state.locationError!.trim().isNotEmpty) {
                  _notify(
                    title: 'Falha ao obter endereço',
                    subtitle: state.locationError!,
                    type: NotificationStatus.error,
                    leadingLabel: 'Localização',
                    duration: const Duration(seconds: 6),
                  );
                }

                if (state.locationSuggestion != null) {
                  _applyLocationSuggestionToForm(state);
                }
              },
              builder: (context, state) {
                if (!_didScheduleInitialLoad &&
                    !_loadingLocal &&
                    !state.initialized) {
                  _didScheduleInitialLoad = true;

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;

                    unawaited(_refreshAccidents(forceReload: true));
                  });
                }

                final loading = _loadingLocal ||
                    (!state.initialized && state.loading);

                return Scaffold(
                  appBar: UpBar(
                    titleWidgets: const [
                      Text('Acidentes'),
                    ],
                    actions: [
                      IconButton(
                        tooltip: 'Formulário',
                        icon: Icon(
                          _showForm
                              ? Icons.description
                              : Icons.description_outlined,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            _showForm = !_showForm;
                          });
                        },
                      ),
                      IconButton(
                        tooltip: 'Tabela',
                        icon: Icon(
                          _showTable
                              ? Icons.table_chart
                              : Icons.table_chart_outlined,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            _showTable = !_showTable;
                          });
                        },
                      ),
                      IconButton(
                        tooltip: 'Mapa',
                        icon: Icon(
                          _showMap ? Icons.map : Icons.map_outlined,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            _showMap = !_showMap;
                          });
                        },
                      ),
                      IconButton(
                        tooltip: 'Atualizar',
                        icon: const Icon(
                          Icons.refresh,
                          color: Colors.white,
                        ),
                        onPressed: loading
                            ? null
                            : () {
                          unawaited(
                            _refreshAccidents(forceReload: true),
                          );
                        },
                      ),
                    ],
                  ),
                  backgroundColor: Colors.white,
                  body: Stack(
                    children: [
                      const BackgroundChange(),
                      if (loading && state.universe.isEmpty)
                        const Center(
                          child: LoadingTreeDots(
                            color: Colors.blue,
                            message: Text('Carregando acidentes ...'),
                          ),
                        )
                      else
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
                            const Center(
                              child: LoadingTreeDots(size: 120),
                            ),
                          ],
                        ),
                    ],
                  ),
                  floatingActionButton: ExpandedButtonChange(
                    icon: Icons.add,
                    label: 'Novo acidente',
                    color: Colors.blue,
                    onPressed: state.saving || state.gettingLocation
                        ? null
                        : () {
                      unawaited(_createNew(state));
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}