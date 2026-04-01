import 'package:flutter/material.dart';
import 'package:sipged/_widgets/draw/colors/checkerboard_painter.dart';
import 'package:sipged/_widgets/draw/colors/horizontal_gradient_slider.dart';
import 'package:sipged/_widgets/draw/colors/saturation_value_box.dart';
import 'package:sipged/_widgets/draw/colors/vertical_hue_slider.dart';

class ColorsCatalogDialog extends StatefulWidget {
  final int initialColorValue;
  final String title;

  const ColorsCatalogDialog({super.key,
    required this.initialColorValue,
    required this.title,
  });

  @override
  State<ColorsCatalogDialog> createState() => _ColorsCatalogDialogState();
}

class _ColorsCatalogDialogState extends State<ColorsCatalogDialog> {
  late HSVColor _hsvColor;
  late double _alpha;

  late final TextEditingController _hCtrl;
  late final TextEditingController _sCtrl;
  late final TextEditingController _vCtrl;
  late final TextEditingController _rCtrl;
  late final TextEditingController _gCtrl;
  late final TextEditingController _bCtrl;
  late final TextEditingController _aCtrl;
  late final TextEditingController _hexCtrl;

  bool _isUpdatingTextFields = false;

  @override
  void initState() {
    super.initState();
    final initialColor = Color(widget.initialColorValue);
    _hsvColor = HSVColor.fromColor(initialColor);
    _alpha = _alpha8(initialColor) / 255.0;

    _hCtrl = TextEditingController();
    _sCtrl = TextEditingController();
    _vCtrl = TextEditingController();
    _rCtrl = TextEditingController();
    _gCtrl = TextEditingController();
    _bCtrl = TextEditingController();
    _aCtrl = TextEditingController();
    _hexCtrl = TextEditingController();

    _syncControllersFromColor();
  }

  @override
  void dispose() {
    _hCtrl.dispose();
    _sCtrl.dispose();
    _vCtrl.dispose();
    _rCtrl.dispose();
    _gCtrl.dispose();
    _bCtrl.dispose();
    _aCtrl.dispose();
    _hexCtrl.dispose();
    super.dispose();
  }

  Color get _selectedColor {
    final base = _hsvColor.toColor();
    return Color.fromARGB(
      (_alpha * 255).round().clamp(0, 255),
      _red8(base),
      _green8(base),
      _blue8(base),
    );
  }

  void _syncControllersFromColor() {
    _isUpdatingTextFields = true;
    final color = _selectedColor;

    _hCtrl.text = _hsvColor.hue.round().toString();
    _sCtrl.text = (_hsvColor.saturation * 100).round().toString();
    _vCtrl.text = (_hsvColor.value * 100).round().toString();

    _rCtrl.text = _red8(color).toString();
    _gCtrl.text = _green8(color).toString();
    _bCtrl.text = _blue8(color).toString();
    _aCtrl.text = (_alpha * 100).round().toString();
    _hexCtrl.text = _hexRgb(color);

    _isUpdatingTextFields = false;
  }

  void _updateFromHsv({
    double? hue,
    double? saturation,
    double? value,
    double? alpha,
  }) {
    setState(() {
      _hsvColor = _hsvColor.withHue((hue ?? _hsvColor.hue).clamp(0.0, 360.0));
      _hsvColor = _hsvColor.withSaturation(
        (saturation ?? _hsvColor.saturation).clamp(0.0, 1.0),
      );
      _hsvColor = _hsvColor.withValue(
        (value ?? _hsvColor.value).clamp(0.0, 1.0),
      );
      _alpha = (alpha ?? _alpha).clamp(0.0, 1.0);
      _syncControllersFromColor();
    });
  }

  void _updateFromRgb({
    int? red,
    int? green,
    int? blue,
    double? alpha,
  }) {
    final current = _selectedColor;
    final next = Color.fromARGB(
      (((alpha ?? _alpha) * 255).round()).clamp(0, 255),
      (red ?? _red8(current)).clamp(0, 255),
      (green ?? _green8(current)).clamp(0, 255),
      (blue ?? _blue8(current)).clamp(0, 255),
    );

    setState(() {
      _hsvColor = HSVColor.fromColor(next).withAlpha(1);
      _alpha = _alpha8(next) / 255.0;
      _syncControllersFromColor();
    });
  }

