import 'package:flutter/material.dart';
import 'package:sipged/_widgets/draw/icons/icons_change_catalog.dart';

class IconPickerGrid extends StatefulWidget {
  final List<IconsChangeCatalog>? options;
  final String? selectedKey;
  final ValueChanged<String> onChanged;
  final Color previewColor;
  final double itemSize;
  final int maxColumns;
  final String title;
  final bool showSearch;
  final double maxGridHeight;

  const IconPickerGrid({
    super.key,
    this.options,
    required this.selectedKey,
    required this.onChanged,
    this.previewColor = Colors.blue,
    this.itemSize = 52,
    this.maxColumns = 7,
    this.title = 'Ícone',
    this.showSearch = true,
    this.maxGridHeight = 320,
  });

  @override
  State<IconPickerGrid> createState() => _IconPickerGridState();
}

class _IconPickerGridState extends State<IconPickerGrid> {
  late String? _selectedKey;
  late final TextEditingController _searchController;
  String _query = '';

  List<IconsChangeCatalog> get _sourceOptions =>
      widget.options ?? IconsCatalog.options;

  List<IconsChangeCatalog> get _filteredOptions {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _sourceOptions;

    return _sourceOptions.where((option) {
      return option.label.toLowerCase().contains(q) ||
          option.key.toLowerCase().contains(q);
    }).toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _selectedKey = widget.selectedKey;
    _searchController = TextEditingController()
      ..addListener(_handleSearchChanged);
  }

  @override
  void didUpdateWidget(covariant IconPickerGrid oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedKey != widget.selectedKey) {
      _selectedKey = widget.selectedKey;
    }
  }

  void _handleSearchChanged() {
    if (!mounted) return;
    setState(() => _query = _searchController.text);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    super.dispose();
  }

  int _resolveColumns(double maxWidth) {
    if (maxWidth < 260) return 3;
    if (maxWidth < 340) return 4;
    if (maxWidth < 440) return 5;
    if (maxWidth < 560) return 6;
    return widget.maxColumns;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredOptions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        if (widget.showSearch) ...[
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Buscar ícone',
              prefixIcon: const Icon(Icons.search, size: 18),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                onPressed: _searchController.clear,
                icon: const Icon(Icons.close, size: 18),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        SizedBox(
          height: widget.maxGridHeight,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: filtered.isEmpty
                ? const Center(
              child: Text('Nenhum ícone encontrado.'),
            )
                : LayoutBuilder(
              builder: (context, constraints) {
                const spacing = 10.0;
                final crossAxisCount =
                _resolveColumns(constraints.maxWidth);
                final totalSpacing = (crossAxisCount - 1) * spacing;
                final tileWidth =
                ((constraints.maxWidth - totalSpacing) /
                    crossAxisCount)
                    .clamp(40.0, widget.itemSize);

                return Scrollbar(
                  thumbVisibility: true,
                  child: GridView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: filtered.length,
                    gridDelegate:
                    SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: spacing,
                      crossAxisSpacing: spacing,
                      childAspectRatio: 1,
                      mainAxisExtent: tileWidth,
                    ),
                    itemBuilder: (context, index) {
                      final option = filtered[index];
                      final isSelected = option.key == _selectedKey;

                      return Tooltip(
                        message: option.label,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            setState(() => _selectedKey = option.key);
                            widget.onChanged(option.key);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? widget.previewColor
                                  .withValues(alpha: 0.12)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? widget.previewColor
                                    : Colors.grey.shade300,
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                BoxShadow(
                                  color: widget.previewColor
                                      .withValues(alpha: 0.18),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                                  : null,
                            ),
                            child: Icon(
                              option.icon,
                              size: tileWidth < 46 ? 18 : 22,
                              color: isSelected
                                  ? widget.previewColor
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}