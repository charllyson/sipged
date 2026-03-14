import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data.dart';
import 'package:sipged/_widgets/geo/properties/dialog/layer_properties_menu.dart';
import 'package:sipged/_widgets/geo/properties/dialog/layer_properties_types.dart';
import 'package:sipged/_widgets/geo/properties/editors/layer_general_editor.dart';
import 'package:sipged/_widgets/geo/properties/editors/layer_placeholder_editor.dart';
import 'package:sipged/_widgets/geo/properties/editors/layer_symbology_editor.dart';
import 'package:sipged/_widgets/windows/show_window_dialog.dart';

class LayerPropertiesDialog extends StatefulWidget {
  final GeoLayersData current;
  final List<String> availableRuleFields;

  const LayerPropertiesDialog({
    super.key,
    required this.current,
    this.availableRuleFields = const [],
  });

  static Future<GeoLayersData?> show(
      BuildContext context, {
        required GeoLayersData current,
        List<String> availableRuleFields = const [],
      }) {
    final media = MediaQuery.of(context).size;
    final isMobile = media.width < 700;

    // Em telas menores, o dialog ocupa quase toda a tela para
    // preservar espaço útil sem estourar margens.
    final dialogWidth = isMobile
        ? media.width - 8
        : math.min(1100.0, media.width - 24);

    final dialogHeight = isMobile
        ? media.height * 0.88
        : math.min(760.0, media.height - 24);

    return showWindowDialog<GeoLayersData>(
      context: context,
      title: 'Propriedades da camada',
      width: dialogWidth,
      contentPadding: const EdgeInsets.only(bottom: 12),
      barrierDismissible: true,
      usePointerInterceptor: true,
      useSafeArea: false,
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: LayerPropertiesDialog(
          current: current,
          availableRuleFields: availableRuleFields,
        ),
      ),
    );
  }

  @override
  State<LayerPropertiesDialog> createState() => _LayerPropertiesDialogState();
}

class _LayerPropertiesDialogState extends State<LayerPropertiesDialog> {
  late final TextEditingController _nameController;

  late LayerRendererType _rendererType;
  late List<LayerSimpleSymbolData> _symbolLayers;
  late List<LayerRuleData> _ruleBasedSymbols;

  LayerPropertiesTab _selectedTab = LayerPropertiesTab.general;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.current.title);

    _rendererType = widget.current.rendererType;
    _symbolLayers = List<LayerSimpleSymbolData>.from(
      widget.current.symbolLayers,
    );
    _ruleBasedSymbols = List<LayerRuleData>.from(
      widget.current.ruleBasedSymbols,
    );
  }

  @override
  void didUpdateWidget(covariant LayerPropertiesDialog oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Se a camada mudou, recarregamos todo o estado local do dialog.
    if (oldWidget.current.id != widget.current.id) {
      _nameController.text = widget.current.title;
      _rendererType = widget.current.rendererType;
      _symbolLayers = List<LayerSimpleSymbolData>.from(
        widget.current.symbolLayers,
      );
      _ruleBasedSymbols = List<LayerRuleData>.from(
        widget.current.ruleBasedSymbols,
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

    // Caso a lista local esteja vazia, ainda tentamos manter uma base
    // coerente usando os símbolos efetivos atuais da camada.
    final baseSymbols = _symbolLayers.isNotEmpty
        ? _symbolLayers
        : widget.current.effectiveSymbolLayers;

    final firstSymbol = baseSymbols.isNotEmpty ? baseSymbols.first : null;

    Navigator.of(context).pop(
      widget.current.copyWith(
        title: trimmed,
        rendererType: _rendererType,
        symbolLayers: _symbolLayers,
        ruleBasedSymbols: _ruleBasedSymbols,
        // Mantemos compatibilidade com campos legados/derivados do layer.
        iconKey: firstSymbol?.iconKey ?? widget.current.iconKey,
        colorValue: firstSymbol?.fillColorValue ?? widget.current.colorValue,
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
      subtitle: 'Símbolos e regras',
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
          key: const ValueKey('general'),
          nameController: _nameController,
          onSubmit: _submit,
        );

      case LayerPropertiesTab.symbology:
        return LayerSymbologyEditor(
          key: const ValueKey('symbology'),
          rendererType: _rendererType,
          symbolLayers: _symbolLayers,
          ruleBasedSymbols: _ruleBasedSymbols,
          availableRuleFields: widget.availableRuleFields,
          onRendererTypeChanged: (value) {
            setState(() => _rendererType = value);
          },
          onSymbolLayersChanged: (value) {
            setState(() => _symbolLayers = value);
          },
          onRuleBasedSymbolsChanged: (value) {
            setState(() => _ruleBasedSymbols = value);
          },
        );

      case LayerPropertiesTab.labels:
        return const LayerPlaceholderEditor(
          key: ValueKey('labels'),
          title: 'Rótulos',
          subtitle: 'Esta aba será usada para configurar os rótulos da camada.',
          icon: Icons.label_outline,
        );

      case LayerPropertiesTab.source:
        return const LayerPlaceholderEditor(
          key: ValueKey('source'),
          title: 'Fonte',
          subtitle:
          'Esta aba será usada para configurar a fonte/origem dos dados da camada.',
          icon: Icons.source_outlined,
        );

      case LayerPropertiesTab.metadata:
        return const LayerPlaceholderEditor(
          key: ValueKey('metadata'),
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
        final isCompactMenu = constraints.maxWidth < 760;
        final menuWidth = isCompactMenu ? 60.0 : 190.0;

        return ClipRect(
          child: Column(
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
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        child: _buildTabContent(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
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
          ),
        );
      },
    );
  }
}