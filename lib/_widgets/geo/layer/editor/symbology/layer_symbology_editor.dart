import 'package:flutter/material.dart';

import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data.dart';
import 'package:sipged/_widgets/geo/layer/editor/symbology/stack_action_button.dart';
import 'package:sipged/_widgets/geo/layer/editor/symbology/symbol_axis_preview.dart';
import 'package:sipged/_widgets/geo/layer/editor/symbology/symbol_layers_list.dart';
import 'package:sipged/_widgets/geo/layer/editor/symbology/symbol_marker_form.dart';

class LayerSymbologyEditor extends StatefulWidget {
  final List<LayerSimpleSymbolData> symbolLayers;
  final ValueChanged<List<LayerSimpleSymbolData>> onChanged;

  const LayerSymbologyEditor({
    super.key,
    required this.symbolLayers,
    required this.onChanged,
  });

  @override
  State<LayerSymbologyEditor> createState() => _LayerSymbologyEditorState();
}

class _LayerSymbologyEditorState extends State<LayerSymbologyEditor> {
  late List<LayerSimpleSymbolData> _layers;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _layers = List<LayerSimpleSymbolData>.from(widget.symbolLayers);
    _normalizeSelection();
  }

  @override
  void didUpdateWidget(covariant LayerSymbologyEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.symbolLayers != widget.symbolLayers) {
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
    if (_selectedIndex < 0) {
      _selectedIndex = 0;
    }
  }

  void _emit() {
    widget.onChanged(List<LayerSimpleSymbolData>.from(_layers));
    setState(() {});
  }

  LayerSimpleSymbolData? get _selectedLayer {
    if (_layers.isEmpty) return null;
    return _layers[_selectedIndex];
  }

  void _addLayer() {
    final base = _selectedLayer;
    final newLayer = base != null
        ? base.copyWith(id: 'symbol_${DateTime.now().microsecondsSinceEpoch}')
        : LayerSimpleSymbolData(
      id: 'symbol_${DateTime.now().microsecondsSinceEpoch}',
      type: LayerSimpleSymbolType.svgMarker,
      iconKey: 'location_on_outlined',
      fillColorValue: 0xFF2563EB,
      strokeColorValue: 0xFF1F2937,
      width: 28,
      height: 28,
    );

    _layers.add(newLayer);
    _selectedIndex = _layers.length - 1;
    _emit();
  }

  void _removeLayer() {
    if (_layers.isEmpty) return;
    _layers.removeAt(_selectedIndex);
    if (_selectedIndex >= _layers.length) {
      _selectedIndex = _layers.isEmpty ? 0 : _layers.length - 1;
    }
    _emit();
  }

  void _duplicateLayer() {
    if (_selectedLayer == null) return;
    final duplicated = _selectedLayer!.copyWith(
      id: 'symbol_${DateTime.now().microsecondsSinceEpoch}',
    );
    _layers.insert(_selectedIndex + 1, duplicated);
    _selectedIndex = _selectedIndex + 1;
    _emit();
  }

  void _moveUp() {
    if (_selectedIndex <= 0 || _layers.isEmpty) return;
    final item = _layers.removeAt(_selectedIndex);
    _layers.insert(_selectedIndex - 1, item);
    _selectedIndex--;
    _emit();
  }

  void _moveDown() {
    if (_layers.isEmpty || _selectedIndex >= _layers.length - 1) return;
    final item = _layers.removeAt(_selectedIndex);
    _layers.insert(_selectedIndex + 1, item);
    _selectedIndex++;
    _emit();
  }

  void _updateSelected(LayerSimpleSymbolData updated) {
    if (_selectedLayer == null) return;
    _layers[_selectedIndex] = updated;
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedLayer;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 254,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 210,
                      child: SymbolAxisPreview(
                        layers: _layers,
                      ),
                    ),
                    VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: Colors.grey.shade300,
                    ),
                    Expanded(
                      child: SymbolLayersList(
                        layers: _layers,
                        selectedIndex: _selectedIndex,
                        onSelect: (index) {
                          setState(() => _selectedIndex = index);
                        },
                      ),
                    ),
                    Container(
                      width: 58,
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        border: Border(
                          left: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: Column(
                        children: [
                          StackActionButton(
                            icon: Icons.arrow_upward,
                            tooltip: 'Mover para cima',
                            color: Colors.blue.shade700,
                            onTap: _layers.isEmpty ? null : _moveUp,
                          ),
                          const SizedBox(height: 8),
                          StackActionButton(
                            icon: Icons.arrow_downward,
                            tooltip: 'Mover para baixo',
                            color: Colors.grey.shade700,
                            onTap: _layers.isEmpty ? null : _moveDown,
                          ),
                          const SizedBox(height: 8),
                          StackActionButton(
                            icon: Icons.add,
                            tooltip: 'Adicionar símbolo',
                            color: Colors.green.shade600,
                            onTap: _addLayer,
                          ),
                          const SizedBox(height: 8),
                          StackActionButton(
                            icon: Icons.remove,
                            tooltip: 'Remover símbolo',
                            color: Colors.red.shade600,
                            onTap: _layers.isEmpty ? null : _removeLayer,
                          ),
                          const SizedBox(height: 8),
                          StackActionButton(
                            icon: Icons.copy_outlined,
                            tooltip: 'Duplicar símbolo',
                            color: Colors.amber.shade800,
                            onTap: _layers.isEmpty ? null : _duplicateLayer,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (selected != null)
                SymbolMarkerForm(
                  symbol: selected,
                  onChanged: _updateSelected,
                )
              else
                const _EmptySymbologyState(),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptySymbologyState extends StatelessWidget {
  const _EmptySymbologyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: const Center(
        child: Text('Nenhum símbolo selecionado.'),
      ),
    );
  }
}