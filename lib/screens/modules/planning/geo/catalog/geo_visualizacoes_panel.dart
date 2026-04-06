import 'package:flutter/material.dart';

import 'package:sipged/_blocs/modules/planning/geo/attribute/attribute_data_drag.dart';
import 'package:sipged/_blocs/modules/planning/geo/catalog/component/component_data_catalog.dart';
import 'package:sipged/_blocs/modules/planning/geo/catalog/property/component_data_property.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/workspace_data.dart';
import 'package:sipged/screens/modules/planning/geo/catalog/component/component_panel.dart';
import 'package:sipged/screens/modules/planning/geo/catalog/property/property_panel.dart';

class GeoVisualizacoesPanel extends StatelessWidget {
  const GeoVisualizacoesPanel({
    super.key,
    required this.selectedCatalogItemId,
    required this.selectedWorkspaceItem,
    required this.workspaceItemsToken,
    required this.selectedWorkspaceToken,
    required this.onCatalogItemTap,
    required this.onPropertyChanged,
    required this.onBindingDropped,
  });

  final String? selectedCatalogItemId;
  final WorkspaceData? selectedWorkspaceItem;
  final Object workspaceItemsToken;
  final Object selectedWorkspaceToken;
  final ValueChanged<ComponentDataCatalog> onCatalogItemTap;
  final void Function(String itemId, ComponentDataProperty property)
  onPropertyChanged;
  final void Function(String itemId, String propertyKey, AttributeDataDrag data)
  onBindingDropped;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final divider = theme.dividerColor.withValues(alpha: 0.22);

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
            child: Container(
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: divider,
                  width: 0.8,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TabBar(
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.label,
                indicator: UnderlineTabIndicator(
                  borderSide: BorderSide(
                    width: 2,
                    color: theme.colorScheme.primary,
                  ),
                  insets: const EdgeInsets.symmetric(horizontal: 18),
                ),
                labelPadding: const EdgeInsets.symmetric(horizontal: 10),
                tabs: const [
                  Tab(height: 30, text: 'Itens'),
                  Tab(height: 30, text: 'Dados'),
                ],
              ),
            ),
          ),
          Container(
            height: 1,
            color: divider,
          ),
          Expanded(
            child: TabBarView(
              children: [
                RepaintBoundary(
                  child: ComponentPanel(
                    selectedItemId: selectedCatalogItemId,
                    onItemTap: onCatalogItemTap,
                  ),
                ),
                RepaintBoundary(
                  child: PropertyPanel(
                    key: ValueKey(
                      'visualizations_data_'
                          '$selectedWorkspaceToken'
                          '_$workspaceItemsToken',
                    ),
                    selectedItem: selectedWorkspaceItem,
                    onPropertyChanged: onPropertyChanged,
                    onBindingDropped: onBindingDropped,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}