  void _updateFromHex(String raw) {
    final sanitized = raw
        .trim()
        .replaceAll('#', '')
        .replaceAll('0x', '')
        .replaceAll('0X', '')
        .toUpperCase();

    if (sanitized.length != 6 && sanitized.length != 8) return;

    final parsed = int.tryParse(sanitized, radix: 16);
    if (parsed == null) return;

    Color color;
    if (sanitized.length == 6) {
      color = Color(0xFF000000 | parsed);
    } else {
      color = Color(parsed);
    }

    setState(() {
      _hsvColor = HSVColor.fromColor(color).withAlpha(1);
      _alpha = _alpha8(color) / 255.0;
      _syncControllersFromColor();
    });
  }

  void _onTextFieldChanged(VoidCallback action) {
    if (_isUpdatingTextFields) return;
    action();
  }

  @override
  Widget build(BuildContext context) {
    final selectedColor = _selectedColor;
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 980,
          maxHeight: 760,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
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
              const SizedBox(height: 10),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 760;

                    if (isCompact) {
                      return SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildPickerPanel(compact: true),
                            const SizedBox(height: 16),
                            _buildControlsPanel(theme, selectedColor),
                          ],
                        ),
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 11,
                          child: _buildPickerPanel(compact: false),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          flex: 12,
                          child: _buildControlsPanel(theme, selectedColor),
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
                        Navigator.of(context).pop(_selectedColor.toARGB32()),
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

