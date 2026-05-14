import 'package:flutter/material.dart';

import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_road_data.dart';
import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_road_style.dart';

import 'package:sipged/_widgets/dialog/windows/window_dialog.dart';
import 'package:sipged/_widgets/input/text_field_change.dart';

class ScheduleLaneEdit extends StatefulWidget {
  const ScheduleLaneEdit({
    super.key,
    required this.initialRows,
    required this.initialServices,
    required this.selectedServiceKey,
    this.selectedServiceLabel,
  });

  final List<ScheduleRoadData> initialRows;

  /// Serviços configurados manualmente no cronograma.
  /// Agora não vêm mais do orçamento.
  final List<ScheduleRoadData> initialServices;

  /// Serviço selecionado atualmente no cronograma.
  /// Exemplo: "geral", "asfalto", "base", "terraplenagem".
  final String selectedServiceKey;

  /// Rótulo visual do serviço para o cabeçalho.
  final String? selectedServiceLabel;

  @override
  State<ScheduleLaneEdit> createState() => _ScheduleLaneEditState();
}

class _ScheduleLaneEditState extends State<ScheduleLaneEdit> {
  final List<ScheduleRoadData> _rows = <ScheduleRoadData>[];
  final List<_EditableScheduleService> _services =
  <_EditableScheduleService>[];

  final Set<String> _lockedIds = <String>{};

  String _activeServiceKey = 'geral';

  bool get _isActiveGeral => _activeServiceKey == 'geral';

  String get _serviceKey => _activeServiceKey.trim();

  @override
  void initState() {
    super.initState();

    _activeServiceKey = _cleanKey(widget.selectedServiceKey);

    if (_activeServiceKey.isEmpty) {
      _activeServiceKey = 'geral';
    }

    _buildInitialServices();
    _buildInitialRows();

    if (_rows.isEmpty) {
      _createDefaultRows();
    }

    if (!_services.any((service) => service.key == _activeServiceKey)) {
      _activeServiceKey = 'geral';
    }

    _lockCentralRows();
  }

  String _cleanKey(String value) {
    return value.trim();
  }

  void _buildInitialServices() {
    final source = widget.initialServices.isEmpty
        ? const <ScheduleRoadData>[
      ScheduleRoadData.emptyGeral,
    ]
        : widget.initialServices;

    final seen = <String>{};

    for (final service in source) {
      final key = _cleanKey(service.key);

      if (key.isEmpty || seen.contains(key)) continue;

      seen.add(key);

      _services.add(
        _EditableScheduleService.fromData(
          service.copyWith(
            key: key,
            label: service.label.trim().isEmpty ? key : service.label.trim(),
            icon: service.icon,
            color: service.color,
          ),
        ),
      );
    }

    if (!seen.contains('geral')) {
      _services.insert(
        0,
        _EditableScheduleService.fromData(ScheduleRoadData.emptyGeral),
      );
    }

    _sortServices();
  }

  void _buildInitialRows() {
    for (final rowData in widget.initialRows) {
      final nome = (rowData.nome ?? '').trim();

      final row = ScheduleRoadData.laneEditor(
        faixaIndex: rowData.faixaIndex,
        pos: rowData.pos ?? '',
        nome: nome,
        altura: rowData.altura ?? 20.0,
        anchor: rowData.anchor,
        allowedByService: _cleanAllowedMap(rowData.allowedByService),
        color: ScheduleRoadStyle.colorForFaixa(nome),
      );

      _rows.add(row);
    }
  }

