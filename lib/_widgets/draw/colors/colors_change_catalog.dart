import 'package:flutter/material.dart';
import 'package:sipged/_widgets/draw/colors/colors_catalog_dialog.dart';

class ColorsChangeCatalog extends StatefulWidget {
  final int selectedColorValue;
  final ValueChanged<int> onChanged;
  final String title;

  const ColorsChangeCatalog({
    super.key,
    required this.selectedColorValue,
    required this.onChanged,
    this.title = 'Cor do ícone',
  });

  @override
  State<ColorsChangeCatalog> createState() => _ColorsChangeCatalogState();
}

class _ColorsChangeCatalogState extends State<ColorsChangeCatalog> {
  late int _selectedColorValue;

  @override
  void initState() {
    super.initState();
    _selectedColorValue = widget.selectedColorValue;
  }

  @override
  void didUpdateWidget(covariant ColorsChangeCatalog oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedColorValue != widget.selectedColorValue) {
      _selectedColorValue = widget.selectedColorValue;
    }
  }

  Future<void> _openColorPickerDialog() async {
    final result = await showDialog<int>(
      context: context,
      builder: (_) {
        return ColorsCatalogDialog(
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
                        color: selectedColor.withValues(alpha: 56 / 255),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hexArgb(selectedColor),
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