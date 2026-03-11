import 'package:flutter/material.dart';

class ColorsCatalog extends StatefulWidget {
  final int selectedColorValue;
  final ValueChanged<int> onChanged;
  final String title;
  final double maxHeight;

  const ColorsCatalog({
    super.key,
    required this.selectedColorValue,
    required this.onChanged,
    this.title = 'Cor do ícone',
    this.maxHeight = 220,
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
      builder: (dialogContext) {
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
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '#${selectedColor.value.toRadixString(16).padLeft(8, '0').toUpperCase()}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
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

    final neutralRows = <List<Color>>[
      [
        Colors.black,
        const Color(0xFF111111),
        const Color(0xFF222222),
        const Color(0xFF333333),
        const Color(0xFF444444),
        const Color(0xFF555555),
        const Color(0xFF666666),
        const Color(0xFF777777),
        const Color(0xFF888888),
        const Color(0xFF999999),
        const Color(0xFFAAAAAA),
        const Color(0xFFBBBBBB),
        const Color(0xFFCCCCCC),
        const Color(0xFFDDDDDD),
        const Color(0xFFEEEEEE),
        Colors.white,
      ],
      [
        const Color(0xFF330000),
        const Color(0xFF332000),
        const Color(0xFF333300),
        const Color(0xFF203300),
        const Color(0xFF003300),
        const Color(0xFF003320),
        const Color(0xFF003333),
        const Color(0xFF002033),
        const Color(0xFF000033),
        const Color(0xFF200033),
        const Color(0xFF330033),
        const Color(0xFF330020),
        const Color(0xFF4D2626),
        const Color(0xFF4D4D26),
        const Color(0xFF264D4D),
        const Color(0xFF4D264D),
      ],
    ];

    for (final row in neutralRows) {
      if (row.length == columns) {
        palette.addAll(row);
      } else {
        for (var i = 0; i < columns; i++) {
          final t = columns == 1 ? 0.0 : i / (columns - 1);
          final index =
          (t * (row.length - 1)).round().clamp(0, row.length - 1);
          palette.add(row[index]);
        }
      }
    }

    for (var row = 0; row < colorRows; row++) {
      final rowFactor = colorRows <= 1 ? 0.0 : row / (colorRows - 1);

      final saturation = 0.35 + (0.65 * rowFactor);
      final value = 1.0 - (0.45 * rowFactor);

      for (var col = 0; col < columns; col++) {
        final hue = columns <= 1 ? 0.0 : (col / columns) * 360.0;
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

  int _resolveColumns(double width) {
    if (width < 180) return 12;
    if (width < 240) return 14;
    if (width < 320) return 16;
    if (width < 420) return 18;
    return 20;
  }

  int _resolveColorRows(double height) {
    if (height < 120) return 6;
    if (height < 160) return 8;
    if (height < 220) return 10;
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
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 860,
          maxHeight: 700,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                    const infoAreaHeight = 44.0;
                    final usableGridHeight =
                    (constraints.maxHeight - infoAreaHeight)
                        .clamp(120.0, 10000.0);

                    final columns = _resolveColumns(constraints.maxWidth);
                    final colorRows = _resolveColorRows(usableGridHeight);
                    final palette = _buildPaletteGrid(
                      columns: columns,
                      colorRows: colorRows,
                    );

                    return Column(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border:
                              Border.all(color: Colors.grey.shade300),
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
                                          width: isSelected ? 2 : 0.35,
                                        ),
                                      ),
                                      child: isSelected
                                          ? Icon(
                                        Icons.check,
                                        size: 11,
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
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: selectedColor,
                                border:
                                Border.all(color: Colors.grey.shade500),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '#${selectedColor.value.toRadixString(16).padLeft(8, '0').toUpperCase()}',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
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