  Map<String, bool> _cleanAllowedMap(Map<String, bool> source) {
    final out = <String, bool>{};

    for (final entry in source.entries) {
      final key = _cleanKey(entry.key);

      if (key.isEmpty || key == 'geral') continue;

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

      final row = ScheduleRoadData.laneEditor(
        faixaIndex: i,
        pos: item.pos,
        nome: item.nome,
        altura: 20.0,
        color: ScheduleRoadStyle.colorForFaixa(item.nome),
      );

      _rows.add(row);
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
    _services.sort((a, b) {
      if (a.key == 'geral') return -1;
      if (b.key == 'geral') return 1;

      return a.label.compareTo(b.label);
    });
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.disposeEditorControllers();
    }

    for (final service in _services) {
      service.dispose();
    }

    super.dispose();
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
        if (service.key != 'geral') service.key: true,
    };
  }

  void _addAbove() {
    setState(() {
      _rows.insert(
        0,
        ScheduleRoadData.laneEditor(
          faixaIndex: 0,
          pos: '',
          nome: '',
          altura: 20.0,
          color: ScheduleRoadStyle.colorForFaixa(''),
          allowedByService: _defaultAllowedForNewLane(),
        ),
      );

      _normalizeFaixaIndexes();
    });
  }

  void _addBelow() {
    setState(() {
      _rows.add(
        ScheduleRoadData.laneEditor(
          faixaIndex: _rows.length,
          pos: '',
          nome: '',
          altura: 20.0,
          color: ScheduleRoadStyle.colorForFaixa(''),
          allowedByService: _defaultAllowedForNewLane(),
        ),
      );

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
      _rows[index] = _rows[index].copyWith(
        nome: value,
        color: ScheduleRoadStyle.colorForFaixa(value),
      );
    });
  }

  void _onPosChanged(int index, String value) {
    setState(() {
      _rows[index] = _rows[index].copyWith(
        pos: value,
      );
    });
  }

  void _normalizeFaixaIndexes() {
    for (int i = 0; i < _rows.length; i++) {
      _rows[i] = _rows[i].copyWith(
        faixaIndex: i,
      );
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

  void _addService() {
    setState(() {
      final key = _nextServiceKey();
      final label = _nextServiceLabel();

      final service = _EditableScheduleService(
        key: key,
        label: label,
        color: ScheduleRoadStyle.colorForService(label),
        icon: ScheduleRoadStyle.pickIconForTitle(label),
      );

      _services.add(service);
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

    if (cleanKey == 'geral') return;

    final serviceIndex = _services.indexWhere(
          (service) => service.key == cleanKey,
    );

    if (serviceIndex < 0) return;

    setState(() {
      final removed = _services.removeAt(serviceIndex);
      removed.dispose();

      for (int i = 0; i < _rows.length; i++) {
        final allowed = Map<String, bool>.from(_rows[i].allowedByService);
        allowed.remove(cleanKey);

        _rows[i] = _rows[i].copyWith(
          allowedByService: allowed,
        );
      }

      if (_activeServiceKey == cleanKey) {
        _activeServiceKey = 'geral';
      }
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

  void _onServiceLabelChanged(
      _EditableScheduleService service,
      String value,
      ) {
    if (service.key == 'geral') return;

    final nextLabel = value.trim().isEmpty ? 'Serviço' : value.trim();

    setState(() {
      service.label = nextLabel;
      service.color = ScheduleRoadStyle.colorForService(nextLabel);
      service.icon = ScheduleRoadStyle.pickIconForTitle(nextLabel);

      _sortServices();
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

  List<ScheduleRoadData> _collectServices() {
    final seen = <String>{};
    final out = <ScheduleRoadData>[];

    for (final service in _services) {
      final key = _cleanKey(service.key);

      if (key.isEmpty || seen.contains(key)) continue;

      seen.add(key);

      out.add(
        ScheduleRoadData.service(
          key: key,
          label: key == 'geral' ? 'GERAL' : service.label.trim(),
          icon: key == 'geral' ? Icons.clear_all : service.icon,
          color: key == 'geral' ? Colors.grey : service.color,
        ),
      );
    }

    if (!seen.contains('geral')) {
      out.insert(0, ScheduleRoadData.emptyGeral);
    }

    out.sort((a, b) {
      if (a.key == 'geral') return -1;
      if (b.key == 'geral') return 1;

      return a.label.compareTo(b.label);
    });

    return out;
  }

  List<ScheduleRoadData> _collectLanes(List<ScheduleRoadData> services) {
    final serviceKeys = services
        .where((service) => service.key != 'geral')
        .map((service) => service.key)
        .toSet();

    return List<ScheduleRoadData>.generate(_rows.length, (index) {
      final row = _rows[index];

      final allowedByService = <String, bool>{
        for (final key in serviceKeys) key: row.allowedByService[key] ?? true,
      };

      return ScheduleRoadData.lane(
        faixaIndex: index,
        pos: row.resolvedPos,
        nome: row.resolvedNome,
        altura: row.resolvedAltura,
        anchor: row.anchor,
        allowedByService: allowedByService,
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

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);

    final isMobile = screen.width < 720;

    final maxW = screen.width * (isMobile ? 0.98 : 0.94);
    final dialogW = isMobile ? maxW : maxW.clamp(380.0, 1040.0);

    final activeService = _services.firstWhere(
          (service) => service.key == _activeServiceKey,
      orElse: () => _services.first,
    );

    final activeServiceLabel = activeService.label.trim().isEmpty
        ? activeService.key
        : activeService.label.trim();

    final header = _ScheduleConfigHeader(
      activeServiceLabel: activeServiceLabel,
      activeServiceColor: activeService.color,
      activeServiceIcon:
      activeService.key == 'geral' ? Icons.clear_all : activeService.icon,
      lanesCount: _rows.length,
      servicesCount: _services.length,
      compact: isMobile,
    );

    return WindowDialog(
      title: 'Configurar faixas e serviços',
      width: dialogW,
      contentPadding: EdgeInsets.fromLTRB(
        isMobile ? 10 : 16,
        12,
        isMobile ? 10 : 16,
        12,
      ),
      onClose: () => Navigator.of(context).maybePop(),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogW,
          maxHeight: screen.height * (isMobile ? 0.88 : 0.82),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: isMobile
                  ? ListView(
                padding: EdgeInsets.zero,
                physics: const ClampingScrollPhysics(),
                children: [
                  header,
                  const SizedBox(height: 12),
                  _ScheduleServicesEditor(
                    services: _services,
                    activeServiceKey: _activeServiceKey,
                    onAdd: _addService,
                    onSelect: _selectService,
                    onRemove: _removeService,
                    onLabelChanged: _onServiceLabelChanged,
                    compact: true,
                  ),
                  const SizedBox(height: 12),
                  _ScheduleLanesEditor(
                    rows: _rows,
                    isActiveGeral: _isActiveGeral,
                    activeServiceLabel: activeServiceLabel,
                    canRemoveIndex: _canRemoveIndex,
                    allowedForLane: _allowedForLane,
                    onAddAbove: _addAbove,
                    onAddBelow: _addBelow,
                    onRemoveAt: _removeAt,
                    onPosChanged: _onPosChanged,
                    onNameChanged: _onNameChanged,
                    onAllowedChanged: _setAllowedForLane,
                    compact: true,
                  ),
                ],
              )
                  : Column(
                children: [
                  header,
                  const SizedBox(height: 12),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: dialogW >= 820 ? 300 : 250,
                          child: _ScheduleServicesEditor(
                            services: _services,
                            activeServiceKey: _activeServiceKey,
                            onAdd: _addService,
                            onSelect: _selectService,
                            onRemove: _removeService,
                            onLabelChanged: _onServiceLabelChanged,
                            compact: false,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _ScheduleLanesEditor(
                            rows: _rows,
                            isActiveGeral: _isActiveGeral,
                            activeServiceLabel: activeServiceLabel,
                            canRemoveIndex: _canRemoveIndex,
                            allowedForLane: _allowedForLane,
                            onAddAbove: _addAbove,
                            onAddBelow: _addBelow,
                            onRemoveAt: _removeAt,
                            onPosChanged: _onPosChanged,
                            onNameChanged: _onNameChanged,
                            onAllowedChanged: _setAllowedForLane,
                            compact: false,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _ScheduleLaneDialogActions(
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
    );
  }
}

class _EditableScheduleService {
  _EditableScheduleService({
    required this.key,
    required this.label,
    required this.icon,
    required this.color,
  }) : labelCtrl = TextEditingController(text: label);

  factory _EditableScheduleService.fromData(ScheduleRoadData data) {
    final key = data.key.trim();
    final label = data.label.trim().isEmpty ? key : data.label.trim();

    return _EditableScheduleService(
      key: key,
      label: label,
      icon: data.icon,
      color: data.color,
    );
  }

  String key;
  String label;
  IconData icon;
  Color color;

  final TextEditingController labelCtrl;

  void dispose() {
    labelCtrl.dispose();
  }
}

class _ScheduleConfigHeader extends StatelessWidget {
  const _ScheduleConfigHeader({
    required this.activeServiceLabel,
    required this.activeServiceColor,
    required this.activeServiceIcon,
    required this.lanesCount,
    required this.servicesCount,
    required this.compact,
  });

  final String activeServiceLabel;
  final Color activeServiceColor;
  final IconData activeServiceIcon;
  final int lanesCount;
  final int servicesCount;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final iconBox = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: activeServiceColor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        activeServiceIcon,
        color: activeServiceColor,
      ),
    );

    final title = Text.rich(
      TextSpan(
        children: [
          const TextSpan(
            text: 'Serviço em edição: ',
            style: TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(
            text: activeServiceLabel,
            style: TextStyle(
              color: activeServiceColor,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
      maxLines: compact ? 3 : 2,
      overflow: TextOverflow.ellipsis,
    );

    final pills = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _MiniCountPill(
          icon: Icons.view_stream_outlined,
          label: '$lanesCount faixa(s)',
        ),
        _MiniCountPill(
          icon: Icons.layers_outlined,
          label: '$servicesCount serviço(s)',
        ),
      ],
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.34),
        ),
      ),
      child: compact
          ? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              iconBox,
              const SizedBox(width: 12),
              Expanded(child: title),
            ],
          ),
          const SizedBox(height: 12),
          pills,
        ],
      )
          : Row(
        children: [
          iconBox,
          const SizedBox(width: 12),
          Expanded(child: title),
          const SizedBox(width: 12),
          pills,
        ],
      ),
    );
  }
}

class _MiniCountPill extends StatelessWidget {
  const _MiniCountPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleServicesEditor extends StatelessWidget {
  const _ScheduleServicesEditor({
    required this.services,
    required this.activeServiceKey,
    required this.onAdd,
    required this.onSelect,
    required this.onRemove,
    required this.onLabelChanged,
    required this.compact,
  });

  final List<_EditableScheduleService> services;
  final String activeServiceKey;

  final VoidCallback onAdd;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onRemove;
  final void Function(_EditableScheduleService service, String value)
  onLabelChanged;

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final list = ListView.separated(
      itemCount: services.length,
      shrinkWrap: compact,
      physics: compact
          ? const NeverScrollableScrollPhysics()
          : const ClampingScrollPhysics(),
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final service = services[index];
        final isSelected = service.key == activeServiceKey;
        final isGeral = service.key == 'geral';

        return _ServiceEditorTile(
          service: service,
          isSelected: isSelected,
          isGeral: isGeral,
          compact: compact,
          onTap: () => onSelect(service.key),
          onRemove: isGeral ? null : () => onRemove(service.key),
          onChanged: isGeral
              ? null
              : (value) => onLabelChanged(
            service,
            value,
          ),
        );
      },
    );

    return Container(
      width: double.infinity,
      height: compact ? null : double.infinity,
      padding: EdgeInsets.all(compact ? 10 : 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.34),
        ),
      ),
      child: compact
          ? Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SectionTitleRow(
            title: 'Serviços',
            action: IconButton.filledTonal(
              tooltip: 'Adicionar serviço',
              onPressed: onAdd,
              icon: const Icon(Icons.add),
            ),
          ),
          const SizedBox(height: 8),
          list,
        ],
      )
          : Column(
        children: [
          _SectionTitleRow(
            title: 'Serviços',
            action: IconButton.filledTonal(
              tooltip: 'Adicionar serviço',
              onPressed: onAdd,
              icon: const Icon(Icons.add),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: list,
          ),
        ],
      ),
    );
  }
}

class _SectionTitleRow extends StatelessWidget {
  const _SectionTitleRow({
    required this.title,
    required this.action,
  });

  final String title;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
        ),
        action,
      ],
    );
  }
}

class _ServiceEditorTile extends StatelessWidget {
  const _ServiceEditorTile({
    required this.service,
    required this.isSelected,
    required this.isGeral,
    required this.onTap,
    required this.onRemove,
    required this.onChanged,
    required this.compact,
  });

  final _EditableScheduleService service;
  final bool isSelected;
  final bool isGeral;
  final VoidCallback onTap;
  final VoidCallback? onRemove;
  final ValueChanged<String>? onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: isSelected
          ? service.color.withValues(alpha: 0.12)
          : theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(compact ? 8 : 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? service.color
                  : theme.dividerColor.withValues(alpha: 0.30),
              width: isSelected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: compact ? 16 : 18,
                backgroundColor: service.color.withValues(alpha: 0.16),
                child: Icon(
                  isGeral ? Icons.clear_all : service.icon,
                  color: service.color,
                  size: compact ? 17 : 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: isGeral
                    ? const Text(
                  'GERAL',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                  ),
                )
                    : CustomTextField(
                  controller: service.labelCtrl,
                  onChanged: onChanged,
                  textInputAction: TextInputAction.done,
                  labelText: 'Serviço',
                  hintText: 'Ex: ASFALTO, BASE...',
                ),
              ),
              if (onRemove != null) ...[
                const SizedBox(width: 6),
                IconButton(
                  tooltip: 'Remover serviço',
                  onPressed: onRemove,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ScheduleLanesEditor extends StatelessWidget {
  const _ScheduleLanesEditor({
    required this.rows,
    required this.isActiveGeral,
    required this.activeServiceLabel,
    required this.canRemoveIndex,
    required this.allowedForLane,
    required this.onAddAbove,
    required this.onAddBelow,
    required this.onRemoveAt,
    required this.onPosChanged,
    required this.onNameChanged,
    required this.onAllowedChanged,
    required this.compact,
  });

  final List<ScheduleRoadData> rows;
  final bool isActiveGeral;
  final String activeServiceLabel;

  final bool Function(int index) canRemoveIndex;
  final bool Function(int index) allowedForLane;

  final VoidCallback onAddAbove;
  final VoidCallback onAddBelow;

  final ValueChanged<int> onRemoveAt;
  final void Function(int index, String value) onPosChanged;
  final void Function(int index, String value) onNameChanged;
  final void Function(int index, bool value) onAllowedChanged;

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final lanesList = ListView(
      shrinkWrap: compact,
      physics: compact
          ? const NeverScrollableScrollPhysics()
          : const ClampingScrollPhysics(),
      children: [
        for (int i = 0; i < rows.length; i++) ...[
          _ScheduleLaneProfile(
            index: i,
            data: rows[i],
            compact: compact,
            canRemove: canRemoveIndex(i),
            onRemove: () => onRemoveAt(i),
            onPosChanged: (value) => onPosChanged(i, value),
            onNameChanged: (value) => onNameChanged(i, value),
          ),
          const SizedBox(height: 6),
          _ScheduleLaneApplicabilityRow(
            isGeral: isActiveGeral,
            serviceLabel: activeServiceLabel,
            value: allowedForLane(i),
            compact: compact,
            onChanged: isActiveGeral
                ? null
                : (value) {
              if (value == null) return;

              onAllowedChanged(i, value);
            },
          ),
          const Divider(height: 18),
        ],
      ],
    );

    return Container(
      width: double.infinity,
      height: compact ? null : double.infinity,
      padding: EdgeInsets.all(compact ? 10 : 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.34),
        ),
      ),
      child: compact
          ? Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MobileLanesHeader(
            onAddAbove: onAddAbove,
            onAddBelow: onAddBelow,
          ),
          const SizedBox(height: 8),
          lanesList,
        ],
      )
          : Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Faixas',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onAddAbove,
                icon: const Icon(Icons.vertical_align_top),
                label: const Text('Acima'),
              ),
              const SizedBox(width: 6),
              TextButton.icon(
                onPressed: onAddBelow,
                icon: const Icon(Icons.vertical_align_bottom),
                label: const Text('Abaixo'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: lanesList,
          ),
        ],
      ),
    );
  }
}

