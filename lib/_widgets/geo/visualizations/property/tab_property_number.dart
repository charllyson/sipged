import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/geo_workspace_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/geo_workspace_data_property.dart';


class TabPropertyNumber extends StatefulWidget {
  const TabPropertyNumber({
    super.key,
    required this.property,
    required this.onChanged,
  });

  final GeoWorkspaceDataProperty property;
  final ValueChanged<double> onChanged;

  @override
  State<TabPropertyNumber> createState() => _TabPropertyNumberState();
}

class _TabPropertyNumberState extends State<TabPropertyNumber> {
  late final TextEditingController _controller;

  String get _externalValue => widget.property.numberValue?.toString() ?? '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _externalValue);
  }

  @override
  void didUpdateWidget(covariant TabPropertyNumber oldWidget) {
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
