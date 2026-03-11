import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data.dart';
import 'package:sipged/_widgets/geo/layer/editor/layer_general_editor.dart';
import 'package:sipged/_widgets/geo/layer/editor/layer_placeholder_editor.dart';
import 'package:sipged/_widgets/geo/layer/editor/menu/layer_properties_menu.dart';
import 'package:sipged/_widgets/geo/layer/editor/menu/layer_properties_types.dart';
import 'package:sipged/_widgets/geo/layer/editor/symbology/layer_symbology_editor.dart';
import 'package:sipged/_widgets/windows/show_window_dialog.dart';

class LayerPropertiesDialog extends StatefulWidget {
  final GeoLayersData current;

  const LayerPropertiesDialog({
    super.key,
    required this.current,
  });

  static Future<GeoLayersData?> show(
      BuildContext context, {
        required GeoLayersData current,
      }) {
    final media = MediaQuery.of(context).size;

    final dialogWidth = math.min(980.0, media.width - 12);
    final dialogHeight = math.min(720.0, media.height - 12);

    return showWindowDialog<GeoLayersData>(
      contentPadding: const EdgeInsets.only(bottom: 12),
      context: context,
      title: 'Propriedades da camada',
      width: dialogWidth,
      barrierDismissible: true,
      usePointerInterceptor: true,
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: LayerPropertiesDialog(current: current),
      ),
    );
  }

  @override
  State<LayerPropertiesDialog> createState() => _LayerPropertiesDialogState();
}

class _LayerPropertiesDialogState extends State<LayerPropertiesDialog> {
  late final TextEditingController _nameController;
  late List<LayerSimpleSymbolData> _symbolLayers;

  LayerPropertiesTab _selectedTab = LayerPropertiesTab.general;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.current.title);
    _symbolLayers = List<LayerSimpleSymbolData>.from(
      widget.current.effectiveSymbolLayers,
    );
  }

  @override
  void didUpdateWidget(covariant LayerPropertiesDialog oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.current.id != widget.current.id) {
      _nameController.text = widget.current.title;
      _symbolLayers = List<LayerSimpleSymbolData>.from(
        widget.current.effectiveSymbolLayers,
      );
      _selectedTab = LayerPropertiesTab.general;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final trimmed = _nameController.text.trim();
    if (trimmed.isEmpty) return;

    final first = _symbolLayers.isNotEmpty
        ? _symbolLayers.first
        : LayerSimpleSymbolData(
      id: 'symbol_${widget.current.id}',
      type: LayerSimpleSymbolType.svgMarker,
      iconKey: widget.current.iconKey,
      fillColorValue: widget.current.colorValue,
      strokeColorValue: 0xFF1F2937,
      width: 28,
      height: 28,
    );

    Navigator.of(context).pop(
      widget.current.copyWith(
        title: trimmed,
        iconKey: first.iconKey,
        colorValue: first.fillColorValue,
        symbolLayers: _symbolLayers,
      ),
    );
  }

  List<LayerPropertiesMenuItemData> get _menuItems => const [
    LayerPropertiesMenuItemData(
      tab: LayerPropertiesTab.general,
      icon: Icons.tune_outlined,
      title: 'Geral',
      subtitle: 'Nome da camada',
    ),
    LayerPropertiesMenuItemData(
      tab: LayerPropertiesTab.symbology,
      icon: Icons.palette_outlined,
      title: 'Simbologia',
      subtitle: 'Símbolos empilhados',
    ),
    LayerPropertiesMenuItemData(
      tab: LayerPropertiesTab.labels,
      icon: Icons.label_outline,
      title: 'Rótulos',
      subtitle: 'Em breve',
    ),
    LayerPropertiesMenuItemData(
      tab: LayerPropertiesTab.source,
      icon: Icons.source_outlined,
      title: 'Fonte',
      subtitle: 'Em breve',
    ),
    LayerPropertiesMenuItemData(
      tab: LayerPropertiesTab.metadata,
      icon: Icons.info_outline,
      title: 'Metadados',
      subtitle: 'Em breve',
    ),
  ];

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case LayerPropertiesTab.general:
        return LayerGeneralEditor(
          nameController: _nameController,
          onSubmit: _submit,
        );

      case LayerPropertiesTab.symbology:
        return LayerSymbologyEditor(
          symbolLayers: _symbolLayers,
          onChanged: (value) {
            setState(() => _symbolLayers = value);
          },
        );

      case LayerPropertiesTab.labels:
        return const LayerPlaceholderEditor(
          title: 'Rótulos',
          subtitle: 'Esta aba será usada para configurar os rótulos da camada.',
          icon: Icons.label_outline,
        );

      case LayerPropertiesTab.source:
        return const LayerPlaceholderEditor(
          title: 'Fonte',
          subtitle:
          'Esta aba será usada para configurar a fonte/origem dos dados da camada.',
          icon: Icons.source_outlined,
        );

      case LayerPropertiesTab.metadata:
        return const LayerPlaceholderEditor(
          title: 'Metadados',
          subtitle:
          'Esta aba será usada para exibir e editar os metadados da camada.',
          icon: Icons.info_outline,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompactMenu = constraints.maxWidth < 700;
        final menuWidth = isCompactMenu ? 64.0 : 170.0;

        return Column(
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: menuWidth,
                    child: LayerPropertiesMenu(
                      items: _menuItems,
                      selectedTab: _selectedTab,
                      isCompact: isCompactMenu,
                      onTapItem: (tab) {
                        setState(() => _selectedTab = tab);
                      },
                    ),
                  ),
                  Expanded(
                    child: _buildTabContent(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                    FilledButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Salvar'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}