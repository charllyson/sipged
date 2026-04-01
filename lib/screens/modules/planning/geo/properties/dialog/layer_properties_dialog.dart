import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data_labels.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data_rule.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data_simple.dart';
import 'package:sipged/_widgets/windows/show_window_dialog.dart';
import 'package:sipged/screens/modules/planning/geo/properties/dialog/layer_placeholder_menu.dart';
import 'package:sipged/screens/modules/planning/geo/properties/dialog/layer_properties_menu.dart';
import 'package:sipged/screens/modules/planning/geo/properties/dialog/layer_properties_types.dart';
import 'package:sipged/screens/modules/planning/geo/properties/menu/general/menu_general.dart';
import 'package:sipged/screens/modules/planning/geo/properties/menu/labels/labels_menu.dart';
import 'package:sipged/screens/modules/planning/geo/properties/menu/symbology/symbology_menu.dart';

class LayerPropertiesDialog extends StatefulWidget {
  final LayerData current;
  final List<String> availableRuleFields;

  const LayerPropertiesDialog({
    super.key,
    required this.current,
    this.availableRuleFields = const [],
  });

  static Future<LayerData?> show(
      BuildContext context, {
        required LayerData current,
        List<String> availableRuleFields = const [],
      }) {
    final media = MediaQuery.of(context).size;
    final isMobile = media.width < 700;

    final dialogWidth =
    isMobile ? media.width - 8 : math.min(1100.0, media.width - 24);

    final dialogHeight =
    isMobile ? media.height * 0.88 : math.min(760.0, media.height - 24);

    return showWindowDialog<LayerData>(
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
  static const List<LayerPropertiesMenuItemData> _menuItems = [
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
      subtitle: 'Texto e regras',
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

  late final TextEditingController _nameController;

  late LayerRendererType _rendererType;
  late List<LayerDataSimple> _symbolLayers;
  late List<LayerDataRule> _ruleBasedSymbols;

  late LabelRendererType _labelRendererType;
  late List<LayerDataLabel> _labelLayers;
  late List<GeoLabelRuleData> _ruleBasedLabels;

  LayerPropertiesTab _selectedTab = LayerPropertiesTab.general;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.current.title);
    _syncFromCurrent(widget.current);
  }

  @override
  void didUpdateWidget(covariant LayerPropertiesDialog oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.current != widget.current) {
      _nameController.text = widget.current.title;
      _syncFromCurrent(widget.current);
      _selectedTab = LayerPropertiesTab.general;
    }
  }

  void _syncFromCurrent(LayerData current) {
    _rendererType = current.rendererType;
    _symbolLayers = List<LayerDataSimple>.from(current.symbolLayers);
    _ruleBasedSymbols = List<LayerDataRule>.from(current.ruleBasedSymbols);

    _labelRendererType = current.labelRendererType;
    _labelLayers = List<LayerDataLabel>.from(current.labelLayers);
    _ruleBasedLabels = List<GeoLabelRuleData>.from(current.ruleBasedLabels);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  int _resolveColorValue(LayerDataSimple? firstSymbol) {
    if (firstSymbol == null) {
      return widget.current.colorValue;
    }

    if (firstSymbol.type == LayerSimpleSymbolType.textLayer) {
      return firstSymbol.textColorValue;
    }

    if (widget.current.geometryKind == LayerGeometryKind.line) {
      return firstSymbol.strokeColorValue;
    }

    return firstSymbol.fillColorValue;
  }

  void _submit() {
    final trimmed = _nameController.text.trim();
    if (trimmed.isEmpty) return;

    final baseSymbols = _symbolLayers.isNotEmpty
        ? _symbolLayers
        : widget.current.effectiveSymbolLayers;

    final firstSymbol = baseSymbols.isNotEmpty ? baseSymbols.first : null;

    final updated = widget.current.copyWith(
      title: trimmed,
      rendererType: _rendererType,
      symbolLayers: _symbolLayers,
      ruleBasedSymbols: _ruleBasedSymbols,
      labelRendererType: _labelRendererType,
      labelLayers: _labelLayers,
      ruleBasedLabels: _ruleBasedLabels,
      iconKey: firstSymbol?.iconKey ?? widget.current.iconKey,
      colorValue: _resolveColorValue(firstSymbol),
    );

    Navigator.of(context).pop(updated);
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case LayerPropertiesTab.general:
        return MenuGeneral(
          key: const ValueKey('general'),
          nameController: _nameController,
          geometryKind: widget.current.geometryKind,
          onSubmit: _submit,
        );

      case LayerPropertiesTab.symbology:
        return SymbologyMenu(
          key: const ValueKey('symbology'),
          geometryKind: widget.current.geometryKind,
          rendererType: _rendererType,
          symbolLayers: _symbolLayers,
          ruleBasedSymbols: _ruleBasedSymbols,
          availableRuleFields: widget.availableRuleFields,
          onRendererTypeChanged: (value) {
            if (_rendererType == value) return;
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
        return LabelsMenu(
          key: const ValueKey('labels'),
          geometryKind: widget.current.geometryKind,
          symbolLayers: _symbolLayers.isNotEmpty
              ? _symbolLayers
              : widget.current.effectiveSymbolLayers,
          rendererType: _labelRendererType,
          labelLayers: _labelLayers,
          ruleBasedLabels: _ruleBasedLabels,
          availableRuleFields: widget.availableRuleFields,
          onRendererTypeChanged: (value) {
            if (_labelRendererType == value) return;
            setState(() => _labelRendererType = value);
          },
          onLabelLayersChanged: (value) {
            setState(() => _labelLayers = value);
          },
          onRuleBasedLabelsChanged: (value) {
            setState(() => _ruleBasedLabels = value);
          },
        );

      case LayerPropertiesTab.source:
        return const LayerPlaceholderMenu(
          key: ValueKey('source'),
          title: 'Fonte',
          subtitle:
          'Esta aba será usada para configurar a fonte/origem dos dados da camada.',
          icon: Icons.source_outlined,
        );

      case LayerPropertiesTab.metadata:
        return const LayerPlaceholderMenu(
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
                    RepaintBoundary(
                      child: SizedBox(
                        width: menuWidth,
                        child: LayerPropertiesMenu(
                          items: _menuItems,
                          selectedTab: _selectedTab,
                          isCompact: isCompactMenu,
                          onTapItem: (tab) {
                            if (_selectedTab == tab) return;
                            setState(() => _selectedTab = tab);
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      child: RepaintBoundary(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          child: _buildTabContent(),
                        ),
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