class _MobileLanesHeader extends StatelessWidget {
  const _MobileLanesHeader({
    required this.onAddAbove,
    required this.onAddBelow,
  });

  final VoidCallback onAddAbove;
  final VoidCallback onAddBelow;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Faixas',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            TextButton.icon(
              onPressed: onAddAbove,
              icon: const Icon(Icons.vertical_align_top),
              label: const Text('Adicionar acima'),
            ),
            TextButton.icon(
              onPressed: onAddBelow,
              icon: const Icon(Icons.vertical_align_bottom),
              label: const Text('Adicionar abaixo'),
            ),
          ],
        ),
      ],
    );
  }
}

class _ScheduleLaneProfile extends StatelessWidget {
  const _ScheduleLaneProfile({
    required this.index,
    required this.data,
    required this.canRemove,
    required this.onRemove,
    required this.onPosChanged,
    required this.onNameChanged,
    required this.compact,
  });

  final int index;
  final ScheduleRoadData data;
  final bool canRemove;
  final VoidCallback onRemove;
  final ValueChanged<String> onPosChanged;
  final ValueChanged<String> onNameChanged;
  final bool compact;

  static const double _desktopRowHeight = 58.0;

  @override
  Widget build(BuildContext context) {
    final indexAvatar = Tooltip(
      message: 'Faixa ${index + 1}',
      child: CircleAvatar(
        radius: 15,
        backgroundColor: data.color.withValues(alpha: 0.16),
        child: Text(
          '${index + 1}',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: data.color,
          ),
        ),
      ),
    );

