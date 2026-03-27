import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/geo_workspace_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/geo_workspace_data_property.dart';

class TabPropertyText extends StatefulWidget {
  const TabPropertyText({
    super.key,
    required this.property,
    required this.onChanged,
  });

  final GeoWorkspaceDataProperty property;
  final ValueChanged<String> onChanged;

  @override
  State<TabPropertyText> createState() => _TabPropertyTextState();
}

class _TabPropertyTextState extends State<TabPropertyText> {
  late final TextEditingController _controller;

  String get _externalValue => widget.property.textValue ?? '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _externalValue);
  }

  @override
  void didUpdateWidget(covariant TabPropertyText oldWidget) {
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
      onChanged: widget.onChanged,
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
