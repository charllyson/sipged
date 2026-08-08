import 'package:flutter/material.dart';

import 'text_change_data.dart';

typedef TextChangeTextFieldBuilder = Widget Function({
required BuildContext context,
required TextEditingController controller,
required String labelText,
required ValueChanged<String> onChanged,
});

typedef TextChangeDropdownBuilder = Widget Function({
required BuildContext context,
required TextEditingController controller,
required String labelText,
required List<String> items,
required ValueChanged<String?> onChanged,
required bool enabled,
});

typedef TextChangeNumberFieldBuilder = Widget Function({
required BuildContext context,
required String label,
required double value,
required ValueChanged<double> onChanged,
});

typedef TextChangeColorPickerBuilder = Widget Function({
required BuildContext context,
required String title,
required int selectedColorValue,
required ValueChanged<int> onChanged,
});

class TextChangeDataStyle extends StatefulWidget {
  const TextChangeDataStyle({
    super.key,
    required this.value,
    required this.onChanged,
    this.titleLabel = 'Nome da camada',
    this.textLabel = 'Texto',
    this.availableTextFields = const <String>[],
    this.useFieldSelectorWhenAvailable = true,
    this.textFieldBuilder,
    this.dropdownBuilder,
    this.numberFieldBuilder,
    this.colorPickerBuilder,
  });

  final TextChangeData value;
  final ValueChanged<TextChangeData> onChanged;

  final String titleLabel;
  final String textLabel;

  /// Quando informado, o campo de texto passa a poder usar seletor de campos.
  final List<String> availableTextFields;

  /// Se true e houver campos disponíveis, usa dropdown em vez de texto livre.
  final bool useFieldSelectorWhenAvailable;

  /// Builder externo para campo de texto.
  ///
  /// Exemplo: CustomTextField do SIPGED/sipged.
  final TextChangeTextFieldBuilder? textFieldBuilder;

  /// Builder externo para dropdown.
  ///
  /// Exemplo: DropDownChange.
  final TextChangeDropdownBuilder? dropdownBuilder;

  /// Builder externo para campo numérico.
  ///
  /// Exemplo: NumberField.
  final TextChangeNumberFieldBuilder? numberFieldBuilder;

  /// Builder externo para seletor de cor.
  ///
  /// Exemplo: ColorsChangeCatalog.
  final TextChangeColorPickerBuilder? colorPickerBuilder;

  @override
  State<TextChangeDataStyle> createState() => _TextChangeDataStyleState();
}

