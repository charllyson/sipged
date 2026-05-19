import 'package:flutter/material.dart';

import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_linear_lane_data.dart';
import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_linear_services_data.dart';

import 'package:sipged/_widgets/dialog/windows/window_dialog.dart';
import 'package:sipged/screens/modules/operation/schedule/common/schedule_actions_buttons.dart';
import 'package:sipged/screens/modules/operation/schedule/common/schedule_header_dialog.dart';
import 'package:sipged/screens/modules/operation/schedule/linear/editor/lanes/schedule_lanes_profile.dart';
import 'package:sipged/screens/modules/operation/schedule/linear/editor/services/schedule_services_profile.dart';

class ScheduleLaneResult {
  const ScheduleLaneResult({
    required this.lanes,
    required this.services,
  });

  final List<ScheduleLinearLaneData> lanes;
  final List<ScheduleLinearServicesData> services;
}

class ScheduleLaneEdit extends StatefulWidget {
  const ScheduleLaneEdit({
    super.key,
    required this.initialRows,
    required this.initialServices,
    required this.selectedServiceKey,
    this.selectedServiceLabel,
    this.onImportGeometry,
  });

  final List<ScheduleLinearLaneData> initialRows;
  final List<ScheduleLinearServicesData> initialServices;
  final String selectedServiceKey;
  final String? selectedServiceLabel;

  final Future<void> Function()? onImportGeometry;

  @override
  State<ScheduleLaneEdit> createState() => _ScheduleLaneEditState();
}

class _ScheduleLaneEditState extends State<ScheduleLaneEdit> {
  final List<ScheduleLinearLaneData> _rows = <ScheduleLinearLaneData>[];
  final List<ScheduleLinearServicesData> _services =
  <ScheduleLinearServicesData>[];

  final Set<String> _lockedIds = <String>{};

  String _activeServiceKey = ScheduleLinearServicesData.geralKey;

  bool _importingGeometry = false;

  static const double _desktopSectionTopPadding = 8.0;
  static const double _mobileContentTopPadding = 8.0;
  static const double _mobileContentBottomPadding = 16.0;
  static const double _desktopContentBottomPadding = 8.0;

  bool get _isActiveGeral {
    return _activeServiceKey == ScheduleLinearServicesData.geralKey;
  }

  String get _serviceKey {
    return _activeServiceKey.trim();
  }

  @override
  void initState() {
    super.initState();

    _activeServiceKey = _cleanKey(widget.selectedServiceKey);

    if (_activeServiceKey.isEmpty) {
      _activeServiceKey = ScheduleLinearServicesData.geralKey;
    }

    _buildInitialServices();
    _buildInitialRows();

    if (_rows.isEmpty) {
      _createDefaultRows();
    }

    if (_services.isEmpty) {
      _services.add(ScheduleLinearServicesData.emptyGeral);
    }

    if (!_services.any((service) => service.key == _activeServiceKey)) {
      _activeServiceKey = ScheduleLinearServicesData.geralKey;
    }

    _normalizeServiceLayerOrders();
    _sortServices();
    _lockCentralRows();
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.disposeEditorControllers();
    }

