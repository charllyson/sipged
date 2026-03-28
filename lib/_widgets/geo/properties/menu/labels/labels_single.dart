import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data_labels.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data_simple.dart';
import 'package:sipged/_widgets/geo/properties/menu/labels/label_form.dart';
import 'package:sipged/_widgets/geo/properties/menu/share/layer_panel.dart';
import 'package:sipged/_widgets/geo/properties/menu/share/list_layer/layer_buttons.dart';
import 'package:sipged/_widgets/geo/properties/menu/share/list_layer/layer_items_list.dart';
import 'package:sipged/_widgets/geo/properties/menu/share/list_layer/layer_mini_preview.dart';
import 'package:sipged/_widgets/geo/properties/menu/share/preview/axis_preview.dart';

class LabelsSingle extends StatefulWidget {
  final LayerGeometryKind geometryKind;
  final List<GeoLayersDataSimple> symbolLayers;
  final List<GeoLabelStyleData> labelLayers;
  final List<String> availableFields;
  final ValueChanged<List<GeoLabelStyleData>> onChanged;

  const LabelsSingle({
    super.key,
    required this.geometryKind,
    required this.symbolLayers,
    required this.labelLayers,
    required this.availableFields,
    required this.onChanged,
  });

  @override
  State<LabelsSingle> createState() => _LabelsSingleState();
}