class _TextChangeDataStyleState extends State<TextChangeDataStyle> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _textCtrl;
  late final TextEditingController _fontWeightCtrl;

  static const String _weightNormal = 'Normal';
  static const String _weightMedium = 'Médio';
  static const String _weightSemiBold = 'Semi negrito';
  static const String _weightBold = 'Negrito';

  bool get _useFieldSelector {
    return widget.useFieldSelectorWhenAvailable &&
        widget.availableTextFields.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();

    _titleCtrl = TextEditingController(text: widget.value.title);
    _textCtrl = TextEditingController(text: widget.value.text);
    _fontWeightCtrl = TextEditingController(
      text: _labelFromFontWeight(widget.value.fontWeight),
    );
  }

  @override
  void didUpdateWidget(covariant TextChangeDataStyle oldWidget) {
    super.didUpdateWidget(oldWidget);

    final shouldSyncControllers = oldWidget.value != widget.value ||
        oldWidget.availableTextFields != widget.availableTextFields ||
        oldWidget.useFieldSelectorWhenAvailable !=
            widget.useFieldSelectorWhenAvailable;

    if (!shouldSyncControllers) return;

    _setControllerText(_titleCtrl, widget.value.title);
    _setControllerText(_textCtrl, widget.value.text);
    _setControllerText(
      _fontWeightCtrl,
      _labelFromFontWeight(widget.value.fontWeight),
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _textCtrl.dispose();
    _fontWeightCtrl.dispose();

    super.dispose();
  }

  void _setControllerText(
      TextEditingController controller,
      String value,
      ) {
    if (controller.text == value) return;

    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  void _emit(TextChangeData value) {
    _setControllerText(
      _fontWeightCtrl,
      _labelFromFontWeight(value.fontWeight),
    );

    widget.onChanged(value);
  }

  String _labelFromFontWeight(FontWeight weight) {
    if (weight == FontWeight.w400) return _weightNormal;
    if (weight == FontWeight.w500) return _weightMedium;
    if (weight == FontWeight.w700) return _weightBold;

    return _weightSemiBold;
  }

  FontWeight _fontWeightFromLabel(String? value) {
    switch (value) {
      case _weightNormal:
        return FontWeight.w400;
      case _weightMedium:
        return FontWeight.w500;
      case _weightBold:
        return FontWeight.w700;
      case _weightSemiBold:
      default:
        return FontWeight.w600;
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required ValueChanged<String> onChanged,
  }) {
    final externalBuilder = widget.textFieldBuilder;

    if (externalBuilder != null) {
      return externalBuilder(
        context: context,
        controller: controller,
        labelText: labelText,
        onChanged: onChanged,
      );
    }

    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }

  Widget _buildDropdown({
    required TextEditingController controller,
    required String labelText,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    bool enabled = true,
  }) {
    final externalBuilder = widget.dropdownBuilder;

    if (externalBuilder != null) {
      return externalBuilder(
        context: context,
        controller: controller,
        labelText: labelText,
        items: items,
        onChanged: onChanged,
        enabled: enabled,
      );
    }

    final selectedValue = items.contains(controller.text) ? controller.text : null;

    return DropdownButtonFormField<String>(
      initialValue: selectedValue,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(
            item,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(growable: false),
      onChanged: enabled ? onChanged : null,
    );
  }

  Widget _buildNumberField({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    final externalBuilder = widget.numberFieldBuilder;

    if (externalBuilder != null) {
      return externalBuilder(
        context: context,
        label: label,
        value: value,
        onChanged: onChanged,
      );
    }

    return _FallbackNumberField(
      label: label,
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _buildColorPicker() {
    final externalBuilder = widget.colorPickerBuilder;

    if (externalBuilder != null) {
      return externalBuilder(
        context: context,
        title: 'Cor do texto',
        selectedColorValue: widget.value.colorValue,
        onChanged: (value) {
          _emit(widget.value.copyWith(colorValue: value));
        },
      );
    }

    return _FallbackColorField(
      title: 'Cor do texto',
      selectedColorValue: widget.value.colorValue,
      onChanged: (value) {
        _emit(widget.value.copyWith(colorValue: value));
      },
    );
  }

  Widget _buildTextSourceField() {
    if (_useFieldSelector) {
      return _buildDropdown(
        controller: _textCtrl,
        labelText: widget.textLabel,
        items: widget.availableTextFields,
        enabled: widget.availableTextFields.isNotEmpty,
        onChanged: (value) {
          final nextValue = value ?? '';

          _setControllerText(_textCtrl, nextValue);
          _emit(widget.value.copyWith(text: nextValue));
        },
      );
    }

    return _buildTextField(
      controller: _textCtrl,
      labelText: widget.textLabel,
      onChanged: (value) {
        _emit(widget.value.copyWith(text: value));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final safeMaxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;

        final isSmall = safeMaxWidth < 760;
        final fieldWidth = isSmall ? safeMaxWidth : 220.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: isSmall ? safeMaxWidth : 320,
                  child: _buildTextField(
                    controller: _titleCtrl,
                    labelText: widget.titleLabel,
                    onChanged: (value) {
                      _emit(widget.value.copyWith(title: value));
                    },
                  ),
                ),
                Container(
                  width: fieldWidth,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                    color: Colors.white,
                  ),
                  child: CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Ativo'),
                    value: widget.value.enabled,
                    onChanged: (value) {
                      _emit(
                        widget.value.copyWith(
                          enabled: value ?? true,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTextSourceField(),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: fieldWidth,
                  child: _buildNumberField(
                    label: 'Tamanho da fonte',
                    value: widget.value.fontSize,
                    onChanged: (value) {
                      _emit(widget.value.copyWith(fontSize: value));
                    },
                  ),
                ),
                SizedBox(
                  width: fieldWidth,
                  child: _buildDropdown(
                    controller: _fontWeightCtrl,
                    labelText: 'Peso da fonte',
                    items: const <String>[
                      _weightNormal,
                      _weightMedium,
                      _weightSemiBold,
                      _weightBold,
                    ],
                    onChanged: (value) {
                      _emit(
                        widget.value.copyWith(
                          fontWeight: _fontWeightFromLabel(value),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: fieldWidth,
                  child: _buildNumberField(
                    label: 'Offset horizontal (X)',
                    value: widget.value.offsetX,
                    onChanged: (value) {
                      _emit(widget.value.copyWith(offsetX: value));
                    },
                  ),
                ),
                SizedBox(
                  width: fieldWidth,
                  child: _buildNumberField(
                    label: 'Offset vertical (Y)',
                    value: widget.value.offsetY,
                    onChanged: (value) {
                      _emit(widget.value.copyWith(offsetY: value));
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildColorPicker(),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }
}

class _FallbackNumberField extends StatefulWidget {
  const _FallbackNumberField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  State<_FallbackNumberField> createState() => _FallbackNumberFieldState();
}

class _FallbackNumberFieldState extends State<_FallbackNumberField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(
      text: _formatDouble(widget.value),
    );
  }

  @override
  void didUpdateWidget(covariant _FallbackNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.value == widget.value) return;

    final nextText = _formatDouble(widget.value);

    if (_controller.text == nextText) return;

    _controller.value = TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: nextText.length),
    );
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  String _formatDouble(double value) {
    if (value % 1 == 0) {
      return value.toInt().toString();
    }

    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: true,
      ),
      decoration: InputDecoration(
        labelText: widget.label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      onChanged: (value) {
        final parsed = double.tryParse(
          value.trim().replaceAll(',', '.'),
        );

        if (parsed == null) return;

        widget.onChanged(parsed);
      },
    );
  }
}

class _FallbackColorField extends StatelessWidget {
  const _FallbackColorField({
    required this.title,
    required this.selectedColorValue,
    required this.onChanged,
  });

  final String title;
  final int selectedColorValue;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final selectedColor = Color(selectedColorValue);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 10),
        InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => onChanged(selectedColorValue),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: selectedColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.black.withValues(alpha: 0.16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}