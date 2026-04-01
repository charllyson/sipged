import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sipged/_blocs/modules/planning/geo/catalog/property/component_data_property.dart';
import 'package:sipged/_widgets/input/drop_down_change.dart';
import 'package:sipged/_widgets/input/text_field_change.dart';

class PropertyField extends StatefulWidget {
  const PropertyField({
    super.key,
    required this.property,
    required this.onPropertyChanged,
  });

  final ComponentDataProperty property;
  final ValueChanged<ComponentDataProperty> onPropertyChanged;

  @override
  State<PropertyField> createState() => _PropertyFieldState();
}

class _PropertyFieldState extends State<PropertyField> {
  late final TextEditingController _textController;
  late final TextEditingController _selectController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: _currentTextValue);
    _selectController = TextEditingController(text: _currentSelectValue);
  }

  @override
  void didUpdateWidget(covariant PropertyField oldWidget) {
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
      case ComponentPropertyType.text:
        return widget.property.textValue ?? '';
      case ComponentPropertyType.number:
        return widget.property.numberValue?.toString() ?? '';
      case ComponentPropertyType.select:
      case ComponentPropertyType.binding:
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
      case ComponentPropertyType.text:
        return CustomTextField(
          controller: _textController,
          hintText: widget.property.hint,
          onChanged: (value) {
            widget.onPropertyChanged(
              widget.property.copyWith(textValue: value),
            );
          },
        );

      case ComponentPropertyType.number:
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

      case ComponentPropertyType.select:
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

      case ComponentPropertyType.binding:
        return const SizedBox.shrink();
    }
  }
}