    final colorBar = ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: Container(
        width: 10,
        height: compact ? 44 : double.infinity,
        color: data.color,
      ),
    );

    final removeButton = canRemove
        ? IconButton(
      tooltip: 'Remover faixa',
      onPressed: onRemove,
      icon: const Icon(
        Icons.remove_circle,
        color: Colors.red,
      ),
    )
        : const SizedBox(width: 48);

    if (compact) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Column(
          children: [
            Row(
              children: [
                indexAvatar,
                const SizedBox(width: 10),
                colorBar,
                const SizedBox(width: 10),
                Expanded(
                  child: CustomTextField(
                    controller: data.posCtrl,
                    onChanged: onPosChanged,
                    textInputAction: TextInputAction.next,
                    labelText: 'Posição',
                    hintText: 'LE, CE, LD...',
                  ),
                ),
                const SizedBox(width: 6),
                removeButton,
              ],
            ),
            const SizedBox(height: 10),
            CustomTextField(
              controller: data.nameCtrl,
              onChanged: onNameChanged,
              textInputAction: TextInputAction.done,
              labelText: 'Nome da faixa',
              hintText: 'PISTA ATUAL, CANTEIRO...',
            ),
          ],
        ),
      );
    }

    return Container(
      height: _desktopRowHeight,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          indexAvatar,
          const SizedBox(width: 10),
          colorBar,
          const SizedBox(width: 10),
          SizedBox(
            width: 76,
            child: CustomTextField(
              controller: data.posCtrl,
              onChanged: onPosChanged,
              textInputAction: TextInputAction.next,
              labelText: 'Posição',
              hintText: 'LE, CE, LD...',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: CustomTextField(
              controller: data.nameCtrl,
              onChanged: onNameChanged,
              textInputAction: TextInputAction.done,
              labelText: 'Nome da faixa',
              hintText: 'PISTA ATUAL, CANTEIRO...',
            ),
          ),
          const SizedBox(width: 4),
          removeButton,
        ],
      ),
    );
  }
}

