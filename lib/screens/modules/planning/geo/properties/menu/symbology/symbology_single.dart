import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data_simple.dart';
import 'package:sipged/_widgets/draw/shapes/shapes_catalog.dart';
import 'package:sipged/screens/modules/planning/geo/properties/menu/share/list_layer/layer_buttons.dart';
import 'package:sipged/screens/modules/planning/geo/properties/menu/share/list_layer/layer_items_list.dart';
import 'package:sipged/screens/modules/planning/geo/properties/menu/share/list_layer/layer_mini_preview.dart';
import 'package:sipged/screens/modules/planning/geo/properties/menu/share/preview/axis_preview.dart';
import 'package:sipged/screens/modules/planning/geo/properties/menu/symbology/symbology_form.dart';

import '../share/layer_share_panel.dart';

class SymbologySingle extends StatefulWidget {
  final LayerGeometryKind geometryKind;
  final List<LayerDataSimple> symbolLayers;
  final ValueChanged<List<LayerDataSimple>> onChanged;

  const SymbologySingle({
    super.key,
    required this.geometryKind,
    required this.symbolLayers,
    required this.onChanged,
  });

  @override
  State<SymbologySingle> createState() => _SymbologySingleState();
}

class _SymbologySingleState extends State<SymbologySingle> {
  late List<LayerDataSimple> _layers;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _layers = List<LayerDataSimple>.from(widget.symbolLayers);
    _normalizeSelection();
  }

  @override
  void didUpdateWidget(covariant SymbologySingle oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!listEquals(oldWidget.symbolLayers, widget.symbolLayers) ||
        oldWidget.geometryKind != widget.geometryKind) {
      _layers = List<LayerDataSimple>.from(widget.symbolLayers);
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
    widget.onChanged(List<LayerDataSimple>.unmodifiable(_layers));
  }

  LayerDataSimple? get _selectedLayer {
    if (_layers.isEmpty) return null;
    return _layers[_selectedIndex];
  }

  List<LayerDataSimple> get _previewLayers =>
      _layers.reversed.toList(growable: false);

  LayerSymbolFamily _familyFromGeometry() {
    switch (widget.geometryKind) {
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

  void _addLayer() {
    final base = _selectedLayer;
    final now = DateTime.now().microsecondsSinceEpoch;

    final newLayer = base != null
        ? base.copyWith(
      id: 'symbol_$now',
      family: _familyFromGeometry(),
    )
        : LayerDataSimple(
      id: 'symbol_$now',
      family: _familyFromGeometry(),
    );

    _layers.add(newLayer);
    _selectedIndex = _layers.length - 1;
    _notifyParent();
  }

  void _removeLayer() {
    if (_layers.isEmpty) return;

    _layers.removeAt(_selectedIndex);

    if (_selectedIndex >= _layers.length) {
      _selectedIndex = _layers.isEmpty ? 0 : _layers.length - 1;
    }

    _notifyParent();
  }

  void _duplicateLayer() {
    final selected = _selectedLayer;
    if (selected == null) return;

    final duplicated = selected.copyWith(
      id: 'symbol_${DateTime.now().microsecondsSinceEpoch}',
      family: _familyFromGeometry(),
    );

    _layers.insert(_selectedIndex + 1, duplicated);
    _selectedIndex++;
    _notifyParent();
  }

  void _moveUp() {
    if (_selectedIndex <= 0 || _layers.isEmpty) return;

    final item = _layers.removeAt(_selectedIndex);
    _layers.insert(_selectedIndex - 1, item);
    _selectedIndex--;
    _notifyParent();
  }

  void _moveDown() {
    if (_layers.isEmpty || _selectedIndex >= _layers.length - 1) return;

    final item = _layers.removeAt(_selectedIndex);
    _layers.insert(_selectedIndex + 1, item);
    _selectedIndex++;
    _notifyParent();
  }

  void _updateSelected(LayerDataSimple value) {
    if (_selectedLayer == null) return;

    _layers[_selectedIndex] = value.copyWith(
      family: _familyFromGeometry(),
    );
    _notifyParent();
  }

  String _labelForLayer(LayerDataSimple layer, int index) {
    if (layer.type == LayerSimpleSymbolType.textLayer) {
      return layer.title.trim().isNotEmpty
          ? layer.title
          : 'Texto ${index + 1}';
    }

    switch (widget.geometryKind) {
      case LayerGeometryKind.line:
        return 'Linha ${index + 1}';
      case LayerGeometryKind.polygon:
        return 'Polígono ${index + 1}';
      case LayerGeometryKind.point:
      case LayerGeometryKind.mixed:
      case LayerGeometryKind.unknown:
        return layer.type == LayerSimpleSymbolType.svgMarker
            ? 'SVG ${index + 1}'
            : '${ShapesCatalog.labelFor(layer.shapeType)} ${index + 1}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedLayer;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayerSharePanel(
          preview: RepaintBoundary(
            child: AxisPreview(
              geometryKind: widget.geometryKind,
              layers: _previewLayers,
            ),
          ),
          list: LayerItemsList<LayerDataSimple>(
            title: 'Camadas',
            emptyMessage: 'Nenhuma camada cadastrada.',
            items: _layers,
            selectedIndex: _selectedIndex,
            onSelect: (index) {
              if (_selectedIndex == index) return;
              setState(() => _selectedIndex = index);
            },
            previewBuilder: (context, item, index, isSelected) {
              return MiniLayerPreview.symbol(
                geometryKind: widget.geometryKind,
                symbol: item,
                width: 24,
                height: 24,
                showContainerBackground: false,
              );
            },
            titleBuilder: (item, index) => _labelForLayer(item, index),
          ),
          actions: [
            LayerButtons(
              onAdd: _addLayer,
              onRemove: _layers.isEmpty ? null : _removeLayer,
              onDuplicate: _layers.isEmpty ? null : _duplicateLayer,
              onMoveUp: _layers.isEmpty ? null : _moveUp,
              onMoveDown: _layers.isEmpty ? null : _moveDown,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (selected != null)
          SymbologyForm(
            key: ValueKey(selected.id),
            geometryKind: widget.geometryKind,
            symbol: selected,
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
              child: Text('Nenhum símbolo selecionado.'),
            ),
          ),
      ],
    );
  }
}