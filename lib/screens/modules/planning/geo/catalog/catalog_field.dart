import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sipged/_blocs/modules/planning/geo/catalog/catalog_data.dart';
import 'package:sipged/_widgets/input/drop_down_change.dart';
import 'package:sipged/_widgets/input/text_field_change.dart';

class CatalogField extends StatefulWidget {
  const CatalogField({
    super.key,
    required this.property,
    required this.onPropertyChanged,
  });

  final CatalogData property;
  final ValueChanged<CatalogData> onPropertyChanged;

  @override
  State<CatalogField> createState() => _CatalogFieldState();
}

class _CatalogFieldState extends State<CatalogField> {
  late final TextEditingController _textController;
  late final TextEditingController _selectController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: _currentTextValue);
    _selectController = TextEditingController(text: _currentSelectValue);
  }

  @override
  void didUpdateWidget(covariant CatalogField oldWidget) {
    super.didUpdateWidget(oldWidget);

    final nextText = _currentTextValue;
    if (_textController.text != nextText) {
      _textController.value = TextEditingValue(
        text: nextText,
        selection: TextSelection.collapsed(offset: nextText.length),
      );
    }

    final nextSelect = _currentSelectValue;
    if (_selectController.text != nextSelect) {
      _selectController.value = TextEditingValue(
        text: nextSelect,
        selection: TextSelection.collapsed(offset: nextSelect.length),
      );
    }
  }

  String get _currentTextValue {
    switch (widget.property.type) {
      case CatalogPropertyType.text:
        return widget.property.textValue ?? '';
      case CatalogPropertyType.number:
        return widget.property.numberValue?.toString() ?? '';
      case CatalogPropertyType.select:
      case CatalogPropertyType.binding:
      case null:
        return '';
    }
  }

  String get _currentSelectValue => widget.property.selectedValue ?? '';

  @override
  void dispose() {
    _textController.dispose();
    _selectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.property.type) {
      case CatalogPropertyType.text:
        return CustomTextField(
          controller: _textController,
          hintText: widget.property.hint,
          onChanged: (value) {
            widget.onPropertyChanged(
              widget.property.copyWith(textValue: value),
            );
          },
        );

      case CatalogPropertyType.number:
        return CustomTextField(
          controller: _textController,
          hintText: widget.property.hint,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9,.\-]')),
          ],
          onChanged: (value) {
            final normalized = value.trim().replaceAll(',', '.');

            if (normalized.isEmpty) {
              widget.onPropertyChanged(
                widget.property.copyWith(numberValue: null),
              );
              return;
            }

            final parsed = double.tryParse(normalized);
            if (parsed == null) return;

            widget.onPropertyChanged(
              widget.property.copyWith(numberValue: parsed),
            );
          },
        );

      case CatalogPropertyType.select:
        return DropDownChange(
          controller: _selectController,
          items: widget.property.options ?? const <String>[],
          tooltipMessage: widget.property.hint,
          onChanged: (value) {
            widget.onPropertyChanged(
              widget.property.copyWith(selectedValue: value),
            );
          },
        );

      case CatalogPropertyType.binding:
      case null:
        return const SizedBox.shrink();
    }
  }
}