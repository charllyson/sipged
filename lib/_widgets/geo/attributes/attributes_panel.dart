import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/geo_feature_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/geo_feature_state.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data.dart';
import 'package:sipged/_widgets/geo/workspace/geo_workspace_item_data.dart';

class AttributesPanel extends StatelessWidget {
  final GeoFeatureState genericState;
  final Map<String, GeoLayersData> layersById;
  final String? selectedLayerId;
  final Map<String, List<String>> availableFieldsByLayer;

  const AttributesPanel({
    super.key,
    required this.genericState,
    required this.layersById,
    required this.selectedLayerId,
    required this.availableFieldsByLayer,
  });

  @override
  Widget build(BuildContext context) {
    final featureSelection = genericState.selected;
    final selectedLayer =
    selectedLayerId == null ? null : layersById[selectedLayerId!];

    // A feição clicada no mapa sempre tem prioridade no painel de atributos.
    if (featureSelection != null) {
      final layer = layersById[featureSelection.layerId];
      final feature = featureSelection.feature;

      final entries = feature.properties.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));

      return RepaintBoundary(
        child: _AttributesContent(
          headerTitle: layer?.title ?? 'Camada',
          headerSubtitle: 'Atributos da feição selecionada',
          headerColor: (layer?.color ?? Colors.blue).withValues(alpha: 0.10),
          emptyText: 'Esta feição não possui atributos.',
          children: [
            for (final entry in entries)
              _AttributeTile(
                label: entry.key,
                value: entry.value == null ? '' : entry.value.toString(),
                dragData: GeoWorkspaceFieldDragData(
                  sourceId: featureSelection.layerId,
                  sourceLabel: layer?.title ?? 'Camada',
                  fieldName: entry.key,
                  fieldValue: entry.value,
                ),
              ),
          ],
        ),
      );
    }

    if (selectedLayer != null) {
      final fields = List<String>.from(
        availableFieldsByLayer[selectedLayer.id] ?? const <String>[],
      )..sort((a, b) => a.compareTo(b));

      final hasLoadedFeatures =
          genericState.loadedByLayer[selectedLayer.id] == true;
      final loadingFeatures =
          genericState.loadingByLayer[selectedLayer.id] == true;
      final features =
          genericState.featuresByLayer[selectedLayer.id] ?? const <GeoFeatureData>[];

      return RepaintBoundary(
        child: _AttributesContent(
          headerTitle: selectedLayer.title,
          headerSubtitle: 'Campos disponíveis da camada',
          headerColor: selectedLayer.color.withValues(alpha: 0.10),
          emptyText: 'Esta camada ainda não possui campos identificados.',
          children: [
            for (final field in fields)
              _FieldHeaderTile(
                label: field,
                previewText: _buildPreviewText(
                  loading: loadingFeatures,
                  loaded: hasLoadedFeatures,
                  features: features,
                  field: field,
                ),
                dragData: GeoWorkspaceFieldDragData(
                  sourceId: selectedLayer.id,
                  sourceLabel: selectedLayer.title,
                  fieldName: field,
                ),
              ),
          ],
        ),
      );
    }

    return const Center(
      child: Text(
        'Selecione uma feição no mapa ou uma camada no painel para visualizar os atributos.',
        textAlign: TextAlign.center,
      ),
    );
  }

  static String _buildPreviewText({
    required bool loading,
    required bool loaded,
    required List<GeoFeatureData> features,
    required String field,
  }) {
    if (loading) {
      return 'Carregando dados...';
    }

    if (!loaded) {
      return 'Aguardando carga da camada';
    }

    if (features.isEmpty) {
      return 'Camada sem registros carregados';
    }

    int filled = 0;
    final unique = <String>{};

    for (final feature in features) {
      final value = feature.properties[field];
      if (value == null) continue;

      final text = value.toString().trim();
      if (text.isEmpty) continue;

      filled++;
      unique.add(text);
    }

    return '$filled preenchidos • ${unique.length} distintos';
  }
}