    super.dispose();
  }

  String _cleanKey(String value) {
    return value.trim();
  }

  String _safeIconKey(String? value) {
    return ScheduleLinearServicesData.normalizeIconKey(
      value,
      fallback: ScheduleLinearServicesData.defaultServiceIconKey,
    );
  }

  Color _safeServiceColor(Color? value) {
    return ScheduleLinearServicesData.normalizeColor(
      value,
      fallback: ScheduleLinearServicesData.defaultServiceColor,
    );
  }

  Color _safeLaneColor(Color? value) {
    return value ?? ScheduleLinearLaneData.defaultLaneColor;
  }

  int _safeLayerOrder(int? value) {
    return ScheduleLinearServicesData.normalizeLayerOrder(value);
  }

  void _buildInitialServices() {
    final source = widget.initialServices.isEmpty
        ? const <ScheduleLinearServicesData>[
      ScheduleLinearServicesData.emptyGeral,
    ]
        : widget.initialServices;

    final seen = <String>{};

    for (final service in source) {
      final key = _cleanKey(service.key);

      if (key.isEmpty || seen.contains(key)) continue;

      seen.add(key);

      final isGeral = key == ScheduleLinearServicesData.geralKey;

      final iconKey = isGeral
          ? ScheduleLinearServicesData.geralIconKey
          : _safeIconKey(service.iconKey);

      final normalizedService = ScheduleLinearServicesData.create(
        key: key,
        label: isGeral
            ? 'GERAL'
            : service.label.trim().isEmpty
            ? key
            : service.label.trim(),
        iconKey: iconKey,
        icon: isGeral
            ? Icons.clear_all
            : ScheduleLinearServicesData.iconForKey(iconKey),
        color: isGeral
            ? ScheduleLinearServicesData.defaultGeralColor
            : _safeServiceColor(service.color),
        layerOrder: isGeral
            ? ScheduleLinearServicesData.geralLayerOrder
            : _safeLayerOrder(service.layerOrder),
      );

      _services.add(normalizedService);
    }

    if (!seen.contains(ScheduleLinearServicesData.geralKey)) {
      _services.insert(0, ScheduleLinearServicesData.emptyGeral);
    }

    _normalizeServiceLayerOrders();
    _sortServices();
  }

  void _buildInitialRows() {
    for (final rowData in widget.initialRows) {
      final row = ScheduleLinearLaneData.editor(
        faixaIndex: rowData.faixaIndex,
        pos: rowData.resolvedPos,
        nome: rowData.resolvedNome,
        altura: rowData.resolvedAltura,
        anchor: rowData.anchor,
        allowedByService: _cleanAllowedMap(rowData.allowedByService),
        color: _safeLaneColor(rowData.color),
        iconKey: rowData.iconKey,
        icon: rowData.icon,
      );

      _rows.add(row);
    }
  }

  Map<String, bool> _cleanAllowedMap(Map<String, bool> source) {
    final out = <String, bool>{};

    for (final entry in source.entries) {
      final key = _cleanKey(entry.key);

      if (key.isEmpty || key == ScheduleLinearServicesData.geralKey) continue;

      out[key] = entry.value;
    }

    return out;
  }

  void _createDefaultRows() {
    final defaults = <({String pos, String nome})>[
      (pos: 'LE', nome: 'LADO ESQUERDO'),
      (pos: 'CE', nome: 'EIXO'),
      (pos: 'LD', nome: 'LADO DIREITO'),
    ];

    for (int i = 0; i < defaults.length; i++) {
      final item = defaults[i];

      _rows.add(
        ScheduleLinearLaneData.editor(
          faixaIndex: i,
          pos: item.pos,
          nome: item.nome,
          altura: ScheduleLinearLaneData.defaultLaneHeight,
          color: ScheduleLinearLaneData.defaultLaneColor,
          iconKey: ScheduleLinearLaneData.defaultLaneIconKey,
        ),
      );
    }
  }

  void _lockCentralRows() {
    if (_rows.isEmpty) return;

    final lockCount = _rows.length < 3 ? _rows.length : 3;
    final start = (_rows.length - lockCount) ~/ 2;

    for (int i = start; i < start + lockCount; i++) {
      final id = _rows[i].editorId;

      if (id != null) {
        _lockedIds.add(id);
      }
    }
  }

  void _sortServices() {
    _services.sort(ScheduleLinearServicesData.compareByLayer);
  }

  void _normalizeServiceLayerOrders() {
    final specificServices =
    ScheduleLinearServicesData.specificSortedByLayer(_services);

    final nextByKey = <String, ScheduleLinearServicesData>{};

    for (int i = 0; i < specificServices.length; i++) {
      final service = specificServices[i];
      final nextLayer = i + 1;

      nextByKey[service.key] = service.copyWith(
        layerOrder: nextLayer,
      );
    }

    for (int i = 0; i < _services.length; i++) {
      final service = _services[i];

      if (service.isGeral) {
        _services[i] = ScheduleLinearServicesData.emptyGeral;
        continue;
      }

      final updated = nextByKey[service.key];

      if (updated != null) {
        _services[i] = updated;
      }
    }
  }

  Future<void> _handleImportGeometry() async {
    final callback = widget.onImportGeometry;

    if (callback == null || _importingGeometry) return;

    setState(() {
      _importingGeometry = true;
    });

    try {
      await callback();
    } finally {
      if (mounted) {
        setState(() {
          _importingGeometry = false;
        });
      }
    }
  }

  Widget _buildGeometryImportButton({
    required bool compact,
  }) {
    if (widget.onImportGeometry == null) {
      return const SizedBox.shrink();
    }

    final label = _importingGeometry
        ? 'Importando geometria...'
        : 'Adicionar / reimportar geometria';

    final icon = _importingGeometry
        ? SizedBox(
      width: compact ? 15 : 16,
      height: compact ? 15 : 16,
      child: const CircularProgressIndicator(
        strokeWidth: 2,
      ),
    )
        : Icon(
      Icons.add_road_outlined,
      size: compact ? 18 : 20,
    );

    return Align(
      alignment: Alignment.centerRight,
      child: OutlinedButton.icon(
        onPressed: _importingGeometry ? null : _handleImportGeometry,
        icon: icon,
        label: Text(
          label,
          overflow: TextOverflow.ellipsis,
        ),
        style: OutlinedButton.styleFrom(
          visualDensity:
          compact ? VisualDensity.compact : VisualDensity.standard,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 14,
            vertical: compact ? 9 : 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  void _moveServiceUp(ScheduleLinearServicesData service) {
    _moveServiceLayer(service, -1);
  }

  void _moveServiceDown(ScheduleLinearServicesData service) {
    _moveServiceLayer(service, 1);
  }

  void _moveServiceLayer(
      ScheduleLinearServicesData service,
      int direction,
      ) {
    if (service.isGeral) return;

    final ordered =
    ScheduleLinearServicesData.specificSortedByLayer(_services).toList();

    final currentIndex = ordered.indexWhere((item) => item.key == service.key);

    if (currentIndex < 0) return;

    final nextIndex = currentIndex + direction;

    if (nextIndex < 0 || nextIndex >= ordered.length) return;

    final current = ordered[currentIndex];
    final target = ordered[nextIndex];

    ordered[currentIndex] = target;
    ordered[nextIndex] = current;

    setState(() {
      for (int i = 0; i < ordered.length; i++) {
        _replaceService(
          ordered[i].copyWith(
            layerOrder: i + 1,
          ),
        );
      }

      _sortServices();
    });
  }

  bool _canRemoveIndex(int index) {
    if (_rows.length <= 3) return false;

    final id = _rows[index].editorId;

    if (id == null) return true;

    return !_lockedIds.contains(id);
  }

  Map<String, bool> _defaultAllowedForNewLane() {
    return <String, bool>{
      for (final service in _services)
        if (!service.isGeral) service.key: true,
    };
  }

  void _addLane() {
    setState(() {
      _rows.add(
        ScheduleLinearLaneData.editor(
          faixaIndex: _rows.length,
          pos: '',
          nome: '',
          altura: ScheduleLinearLaneData.defaultLaneHeight,
          color: ScheduleLinearLaneData.defaultLaneColor,
          iconKey: ScheduleLinearLaneData.defaultLaneIconKey,
          allowedByService: _defaultAllowedForNewLane(),
        ),
      );

      _normalizeFaixaIndexes();
    });
  }

  void _moveLaneUp(int index) {
    _moveLane(index, -1);
  }

  void _moveLaneDown(int index) {
    _moveLane(index, 1);
  }

  void _moveLane(int index, int direction) {
    final nextIndex = index + direction;

    if (index < 0 || index >= _rows.length) return;
    if (nextIndex < 0 || nextIndex >= _rows.length) return;

    setState(() {
      final current = _rows[index];

      _rows[index] = _rows[nextIndex];
      _rows[nextIndex] = current;

      _normalizeFaixaIndexes();
    });
  }

  void _removeAt(int index) {
    if (!_canRemoveIndex(index)) return;

    setState(() {
      final row = _rows.removeAt(index);
      row.disposeEditorControllers();
      _normalizeFaixaIndexes();
    });
  }

  void _onNameChanged(int index, String value) {
    setState(() {
      _rows[index] = _rows[index].copyWith(nome: value);
    });
  }

  void _onPosChanged(int index, String value) {
    setState(() {
      _rows[index] = _rows[index].copyWith(pos: value);
    });
  }

  void _onLaneColorChanged(int index, int colorValue) {
    setState(() {
      _rows[index] = _rows[index].copyWith(
        color: Color(colorValue),
      );
    });
  }

  void _normalizeFaixaIndexes() {
    for (int i = 0; i < _rows.length; i++) {
      _rows[i] = _rows[i].copyWith(faixaIndex: i);
    }
  }

  String _nextServiceKey() {
    const base = 'servico';

    if (!_services.any((service) => service.key == base)) {
      return base;
    }

    var counter = 2;

    while (_services.any((service) => service.key == '${base}_$counter')) {
      counter++;
    }

    return '${base}_$counter';
  }

  String _nextServiceLabel() {
    const base = 'Novo serviço';

    if (!_services.any((service) => service.label == base)) {
      return base;
    }

    var counter = 2;

    while (_services.any((service) => service.label == '$base $counter')) {
      counter++;
    }

    return '$base $counter';
  }

  int _nextServiceLayerOrder() {
    final specific = _services.where((service) => !service.isGeral);

    if (specific.isEmpty) return 1;

    final maxOrder = specific
        .map((service) => service.layerOrder)
        .fold<int>(0, (previous, current) {
      return current > previous ? current : previous;
    });

    return maxOrder + 1;
  }

  void _addService() {
    setState(() {
      final key = _nextServiceKey();
      final label = _nextServiceLabel();

      const iconKey = ScheduleLinearServicesData.defaultServiceIconKey;
      const color = ScheduleLinearServicesData.defaultServiceColor;

      final service = ScheduleLinearServicesData.create(
        key: key,
        label: label,
        iconKey: iconKey,
        icon: ScheduleLinearServicesData.iconForKey(iconKey),
        color: color,
        layerOrder: _nextServiceLayerOrder(),
      );

      _services.add(service);
      _normalizeServiceLayerOrders();
      _sortServices();

      for (int i = 0; i < _rows.length; i++) {
        final allowed = Map<String, bool>.from(_rows[i].allowedByService);
        allowed[key] = true;

        _rows[i] = _rows[i].copyWith(
          allowedByService: allowed,
        );
      }

      _activeServiceKey = key;
    });
  }

  void _removeService(String key) {
    final cleanKey = _cleanKey(key);

    if (cleanKey == ScheduleLinearServicesData.geralKey) return;

    final serviceIndex = _services.indexWhere(
          (service) => service.key == cleanKey,
    );

    if (serviceIndex < 0) return;

    setState(() {
      _services.removeAt(serviceIndex);

      for (int i = 0; i < _rows.length; i++) {
        final allowed = Map<String, bool>.from(_rows[i].allowedByService);
        allowed.remove(cleanKey);

        _rows[i] = _rows[i].copyWith(
          allowedByService: allowed,
        );
      }

      if (_activeServiceKey == cleanKey) {
        _activeServiceKey = ScheduleLinearServicesData.geralKey;
      }

      _normalizeServiceLayerOrders();
      _sortServices();
    });
  }

  void _selectService(String key) {
    final cleanKey = _cleanKey(key);

    if (cleanKey.isEmpty) return;
    if (_activeServiceKey == cleanKey) return;

    setState(() {
      _activeServiceKey = cleanKey;
    });
  }

  void _replaceService(ScheduleLinearServicesData nextService) {
    final index = _services.indexWhere(
          (service) => service.key == nextService.key,
    );

    if (index < 0) return;

    _services[index] = nextService;
  }

  void _onServiceLabelChanged(
      ScheduleLinearServicesData service,
      String value,
      ) {
    if (service.isGeral) return;

    final nextLabel = value.trim().isEmpty ? 'Serviço' : value.trim();

    setState(() {
      _replaceService(
        service.copyWith(
          label: nextLabel,
        ),
      );
    });
  }

  void _onServiceIconChanged(
      ScheduleLinearServicesData service,
      String iconKey,
      ) {
    if (service.isGeral) return;

    final cleanIconKey = _safeIconKey(iconKey);

    setState(() {
      _replaceService(
        service.copyWith(
          iconKey: cleanIconKey,
          icon: ScheduleLinearServicesData.iconForKey(cleanIconKey),
        ),
      );
    });
  }

  void _onServiceColorChanged(
      ScheduleLinearServicesData service,
      int colorValue,
      ) {
    if (service.isGeral) return;

    setState(() {
      _replaceService(
        service.copyWith(
          color: Color(colorValue),
        ),
      );
    });
  }

  bool _allowedForLane(int laneIndex) {
    if (_isActiveGeral) return true;

    final allowed = _rows[laneIndex].allowedByService[_serviceKey];

    return allowed ?? true;
  }

  void _setAllowedForLane(int laneIndex, bool value) {
    if (_isActiveGeral) return;

    setState(() {
      final allowed = Map<String, bool>.from(_rows[laneIndex].allowedByService);
      allowed[_serviceKey] = value;

      _rows[laneIndex] = _rows[laneIndex].copyWith(
        allowedByService: allowed,
      );
    });
  }

  List<ScheduleLinearServicesData> _collectServices() {
    _normalizeServiceLayerOrders();
    _sortServices();

    final seen = <String>{};
    final out = <ScheduleLinearServicesData>[];

    for (final service in _services) {
      final key = _cleanKey(service.key);

      if (key.isEmpty || seen.contains(key)) continue;

      seen.add(key);

      final isGeral = key == ScheduleLinearServicesData.geralKey;

      final iconKey = isGeral
          ? ScheduleLinearServicesData.geralIconKey
          : _safeIconKey(service.iconKey);

      out.add(
        ScheduleLinearServicesData.create(
          key: key,
          label: isGeral ? 'GERAL' : service.label.trim(),
          iconKey: iconKey,
          icon: isGeral
              ? Icons.clear_all
              : ScheduleLinearServicesData.iconForKey(iconKey),
          color: isGeral
              ? ScheduleLinearServicesData.defaultGeralColor
              : service.color,
          layerOrder: isGeral
              ? ScheduleLinearServicesData.geralLayerOrder
              : service.layerOrder,
        ),
      );
    }

    if (!seen.contains(ScheduleLinearServicesData.geralKey)) {
      out.insert(0, ScheduleLinearServicesData.emptyGeral);
    }

    out.sort(ScheduleLinearServicesData.compareByLayer);

    return List<ScheduleLinearServicesData>.unmodifiable(out);
  }

  List<ScheduleLinearLaneData> _collectLanes(
      List<ScheduleLinearServicesData> services,
      ) {
    final serviceKeys = services
        .where((service) => !service.isGeral)
        .map((service) => service.key)
        .toSet();

    return List<ScheduleLinearLaneData>.generate(_rows.length, (index) {
      final row = _rows[index];

      final allowedByService = <String, bool>{
        for (final key in serviceKeys) key: row.allowedByService[key] ?? true,
      };

      return ScheduleLinearLaneData.create(
        faixaIndex: index,
        pos: row.resolvedPos,
        nome: row.resolvedNome,
        altura: row.resolvedAltura,
        anchor: row.anchor,
        allowedByService: allowedByService,
        color: row.color,
        iconKey: row.iconKey,
        icon: row.icon,
      );
    });
  }

  ScheduleLaneResult _collectResult() {
    final services = _collectServices();
    final lanes = _collectLanes(services);

    return ScheduleLaneResult(
      lanes: lanes,
      services: services,
    );
  }

  Widget _buildMobileContent({
    required Widget header,
    required String activeServiceLabel,
  }) {
    return ListView(
      padding: const EdgeInsets.only(
        top: _mobileContentTopPadding,
        bottom: _mobileContentBottomPadding,
      ),
      physics: const ClampingScrollPhysics(),
      clipBehavior: Clip.none,
      children: [
        header,
        const SizedBox(height: 10),
        _buildGeometryImportButton(compact: true),
        const SizedBox(height: 12),
        ScheduleServicesProfile(
          services: _services,
          activeServiceKey: _activeServiceKey,
          onAdd: _addService,
          onSelect: _selectService,
          onRemove: _removeService,
          onLabelChanged: _onServiceLabelChanged,
          onIconChanged: _onServiceIconChanged,
          onColorChanged: _onServiceColorChanged,
          onMoveUp: _moveServiceUp,
          onMoveDown: _moveServiceDown,
          compact: true,
        ),
        const SizedBox(height: 12),
        ScheduleLanesProfile(
          rows: _rows,
          isActiveGeral: _isActiveGeral,
          activeServiceLabel: activeServiceLabel,
          canRemoveIndex: _canRemoveIndex,
          allowedForLane: _allowedForLane,
          onAdd: _addLane,
          onRemoveAt: _removeAt,
          onMoveUp: _moveLaneUp,
          onMoveDown: _moveLaneDown,
          onPosChanged: _onPosChanged,
          onNameChanged: _onNameChanged,
          onLaneColorChanged: _onLaneColorChanged,
          onAllowedChanged: _setAllowedForLane,
          compact: true,
        ),
      ],
    );
  }

  Widget _buildDesktopContent({
    required Widget header,
    required String activeServiceLabel,
  }) {
    return Column(
      children: [
        header,
        const SizedBox(height: 10),
        _buildGeometryImportButton(compact: false),
        const SizedBox(height: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(
              bottom: _desktopContentBottomPadding,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: _desktopSectionTopPadding,
                    ),
                    child: ScheduleServicesProfile(
                      services: _services,
                      activeServiceKey: _activeServiceKey,
                      onAdd: _addService,
                      onSelect: _selectService,
                      onRemove: _removeService,
                      onLabelChanged: _onServiceLabelChanged,
                      onIconChanged: _onServiceIconChanged,
                      onColorChanged: _onServiceColorChanged,
                      onMoveUp: _moveServiceUp,
                      onMoveDown: _moveServiceDown,
                      compact: false,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: _desktopSectionTopPadding,
                    ),
                    child: ScheduleLanesProfile(
                      rows: _rows,
                      isActiveGeral: _isActiveGeral,
                      activeServiceLabel: activeServiceLabel,
                      canRemoveIndex: _canRemoveIndex,
                      allowedForLane: _allowedForLane,
                      onAdd: _addLane,
                      onRemoveAt: _removeAt,
                      onMoveUp: _moveLaneUp,
                      onMoveDown: _moveLaneDown,
                      onPosChanged: _onPosChanged,
                      onNameChanged: _onNameChanged,
                      onLaneColorChanged: _onLaneColorChanged,
                      onAllowedChanged: _setAllowedForLane,
                      compact: false,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final isMobile = screen.width < 720;

    final maxW = screen.width * (isMobile ? 0.98 : 0.94);
    final dialogW = isMobile ? maxW : maxW.clamp(380.0, 1040.0);

    final activeService = _services.firstWhere(
          (service) => service.key == _activeServiceKey,
      orElse: () => _services.isNotEmpty
          ? _services.first
          : ScheduleLinearServicesData.emptyGeral,
    );

    final activeServiceLabel = activeService.label.trim().isEmpty
        ? activeService.key
        : activeService.label.trim();

    final header = ScheduleHeaderDialog(
      activeServiceLabel: activeServiceLabel,
      activeServiceColor: activeService.color,
      activeServiceIcon: activeService.key == ScheduleLinearServicesData.geralKey
          ? Icons.clear_all
          : activeService.icon,
      lanesCount: _rows.length,
      servicesCount: _services.length,
      compact: isMobile,
    );

    return WindowDialog(
      title: 'Configurar faixas e serviços',
      width: dialogW,
      contentPadding: EdgeInsets.fromLTRB(
        isMobile ? 10 : 16,
        0,
        isMobile ? 10 : 16,
        10,
      ),
      onClose: () => Navigator.of(context).maybePop(),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogW,
          maxHeight: screen.height * (isMobile ? 0.82 : 0.82),
        ),
        child: SizedBox(
          width: dialogW,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: ClipRect(
                  child: isMobile
                      ? _buildMobileContent(
                    header: header,
                    activeServiceLabel: activeServiceLabel,
                  )
                      : _buildDesktopContent(
                    header: header,
                    activeServiceLabel: activeServiceLabel,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ScheduleActionsButtons(
                compact: isMobile,
                onCancel: () => Navigator.of(context).maybePop(),
                onSave: () {
                  Navigator.of(context).pop<ScheduleLaneResult>(
                    _collectResult(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}