import 'package:flutter/material.dart';

class ColorsCatalog extends StatefulWidget {
  final int selectedColorValue;
  final ValueChanged<int> onChanged;
  final String title;

  const ColorsCatalog({
    super.key,
    required this.selectedColorValue,
    required this.onChanged,
    this.title = 'Cor do ícone',
  });

  @override
  State<ColorsCatalog> createState() => _ColorsCatalogState();
}

class _ColorsCatalogState extends State<ColorsCatalog> {
  late int _selectedColorValue;

  @override
  void initState() {
    super.initState();
    _selectedColorValue = widget.selectedColorValue;
  }

  @override
  void didUpdateWidget(covariant ColorsCatalog oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedColorValue != widget.selectedColorValue) {
      _selectedColorValue = widget.selectedColorValue;
    }
  }

  Future<void> _openColorPickerDialog() async {
    final result = await showDialog<int>(
      context: context,
      builder: (_) {
        return _ColorsCatalogDialog(
          initialColorValue: _selectedColorValue,
          title: widget.title,
        );
      },
    );

    if (result != null && result != _selectedColorValue) {
      setState(() => _selectedColorValue = result);
      widget.onChanged(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedColor = Color(_selectedColorValue);

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
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: _openColorPickerDialog,
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 28,
                  decoration: BoxDecoration(
                    color: selectedColor,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade500),
                    boxShadow: [
                      BoxShadow(
                        color: selectedColor.withValues(alpha: 0.22),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '#${selectedColor.value.toRadixString(16).padLeft(8, '0').toUpperCase()}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: Colors.grey.shade700,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ColorsCatalogDialog extends StatefulWidget {
  final int initialColorValue;
  final String title;

  const _ColorsCatalogDialog({
    required this.initialColorValue,
    required this.title,
  });

  @override
  State<_ColorsCatalogDialog> createState() => _ColorsCatalogDialogState();
}

class _ColorsCatalogDialogState extends State<_ColorsCatalogDialog> {
  late int _selectedColorValue;

  static const List<Color> _accentRow = [
    Color(0xFFE11D48),
    Color(0xFFEF4444),
    Color(0xFFF97316),
    Color(0xFFF59E0B),
    Color(0xFFEAB308),
    Color(0xFF84CC16),
    Color(0xFF22C55E),
    Color(0xFF10B981),
    Color(0xFF14B8A6),
    Color(0xFF06B6D4),
    Color(0xFF0EA5E9),
    Color(0xFF3B82F6),
    Color(0xFF6366F1),
    Color(0xFF8B5CF6),
    Color(0xFFD946EF),
    Color(0xFFEC4899),
  ];

  static const List<Color> _neutralRow = [
    Color(0xFF000000),
    Color(0xFF111827),
    Color(0xFF1F2937),
    Color(0xFF374151),
    Color(0xFF4B5563),
    Color(0xFF6B7280),
    Color(0xFF9CA3AF),
    Color(0xFFD1D5DB),
    Color(0xFFE5E7EB),
    Color(0xFFF3F4F6),
    Color(0xFFFFFFFF),
  ];

  @override
  void initState() {
    super.initState();
    _selectedColorValue = widget.initialColorValue;
  }

  List<Color> _buildPaletteGrid({
    required int columns,
    required int colorRows,
  }) {
    final palette = <Color>[];

    palette.addAll(_expandToColumns(_neutralRow, columns));
    palette.addAll(_expandToColumns(_accentRow, columns));

    for (int row = 0; row < colorRows; row++) {
      final t = colorRows <= 1 ? 0.0 : row / (colorRows - 1);

      final saturation = _lerpNum(0.35, 1.0, t);
      final value = _lerpNum(1.0, 0.78, t);

      for (int col = 0; col < columns; col++) {
        final hue = (col / columns) * 360.0;
        palette.add(
          HSVColor.fromAHSV(
            1,
            hue,
            saturation.clamp(0.0, 1.0),
            value.clamp(0.0, 1.0),
          ).toColor(),
        );
      }
    }

    return palette;
  }

  List<Color> _expandToColumns(List<Color> base, int columns) {
    if (base.length == columns) return base;

    return List<Color>.generate(columns, (index) {
      final t = columns == 1 ? 0.0 : index / (columns - 1);
      final mapped = (t * (base.length - 1)).round().clamp(0, base.length - 1);
      return base[mapped];
    });
  }

  int _resolveColumns(double width) {
    if (width < 220) return 10;
    if (width < 280) return 12;
    if (width < 360) return 14;
    if (width < 460) return 16;
    if (width < 640) return 18;
    return 20;
  }

  int _resolveColorRows(double height) {
    if (height < 140) return 6;
    if (height < 200) return 8;
    if (height < 260) return 10;
    return 12;
  }

  Color _bestContrast(Color c) {
    final brightness = ThemeData.estimateBrightnessForColor(c);
    return brightness == Brightness.dark ? Colors.white : Colors.black;
  }

  @override
  Widget build(BuildContext context) {
    final selectedColor = Color(_selectedColorValue);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 900,
          maxHeight: 720,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fechar',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = _resolveColumns(constraints.maxWidth);
                    final rows = _resolveColorRows(constraints.maxHeight);
                    final palette = _buildPaletteGrid(
                      columns: columns,
                      colorRows: rows,
                    );

                    return Column(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: GridView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: palette.length,
                              gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                mainAxisSpacing: 0,
                                crossAxisSpacing: 0,
                                childAspectRatio: 1,
                              ),
                              itemBuilder: (context, index) {
                                final color = palette[index];
                                final isSelected =
                                    color.value == _selectedColorValue;

                                return Tooltip(
                                  message:
                                  '#${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}',
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        _selectedColorValue = color.value;
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: color,
                                        border: Border.all(
                                          color: isSelected
                                              ? Colors.black
                                              : Colors.black12,
                                          width: isSelected ? 2.2 : 0.35,
                                        ),
                                      ),
                                      child: isSelected
                                          ? Icon(
                                        Icons.check,
                                        size: 12,
                                        color: _bestContrast(color),
                                      )
                                          : null,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Text(
                              'Selecionada:',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: selectedColor,
                                border: Border.all(
                                  color: Colors.grey.shade500,
                                ),
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                    selectedColor.withValues(alpha: 0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '#${selectedColor.value.toRadixString(16).padLeft(8, '0').toUpperCase()}',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: () =>
                        Navigator.of(context).pop(_selectedColorValue),
                    child: const Text('Aplicar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

double _lerpNum(num a, num b, double t) {
  return a * (1.0 - t) + b * t;
}