class _LabelsSingleState extends State<LabelsSingle> {
  late List<GeoLabelStyleData> _layers;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _layers = List<GeoLabelStyleData>.from(widget.labelLayers);
    _normalizeSelection();
  }

  @override
  void didUpdateWidget(covariant LabelsSingle oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.labelLayers != widget.labelLayers ||
        oldWidget.geometryKind != widget.geometryKind ||
        oldWidget.symbolLayers != widget.symbolLayers ||
        oldWidget.availableFields != widget.availableFields) {
      _layers = List<GeoLabelStyleData>.from(widget.labelLayers);
      _normalizeSelection();
    }
  }

  void _normalizeSelection() {
    if (_layers.isEmpty) {
      _selectedIndex = 0;
      return;
    }

    if (_selectedIndex >= _layers.length) {
      _selectedIndex = _layers.length - 1;
    }
  }

  void _notifyParent() {
    widget.onChanged(List<GeoLabelStyleData>.unmodifiable(_layers));
  }

  GeoLabelStyleData? get _selectedLayer {
    if (_layers.isEmpty) return null;
    return _layers[_selectedIndex];
  }

  List<GeoLabelStyleData> get _visualLayers =>
      _layers.reversed.toList(growable: false);

  int _visualIndexFromSourceIndex(int sourceIndex) {
    return _layers.length - 1 - sourceIndex;
  }

  int _sourceIndexFromVisualIndex(int visualIndex) {
    return _layers.length - 1 - visualIndex;
  }

  int get _selectedVisualIndex {
    if (_layers.isEmpty) return 0;
    return _visualIndexFromSourceIndex(_selectedIndex);
  }

  void _addLayer() {
    final base = _selectedLayer;
    final now = DateTime.now().microsecondsSinceEpoch;
    final defaultField =
    widget.availableFields.isNotEmpty ? widget.availableFields.first : '';

    final newLayer = base != null
        ? base.copyWith(
      id: 'label_$now',
      title: '${base.title} (cópia base)',
    )
        : GeoLabelStyleData(
      id: 'label_$now',
      title: 'Rótulo ${_layers.length + 1}',
      text: defaultField,
      enabled: true,
      fontSize: 13,
      colorValue: 0xFF111827,
      fontWeight: FontWeight.w600,
      offsetX: 0,
      offsetY: 0,
      type: LayerSimpleSymbolType.textLayer,
    );

    setState(() {
      _layers.add(newLayer);
      _selectedIndex = _layers.length - 1;
    });

    _notifyParent();
  }

  void _removeLayer() {
    if (_layers.isEmpty) return;

    setState(() {
      _layers.removeAt(_selectedIndex);

      if (_selectedIndex >= _layers.length) {
        _selectedIndex = _layers.isEmpty ? 0 : _layers.length - 1;
      }
    });

    _notifyParent();
  }

  void _duplicateLayer() {
    final selected = _selectedLayer;
    if (selected == null) return;

    final duplicated = selected.copyWith(
      id: 'label_${DateTime.now().microsecondsSinceEpoch}',
      title: '${selected.title} (cópia)',
    );

    setState(() {
      _layers.insert(_selectedIndex + 1, duplicated);
      _selectedIndex++;
    });

    _notifyParent();
  }

  void _moveUp() {
    if (_layers.isEmpty) return;

    // Como a lista visual está invertida, "subir" visualmente
    // significa mover para o fim da lista real.
    if (_selectedIndex >= _layers.length - 1) return;

    setState(() {
      final item = _layers.removeAt(_selectedIndex);
      _layers.insert(_selectedIndex + 1, item);
      _selectedIndex++;
    });

    _notifyParent();
  }

  void _moveDown() {
    if (_layers.isEmpty) return;

    // Como a lista visual está invertida, "descer" visualmente
    // significa mover para o início da lista real.
    if (_selectedIndex <= 0) return;

    setState(() {
      final item = _layers.removeAt(_selectedIndex);
      _layers.insert(_selectedIndex - 1, item);
      _selectedIndex--;
    });

    _notifyParent();
  }

  void _updateSelected(GeoLabelStyleData value) {
    if (_selectedLayer == null) return;

    setState(() {
      _layers[_selectedIndex] = value;
    });

    _notifyParent();
  }

  String _itemTitle(GeoLabelStyleData item, int sourceIndex) {
    if (item.title.trim().isNotEmpty) return item.title;

    switch (item.type) {
      case LayerSimpleSymbolType.textLayer:
        return 'Texto ${sourceIndex + 1}';
      case LayerSimpleSymbolType.svgMarker:
        return 'SVG ${sourceIndex + 1}';
      case LayerSimpleSymbolType.simpleMarker:
        return 'Geometria ${sourceIndex + 1}';
    }
  }

  List<GeoLayersDataSimple> _buildPreviewLayers() {
    return _layers.map(_mapLabelToPreviewLayer).toList(growable: false);
  }

  GeoLayersDataSimple _mapLabelToPreviewLayer(GeoLabelStyleData label) {
    final isPointLike =
        label.type == LayerSimpleSymbolType.svgMarker ||
            label.type == LayerSimpleSymbolType.simpleMarker;

    return GeoLayersDataSimple(
      id: label.id,
      title: label.title,
      enabled: label.enabled,
      family: isPointLike
          ? LayerSymbolFamily.point
          : _familyFromGeometry(widget.geometryKind),
      type: label.type,
      iconKey: label.iconKey,
      shapeType: label.shapeType,
      width: label.width,
      height: label.height,
      keepAspectRatio: label.keepAspectRatio,
      fillColorValue: label.fillColorValue,
      strokeColorValue: label.strokeColorValue,
      strokeWidth: label.strokeWidth,
      rotationDegrees: label.rotationDegrees,
      offset: label.geometryOffset,
      text: _previewTextFor(label),
      textFontSize: label.fontSize,
      textColorValue: label.colorValue,
      textFontWeight: label.fontWeight,
      textOffsetX: label.offsetX,
      textOffsetY: label.offsetY,
      strokePattern: LayerStrokePattern.solid,
      dashArray: const [],
      useCustomDashPattern: false,
      dashWidth: 10,
      dashGap: 6,
      strokeJoin: LayerStrokeJoinType.miter,
      strokeCap: LayerStrokeCapType.butt,
    );
  }

  LayerSymbolFamily _familyFromGeometry(LayerGeometryKind geometryKind) {
    switch (geometryKind) {
      case LayerGeometryKind.line:
        return LayerSymbolFamily.line;
      case LayerGeometryKind.polygon:
        return LayerSymbolFamily.polygon;
      case LayerGeometryKind.point:
      case LayerGeometryKind.mixed:
      case LayerGeometryKind.unknown:
        return LayerSymbolFamily.point;
    }
  }

  String _previewTextFor(GeoLabelStyleData label) {
    final raw = label.text.trim();
    if (raw.isEmpty) return 'Rótulo';
    return '{$raw}';
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedLayer;
    final previewLayers = _buildPreviewLayers();
    final visualLayers = _visualLayers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayerPanel(
          preview: RepaintBoundary(
            child: AxisPreview(
              geometryKind: widget.geometryKind,
              layers: previewLayers,
            ),
          ),
          list: LayerItemsList<GeoLabelStyleData>(
            title: 'Camadas',
            emptyMessage: 'Nenhuma camada cadastrada.',
            items: visualLayers,
            selectedIndex: _selectedVisualIndex,
            onSelect: (visualIndex) {
              final sourceIndex = _sourceIndexFromVisualIndex(visualIndex);
              if (_selectedIndex == sourceIndex) return;
              setState(() => _selectedIndex = sourceIndex);
            },
            previewBuilder: (context, item, visualIndex, isSelected) {
              return MiniLayerPreview.label(
                geometryKind: widget.geometryKind,
                label: item,
              );
            },
            titleBuilder: (item, visualIndex) {
              final sourceIndex = _sourceIndexFromVisualIndex(visualIndex);
              return _itemTitle(item, sourceIndex);
            },
          ),
          actions: [
            LayerButtons(
              onAdd: _addLayer,
              onMoveUp: _layers.isEmpty ? null : _moveUp,
              onRemove: _layers.isEmpty ? null : _removeLayer,
              onMoveDown: _layers.isEmpty ? null : _moveDown,
              onDuplicate: _layers.isEmpty ? null : _duplicateLayer,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (selected != null)
          LabelsForm(
            key: ValueKey(selected.id),
            geometryKind: widget.geometryKind,
            label: selected,
            availableFields: widget.availableFields,
            onChanged: _updateSelected,
          )
        else
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Center(
              child: Text('Nenhuma camada selecionada.'),
            ),
          ),
      ],
    );
  }
}