class _ScheduleLaneApplicabilityRow extends StatelessWidget {
  const _ScheduleLaneApplicabilityRow({
    required this.isGeral,
    required this.serviceLabel,
    required this.value,
    required this.onChanged,
    required this.compact,
  });

  final bool isGeral;
  final String serviceLabel;
  final bool value;
  final ValueChanged<bool?>? onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final textColor = isGeral
        ? theme.colorScheme.onSurface.withValues(alpha: 0.42)
        : theme.colorScheme.onSurface.withValues(alpha: 0.86);

    return Row(
      crossAxisAlignment: compact ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
          visualDensity: compact ? VisualDensity.compact : null,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: compact ? 10 : 0),
            child: Text(
              isGeral
                  ? 'Selecione um serviço específico ao lado para configurar a aplicabilidade por faixa.'
                  : 'Aplicável ao serviço atual ($serviceLabel)',
              style: TextStyle(
                fontSize: 13,
                color: textColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScheduleLaneDialogActions extends StatelessWidget {
  const _ScheduleLaneDialogActions({
    required this.onCancel,
    required this.onSave,
    required this.compact,
  });

  final VoidCallback onCancel;
  final VoidCallback onSave;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: onSave,
            icon: const Icon(Icons.save),
            label: const Text('Salvar configuração'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onCancel,
            child: const Text('Cancelar'),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: onCancel,
          child: const Text('Cancelar'),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: onSave,
          icon: const Icon(Icons.save),
          label: const Text('Salvar configuração'),
        ),
      ],
    );
  }
}