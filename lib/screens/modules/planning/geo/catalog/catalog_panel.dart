import 'package:flutter/material.dart';

import 'package:sipged/_blocs/modules/planning/geo/catalog/catalog_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/feature_binding.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/workspace_data.dart';
import 'package:sipged/_widgets/buttons/icon_button_changed.dart';
import 'package:sipged/screens/modules/planning/geo/catalog/catalog_property.dart';

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
          RepaintBoundary(
            child: KeyedSubtree(
              key: ValueKey(
                'catalog_items_fixed_'
                    '$selectedWorkspaceToken'
                    '_$workspaceItemsToken',
              ),
              child: _FixedCatalogItemsArea(
                selectedCatalogItemId: _effectiveSelectedCatalogItemId,
                onCatalogItemTap: onCatalogItemTap,
              ),
            ),
          ),
          Container(height: 1, color: dividerColor),
          _TabHeader(
            theme: theme,
            dividerColor: dividerColor,
          ),
          Container(height: 1, color: dividerColor),
          Expanded(
            child: TabBarView(
              children: [
                RepaintBoundary(
                  child: KeyedSubtree(
                    key: ValueKey(
                      'catalog_fields_'
                          '$selectedWorkspaceToken'
                          '_$workspaceItemsToken',
                    ),
                    child: _PanelBody(
                      child: _CatalogFieldsTab(
                        item: selectedWorkspaceItem,
                        onPropertyChanged: onPropertyChanged,
                        onBindingDropped: onBindingDropped,
                      ),
                    ),
                  ),
                ),
                const RepaintBoundary(
                  child: _PanelBody(
                    child: _CatalogStyleTab(),
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

class _FixedCatalogItemsArea extends StatelessWidget {
  const _FixedCatalogItemsArea({
    required this.selectedCatalogItemId,
    required this.onCatalogItemTap,
  });

  final String? selectedCatalogItemId;
  final ValueChanged<CatalogData> onCatalogItemTap;

  @override
  Widget build(BuildContext context) {
    return _PanelBody(
      child: _CatalogItemsGrid(
        selectedCatalogItemId: selectedCatalogItemId,
        onCatalogItemTap: onCatalogItemTap,
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
            Tab(height: 30, text: 'Campos'),
            Tab(height: 30, text: 'Estilo'),
          ],
        ),
      ),
    );
  }
}

class _CatalogItemsGrid extends StatelessWidget {
  const _CatalogItemsGrid({
    required this.selectedCatalogItemId,
    required this.onCatalogItemTap,
  });

  final String? selectedCatalogItemId;
  final ValueChanged<CatalogData> onCatalogItemTap;

  @override
  Widget build(BuildContext context) {
    final items = CatalogRegistry.items;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          alignment: WrapAlignment.start,
          spacing: 0,
          runSpacing: 6,
          children: items.map((item) {
            final itemId = item.id;
            final selected = selectedCatalogItemId == itemId;

            final card = IconButtonChanged(
              icon: item.icon ?? Icons.widgets_outlined,
              tooltip: item.title,
              selected: selected,
              onTap: () => onCatalogItemTap(item),
            );

            return Draggable<CatalogData>(
              data: item,
              maxSimultaneousDrags: 1,
              rootOverlay: true,
              feedback: Material(
                color: Colors.transparent,
                child: IgnorePointer(
                  child: IconButtonChanged(
                    icon: item.icon ?? Icons.widgets_outlined,
                    tooltip: item.title,
                    selected: true,
                    isDragging: true,
                  ),
                ),
              ),
              childWhenDragging: Opacity(
                opacity: 0.30,
                child: IgnorePointer(
                  child: card,
                ),
              ),
              child: card,
            );
          }).toList(growable: false),
        ),
      ),
    );
  }
}

class _CatalogFieldsTab extends StatelessWidget {
  const _CatalogFieldsTab({
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
            'Selecione um widget na área de trabalho para editar seus campos.',
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

class _CatalogStyleTab extends StatelessWidget {
  const _CatalogStyleTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          'A aba de estilo será implementada em breve.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.black.withValues(alpha: 0.60),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
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
    return const ColoredBox(
      color: Colors.white,
      child: SizedBox.expand(),
    ).copyWithChild(child);
  }
}

extension _ColoredBoxCopyWith on ColoredBox {
  Widget copyWithChild(Widget child) {
    return ColoredBox(
      color: color,
      child: child,
    );
  }
}