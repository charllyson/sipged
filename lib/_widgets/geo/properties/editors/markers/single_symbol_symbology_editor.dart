import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data.dart';
import 'package:sipged/_widgets/geo/properties/menu/symbology/painters/axis_preview.dart';
import 'package:sipged/_widgets/geo/properties/menu/symbology/widgets/stack_action_button.dart';
import 'package:sipged/_widgets/geo/properties/menu/symbology/widgets/symbology_marker_form.dart';
import 'package:sipged/_widgets/geo/properties/menu/symbology/widgets/symbology_marker_layers_list.dart';

class SingleSymbolSymbologyEditor extends StatefulWidget {
  final List<LayerSimpleSymbolData> symbolLayers;
  final ValueChanged<List<LayerSimpleSymbolData>> onChanged;

  const SingleSymbolSymbologyEditor({
    super.key,
    required this.symbolLayers,
    required this.onChanged,
  });

  @override
  State<SingleSymbolSymbologyEditor> createState() =>
      _SingleSymbolSymbologyEditorState();
}

class _SingleSymbolSymbologyEditorState
    extends State<SingleSymbolSymbologyEditor> {
  late List<LayerSimpleSymbolData> _layers;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _layers = List<LayerSimpleSymbolData>.from(widget.symbolLayers);
    _normalizeSelection();
  }

  @override
  void didUpdateWidget(covariant SingleSymbolSymbologyEditor oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!listEquals(oldWidget.symbolLayers, widget.symbolLayers)) {
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

  void _emit() {
    widget.onChanged(List<LayerSimpleSymbolData>.from(_layers));
    if (mounted) {
      setState(() {});
    }
  }

  LayerSimpleSymbolData? get _selectedLayer {
    if (_layers.isEmpty) return null;
    return _layers[_selectedIndex];
  }

  void _addLayer() {
    final base = _selectedLayer;
    final now = DateTime.now().microsecondsSinceEpoch;

    final newLayer = base != null
        ? base.copyWith(id: 'symbol_$now')
        : LayerSimpleSymbolData(id: 'symbol_$now');

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
    final selected = _selectedLayer;
    if (selected == null) return;

    final duplicated = selected.copyWith(
      id: 'symbol_${DateTime.now().microsecondsSinceEpoch}',
    );

    _layers.insert(_selectedIndex + 1, duplicated);
    _selectedIndex++;
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

  void _updateSelected(LayerSimpleSymbolData value) {
    if (_selectedLayer == null) return;
    _layers[_selectedIndex] = value;
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedLayer;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SymbolStackPanel(
          layers: _layers,
          selectedIndex: _selectedIndex,
          onSelect: (index) => setState(() => _selectedIndex = index),
          onAdd: _addLayer,
          onRemove: _layers.isEmpty ? null : _removeLayer,
          onDuplicate: _layers.isEmpty ? null : _duplicateLayer,
          onMoveUp: _layers.isEmpty ? null : _moveUp,
          onMoveDown: _layers.isEmpty ? null : _moveDown,
        ),
        const SizedBox(height: 12),
        if (selected != null)
          SymbologyMarkerForm(
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

class _SymbolStackPanel extends StatelessWidget {
  final List<LayerSimpleSymbolData> layers;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback? onAdd;
  final VoidCallback? onRemove;
  final VoidCallback? onDuplicate;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  const _SymbolStackPanel({
    required this.layers,
    required this.selectedIndex,
    required this.onSelect,
    required this.onAdd,
    required this.onRemove,
    required this.onDuplicate,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  List<Widget> _buildActionButtons() {
    return [
      StackActionButton(
        icon: Icons.add,
        color: Colors.green.shade600,
        tooltip: 'Adicionar símbolo',
        onTap: onAdd,
      ),
      StackActionButton(
        icon: Icons.arrow_upward,
        color: Colors.blue.shade700,
        tooltip: 'Mover para cima',
        onTap: onMoveUp,
      ),
      StackActionButton(
        icon: Icons.remove,
        color: Colors.red.shade600,
        tooltip: 'Remover símbolo',
        onTap: onRemove,
      ),
      StackActionButton(
        icon: Icons.arrow_downward,
        color: Colors.grey.shade700,
        tooltip: 'Mover para baixo',
        onTap: onMoveDown,
      ),
      StackActionButton(
        icon: Icons.copy_outlined,
        color: Colors.orange.shade700,
        tooltip: 'Duplicar símbolo',
        onTap: onDuplicate,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final buttons = _buildActionButtons();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 760;

        if (isNarrow) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 120,
                  child: AxisPreview(layers: layers),
                ),
                Divider(height: 1, thickness: 1, color: Colors.grey.shade300),
                SizedBox(
                  height: 120,
                  child: SymbologyMarkerLayersList(
                    layers: layers,
                    selectedIndex: selectedIndex,
                    onSelect: onSelect,
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: buttons,
                  ),
                ),
              ],
            ),
          );
        }

        return SizedBox(
          height: 254,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 220,
                  child: AxisPreview(layers: layers),
                ),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: Colors.grey.shade300,
                ),
                Expanded(
                  child: SymbologyMarkerLayersList(
                    layers: layers,
                    selectedIndex: selectedIndex,
                    onSelect: onSelect,
                  ),
                ),
                Container(
                  width: 60,
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    border: Border(
                      left: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Column(
                    children: [
                      for (int i = 0; i < buttons.length; i++) ...[
                        buttons[i],
                        if (i != buttons.length - 1)
                          const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}