  Widget _buildPickerPanel({required bool compact}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: AspectRatio(
        aspectRatio: compact ? 1.1 : 1.22,
        child: Row(
          children: [
            Expanded(
              child: SaturationValueBox(
                hue: _hsvColor.hue,
                saturation: _hsvColor.saturation,
                value: _hsvColor.value,
                onChanged: (saturation, value) {
                  _updateFromHsv(
                    saturation: saturation,
                    value: value,
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 28,
              child: VerticalHueSlider(
                hue: _hsvColor.hue,
                onChanged: (hue) {
                  _updateFromHsv(hue: hue);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsPanel(ThemeData theme, Color selectedColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildPreview(selectedColor),
            const SizedBox(height: 16),
            _buildSliderRow(
              label: 'H',
              valueText: '${_hsvColor.hue.round()}°',
              child: HorizontalGradientSlider(
                value: _hsvColor.hue / 360.0,
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFF0000),
                    Color(0xFFFFFF00),
                    Color(0xFF00FF00),
                    Color(0xFF00FFFF),
                    Color(0xFF0000FF),
                    Color(0xFFFF00FF),
                    Color(0xFFFF0000),
                  ],
                ),
                onChanged: (t) => _updateFromHsv(hue: t * 360.0),
              ),
            ),
            const SizedBox(height: 12),
            _buildSliderRow(
              label: 'S',
              valueText: '${(_hsvColor.saturation * 100).round()}%',
              child: HorizontalGradientSlider(
                value: _hsvColor.saturation,
                gradient: LinearGradient(
                  colors: [
                    HSVColor.fromAHSV(1, _hsvColor.hue, 0, _hsvColor.value)
                        .toColor(),
                    HSVColor.fromAHSV(1, _hsvColor.hue, 1, _hsvColor.value)
                        .toColor(),
                  ],
                ),
                onChanged: (t) => _updateFromHsv(saturation: t),
              ),
            ),
            const SizedBox(height: 12),
            _buildSliderRow(
              label: 'V',
              valueText: '${(_hsvColor.value * 100).round()}%',
              child: HorizontalGradientSlider(
                value: _hsvColor.value,
                gradient: LinearGradient(
                  colors: [
                    Colors.black,
                    HSVColor.fromAHSV(
                      1,
                      _hsvColor.hue,
                      _hsvColor.saturation,
                      1,
                    ).toColor(),
                  ],
                ),
                onChanged: (t) => _updateFromHsv(value: t),
              ),
            ),
            const SizedBox(height: 12),
            _buildSliderRow(
              label: 'Opacidade',
              valueText: '${(_alpha * 100).round()}%',
              child: HorizontalGradientSlider(
                value: _alpha,
                checkerboard: true,
                gradient: LinearGradient(
                  colors: [
                    selectedColor.withValues(alpha: 0),
                    selectedColor.withValues(alpha: 1),
                  ],
                ),
                onChanged: (t) => _updateFromHsv(alpha: t),
              ),
            ),
            const SizedBox(height: 18),
            _buildNumericSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(Color selectedColor) {
    return Row(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade400),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(
                    painter: CheckerboardPainter()
                ),
                ColoredBox(color: selectedColor),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cor selecionada',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              SelectableText(
                hexArgb(selectedColor),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'RGB(${_red8(selectedColor)}, ${_green8(selectedColor)}, ${_blue8(selectedColor)})  •  α ${(100 * _alpha).round()}%',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSliderRow({
    required String label,
    required String valueText,
    required Widget child,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 82,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(child: child),
        const SizedBox(width: 10),
        SizedBox(
          width: 72,
          child: Text(
            valueText,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNumericSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _NumberField(
                controller: _hCtrl,
                label: 'H',
                suffix: '°',
                onChanged: (text) => _onTextFieldChanged(() {
                  final value = int.tryParse(text);
                  if (value == null) return;
                  _updateFromHsv(hue: value.toDouble());
                }),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _NumberField(
                controller: _sCtrl,
                label: 'S',
                suffix: '%',
                onChanged: (text) => _onTextFieldChanged(() {
                  final value = int.tryParse(text);
                  if (value == null) return;
                  _updateFromHsv(saturation: value / 100.0);
                }),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _NumberField(
                controller: _vCtrl,
                label: 'V',
                suffix: '%',
                onChanged: (text) => _onTextFieldChanged(() {
                  final value = int.tryParse(text);
                  if (value == null) return;
                  _updateFromHsv(value: value / 100.0);
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _NumberField(
                controller: _rCtrl,
                label: 'R',
                onChanged: (text) => _onTextFieldChanged(() {
                  final value = int.tryParse(text);
                  if (value == null) return;
                  _updateFromRgb(red: value);
                }),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _NumberField(
                controller: _gCtrl,
                label: 'G',
                onChanged: (text) => _onTextFieldChanged(() {
                  final value = int.tryParse(text);
                  if (value == null) return;
                  _updateFromRgb(green: value);
                }),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _NumberField(
                controller: _bCtrl,
                label: 'B',
                onChanged: (text) => _onTextFieldChanged(() {
                  final value = int.tryParse(text);
                  if (value == null) return;
                  _updateFromRgb(blue: value);
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _NumberField(
                controller: _aCtrl,
                label: 'Opacidade',
                suffix: '%',
                onChanged: (text) => _onTextFieldChanged(() {
                  final value = int.tryParse(text);
                  if (value == null) return;
                  _updateFromHsv(alpha: value / 100.0);
                }),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: TextField(
                controller: _hexCtrl,
                decoration: const InputDecoration(
                  labelText: 'HEX',
                  prefixText: '#',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onChanged: (text) => _onTextFieldChanged(() {
                  if (text.length == 6 || text.length == 8) {
                    _updateFromHex(text);
                  }
                }),
              ),
            ),
          ],
        ),
      ],
    );
  }
}


class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? suffix;
  final ValueChanged<String> onChanged;

  const _NumberField({
    required this.controller,
    required this.label,
    required this.onChanged,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        isDense: true,
        border: const OutlineInputBorder(),
      ),
      onChanged: onChanged,
    );
  }
}

int _red8(Color color) => (color.r * 255.0).round().clamp(0, 255);
int _green8(Color color) => (color.g * 255.0).round().clamp(0, 255);
int _blue8(Color color) => (color.b * 255.0).round().clamp(0, 255);

int _alpha8(Color color) => (color.a * 255.0).round().clamp(0, 255);
String _hexRgb(Color color) {
  final hex = (_red8(color) << 16) | (_green8(color) << 8) | _blue8(color);
  return hex.toRadixString(16).padLeft(6, '0').toUpperCase();
}

String hexArgb(Color color) {
  return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';
}