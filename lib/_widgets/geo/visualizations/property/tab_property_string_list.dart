import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/geo_workspace_data_property.dart';

class TabPropertyStringList extends StatefulWidget {
  const TabPropertyStringList({
    super.key,
    required this.property,
    required this.onChanged,
  });

  final GeoWorkspaceDataProperty property;
  final ValueChanged<List<String>> onChanged;

  @override
  State<TabPropertyStringList> createState() =>
      _TabPropertyStringListState();
}

class _TabPropertyStringListState extends State<TabPropertyStringList> {
  late final TextEditingController _controller;

  String get _externalValue =>
      (widget.property.stringListValue ?? const []).join(', ');

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _externalValue);
  }

  @override
  void didUpdateWidget(covariant TabPropertyStringList oldWidget) {
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
      minLines: 1,
      maxLines: 3,
      onChanged: (value) {
        final next = value
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(growable: false);
        widget.onChanged(next);
      },
      decoration: InputDecoration(
        isDense: true,
        hintText: widget.property.hint ?? 'Separar por vírgula',
        border: const OutlineInputBorder(),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
    );
  }
}
