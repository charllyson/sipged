import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data.dart';
import 'package:sipged/_widgets/geo/properties/menu/symbology/form/form_symbology_menu.dart';
import 'package:sipged/_widgets/geo/properties/menu/symbology/single/single_list_panel.dart';

class SingleSymbology extends StatefulWidget {
  final LayerGeometryKind geometryKind;
  final List<LayerSimpleSymbolData> symbolLayers;
  final ValueChanged<List<LayerSimpleSymbolData>> onChanged;

  const SingleSymbology({
    super.key,
    required this.geometryKind,
    required this.symbolLayers,
    required this.onChanged,
  });

  @override
  State<SingleSymbology> createState() => _SingleSymbologyState();
}

class _SingleSymbologyState extends State<SingleSymbology> {
  late List<LayerSimpleSymbolData> _layers;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _layers = List<LayerSimpleSymbolData>.from(widget.symbolLayers);
    _normalizeSelection();
  }

  @override
  void didUpdateWidget(covariant SingleSymbology oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!listEquals(oldWidget.symbolLayers, widget.symbolLayers) ||
        oldWidget.geometryKind != widget.geometryKind) {
      _layers = List<LayerSimpleSymbolData>.from(widget.symbolLayers);
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
    widget.onChanged(List<LayerSimpleSymbolData>.unmodifiable(_layers));
  }

  LayerSimpleSymbolData? get _selectedLayer {
    if (_layers.isEmpty) return null;
    return _layers[_selectedIndex];
  }

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
        : LayerSimpleSymbolData(
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

  void _updateSelected(LayerSimpleSymbolData value) {
    if (_selectedLayer == null) return;

    _layers[_selectedIndex] = value.copyWith(
      family: _familyFromGeometry(),
    );
    _notifyParent();
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedLayer;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleListPanel(
          geometryKind: widget.geometryKind,
          layers: _layers,
          selectedIndex: _selectedIndex,
          onSelect: (index) {
            if (_selectedIndex == index) return;
            setState(() => _selectedIndex = index);
          },
          onAdd: _addLayer,
          onRemove: _layers.isEmpty ? null : _removeLayer,
          onDuplicate: _layers.isEmpty ? null : _duplicateLayer,
          onMoveUp: _layers.isEmpty ? null : _moveUp,
          onMoveDown: _layers.isEmpty ? null : _moveDown,
        ),
        const SizedBox(height: 12),
        if (selected != null)
          FormSymbologyMenu(
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