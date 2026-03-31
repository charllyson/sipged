import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/text_change_data.dart';
import 'package:sipged/_utils/number_field.dart';
import 'package:sipged/_widgets/draw/colors/colors_change_catalog.dart';
import 'package:sipged/_widgets/input/text_field_change.dart';
import 'package:sipged/_widgets/input/drop_down_change.dart';

class TextChangeDataStyle extends StatefulWidget {
  final TextChangeData value;
  final ValueChanged<TextChangeData> onChanged;

  final String titleLabel;
  final String textLabel;

  /// Quando informado, o campo de texto passa a ser um seletor de campos.
  final List<String> availableTextFields;

  /// Se true e houver campos disponíveis, usa dropdown em vez de texto livre.
  final bool useFieldSelectorWhenAvailable;

  const TextChangeDataStyle({
    super.key,
    required this.value,
    required this.onChanged,
    this.titleLabel = 'Nome da camada',
    this.textLabel = 'Texto',
    this.availableTextFields = const [],
    this.useFieldSelectorWhenAvailable = true,
  });

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

  bool get _useFieldSelector =>
      widget.useFieldSelectorWhenAvailable &&
          widget.availableTextFields.isNotEmpty;

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

    if (oldWidget.value != widget.value ||
        oldWidget.availableTextFields != widget.availableTextFields ||
        oldWidget.useFieldSelectorWhenAvailable !=
            widget.useFieldSelectorWhenAvailable) {
      _titleCtrl.text = widget.value.title;
      _textCtrl.text = widget.value.text;
      _fontWeightCtrl.text = _labelFromFontWeight(widget.value.fontWeight);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _textCtrl.dispose();
    _fontWeightCtrl.dispose();
    super.dispose();
  }

  void _emit(TextChangeData value) {
    _fontWeightCtrl.text = _labelFromFontWeight(value.fontWeight);
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

  Widget _buildTextSourceField() {
    if (_useFieldSelector) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropDownChange(
            controller: _textCtrl,
            labelText: widget.textLabel,
            width: double.infinity,
            items: widget.availableTextFields,
            enabled: widget.availableTextFields.isNotEmpty,
            onChanged: (value) {
              _emit(widget.value.copyWith(text: value ?? ''));
            },
          ),
        ],
      );
    }

    return CustomTextField(
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
        final isSmall = constraints.maxWidth < 760;
        final fieldWidth = isSmall ? constraints.maxWidth : 220.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: isSmall ? constraints.maxWidth : 320,
                  child: CustomTextField(
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
                    onChanged: (v) {
                      _emit(widget.value.copyWith(enabled: v ?? true));
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTextSourceField(),
            if (!_useFieldSelector && widget.availableTextFields.isEmpty) ...[
              const SizedBox(height: 6),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: fieldWidth,
                  child: NumberField(
                    label: 'Tamanho da fonte',
                    value: widget.value.fontSize,
                    onChanged: (value) {
                      _emit(widget.value.copyWith(fontSize: value));
                    },
                  ),
                ),
                SizedBox(
                  width: fieldWidth,
                  child: DropDownChange(
                    controller: _fontWeightCtrl,
                    labelText: 'Peso da fonte',
                    width: double.infinity,
                    items: const [
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
                  child: NumberField(
                    label: 'Offset horizontal (X)',
                    value: widget.value.offsetX,
                    onChanged: (value) {
                      _emit(widget.value.copyWith(offsetX: value));
                    },
                  ),
                ),
                SizedBox(
                  width: fieldWidth,
                  child: NumberField(
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
            ColorsChangeCatalog(
              title: 'Cor do texto',
              selectedColorValue: widget.value.colorValue,
              onChanged: (value) {
                _emit(widget.value.copyWith(colorValue: value));
              },
            ),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }
}