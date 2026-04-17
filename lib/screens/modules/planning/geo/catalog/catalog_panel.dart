import 'package:flutter/material.dart';

import 'package:sipged/_blocs/modules/planning/geo/catalog/catalog_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/feature_data_binding.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/workspace_data.dart';
import 'package:sipged/screens/modules/planning/geo/catalog/catalog_property.dart';
import 'package:sipged/screens/modules/planning/geo/catalog/catalog_section.dart';

class CatalogPanel extends StatelessWidget {
  const CatalogPanel({
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
  final ValueChanged<CatalogData> onCatalogItemTap;
  final void Function(String itemId, CatalogData property) onPropertyChanged;
  final void Function(String itemId, String propertyKey, FeatureDataBinding data)
  onBindingDropped;

  String? get _effectiveSelectedCatalogItemId {
    return selectedWorkspaceItem?.catalogItemId ?? selectedCatalogItemId;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dividerColor = theme.dividerColor.withValues(alpha: 0.22);

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          _TabHeader(
            theme: theme,
            dividerColor: dividerColor,
          ),
          Container(height: 1, color: dividerColor),
          Expanded(
            child: TabBarView(
              children: [
                RepaintBoundary(
                  child: _PanelBody(
                    child: _CatalogItemsTab(
                      selectedCatalogItemId: _effectiveSelectedCatalogItemId,
                      onCatalogItemTap: onCatalogItemTap,
                    ),
                  ),
                ),
                RepaintBoundary(
                  child: KeyedSubtree(
                    key: ValueKey(
                      'visualizations_data_'
                          '$selectedWorkspaceToken'
                          '_$workspaceItemsToken',
                    ),
                    child: _PanelBody(
                      child: _CatalogPropertiesTab(
                        item: selectedWorkspaceItem,
                        onPropertyChanged: onPropertyChanged,
                        onBindingDropped: onBindingDropped,
                      ),
                    ),
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

class _TabHeader extends StatelessWidget {
  const _TabHeader({
    required this.theme,
    required this.dividerColor,
  });

  final ThemeData theme;
  final Color dividerColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      child: Container(
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: dividerColor,
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
    );
  }
}

class _CatalogItemsTab extends StatelessWidget {
  const _CatalogItemsTab({
    required this.selectedCatalogItemId,
    required this.onCatalogItemTap,
  });

  final String? selectedCatalogItemId;
  final ValueChanged<CatalogData> onCatalogItemTap;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
      children: CatalogRegistry.groupedItems.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: CatalogSection(
            title: entry.key,
            items: entry.value,
            selectedItemId: selectedCatalogItemId,
            onItemTap: onCatalogItemTap,
          ),
        );
      }).toList(growable: false),
    );
  }
}

class _CatalogPropertiesTab extends StatelessWidget {
  const _CatalogPropertiesTab({
    required this.item,
    required this.onPropertyChanged,
    required this.onBindingDropped,
  });

  final WorkspaceData? item;
  final void Function(String itemId, CatalogData property) onPropertyChanged;
  final void Function(String itemId, String propertyKey, FeatureDataBinding data)
  onBindingDropped;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (item == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Selecione um widget na área de trabalho para editar seus dados.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.black.withValues(alpha: 0.60),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    final currentItem = item!;

    return ListView.separated(
      padding: const EdgeInsets.all(10),
      itemCount: currentItem.properties.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, index) {
        final property = currentItem.properties[index];
        final propertyKey = property.key ?? '';

        return CatalogProperty(
          key: ValueKey('${currentItem.id}_$propertyKey'),
          item: currentItem,
          property: property,
          onPropertyChanged: (updated) {
            onPropertyChanged(currentItem.id, updated);
          },
          onBindingDropped: (data) {
            if (propertyKey.isEmpty) return;
            onBindingDropped(currentItem.id, propertyKey, data);
          },
        );
      },
    );
  }
}

class _PanelBody extends StatelessWidget {
  const _PanelBody({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: child,
    );
  }
}