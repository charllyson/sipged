import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/geo_feature_data.dart';
import 'package:sipged/_widgets/geo/workspace/geo_workspace_item_data.dart';

class GeoVisualizationsData extends StatelessWidget {
  const GeoVisualizationsData({
    super.key,
    required this.selectedItem,
    required this.featuresByLayer,
    required this.onPropertyChanged,
    required this.onBindingDropped,
  });

  final GeoWorkspaceItemData? selectedItem;
  final Map<String, List<GeoFeatureData>> featuresByLayer;
  final void Function(String itemId, GeoWorkspacePropertyData property)
  onPropertyChanged;
  final void Function(
      String itemId,
      String propertyKey,
      GeoWorkspaceFieldDragData data,
      ) onBindingDropped;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (selectedItem == null) {
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.all(12),
        child: Center(
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

    final item = selectedItem!;
    final sourceBinding = item.getBindingProperty('source');
    final sourceLayerId = _resolveSourceLayerId(item);
    final sourceFeatures =
    sourceLayerId == null ? const <GeoFeatureData>[] : (featuresByLayer[sourceLayerId] ?? const <GeoFeatureData>[]);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dados da visualização',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${item.title} • ${item.id}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.black.withValues(alpha: 0.58),
            ),
          ),
          const SizedBox(height: 10),
          _SourceSummaryCard(
            sourceLabel: sourceBinding?.sourceLabel,
            sourceId: sourceBinding?.sourceId,
            totalFeatures: sourceFeatures.length,
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.separated(
              itemCount: item.properties.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, index) {
                final property = item.properties[index];

                return _VisualizationDataEditorRow(
                  key: ValueKey('${item.id}_${property.key}'),
                  itemId: item.id,
                  property: property,
                  featuresByLayer: featuresByLayer,
                  item: item,
                  onPropertyChanged: (updated) =>
                      onPropertyChanged(item.id, updated),
                  onBindingDropped: (data) =>
                      onBindingDropped(item.id, property.key, data),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static String? _resolveSourceLayerId(GeoWorkspaceItemData item) {
    final source = item.getBindingProperty('source');
    final sourceId = source?.sourceId?.trim();
    if (sourceId != null && sourceId.isNotEmpty) return sourceId;

    for (final property in item.properties) {
      final binding = property.bindingValue;
      final candidate = binding?.sourceId?.trim();
      if (candidate != null && candidate.isNotEmpty) {
        return candidate;
      }
    }

    return null;
  }
}

class _SourceSummaryCard extends StatelessWidget {
  final String? sourceLabel;
  final String? sourceId;
  final int totalFeatures;

  const _SourceSummaryCard({
    required this.sourceLabel,
    required this.sourceId,
    required this.totalFeatures,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    final hasSource = (sourceId ?? '').trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: primary.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.dataset_linked_outlined,
            size: 18,
            color: primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hasSource
                  ? '${sourceLabel ?? 'Camada'} • $totalFeatures registros carregados'
                  : 'Nenhuma fonte vinculada ainda',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VisualizationDataEditorRow extends StatelessWidget {
  const _VisualizationDataEditorRow({
    super.key,
    required this.itemId,
    required this.item,
    required this.property,
    required this.featuresByLayer,
    required this.onPropertyChanged,
    required this.onBindingDropped,
  });

  final String itemId;
  final GeoWorkspaceItemData item;
  final GeoWorkspacePropertyData property;
  final Map<String, List<GeoFeatureData>> featuresByLayer;
  final ValueChanged<GeoWorkspacePropertyData> onPropertyChanged;
  final ValueChanged<GeoWorkspaceFieldDragData> onBindingDropped;

  @override
  Widget build(BuildContext context) {
    final content = switch (property.type) {
      GeoWorkspacePropertyType.text => _TextPropertyEditor(
        key: ValueKey('text_${property.key}'),
        property: property,
        onChanged: (value) => onPropertyChanged(
          property.copyWith(textValue: value),
        ),
      ),
      GeoWorkspacePropertyType.number => _NumberPropertyEditor(
        key: ValueKey('number_${property.key}'),
        property: property,
        onChanged: (value) => onPropertyChanged(
          property.copyWith(numberValue: value),
        ),
      ),
      GeoWorkspacePropertyType.stringList => _StringListPropertyEditor(
        key: ValueKey('string_list_${property.key}'),
        property: property,
        onChanged: (value) => onPropertyChanged(
          property.copyWith(stringListValue: value),
        ),
      ),
      GeoWorkspacePropertyType.numberList => _NumberListPropertyEditor(
        key: ValueKey('number_list_${property.key}'),
        property: property,
        onChanged: (value) => onPropertyChanged(
          property.copyWith(numberListValue: value),
        ),
      ),
      GeoWorkspacePropertyType.select => _SelectPropertyEditor(
        key: ValueKey('select_${property.key}'),
        property: property,
        onChanged: (value) => onPropertyChanged(
          property.copyWith(selectedValue: value),
        ),
      ),
      GeoWorkspacePropertyType.binding => _BindingPropertyEditor(
        key: ValueKey('binding_${property.key}'),
        item: item,
        property: property,
        featuresByLayer: featuresByLayer,
        onBindingDropped: onBindingDropped,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.08),
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                property.label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: content),
        ],
      ),
    );
  }
}

class _TextPropertyEditor extends StatefulWidget {
  const _TextPropertyEditor({
    super.key,
    required this.property,
    required this.onChanged,
  });

  final GeoWorkspacePropertyData property;
  final ValueChanged<String> onChanged;

  @override
  State<_TextPropertyEditor> createState() => _TextPropertyEditorState();
}

class _TextPropertyEditorState extends State<_TextPropertyEditor> {
  late final TextEditingController _controller;

  String get _externalValue => widget.property.textValue ?? '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _externalValue);
  }

  @override
  void didUpdateWidget(covariant _TextPropertyEditor oldWidget) {
    super.didUpdateWidget(oldWidget);

    final newValue = _externalValue;
    if (_controller.text != newValue) {
      _controller.value = TextEditingValue(
        text: newValue,
        selection: TextSelection.collapsed(offset: newValue.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        isDense: true,
        hintText: widget.property.hint,
        border: const OutlineInputBorder(),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
    );
  }
}

class _NumberPropertyEditor extends StatefulWidget {
  const _NumberPropertyEditor({
    super.key,
    required this.property,
    required this.onChanged,
  });

  final GeoWorkspacePropertyData property;
  final ValueChanged<double> onChanged;

  @override
  State<_NumberPropertyEditor> createState() => _NumberPropertyEditorState();
}

class _NumberPropertyEditorState extends State<_NumberPropertyEditor> {
  late final TextEditingController _controller;

  String get _externalValue => widget.property.numberValue?.toString() ?? '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _externalValue);
  }

  @override
  void didUpdateWidget(covariant _NumberPropertyEditor oldWidget) {
    super.didUpdateWidget(oldWidget);

    final newValue = _externalValue;
    if (_controller.text != newValue) {
      _controller.value = TextEditingValue(
        text: newValue,
        selection: TextSelection.collapsed(offset: newValue.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (value) {
        final parsed = double.tryParse(value.replaceAll(',', '.'));
        if (parsed != null) {
          widget.onChanged(parsed);
        }
      },
      decoration: InputDecoration(
        isDense: true,
        hintText: widget.property.hint,
        border: const OutlineInputBorder(),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
    );
  }
}

class _StringListPropertyEditor extends StatefulWidget {
  const _StringListPropertyEditor({
    super.key,
    required this.property,
    required this.onChanged,
  });

  final GeoWorkspacePropertyData property;
  final ValueChanged<List<String>> onChanged;

  @override
  State<_StringListPropertyEditor> createState() =>
      _StringListPropertyEditorState();
}

class _StringListPropertyEditorState extends State<_StringListPropertyEditor> {
  late final TextEditingController _controller;

  String get _externalValue =>
      (widget.property.stringListValue ?? const []).join(', ');

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _externalValue);
  }

  @override
  void didUpdateWidget(covariant _StringListPropertyEditor oldWidget) {
    super.didUpdateWidget(oldWidget);

    final newValue = _externalValue;
    if (_controller.text != newValue) {
      _controller.value = TextEditingValue(
        text: newValue,
        selection: TextSelection.collapsed(offset: newValue.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      minLines: 1,
      maxLines: 3,
      onChanged: (value) {
        final next = value
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(growable: false);
        widget.onChanged(next);
      },
      decoration: InputDecoration(
        isDense: true,
        hintText: widget.property.hint ?? 'Separar por vírgula',
        border: const OutlineInputBorder(),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
    );
  }
}

class _NumberListPropertyEditor extends StatefulWidget {
  const _NumberListPropertyEditor({
    super.key,
    required this.property,
    required this.onChanged,
  });

  final GeoWorkspacePropertyData property;
  final ValueChanged<List<double>> onChanged;

  @override
  State<_NumberListPropertyEditor> createState() =>
      _NumberListPropertyEditorState();
}

class _NumberListPropertyEditorState extends State<_NumberListPropertyEditor> {
  late final TextEditingController _controller;

  String get _externalValue =>
      (widget.property.numberListValue ?? const []).join(', ');

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _externalValue);
  }

  @override
  void didUpdateWidget(covariant _NumberListPropertyEditor oldWidget) {
    super.didUpdateWidget(oldWidget);

    final newValue = _externalValue;
    if (_controller.text != newValue) {
      _controller.value = TextEditingValue(
        text: newValue,
        selection: TextSelection.collapsed(offset: newValue.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      minLines: 1,
      maxLines: 3,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (value) {
        final parts = value.split(',');
        final next = <double>[];

        for (final part in parts) {
          final normalized = part.trim().replaceAll(',', '.');
          final parsed = double.tryParse(normalized);
          if (parsed != null) {
            next.add(parsed);
          }
        }

        widget.onChanged(next);
      },
      decoration: InputDecoration(
        isDense: true,
        hintText: widget.property.hint ?? 'Separar por vírgula',
        border: const OutlineInputBorder(),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
    );
  }
}

class _SelectPropertyEditor extends StatelessWidget {
  const _SelectPropertyEditor({
    super.key,
    required this.property,
    required this.onChanged,
  });

  final GeoWorkspacePropertyData property;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = property.options ?? const <String>[];
    final selected =
    options.contains(property.selectedValue) ? property.selectedValue : null;

    return DropdownButtonFormField<String>(
      value: selected,
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
      items: options
          .map(
            (e) => DropdownMenuItem<String>(
          value: e,
          child: Text(e),
        ),
      )
          .toList(growable: false),
      decoration: const InputDecoration(
        isDense: true,
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
    );
  }
}

class _BindingPropertyEditor extends StatefulWidget {
  const _BindingPropertyEditor({
    super.key,
    required this.item,
    required this.property,
    required this.featuresByLayer,
    required this.onBindingDropped,
  });

  final GeoWorkspaceItemData item;
  final GeoWorkspacePropertyData property;
  final Map<String, List<GeoFeatureData>> featuresByLayer;
  final ValueChanged<GeoWorkspaceFieldDragData> onBindingDropped;

  @override
  State<_BindingPropertyEditor> createState() => _BindingPropertyEditorState();
}

class _BindingPropertyEditorState extends State<_BindingPropertyEditor> {
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final binding = widget.property.bindingValue;
    final hasBinding = binding != null &&
        ((binding.sourceId ?? '').trim().isNotEmpty ||
            (binding.fieldName ?? '').trim().isNotEmpty);

    final display = hasBinding
        ? binding!.displayValue
        : (widget.property.hint ?? 'Arraste um campo aqui');

    final preview = _BindingPreviewData.from(
      item: widget.item,
      property: widget.property,
      featuresByLayer: widget.featuresByLayer,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DragTarget<GeoWorkspaceFieldDragData>(
          onWillAcceptWithDetails: (_) {
            final accepts = widget.property.acceptsDrop;
            if (accepts) {
              setState(() => _dragging = true);
            }
            return accepts;
          },
          onLeave: (_) {
            if (mounted) {
              setState(() => _dragging = false);
            }
          },
          onAcceptWithDetails: (details) {
            setState(() => _dragging = false);
            widget.onBindingDropped(details.data);
          },
          builder: (context, candidateData, rejectedData) {
            final active = _dragging || candidateData.isNotEmpty;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
              decoration: BoxDecoration(
                color: active
                    ? theme.colorScheme.primary.withValues(alpha: 0.06)
                    : hasBinding
                    ? theme.colorScheme.primary.withValues(alpha: 0.025)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: active
                      ? theme.colorScheme.primary.withValues(alpha: 0.55)
                      : hasBinding
                      ? theme.colorScheme.primary.withValues(alpha: 0.24)
                      : Colors.black.withValues(alpha: 0.10),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    hasBinding ? Icons.link_rounded : Icons.input_rounded,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      display,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: hasBinding ? FontWeight.w600 : FontWeight.w500,
                        color: hasBinding
                            ? Colors.black.withValues(alpha: 0.84)
                            : Colors.black.withValues(alpha: 0.62),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        if (preview.hasData) ...[
          const SizedBox(height: 8),
          _BindingPreviewCard(preview: preview),
        ],
      ],
    );
  }
}

class _BindingPreviewData {
  final int totalRows;
  final int filledRows;
  final int distinctRows;
  final List<String> samples;

  const _BindingPreviewData({
    required this.totalRows,
    required this.filledRows,
    required this.distinctRows,
    required this.samples,
  });

  bool get hasData => totalRows > 0;

  factory _BindingPreviewData.from({
    required GeoWorkspaceItemData item,
    required GeoWorkspacePropertyData property,
    required Map<String, List<GeoFeatureData>> featuresByLayer,
  }) {
    final binding = property.bindingValue;
    final sourceId = _resolveSourceId(item, property);

    if (sourceId == null || sourceId.isEmpty) {
      return const _BindingPreviewData(
        totalRows: 0,
        filledRows: 0,
        distinctRows: 0,
        samples: [],
      );
    }

    final features = featuresByLayer[sourceId] ?? const <GeoFeatureData>[];
    if (features.isEmpty) {
      return const _BindingPreviewData(
        totalRows: 0,
        filledRows: 0,
        distinctRows: 0,
        samples: [],
      );
    }

    final fieldName = binding?.fieldName?.trim();

    if (property.key == 'source' || fieldName == null || fieldName.isEmpty) {
      return _BindingPreviewData(
        totalRows: features.length,
        filledRows: features.length,
        distinctRows: features.length,
        samples: const [],
      );
    }

    final values = <String>[];
    final distinct = <String>{};

    for (final feature in features) {
      final raw = feature.properties[fieldName];
      if (raw == null) continue;

      final text = raw.toString().trim();
      if (text.isEmpty) continue;

      values.add(text);
      distinct.add(text);
    }

    return _BindingPreviewData(
      totalRows: features.length,
      filledRows: values.length,
      distinctRows: distinct.length,
      samples: distinct.take(5).toList(growable: false),
    );
  }

  static String? _resolveSourceId(
      GeoWorkspaceItemData item,
      GeoWorkspacePropertyData property,
      ) {
    final ownSourceId = property.bindingValue?.sourceId?.trim();
    if (ownSourceId != null && ownSourceId.isNotEmpty) return ownSourceId;

    final itemSourceId = item.getBindingProperty('source')?.sourceId?.trim();
    if (itemSourceId != null && itemSourceId.isNotEmpty) return itemSourceId;

    for (final prop in item.properties) {
      final candidate = prop.bindingValue?.sourceId?.trim();
      if (candidate != null && candidate.isNotEmpty) return candidate;
    }

    return null;
  }
}

class _BindingPreviewCard extends StatelessWidget {
  final _BindingPreviewData preview;

  const _BindingPreviewCard({
    required this.preview,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${preview.filledRows}/${preview.totalRows} preenchidos • ${preview.distinctRows} distintos',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (preview.samples.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: preview.samples
                  .map(
                    (sample) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    sample,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
                  .toList(growable: false),
            ),
          ],
        ],
      ),
    );
  }
}