class _AttributesContent extends StatelessWidget {
  final String headerTitle;
  final String headerSubtitle;
  final Color headerColor;
  final String emptyText;
  final List<Widget> children;

  const _AttributesContent({
    required this.headerTitle,
    required this.headerSubtitle,
    required this.headerColor,
    required this.emptyText,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: headerColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headerTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  headerSubtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: children.isEmpty
              ? Center(child: Text(emptyText))
              : ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 5),
            itemCount: children.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, index) => children[index],
          ),
        ),
      ],
    );
  }
}

class _AttributeTile extends StatefulWidget {
  final String label;
  final String value;
  final GeoWorkspaceFieldDragData? dragData;

  const _AttributeTile({
    required this.label,
    required this.value,
    this.dragData,
  });

  @override
  State<_AttributeTile> createState() => _AttributeTileState();
}

class _AttributeTileState extends State<_AttributeTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final cardContent = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.drag_indicator_rounded,
          size: 18,
          color: theme.colorScheme.primary.withValues(alpha: 0.85),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.value.isEmpty ? '-' : widget.value,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );

    final card = DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: _hovered ? 0.60 : 0.35),
        ),
        borderRadius: BorderRadius.circular(10),
        color: _hovered
            ? theme.colorScheme.primary.withValues(alpha: 0.03)
            : Colors.transparent,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: IgnorePointer(
          ignoring: true,
          child: cardContent,
        ),
      ),
    );

    final dragData = widget.dragData;
    if (dragData == null) return card;

    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Draggable<GeoWorkspaceFieldDragData>(
        data: dragData,
        maxSimultaneousDrags: 1,
        feedback: _FieldDragFeedback(
          sourceLabel: dragData.sourceLabel,
          fieldName: dragData.fieldName,
          fieldValue: dragData.fieldValue,
        ),
        childWhenDragging: Opacity(
          opacity: 0.35,
          child: card,
        ),
        child: card,
      ),
    );
  }
}

class _FieldHeaderTile extends StatefulWidget {
  final String label;
  final String previewText;
  final GeoWorkspaceFieldDragData dragData;

  const _FieldHeaderTile({
    required this.label,
    required this.previewText,
    required this.dragData,
  });

  @override
  State<_FieldHeaderTile> createState() => _FieldHeaderTileState();
}

class _FieldHeaderTileState extends State<_FieldHeaderTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final child = DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: _hovered ? 0.60 : 0.35),
        ),
        borderRadius: BorderRadius.circular(10),
        color: _hovered
            ? theme.colorScheme.primary.withValues(alpha: 0.04)
            : Colors.transparent,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: IgnorePointer(
          ignoring: true,
          child: Row(
            children: [
              Icon(
                Icons.drag_indicator_rounded,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.previewText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.black.withValues(alpha: 0.58),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.link_rounded,
                size: 16,
                color: theme.colorScheme.primary.withValues(alpha: 0.80),
              ),
            ],
          ),
        ),
      ),
    );

    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Draggable<GeoWorkspaceFieldDragData>(
        data: widget.dragData,
        maxSimultaneousDrags: 1,
        feedback: _FieldDragFeedback(
          sourceLabel: widget.dragData.sourceLabel,
          fieldName: widget.dragData.fieldName,
          fieldValue: widget.dragData.fieldValue,
        ),
        childWhenDragging: Opacity(
          opacity: 0.35,
          child: child,
        ),
        child: child,
      ),
    );
  }
}

class _FieldDragFeedback extends StatelessWidget {
  final String sourceLabel;
  final String fieldName;
  final dynamic fieldValue;

  const _FieldDragFeedback({
    required this.sourceLabel,
    required this.fieldName,
    this.fieldValue,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final valueText = fieldValue?.toString().trim();

    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 260),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: primary.withValues(alpha: 0.45),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.account_tree_outlined,
                  size: 18,
                  color: primary,
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    '$sourceLabel • $fieldName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if (valueText != null && valueText.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  valueText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}